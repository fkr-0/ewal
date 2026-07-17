;;; ewal-uncustomized-faces.el --- Style uncustomized faces with Ewal -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Apply a contrast-safe Ewal foreground/background pair to faces discovered by
;; `uncustomized-faces.el', and optionally append the generated entries to a
;; theme source file.

;;; Code:

(require 'cl-lib)
(require 'ewal)
(require 'ewal-color-utils)
(require 'ewal-palette-utils)
(require 'uncustomized-faces)

(defun ewal-assign-face (_face palette)
  "Return a contrast-safe default face plist derived from PALETTE.

PALETTE is a pywal JSON alist with `special' and `colors' sections.  _FACE is
accepted for future role-specific styling."
  (let* ((special (alist-get 'special palette))
         (colors (alist-get 'colors palette))
         (background (or (ewal-color-normalize
                          (alist-get 'background special))
                         "#000000"))
         (candidates
          (cl-loop for (_key . value) in (append special colors)
                   when (ewal-color-valid-p value)
                   collect (ewal-color-normalize value)))
         (foreground
          (ewal-color-ensure-contrast
           (or (alist-get 'foreground special) "#ffffff")
           background ewal-color-minimum-text-contrast candidates)))
    (list :foreground foreground :background background)))

(defun ewal-style-uncustomized-faces (library theme-faces palette)
  "Return styles for LIBRARY faces absent from THEME-FACES using PALETTE."
  (mapcar (lambda (face)
            (cons face (ewal-assign-face face palette)))
          (ewal-find-uncustomized-faces library theme-faces)))

(defun ewal--face-plist-source (plist)
  "Return PLIST formatted as Emacs Lisp face attributes."
  (mapconcat (lambda (pair)
               (format "%S %S" (car pair) (cdr pair)))
             (cl-loop for (property value) on plist by #'cddr
                      collect (cons property value))
             " "))

(defun ewal-insert-styled-faces (styled-faces file)
  "Append STYLED-FACES to theme source FILE.

STYLED-FACES is an alist of (FACE . ATTRIBUTE-PLIST)."
  (when styled-faces
    (with-temp-buffer
      (insert "\n;; --- Styled faces (ewal-auto) -------------------\n")
      (dolist (entry styled-faces)
        (insert (format "(%S %s)\n"
                        (car entry)
                        (ewal--face-plist-source (cdr entry)))))
      (write-region (point-min) (point-max) file t 'silent)))
  styled-faces)

(defun ewal-process-uncustomized-faces (library theme-faces palette file)
  "Style LIBRARY faces absent from THEME-FACES using PALETTE and append to FILE."
  (let ((styled (ewal-style-uncustomized-faces
                 library theme-faces palette)))
    (ewal-insert-styled-faces styled file)
    (message "Processed %d uncustomized faces from %s"
             (length styled) library)
    styled))

;;;###autoload
(defun ewal-process-uncustomized-faces-interactive (theme-faces file)
  "Prompt for a library and palette, then use THEME-FACES and append to FILE."
  (interactive "xTheme faces (as list): \nfTheme file: ")
  (let* ((library (intern
                   (completing-read "Library: "
                                    (mapcar #'symbol-name features)
                                    nil t)))
         (palette-file (read-file-name "Palette JSON: "))
         (palette (ewal-load-palette palette-file)))
    (unless palette
      (user-error "Could not read palette from %s" palette-file))
    (ewal-process-uncustomized-faces
     library theme-faces palette file)))

(provide 'ewal-uncustomized-faces)
;;; ewal-uncustomized-faces.el ends here
