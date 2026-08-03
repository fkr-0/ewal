;;; ewal-theme-contrast-check.el --- Theme contrast checking and suggestions -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Contrast measurement, reporting, correction, and persistence for Emacs
;; themes.  The optional Transient interface lives in
;; `ewal-theme-contrast-panel.el' so this library stays batch-friendly.

;;; Code:

(require 'cl-lib)
(require 'color)
(require 'ewal-color-utils)
(require 'pp)

(declare-function ewal-theme-contrast-panel "ewal-theme-contrast-panel" ())

(defgroup ewal-contrast nil
  "Contrast checking and auto-fix helpers for themes."
  :group 'faces)

(defvar ewal-base-palette nil
  "Loaded `ewal` base palette as an alist.

This is declared here to avoid a hard dependency on `ewal.el'.")

(defcustom ewal-contrast-suggestion-strategy 'default
  "Suggestion strategy used by interactive contrast fixes.

`default' uses darken/lighten tweaks, `palette' picks a better
foreground/background from palette + black/white, and
`black-white' only tries black/white replacements."
  :type '(choice (const :tag "Default tweak" default)
           (const :tag "Palette + black/white" palette)
           (const :tag "Black/white only" black-white))
  :group 'ewal-contrast)

(defcustom ewal-contrast-user-overrides nil
  "Theme-specific face overrides produced by contrast fixing.

Format:
  ((THEME . ((FACE . (:foreground \"#...\" :background \"#...\")) ...)) ...)"
  :type 'sexp
  :group 'ewal-contrast)

(defvar ewal-contrast-current-theme nil
  "Theme symbol currently targeted by the contrast panel.")

(defvar ewal-contrast-current-min-contrast 4.5
  "Minimum contrast currently used by the contrast panel.")

(defun ewal-theme-contrast-ratio (color1 color2)
  "Calculate WCAG contrast ratio between COLOR1 and COLOR2.

COLOR1 and COLOR2 are strings understood by `color-name-to-rgb`."
  (ewal-color-contrast-ratio color1 color2))

(defun ewal-sort-by-low-contrast (warnings)
  "Sort WARNINGS (FACE FG BG RATIO) ascending by RATIO."
  (sort warnings (lambda (a b) (< (nth 3 a) (nth 3 b)))))

(defun ewal--pad-right (string width)
  "Pad STRING on the right with spaces to WIDTH."
  (format (format "%%-%ds" width) string))

(defun ewal--color-dark-p (color)
  "Return non-nil if COLOR is perceived as dark."
  (< (ewal-color-relative-luminance color) 0.5))

(defun ewal--relative-luminance (color)
  "Return relative luminance for COLOR."
  (ewal-color-relative-luminance color))

(defun ewal-contrast--face-color (face attribute)
  "Return FACE ATTRIBUTE as a concrete normalized color, including inheritance."
  (let ((value (face-attribute face attribute nil 'default)))
    (ewal-color-normalize value)))

(defun ewal-check-contrast (theme-faces &optional min-contrast)
  "Check contrast for THEME-FACES.

Return a list of (FACE FOREGROUND BACKGROUND RATIO) for faces
with contrast below MIN-CONTRAST (default 4.5)."
  (let ((min-contrast (or min-contrast 4.5))
         (warnings '())
         (default-bg (ewal-contrast--face-color 'default :background))
         (default-fg (ewal-contrast--face-color 'default :foreground)))
    (dolist (face theme-faces)
      (when (facep face)
        (let* ((fg (or (ewal-contrast--face-color face :foreground) default-fg))
               (bg (or (ewal-contrast--face-color face :background) default-bg)))
          (when (and (stringp fg) (stringp bg))
            (let ((ratio (ewal-theme-contrast-ratio fg bg)))
              (when (< ratio min-contrast)
                (push (list face fg bg ratio) warnings)))))))
    (ewal-sort-by-low-contrast warnings)))

(defun ewal-get-theme-faces (theme)
  "Retrieve all face symbols explicitly defined in THEME."
  (unless (custom-theme-p theme)
    (condition-case err
        (load-theme theme t t)
      (error
       (error "Theme '%s' is not loaded and could not be loaded: %S" theme err))))
  (let (faces)
    (dolist (entry (get theme 'theme-settings))
      (when (eq (car entry) 'theme-face)
        (let ((face-name (cadr entry)))
          (when (symbolp face-name)
            (push face-name faces)))))
    faces))

(defun ewal-check-theme-contrast (theme &optional min-contrast)
  "Check contrast for THEME (a theme symbol).

Return faces whose contrast is below MIN-CONTRAST, defaulting to 4.5."
  (ewal-check-contrast (ewal-get-theme-faces theme) min-contrast))

(defun ewal--autocorrect-candidate-colors ()
  "Return candidate colors for contrast autocorrection.

Candidates include colors from `ewal-base-palette` plus black/white."
  (cl-remove-duplicates
    (append
      (when (listp ewal-base-palette)
        (cl-loop for (_ . value) in ewal-base-palette
                 when (ewal-color-valid-p value)
                 collect (ewal-color-normalize value)))
      '("black" "white"))
    :test #'string-equal))

(defun ewal--best-autocorrect-option (fg bg current-ratio candidates)
  "Return best single-property contrast fix for FG/BG.

CURRENT-RATIO is the current contrast ratio and CANDIDATES are
replacement colors.  Return plist
`(:property PROP :color COLOR :ratio RATIO)' or nil."
  (let ((best-ratio current-ratio)
        (best nil))
    (dolist (candidate candidates)
      (unless (string-equal candidate fg)
        (let ((ratio (ewal-theme-contrast-ratio candidate bg)))
          (when (> ratio best-ratio)
            (setq best-ratio ratio)
            (setq best (list :property :foreground
                         :color candidate
                         :ratio ratio)))))
      (unless (string-equal candidate bg)
        (let ((ratio (ewal-theme-contrast-ratio fg candidate)))
          (when (> ratio best-ratio)
            (setq best-ratio ratio)
            (setq best (list :property :background
                         :color candidate
                         :ratio ratio))))))
    best))

(defun ewal-build-autocorrections (warnings &optional target-ratio)
  "Build autocorrections from WARNINGS.

WARNINGS is a list of (FACE FG BG RATIO).  TARGET-RATIO defaults to
4.5 and is used only as a quality threshold marker in the return value.

Return a list of
\(FACE FG BG RATIO PROP NEW-COLOR NEW-RATIO MEETS-TARGET\)."
  (let ((target-ratio (or target-ratio 4.5))
        (candidates (ewal--autocorrect-candidate-colors))
        (corrections '()))
    (dolist (warning warnings)
      (let* ((face (nth 0 warning))
             (fg (nth 1 warning))
             (bg (nth 2 warning))
             (ratio (nth 3 warning))
             (best (ewal--best-autocorrect-option fg bg ratio candidates)))
        (when best
          (let ((new-ratio (plist-get best :ratio)))
            (push (list face
                    fg
                    bg
                    ratio
                    (plist-get best :property)
                    (plist-get best :color)
                    new-ratio
                    (>= new-ratio target-ratio))
              corrections)))))
    (nreverse corrections)))

(defun ewal--apply-autocorrections (corrections)
  "Apply CORRECTIONS returned by `ewal-build-autocorrections'."
  (dolist (entry corrections)
    (set-face-attribute (nth 0 entry) nil (nth 4 entry) (nth 5 entry))))

(defun ewal--warning-default-fix (warning)
  "Return default contrast fix alist for WARNING."
  (let ((fg (nth 1 warning))
        (bg (nth 2 warning)))
    (list (cons :foreground
                (ewal-color-ensure-contrast
                 fg bg ewal-contrast-current-min-contrast
                 (ewal--autocorrect-candidate-colors))))))

(defun ewal--warning-palette-fix (warning &optional black-white-only)
  "Return palette-based single-property fix for WARNING.

When BLACK-WHITE-ONLY is non-nil, candidates are only black/white."
  (let* ((fg (nth 1 warning))
         (bg (nth 2 warning))
         (ratio (nth 3 warning))
         (candidates (if black-white-only
                         '("black" "white")
                       (ewal--autocorrect-candidate-colors)))
         (best (ewal--best-autocorrect-option fg bg ratio candidates)))
    (when best
      (list (cons (plist-get best :property) (plist-get best :color))))))

(defun ewal-warning-suggest-fix (warning &optional strategy)
  "Return fix alist for WARNING according to STRATEGY."
  (pcase (or strategy ewal-contrast-suggestion-strategy)
    ('default (ewal--warning-default-fix warning))
    ('palette (ewal--warning-palette-fix warning))
    ('black-white (ewal--warning-palette-fix warning t))
    (_ (ewal--warning-default-fix warning))))

(defun ewal-contrast-store-override (theme face fixes)
  "Store THEME FACE FIXES into `ewal-contrast-user-overrides'."
  (let* ((theme-entry (assoc theme ewal-contrast-user-overrides))
         (theme-faces (copy-tree (cdr theme-entry)))
         (face-entry (assoc face theme-faces))
         (plist (copy-sequence (or (cdr face-entry) '()))))
    (dolist (fix fixes)
      (setq plist (plist-put plist (car fix) (cdr fix))))
    (if face-entry
        (setcdr face-entry plist)
      (push (cons face plist) theme-faces))
    (if theme-entry
        (setcdr theme-entry theme-faces)
      (push (cons theme theme-faces) ewal-contrast-user-overrides))))

(defun ewal-apply-theme-face-overrides (&optional theme)
  "Apply overrides from `ewal-contrast-user-overrides` for THEME."
  (interactive)
  (let* ((theme (or theme (ewal-contrast--resolve-theme)))
         (theme-faces (cdr (assoc theme ewal-contrast-user-overrides))))
    (dolist (entry theme-faces)
      (let ((face (car entry))
            (props (cdr entry)))
        (when (facep face)
          (while props
            (set-face-attribute face nil (pop props) (pop props))))))
    (when theme
      (ewal-contrast-check-refresh theme))))

(defun ewal-contrast-overrides-use-package-sexp ()
  "Return a pasteable `use-package` snippet for current overrides."
  (let* ((payload (pp-to-string ewal-contrast-user-overrides))
         (payload (replace-regexp-in-string "\n\\'" "" payload))
         (payload-lines (split-string payload "\n"))
         (payload (concat "'" (car payload-lines)
                          (if (cdr payload-lines)
                              (concat "\n"
                                      (mapconcat (lambda (line) (concat "      " line))
                                                 (cdr payload-lines)
                                                 "\n"))
                            ""))))
    (concat
     "(use-package ewal-theme-contrast-check\n"
     "  :config\n"
     "  (setq ewal-contrast-user-overrides\n"
     "      " payload "\n"
     "  )\n"
     "  (ewal-apply-theme-face-overrides))")))

(defun ewal-contrast-copy-use-package-snippet ()
  "Copy a pasteable `use-package` snippet to kill ring."
  (interactive)
  (let ((snippet (ewal-contrast-overrides-use-package-sexp)))
    (kill-new snippet)
    (message "Copied use-package snippet with %d theme override set(s)."
             (length ewal-contrast-user-overrides))))

;;;###autoload
(defun ewal-check-autocorrect (&optional theme trigger-ratio target-ratio apply-fixes)
  "Build contrast autocorrections for THEME.

Checks THEME for faces below TRIGGER-RATIO (default 2.0).  Tries
alternative foreground/background colors from `ewal-base-palette`
plus black/white, and returns replacements aiming for TARGET-RATIO.

With APPLY-FIXES non-nil, apply the suggested changes to faces."
  (interactive
    (list (if custom-enabled-themes (car custom-enabled-themes) nil)
          2.0
          4.5
          current-prefix-arg))
  (let* ((theme (or theme (car custom-enabled-themes)))
         (trigger-ratio (or trigger-ratio 2.0)))
    (if (null theme)
      (progn
        (message "No custom-enabled themes.")
        nil)
      (let* ((warnings (ewal-check-theme-contrast-filtered
                         (ewal-get-theme-faces theme)
                         trigger-ratio))
             (corrections (ewal-build-autocorrections warnings target-ratio)))
        (when apply-fixes
          (ewal--apply-autocorrections corrections))
        (message "Theme %s: %d face(s) below %.2f, %d autocorrection(s)%s."
          theme
          (length warnings)
          trigger-ratio
          (length corrections)
          (if apply-fixes " applied" " suggested"))
        corrections))))

(defun ewal-insert-warning-row (warning pad-face pad-fg pad-bg)
  "Insert a table row for WARNING with paddings PAD-FACE, PAD-FG, PAD-BG."
  (let* ((face (nth 0 warning))
          (fg (nth 1 warning))
          (bg (nth 2 warning))
          (ratio (nth 3 warning))
          (fg-text (if (ewal--color-dark-p fg) "white" "black"))
          (bg-text (if (ewal--color-dark-p bg) "white" "black"))
          (p-face (ewal--pad-right (symbol-name face) pad-face))
          (p-fg   (ewal--pad-right fg pad-fg))
          (p-bg   (ewal--pad-right bg pad-bg))
          (def-fg (face-attribute 'default :foreground nil))
          (def-bg (face-attribute 'default :background nil))
          (preview-start nil)
          (preview-end nil))
    (insert "| ")
    (insert (propertize p-face 'face `(:foreground ,fg-text :background ,fg)))
    (insert " | ")
    (insert (propertize "text" 'face `(:foreground ,def-fg :background ,def-bg)))
    (insert " | ")
    (insert (propertize (format "%.2f" ratio) 'face `(:foreground ,def-fg :background ,def-bg)))
    (insert " | ")
    (setq preview-start (point))
    (insert " Preview ")
    (setq preview-end (point))
    (let ((overlay (make-overlay preview-start preview-end)))
      (overlay-put overlay 'face `(:foreground ,fg :background ,bg)))
    (insert " | ")
    (insert (propertize p-fg 'face `(:foreground ,fg-text :background ,fg)))
    (insert " | ")
    (insert (propertize p-bg 'face `(:foreground ,bg-text :background ,bg)))
    (insert " |\n")))

(defun ewal-display-contrast-warnings (warnings)
  "Display WARNINGS (FACE FG BG RATIO) in a simple org-like table."
  (let ((buffer (get-buffer-create "*Theme Contrast Warnings*")))
    (with-current-buffer buffer
      (erase-buffer)
      (if (null warnings)
        (insert "No faces with low contrast.\n")
        (let* ((header (format "Faces with low contrast (%d):\n\n"
                         (length warnings)))
                (pad-face (max 10 (apply #'max (mapcar (lambda (w)
                                                         (length (symbol-name (nth 0 w))))
                                                 warnings))))
                (pad-fg (max 10 (apply #'max (mapcar (lambda (w)
                                                       (length (nth 1 w)))
                                               warnings))))
                (pad-bg (max 10 (apply #'max (mapcar (lambda (w)
                                                       (length (nth 2 w)))
                                               warnings))))
                (table-header (format "| %s | %s | %s | %s | %s | %s |\n"
                                (ewal--pad-right "Face" pad-face)
                                "Text"
                                "Cntr"
                                "Preview"
                                (ewal--pad-right "Foreground" pad-fg)
                                (ewal--pad-right "Background" pad-bg))))
          (insert header)
          (insert (make-string (1- (length table-header)) ?-) "\n")
          (insert table-header)
          (insert (make-string (1- (length table-header)) ?-) "\n")
          (dolist (warning warnings)
            (ewal-insert-warning-row warning pad-face pad-fg pad-bg))
          (insert (make-string (length header) ?-) "\n")))
      (goto-char (point-min)))
    (pop-to-buffer buffer)))

(defun ewal-suggest-face-fix (face)
  "Suggest tweaks for FACE with low contrast.

Return an alist like ((:foreground . \"#...\") (:background . \"#...\")),
or nil when no changes are needed."
  (let* ((fg (ewal-contrast--face-color face :foreground))
          (bg (ewal-contrast--face-color face :background))
          (suggestions '()))
    (when (and (stringp fg) (stringp bg))
      (let ((ratio (ewal-theme-contrast-ratio fg bg)))
        (when (< ratio 4.5)
          (push (cons :foreground
                      (ewal-color-ensure-contrast
                       fg bg ewal-contrast-current-min-contrast
                       (ewal--autocorrect-candidate-colors)))
                suggestions))))
    suggestions))

(defun ewal-fix-face (face fixes)
  "Apply FIXES plist (alist) to FACE."
  (dolist (prop fixes)
    (set-face-attribute face nil (car prop) (cdr prop))))

;;;###autoload
(defun ewal-check-and-fix-theme (theme)
  "Check THEME for contrast issues and interactively offer fixes."
  (interactive
    (list (intern (completing-read
                    "Theme: "
                    (mapcar #'symbol-name custom-known-themes)
                    nil t nil nil
                    (symbol-name (car custom-enabled-themes))))))
  (setq ewal-contrast-current-theme theme)
  (let ((warnings (ewal-check-theme-contrast theme)))
    (if (null warnings)
      (message "Theme %s: no contrast issues." theme)
      (ewal-display-contrast-warnings warnings)
      (dolist (warning warnings)
        (let ((face (nth 0 warning)))
          (when (yes-or-no-p (format "Fix face %s? " face))
            (let ((fixes (ewal-warning-suggest-fix warning)))
              (when fixes
                (ewal-fix-face face fixes)
                (ewal-contrast-store-override theme face fixes)))))))
    (ewal-check-theme-contrast-and-report theme ewal-contrast-current-min-contrast)))

(defcustom ewal-check-theme-contrast-ignored-faces
  '("ansi-color-" "vterm-color-" "term-color-" "vertical-border" "tab-line" "tab-bar")
  "List of face name prefixes to ignore when checking contrast."
  :type '(repeat string)
  :group 'ewal-contrast)

(defcustom ewal-contrast-preview-limit 5
  "How many low-contrast rows to include in preview messages."
  :type 'integer
  :group 'ewal-contrast)

(defun ewal-check-theme-contrast-filtered (theme-faces &optional min-contrast)
  "Check contrast for THEME-FACES, ignoring expected cases.

Report faces below MIN-CONTRAST, defaulting to 4.5.  Ignore faces whose names
start with a prefix from
`ewal-check-theme-contrast-ignored-faces`."
  (let ((min-contrast (or min-contrast 4.5))
         (warnings '())
         (default-bg (ewal-contrast--face-color 'default :background))
         (default-fg (ewal-contrast--face-color 'default :foreground)))
    (dolist (face theme-faces)
      (when (facep face)
        (let* ((fg (or (ewal-contrast--face-color face :foreground) default-fg))
               (bg (or (ewal-contrast--face-color face :background) default-bg))
                (ignored (cl-some (lambda (prefix)
                                    (string-prefix-p prefix (symbol-name face)))
                           ewal-check-theme-contrast-ignored-faces)))
          (when (and (stringp fg) (stringp bg)
                  (not ignored))
            (let ((ratio (ewal-theme-contrast-ratio fg bg)))
              (when (< ratio min-contrast)
                (push (list face fg bg ratio) warnings)))))))
    (ewal-sort-by-low-contrast warnings)))

(defun ewal-contrast-warnings-preview (warnings &optional limit)
  "Return a compact preview string for WARNINGS.

WARNINGS is a list of (FACE FOREGROUND BACKGROUND RATIO).  LIMIT is
the number of rows to include (defaults to
`ewal-contrast-preview-limit')."
  (if (null warnings)
    ""
    (let* ((limit (max 0 (or limit ewal-contrast-preview-limit)))
            (rows (cl-subseq warnings 0 (min limit (length warnings)))))
      (mapconcat
        (lambda (warning)
          (format "%-30s %5.2f %s on %s"
            (symbol-name (nth 0 warning))
            (nth 3 warning)
            (nth 1 warning)
            (nth 2 warning)))
        rows
        "\n"))))

(defun ewal-check-theme-contrast-and-report (theme &optional min-contrast preview-limit)
  "Check THEME and report low-contrast faces.

Uses `ewal-check-theme-contrast-filtered' and returns the WARNINGS
list.  MIN-CONTRAST defaults to 4.5 and PREVIEW-LIMIT defaults to
`ewal-contrast-preview-limit'."
  (let* ((min-contrast (or min-contrast 4.5))
          (warnings (ewal-check-theme-contrast-filtered
                      (ewal-get-theme-faces theme)
                      min-contrast)))
    (if (null warnings)
      (message "Theme %s: no contrast issues below %.2f." theme min-contrast)
      (ewal-display-contrast-warnings warnings)
      (message "Theme %s: %d faces below %.2f contrast.\n%s"
        theme
        (length warnings)
        min-contrast
        (ewal-contrast-warnings-preview warnings preview-limit)))
    warnings))

(defun ewal-contrast--resolve-theme ()
  "Return current theme for contrast panel operations."
  (or ewal-contrast-current-theme
      (car custom-enabled-themes)
      (car custom-known-themes)))

(defun ewal-contrast--context-string ()
  "Return compact context string for panel state."
  (format "theme=%s min=%.2f strategy=%s"
          (or (ewal-contrast--resolve-theme) "none")
          ewal-contrast-current-min-contrast
          ewal-contrast-suggestion-strategy))

(defun ewal-contrast-check-refresh (&optional theme)
  "Refresh contrast check buffer for THEME."
  (interactive)
  (let ((theme (or theme (ewal-contrast--resolve-theme))))
    (if theme
        (progn
          (setq ewal-contrast-current-theme theme)
          (ewal-check-theme-contrast-and-report
           theme ewal-contrast-current-min-contrast ewal-contrast-preview-limit))
      (message "No custom-enabled themes."))))

(defun ewal-contrast-preview-suggestions (&optional theme strategy)
  "Preview suggestions for THEME using STRATEGY in a dedicated buffer."
  (interactive)
  (let* ((theme (or theme (ewal-contrast--resolve-theme)))
         (strategy (or strategy ewal-contrast-suggestion-strategy)))
    (if (null theme)
        (message "No theme selected.")
      (let* ((warnings (ewal-check-theme-contrast-filtered
                        (ewal-get-theme-faces theme)
                        ewal-contrast-current-min-contrast))
             (buf (get-buffer-create "*Theme Contrast Suggestions*")))
        (with-current-buffer buf
          (erase-buffer)
          (insert (format "Contrast suggestions for %s (%s, min %.2f)\n\n"
                          theme strategy ewal-contrast-current-min-contrast))
          (if (null warnings)
              (insert "No low-contrast faces to suggest.\n")
            (dolist (warning warnings)
              (let* ((face (nth 0 warning))
                     (ratio (nth 3 warning))
                     (fixes (ewal-warning-suggest-fix warning strategy)))
                (insert (format "%-32s %.2f\n" face ratio))
                (if fixes
                    (dolist (fix fixes)
                      (insert (format "  %s -> %s\n" (car fix) (cdr fix))))
                  (insert "  (no suggestion)\n"))
                (insert "\n")))))
        (pop-to-buffer buf)
        (ewal-contrast-check-refresh theme)))))

(defun ewal-contrast-apply-suggestions (&optional theme strategy)
  "Apply STRATEGY suggestions for THEME and refresh warning buffer."
  (interactive)
  (let* ((theme (or theme (ewal-contrast--resolve-theme)))
         (strategy (or strategy ewal-contrast-suggestion-strategy)))
    (if (null theme)
        (message "No custom-enabled themes.")
      (let* ((warnings (ewal-check-theme-contrast-filtered
                        (ewal-get-theme-faces theme)
                        ewal-contrast-current-min-contrast))
             (applied 0))
        (dolist (warning warnings)
          (let* ((face (nth 0 warning))
                 (fixes (ewal-warning-suggest-fix warning strategy)))
            (when fixes
              (ewal-fix-face face fixes)
              (ewal-contrast-store-override theme face fixes)
              (setq applied (1+ applied)))))
        (ewal-contrast-check-refresh theme)
        (message "Applied %d %s suggestion(s) for %s."
                 applied strategy theme)))))

(defun ewal-contrast-set-theme (theme)
  "Set current contrast panel THEME."
  (interactive
   (list (intern (completing-read
                  "Theme: "
                  (mapcar #'symbol-name custom-known-themes)
                  nil t nil nil
                  (symbol-name (or (ewal-contrast--resolve-theme)
                                   (car custom-known-themes)))))))
  (setq ewal-contrast-current-theme theme)
  (ewal-contrast-check-refresh theme))

(defun ewal-contrast-set-min-contrast (value)
  "Set panel minimum contrast VALUE and refresh."
  (interactive "nMin contrast: ")
  (setq ewal-contrast-current-min-contrast value)
  (ewal-contrast-check-refresh))

(defun ewal-contrast-set-strategy-default ()
  "Switch to default suggestion strategy."
  (interactive)
  (setq ewal-contrast-suggestion-strategy 'default)
  (ewal-contrast-preview-suggestions))

(defun ewal-contrast-set-strategy-palette ()
  "Switch to palette suggestion strategy."
  (interactive)
  (setq ewal-contrast-suggestion-strategy 'palette)
  (ewal-contrast-preview-suggestions))

(defun ewal-contrast-set-strategy-black-white ()
  "Switch to black/white-only suggestion strategy."
  (interactive)
  (setq ewal-contrast-suggestion-strategy 'black-white)
  (ewal-contrast-preview-suggestions))

(defun ewal-contrast-cycle-strategy ()
  "Cycle suggestion strategy and immediately preview suggestions."
  (interactive)
  (setq ewal-contrast-suggestion-strategy
        (pcase ewal-contrast-suggestion-strategy
          ('default 'palette)
          ('palette 'black-white)
          (_ 'default)))
  (ewal-contrast-preview-suggestions))

(defun ewal-contrast-show-status ()
  "Echo current panel state."
  (interactive)
  (message "ewal-contrast %s" (ewal-contrast--context-string)))

(defun ewal-contrast--theme-description ()
  "Return transient description of currently selected theme."
  (format "Set theme (current: %s)" (or (ewal-contrast--resolve-theme) "none")))

(defun ewal-contrast--strategy-description ()
  "Return transient description of current strategy."
  (format "Strategy: %s" ewal-contrast-suggestion-strategy))

(defun ewal-contrast--strategy-label (strategy label)
  "Return LABEL with marker when STRATEGY is currently selected."
  (if (eq ewal-contrast-suggestion-strategy strategy)
      (format "%s [current]" label)
    label))

(defun ewal-contrast--strategy-default-description ()
  "Return transient label for default strategy."
  (ewal-contrast--strategy-label 'default "Use default suggestions"))

(defun ewal-contrast--strategy-palette-description ()
  "Return transient label for palette strategy."
  (ewal-contrast--strategy-label 'palette "Use palette suggestions"))

(defun ewal-contrast--strategy-black-white-description ()
  "Return transient label for black/white strategy."
  (ewal-contrast--strategy-label 'black-white "Use black/white suggestions"))

(defun ewal-contrast--refresh-description ()
  "Return transient label for refresh action."
  (format "Refresh warnings (%s)" (ewal-contrast--context-string)))

(defun ewal-contrast--apply-description ()
  "Return transient label for apply action."
  (format "Apply %s suggestions"
          ewal-contrast-suggestion-strategy))

(defun ewal-contrast--preview-description ()
  "Return transient label for preview action."
  (format "Preview %s suggestions"
          ewal-contrast-suggestion-strategy))

;;;###autoload
(defun ewal-check-current-theme-contrast (&optional min-contrast preview-limit)
  "Check contrast for the currently enabled theme.

With prefix arg MIN-CONTRAST, use that ratio instead of the
default 4.5.  PREVIEW-LIMIT controls how many entries to print in
the message preview."
  (interactive "P")
  (if (null custom-enabled-themes)
    (message "No custom-enabled themes.")
    (ewal-check-theme-contrast-and-report
      (car custom-enabled-themes)
      (or min-contrast 4.5)
      preview-limit)))

;;;###autoload
(defun ewal-check-contrast-panel ()
  "Open the optional Transient contrast workflow panel."
  (interactive)
  (unless (require 'ewal-theme-contrast-panel nil t)
    (user-error "The optional Transient contrast UI is unavailable"))
  (call-interactively #'ewal-theme-contrast-panel))

(defalias 'ewal-contrast-panel #'ewal-check-contrast-panel)

(provide 'ewal-theme-contrast-check)
;;; ewal-theme-contrast-check.el ends here
