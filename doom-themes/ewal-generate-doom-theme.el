;;; ewal-generate-doom-theme.el --- Generate Doom theme dynamically -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Validate, normalize, construct, and optionally write Doom themes from flat
;; Ewal palette alists.

;;; Code:

(require 'cl-lib)
(require 'ewal)
(require 'ewal-color-utils)
(require 'ewal-palette-utils)
(require 'doom-themes)
(require 'ewal-doom-themes)
(require 'seq)

(defcustom ewal-generate-doom-theme-auto-check-contrast t
  "When non-nil, run a contrast audit after loading a generated theme."
  :type 'boolean
  :group 'doom-themes)

(defconst ewal-doom-theme-required-palette-keys
  '(background foreground highlight red green yellow blue magenta cyan)
  "Required keys for generated Doom themes.")

(defun ewal-validate-doom-theme-palette (palette)
  "Validate that PALETTE has all required keys and valid color values.

Signal `user-error' if required keys are missing or invalid."
  (let* ((missing
          (seq-remove (lambda (key) (alist-get key palette))
                      ewal-doom-theme-required-palette-keys))
         (invalid
          (seq-filter
           (lambda (key)
             (let ((value (alist-get key palette)))
               (not (and (stringp value)
                         (color-name-to-rgb value)))))
           ewal-doom-theme-required-palette-keys)))
    (when missing
      (user-error "Palette missing required keys: %s"
                  (mapconcat #'symbol-name missing ", ")))
    (when invalid
      (user-error "Palette has invalid color values for: %s"
                  (mapconcat #'symbol-name invalid ", ")))
    t))

(defun ewal-normalize-doom-theme-palette (palette)
  "Return a contrast-safe copy of flat Doom PALETTE.

All text roles are made distinct from `background' and adjusted to at least
`ewal-doom-themes-min-contrast'.  `highlight' is treated as a UI accent and
uses `ewal-doom-themes-min-ui-contrast'."
  (ewal-validate-doom-theme-palette palette)
  (let* ((palette (copy-tree palette))
         (background (ewal-color-normalize (alist-get 'background palette)))
         (candidates (ewal-palette-color-values palette)))
    (setf (alist-get 'background palette) background)
    (dolist (role '(foreground red green yellow blue magenta cyan))
      (setf (alist-get role palette)
            (ewal-color-ensure-contrast
             (alist-get role palette) background
             ewal-doom-themes-min-contrast candidates)))
    (setf (alist-get 'highlight palette)
          (ewal-color-ensure-contrast
           (alist-get 'highlight palette) background
           ewal-doom-themes-min-ui-contrast candidates))
    palette))

(defun ewal-generate-doom-theme (name palette)
  "Generate a Doom theme form for NAME using PALETTE.

NAME is a symbol.  PALETTE is an alist with at least these keys:

  background, foreground, highlight, red, green, yellow, blue,
  magenta, cyan

The return value is a `def-doom-theme` form that you can `eval`."
  (let* ((palette (ewal-normalize-doom-theme-palette palette))
          (bg (alist-get 'background palette))
          (fg (alist-get 'foreground palette))
          (bg-shades (ewal-generate-shades bg 3 10))
          (fg-shades (ewal-generate-shades fg 3 10))
          (bg-light   (alist-get :light-1 bg-shades))
          (bg-lighter (alist-get :light-2 bg-shades))
          (bg-dark    (alist-get :dark-1 bg-shades))
          (bg-darker  (alist-get :dark-2 bg-shades))
          (fg-light   (alist-get :light-1 fg-shades))
          (fg-dark    (alist-get :dark-1 fg-shades))
          (comment (ewal-color-ensure-contrast
                    fg-dark bg ewal-doom-themes-min-contrast
                    (mapcar #'cdr palette)))
          (highlight (alist-get 'highlight palette))
          (highlight-fg (ewal-color-ensure-contrast
                         fg highlight ewal-doom-themes-min-contrast
                         (mapcar #'cdr palette)))
          (region-fg (ewal-color-ensure-contrast
                      fg-light bg-dark ewal-doom-themes-min-contrast
                      (mapcar #'cdr palette)))
          (red (alist-get 'red palette))
          (green (alist-get 'green palette))
          (yellow (alist-get 'yellow palette))
          (blue (alist-get 'blue palette))
          (magenta (alist-get 'magenta palette))
          (cyan (alist-get 'cyan palette)))
    `(def-doom-theme ,name
       ,(format "A dynamically generated Doom theme `%s` using `ewal`." name)

       ;; Color Definitions
       ((bg         . ,bg)
         (bg-light   . ,bg-light)
         (bg-lighter . ,bg-lighter)
         (bg-dark    . ,bg-dark)
         (bg-darker  . ,bg-darker)
         (fg         . ,fg)
         (fg-light   . ,fg-light)
         (fg-dark    . ,fg-dark)
         (comment    . ,comment)
         (highlight  . ,highlight)
         (highlight-fg . ,highlight-fg)
         (region-fg  . ,region-fg)
         (red        . ,red)
         (green      . ,green)
         (yellow     . ,yellow)
         (blue       . ,blue)
         (magenta    . ,magenta)
         (cyan       . ,cyan))

       ;; Face Definitions
       ((default :background bg :foreground fg)
         (cursor  :background fg :foreground bg)
         (region  :background bg-dark :foreground region-fg)
         (highlight :background highlight :foreground highlight-fg)
         (error   :foreground red :weight 'bold)
         (warning :foreground yellow :weight 'bold)
         (success :foreground green :weight 'bold)
         (font-lock-comment-face :foreground comment :slant 'italic)
         (font-lock-function-name-face :foreground blue :weight 'bold)
         (font-lock-keyword-face :foreground magenta :weight 'bold)
         (font-lock-string-face :foreground green)
         (font-lock-variable-name-face :foreground yellow)
         (font-lock-type-face :foreground cyan))

       ;; Extra Variables
       ())))

;;;###autoload
(defun ewal-generate-doom-theme-interactive ()
  "Interactively generate and load a Doom theme from an `ewal` palette file.

Prompts for a palette JSON file, a theme name, generates the
theme, evaluates it, and enables it."
  (interactive)
  (let* ((theme-name (intern (read-string "Enter theme name: " "ewal-doom-generated")))
          (palette-file (read-file-name "Select palette JSON: "))
          (palette (ewal-load-palette palette-file)))
    (unless palette
      (user-error "Could not read palette from %s" palette-file))
    (let ((form (ewal-generate-doom-theme theme-name
                  (append (alist-get 'special palette)
                    (alist-get 'colors palette)))))
      (eval form)
      (load-theme theme-name t)
      (when ewal-generate-doom-theme-auto-check-contrast
        (ewal-doom-themes-check-contrast))
      (message "Generated and loaded Doom theme `%s` from %s" theme-name palette-file))))

(provide 'ewal-generate-doom-theme)
;;; ewal-generate-doom-theme.el ends here
