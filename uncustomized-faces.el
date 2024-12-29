;;; uncustomized-faces.el --- Identify and manage uncustomized faces -*- lexical-binding: t; -*-

(defun find-uncustomized-faces (library-name theme-faces)
  "Find faces defined in LIBRARY-NAME that are not customized in THEME-FACES.
Arguments:
  - library-name (string): The library to check (e.g., 'lsp-mode').
  - theme-faces (list): List of already customized faces in the theme.

Returns:
  - (list): Faces defined by the library but missing in THEME-FACES."
  (let ((all-faces (face-list))
        (uncustomized-faces '()))
    (require (intern library-name)) ; Ensure the library is loaded
    (dolist (face all-faces)
      (when (and (string-prefix-p library-name (symbol-name face))
                 (not (memq face theme-faces)))
        (push face uncustomized-faces)))
    uncustomized-faces))

(defun insert-uncustomized-faces (library-name theme-faces file-path)
  "Insert boilerplate for uncustomized faces into a theme file.
Arguments:
  - library-name (string): The library to check.
  - theme-faces (list): List of already customized faces in the theme.
  - file-path (string): Path to the theme file.

Appends boilerplate for uncustomized faces to the theme file."
  (let ((uncustomized (find-uncustomized-faces library-name theme-faces)))
    (when uncustomized
      (with-current-buffer (find-file-noselect file-path)
        (goto-char (point-max))
        (insert (format ";; --- %s faces -------------------\n" library-name))
        (dolist (face uncustomized)
          (insert (format "(%s :foreground base4)\n" face)))
        (save-buffer)))))

(defun retrieve-customized-faces (theme)
  "Retrieve all faces customized in a given THEME.
Arguments:
  - theme (string): The name of the theme.

Returns:
  - (list): List of faces customized in the theme."
  (let ((theme-faces '()))
    (dolist (spec (custom-theme--flatten-spec theme))
      (when (eq (car spec) 'custom-declare-face)
        (push (nth 1 spec) theme-faces)))
    theme-faces))

(defun insert-uncustomized-faces-interactive (theme-faces file-path)
  "Interactive function to insert uncustomized faces into a theme file.
Arguments:
  - theme-faces (list): List of already customized faces in the theme.
  - file-path (string): Path to the theme file."
  (interactive "xTheme Faces (as list): \nfPath to theme file: ")
  (let ((library-name (completing-read "Select library: " features nil t)))
    (insert-uncustomized-faces library-name theme-faces file-path)))

;;; Example usage:
;; Identify uncustomized faces for a library
(message "Uncustomized faces: %s"
         (find-uncustomized-faces "lsp-mode" '(lsp-ui-doc-header lsp-ui-doc-background)))

;; Insert uncustomized faces into a theme file
(insert-uncustomized-faces "lsp-mode" '(lsp-ui-doc-header lsp-ui-doc-background) "/path/to/your-theme.el")

(provide 'uncustomized-faces)
;;; uncustomized-faces.el ends here
