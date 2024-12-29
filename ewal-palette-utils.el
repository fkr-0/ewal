;;; .local/straight/repos/ewal/ewal-palette-utils.el -*- lexical-binding: t; -*-

;;; ewal-palette-utils.el --- Utilities for handling palettes -*- lexical-binding: t; -*-

(require 'json)
(require 'color)
(require 'transient)

(defvar ewal-palettes nil
  "List of loaded palettes with their filenames.")

;;;###autoload
(defun ewal-load-palette (file-path)
  "Load a palette from a JSON file.

Arguments:
  - file-path (string): Path to the JSON file containing the palette.

Returns:
  - (alist): Parsed palette as an alist."
  (when (file-readable-p file-path)
    (let* ((json-object-type 'alist)
           (json-array-type 'list))
      (json-read-file file-path))))

;;;###autoload
(defun ewal-save-palette (palette file-path)
  "Save a palette to a JSON file.

Arguments:
  - palette (alist): The palette to save.
  - file-path (string): Path to the JSON file.

Writes the palette to the specified file in JSON format."
  (with-temp-file file-path
    (insert (json-encode-alist palette))))

(defun ewal-palette-contrast-ratio (color1 color2)
  "Calculate the contrast ratio between two colors.

Arguments:
  - color1 (string): First color in hex format.
  - color2 (string): Second color in hex format.

Returns:
  - (float): The contrast ratio, where a higher value indicates better contrast."
  (let ((l1 (color-luminance (color-name-to-rgb color1)))
        (l2 (color-luminance (color-name-to-rgb color2))))
    (if (> l1 l2)
        (/ (+ l1 0.05) (+ l2 0.05))
      (/ (+ l2 0.05) (+ l1 0.05)))))

(defun ewal-palette-check-contrast (palette)
  "Check contrast suitability for a given palette.

Arguments:
  - palette (alist): A palette containing "special" and "colors" keys.

Returns:
  - (list): List of warnings for low contrast colors."
  (let* ((background (alist-get 'background (alist-get 'special palette)))
         (foreground (alist-get 'foreground (alist-get 'special palette)))
         (cursor (alist-get 'cursor (alist-get 'special palette)))
         (warnings '()))
    (when (< (ewal-palette-contrast-ratio background foreground) 4.5)
      (push "Low contrast between background and foreground." warnings))
    (when (< (ewal-palette-contrast-ratio background cursor) 4.5)
      (push "Low contrast between background and cursor." warnings))
    warnings))

(defun ewal-palette-suggest-improvements (palette)
  "Suggest improvements for the given palette to enhance readability.

Arguments:
  - palette (alist): A palette containing "special" and "colors" keys.

Returns:
  - (alist): Suggested color adjustments for improved contrast."
  (let* ((background (alist-get 'background (alist-get 'special palette)))
         (foreground (alist-get 'foreground (alist-get 'special palette)))
         (cursor (alist-get 'cursor (alist-get 'special palette)))
         (improvements '()))
    (when (< (ewal-palette-contrast-ratio background foreground) 4.5)
      (push (cons 'foreground (color-darken-name foreground 10)) improvements))
    (when (< (ewal-palette-contrast-ratio background cursor) 4.5)
      (push (cons 'cursor (color-lighten-name cursor 10)) improvements))
    improvements))

;;;###autoload
(defun ewal-print-palette-buffer (palette)
  "Print the palette as a buffer with color blocks.

Arguments:
  - palette (alist): A palette containing "special" and "colors" keys.

Displays a buffer with the palette where each color name is accompanied by a color block."
  (with-current-buffer (get-buffer-create "*ewal-palette-preview*")
    (erase-buffer)
    (insert "Palette Preview:\n\n")
    (dolist (entry (append (alist-get 'special palette) (alist-get 'colors palette)))
      (let ((name (symbol-name (car entry)))
            (color (cdr entry)))
        (insert (format "%-15s " name))
        (insert (propertize " " 'face `(:background ,color :foreground ,color :box t)))
        (insert (format " %s\n" color))))
    (goto-char (point-min))
    (pop-to-buffer (current-buffer))))

;;;###autoload
(defun ewal-print-palette-ansi (palette)
  "Print the PALETTE as ANSI escape codes to the terminal.

Arguments:
  - palette (alist): A palette containing "special" and "colors" keys.

Prints each color in the palette with its name and an ANSI-colored block."
  (dolist (entry (append (alist-get 'special palette) (alist-get 'colors palette)))
    (let ((name (symbol-name (car entry)))
          (color (cdr entry)))
      (message "%s \e[48;2;%d;%d;%dm     \e[0m %s"
               name
               (* 255 (nth 0 (color-name-to-rgb color)))
               (* 255 (nth 1 (color-name-to-rgb color)))
               (* 255 (nth 2 (color-name-to-rgb color)))
               color))))

;;;###autoload
(defun ewal-load-palettes-from-directory (dir)
  "Load all palettes from JSON files in a directory.

Arguments:
  - dir (string): Path to the directory containing palette JSON files.

Returns:
  - (list): List of palettes, each with their filename attached."
  (let ((files (directory-files dir t "\.json$")))
    (setq ewal-palettes
          (mapcar (lambda (file)
                    (cons (ewal-load-palette file) file))
                  files))))

;;;###autoload
(defun ewal-save-palettes (palettes)
  "Save a list of palettes to their respective filenames.

Arguments:
  - palettes (list): List of palettes with their filenames.

Saves each palette in the list to the file specified in its filename."
  (dolist (palette palettes)
    (let ((data (car palette))
          (file (cdr palette)))
      (ewal-save-palette data file))))

(defun ewal-preview-palette (palette filename)
  "Preview a palette in the `*ewal-palettes*' buffer.

Arguments:
  - palette (alist): The palette to preview.
  - filename (string): The filename associated with the palette.

Clears the buffer and prints the palette with its colors and filename."
  (with-current-buffer (get-buffer-create "*ewal-palettes*")
    (erase-buffer)
    (insert (format "Palette Preview: %s\n\n" filename))
    (dolist (entry (append (alist-get 'special palette) (alist-get 'colors palette)))
      (let ((name (symbol-name (car entry)))
            (color (cdr entry)))
        (insert (format "%-15s " name))
        (insert (propertize " " 'face `(:background ,color :foreground ,color :box t)))
        (insert (format " %s\n" color))))
    (goto-char (point-min))
    (pop-to-buffer (current-buffer))))

(defun ewal-switch-palette (direction)
  "Switch to the next or previous palette in `ewal-palettes'.

Arguments:
  - direction (integer): +1 for next palette, -1 for previous palette."
  (let ((current-index (or (get 'ewal-palettes 'current-index) 0)))
    (setq current-index (mod (+ current-index direction) (length ewal-palettes)))
    (put 'ewal-palettes 'current-index current-index)
    (let ((palette (nth current-index ewal-palettes)))
      (ewal-preview-palette (car palette) (cdr palette)))))

(defun ewal-palettes-transient ()
  "Transient menu for browsing and manipulating palettes."
  (interactive)
  (transient-define-prefix ewal-palettes-menu ()
    ["Navigation"
     ("j" "Next Palette" (lambda () (interactive) (ewal-switch-palette 1)))
     ("k" "Previous Palette" (lambda () (interactive) (ewal-switch-palette -1)))
     ("q" "Quit" (lambda () (interactive) (kill-buffer "*ewal-palettes*")))])
  (ewal-palettes-menu))

(provide 'ewal-palette-utils)
;;; ewal-palette-utils.el ends here
