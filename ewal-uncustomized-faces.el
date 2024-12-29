;;; ../../.dotfiles/config/doom/themes/ewal/doom-themes/ewal-uncustomized-faces.el -*- lexical-binding: t; -*-

;;; ewal-uncustomized-faces.el --- Integration of uncustomized faces with ewal -*- lexical-binding: t; -*-

(require 'ewal-palette-utils)
(require 'uncustomized-faces)

(defun ewal-assign-face (face palette)
  "Assign a style to FACE based on the given PALETTE.
Arguments:
  - face (symbol): The face to style.
  - palette (alist): The palette containing colors.

Returns:
  - (list): Alist of style attributes for the face."
  (let ((background (alist-get 'background (alist-get 'special palette)))
        (foreground (alist-get 'foreground (alist-get 'special palette))))
    (list :foreground foreground :background background)))

(defun ewal-style-uncustomized-faces (library-name theme-faces palette)
  "Style uncustomized faces from LIBRARY-NAME using PALETTE.
Arguments:
  - library-name (string): The library to check for faces.
  - theme-faces (list): List of already customized faces.
  - palette (alist): The palette containing colors.

Returns:
  - (alist): List of faces with their assigned styles."
  (let ((uncustomized (find-uncustomized-faces library-name theme-faces))
        (styled-faces '()))
    (dolist (face uncustomized)
      (push (cons face (ewal-assign-face face palette)) styled-faces))
    styled-faces))

(defun ewal-insert-styled-faces (styled-faces file-path)
  "Insert styled faces into the theme file.
Arguments:
  - styled-faces (alist): List of faces with their assigned styles.
  - file-path (string): Path to the theme file.

Appends styled face definitions to the theme file."
  (with-current-buffer (find-file-noselect file-path)
    (goto-char (point-max))
    (insert ";; --- Styled Faces -------------------\n")
    (dolist (entry styled-faces)
      (let ((face (car entry))
            (styles (cdr entry)))
        (insert (format "(%s %s)\n" face
                        (mapconcat (lambda (style)
                                     (format ":%s %s" (car style) (cdr style)))
                                   styles " ")))))
    (save-buffer)))

(defun ewal-process-uncustomized-faces (library-name theme-faces palette file-path)
  "Full workflow to process and style uncustomized faces.
Arguments:
  - library-name (string): Library to check for uncustomized faces.
  - theme-faces (list): List of already customized faces.
  - palette (alist): Palette to style the faces.
  - file-path (string): Path to the theme file."
  (let ((styled-faces (ewal-style-uncustomized-faces library-name theme-faces palette)))
    (ewal-insert-styled-faces styled-faces file-path)
    (message "Processed %d uncustomized faces from %s." (length styled-faces) library-name)))

;;;###autoload
(defun ewal-process-uncustomized-faces-interactive (theme-faces file-path)
  "Interactive wrapper for `ewal-process-uncustomized-faces`.
Arguments:
  - theme-faces (list): List of already customized faces.
  - file-path (string): Path to the theme file."
  (interactive "xTheme Faces (as list): \nfPath to theme file: ")
  (let ((library-name (completing-read "Select library: " features nil t))
        (palette (ewal-load-palette
                  (read-file-name "Select palette JSON: "))))
    (ewal-process-uncustomized-faces library-name theme-faces palette file-path)))

;;; Example usage:
;; Process uncustomized faces for lsp-mode using a given palette and theme
;; (ewal-process-uncustomized-faces
;;  "lsp-mode"
;;  '(lsp-ui-doc-header lsp-ui-doc-background)
;;  (ewal-load-palette "/path/to/palette.json")
;;  "/path/to/theme.el")

(provide 'ewal-uncustomized-faces)
;;; ewal-uncustomized-faces.el ends here
