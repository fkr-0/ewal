;;; ewal-palette-utils.el --- Utilities for handling palettes -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Palette loading, preview, navigation, and batch contrast auditing for Ewal.

;;; Code:

(require 'json)
(require 'color)
(require 'ewal-color-utils)
(require 'seq)
(require 'subr-x)

(declare-function ewal-palettes-menu "ewal-palette-transient" ())

(defvar ewal-palettes nil
  "List of loaded palettes as (PALETTE . FILENAME) pairs.")

(defcustom ewal-palette-audit-min-contrast 4.5
  "Default minimum contrast ratio for palette audits."
  :type 'number
  :group 'ewal)

;;;###autoload
(defun ewal-load-palette (file-path)
  "Load a palette from JSON FILE-PATH.

Return an alist with at least `special` and `colors` keys, or nil
if FILE-PATH is not readable."
  (when (file-readable-p file-path)
    (let* ((json-object-type 'alist)
            (json-array-type 'list))
      (json-read-file file-path))))

;;;###autoload
(defun ewal-save-palette (palette file-path)
  "Save PALETTE (alist) to FILE-PATH as JSON."
  (with-temp-file file-path
    (insert (json-encode-alist palette))))

(defun ewal-palette-contrast-ratio (color1 color2)
  "Calculate WCAG contrast ratio between COLOR1 and COLOR2.

COLOR1 and COLOR2 are color strings understood by
`color-name-to-rgb`."
  (ewal-color-contrast-ratio color1 color2))

(defun ewal-palette-check-contrast (palette)
  "Check contrast suitability for PALETTE.

Return list of warning strings for low-contrast pairs."
  (let* ((special (alist-get 'special palette))
          (background (alist-get 'background special))
          (foreground (alist-get 'foreground special))
          (cursor (alist-get 'cursor special))
          (warnings '()))
    (when (and background foreground
            (< (ewal-palette-contrast-ratio background foreground) 4.5))
      (push "Low contrast between background and foreground." warnings))
    (when (and background cursor
            (< (ewal-palette-contrast-ratio background cursor) 4.5))
      (push "Low contrast between background and cursor." warnings))
    warnings))

(defun ewal-palette-audit-entry (palette file &optional min-contrast)
  "Build a contrast audit entry for PALETTE loaded from FILE.

Flag ratios below MIN-CONTRAST, or `ewal-palette-audit-min-contrast' when nil."
  (let* ((special (alist-get 'special palette))
         (background (alist-get 'background special))
         (foreground (alist-get 'foreground special))
         (cursor (alist-get 'cursor special))
         (min-contrast (or min-contrast ewal-palette-audit-min-contrast))
         (bg-foreground (and background foreground
                             (ewal-palette-contrast-ratio background foreground)))
         (bg-cursor (and background cursor
                         (ewal-palette-contrast-ratio background cursor)))
         (ratios (seq-filter #'numberp (list bg-foreground bg-cursor)))
         (worst (if ratios (apply #'min ratios) 0.0))
         (warnings (delq nil
                         (list
                          (when (and (numberp bg-foreground)
                                     (< bg-foreground min-contrast))
                            'background-foreground)
                          (when (and (numberp bg-cursor)
                                     (< bg-cursor min-contrast))
                            'background-cursor)))))
    `((file . ,file)
      (bg-foreground . ,bg-foreground)
      (bg-cursor . ,bg-cursor)
      (worst . ,worst)
      (warnings . ,warnings))))

(defun ewal--palette-audit-sort (entries)
  "Sort ENTRIES by ascending worst contrast."
  (sort entries
        (lambda (a b)
          (< (or (alist-get 'worst a) 0.0)
             (or (alist-get 'worst b) 0.0)))))

(defun ewal-display-palette-contrast-audit (entries min-contrast)
  "Render ENTRIES in a report buffer for MIN-CONTRAST."
  (let ((buffer (get-buffer-create "*ewal-palette-contrast-audit*")))
    (with-current-buffer buffer
      (erase-buffer)
      (insert (format "Palette Contrast Audit (min %.2f)\n\n" min-contrast))
      (insert (format "%-42s  %-8s  %-8s  %-8s  %s\n"
                      "File" "Worst" "BG/FG" "BG/CUR" "Warnings"))
      (insert (make-string 100 ?-) "\n")
      (dolist (entry entries)
        (insert
         (format "%-42s  %8.2f  %8.2f  %8.2f  %s\n"
                 (file-name-nondirectory (alist-get 'file entry))
                 (or (alist-get 'worst entry) 0.0)
                 (or (alist-get 'bg-foreground entry) 0.0)
                 (or (alist-get 'bg-cursor entry) 0.0)
                 (if-let ((warnings (alist-get 'warnings entry)))
                     (mapconcat #'symbol-name warnings ", ")
                   ""))))
      (goto-char (point-min)))
    (pop-to-buffer buffer)))

;;;###autoload
(defun ewal-audit-palettes-contrast (dir &optional min-contrast)
  "Audit all palette JSON files in DIR and rank worst contrast first.

Use MIN-CONTRAST as the warning threshold.  Return sorted audit entries."
  (interactive "DPalette directory: ")
  (let* ((min-contrast (or min-contrast ewal-palette-audit-min-contrast))
         (sorted (ewal-palette-audit-directory dir min-contrast)))
    (ewal-display-palette-contrast-audit sorted min-contrast)
    (message "Audited %d palette(s). %d below %.2f worst-contrast threshold."
             (length sorted)
             (seq-count (lambda (entry)
                          (< (or (alist-get 'worst entry) 0.0) min-contrast))
                        sorted)
             min-contrast)
    sorted))

(defun ewal-palette-audit-directory (dir &optional min-contrast)
  "Return contrast audit entries for all JSON palettes in DIR.

Use MIN-CONTRAST as the warning threshold.  The result is sorted from worst
to best.  Unlike `ewal-audit-palettes-contrast', this function has no display
side effects and is suitable for tests and batch operation."
  (let* ((min-contrast (or min-contrast ewal-palette-audit-min-contrast))
         (files (directory-files dir t "\\.json\\'"))
         (entries
          (mapcar (lambda (file)
                    (ewal-palette-audit-entry
                     (ewal-load-palette file) file min-contrast))
                  files)))
    (ewal--palette-audit-sort entries)))

;;;###autoload
(defun ewal-audit-palettes-contrast-batch (&optional dir min-contrast)
  "Batch-friendly contrast audit for palette JSON files in DIR.

Use MIN-CONTRAST as the warning threshold.  Print a ranked report, worst
contrast first, to stdout and return the sorted entries."
  (let* ((dir (or dir default-directory))
         (entries (ewal-palette-audit-directory dir min-contrast)))
    (dolist (entry entries)
      (princ
       (format "%s\tworst=%.2f\tbg/fg=%.2f\tbg/cursor=%.2f\twarnings=%s\n"
               (alist-get 'file entry)
               (or (alist-get 'worst entry) 0.0)
               (or (alist-get 'bg-foreground entry) 0.0)
               (or (alist-get 'bg-cursor entry) 0.0)
               (if-let ((warnings (alist-get 'warnings entry)))
                   (mapconcat #'symbol-name warnings ",")
                 ""))))
    entries))

(defun ewal-palette-suggest-improvements (palette)
  "Suggest improvements for PALETTE to enhance readability.

Return an alist like ((foreground . \"#...\") (cursor . \"#...\")) with
suggested replacement colors."
  (let* ((special (alist-get 'special palette))
          (background (alist-get 'background special))
          (foreground (alist-get 'foreground special))
          (cursor (alist-get 'cursor special))
          (improvements '()))
    (when (and background foreground
               (not (ewal-color-contrast-sufficient-p
                     foreground background ewal-color-minimum-text-contrast)))
      (push (cons 'foreground
                  (ewal-color-ensure-contrast
                   foreground background ewal-color-minimum-text-contrast))
            improvements))
    (when (and background cursor
               (not (ewal-color-contrast-sufficient-p
                     cursor background ewal-color-minimum-ui-contrast)))
      (push (cons 'cursor
                  (ewal-color-ensure-contrast
                   cursor background ewal-color-minimum-ui-contrast))
            improvements))
    improvements))

;;;###autoload
(defun ewal-print-palette-buffer (palette)
  "Print PALETTE into a preview buffer with colored blocks."
  (with-current-buffer (get-buffer-create "*ewal-palette-preview*")
    (erase-buffer)
    (insert "Palette Preview:\n\n")
    (dolist (entry (append (alist-get 'special palette)
                     (alist-get 'colors palette)))
      (let ((name (symbol-name (car entry)))
             (color (cdr entry)))
        (insert (format "%-15s " name))
        (insert (propertize "  " 'face `(:background ,color :box t)))
        (insert (format " %s\n" color))))
    (goto-char (point-min))
    (pop-to-buffer (current-buffer))))

;;;###autoload
(defun ewal-print-palette-ansi (palette)
  "Print PALETTE colors as ANSI escape codes to *Messages*."
  (dolist (entry (append (alist-get 'special palette)
                   (alist-get 'colors palette)))
    (let* ((name (symbol-name (car entry)))
            (color (cdr entry))
            (rgb   (color-name-to-rgb color)))
      (when rgb
        (message "%s \e[48;2;%d;%d;%dm   \e[0m %s"
          name
          (* 255 (nth 0 rgb))
          (* 255 (nth 1 rgb))
          (* 255 (nth 2 rgb))
          color)))))

;;;###autoload
(defun ewal-load-palettes-from-directory (dir)
  "Load all palette JSON files in DIR into `ewal-palettes`.

`ewal-palettes` becomes a list of (PALETTE . FILENAME) pairs."
  (let ((files (directory-files dir t "\\.json\\'")))
    (setq ewal-palettes
      (mapcar (lambda (file)
                (cons (ewal-load-palette file) file))
        files))))

;;;###autoload
(defun ewal-save-palettes (palettes)
  "Save PALETTES (alist of (PALETTE . FILE)) to their FILEs."
  (dolist (palette palettes)
    (let ((data (car palette))
           (file (cdr palette)))
      (ewal-save-palette data file))))

(defun ewal-preview-palette (palette filename)
  "Preview PALETTE coming from FILENAME in a dedicated buffer."
  (with-current-buffer (get-buffer-create "*ewal-palettes*")
    (erase-buffer)
    (insert (format "Palette Preview: %s\n\n" filename))
    (dolist (entry (append (alist-get 'special palette)
                     (alist-get 'colors palette)))
      (let ((name (symbol-name (car entry)))
             (color (cdr entry)))
        (insert (format "%-15s " name))
        (insert (propertize "  " 'face `(:background ,color :box t)))
        (insert (format " %s\n" color))))
    (goto-char (point-min))
    (pop-to-buffer (current-buffer))))

(defun ewal-switch-palette (direction)
  "Switch to the next (DIRECTION = +1) or previous (DIRECTION = -1) palette."
  (unless ewal-palettes
    (user-error "No palettes loaded; call `ewal-load-palettes-from-directory' first"))
  (let ((current-index (or (get 'ewal-palettes 'current-index) 0)))
    (setq current-index (mod (+ current-index direction)
                          (length ewal-palettes)))
    (put 'ewal-palettes 'current-index current-index)
    (let ((palette (nth current-index ewal-palettes)))
      (ewal-preview-palette (car palette) (cdr palette)))))

(defun ewal-palette-next ()
  "Preview the next loaded palette."
  (interactive)
  (ewal-switch-palette 1))

(defun ewal-palette-previous ()
  "Preview the previous loaded palette."
  (interactive)
  (ewal-switch-palette -1))

(defun ewal-palette-preview-quit ()
  "Close the Ewal palette preview buffer."
  (interactive)
  (when-let ((buffer (get-buffer "*ewal-palettes*")))
    (kill-buffer buffer)))

;;;###autoload
(defun ewal-palettes-transient ()
  "Invoke transient menu for browsing palettes."
  (interactive)
  (unless (require 'ewal-palette-transient nil t)
    (user-error "The optional Transient palette UI is unavailable"))
  (call-interactively #'ewal-palettes-menu))

(provide 'ewal-palette-utils)
;;; ewal-palette-utils.el ends here
