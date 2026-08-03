;;; uncustomized-faces.el --- Identify faces missing from a theme -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Introspection helpers for finding faces contributed by a library but not
;; explicitly present in a custom theme.  The functions are prefixed for safe
;; coexistence with other theme-development packages.

;;; Code:

(require 'cl-lib)
(require 'subr-x)

(defun ewal-find-uncustomized-faces (library theme-faces)
  "Return faces from LIBRARY that are absent from THEME-FACES.

LIBRARY may be a feature symbol or its string name.  Face ownership is inferred
from the conventional face name prefix, so this is a development aid rather
than a package metadata API."
  (let* ((feature (if (symbolp library) library (intern library)))
         (prefix (symbol-name feature)))
    (require feature)
    (sort
     (cl-loop for face in (face-list)
              when (and (string-prefix-p prefix (symbol-name face))
                        (not (memq face theme-faces)))
              collect face)
     (lambda (left right)
       (string-lessp (symbol-name left) (symbol-name right))))))

(defun ewal-theme-customized-faces (theme)
  "Return face symbols explicitly declared by custom THEME."
  (unless (custom-theme-p theme)
    (user-error "Unknown custom theme: %S" theme))
  (delete-dups
   (cl-loop for setting in (get theme 'theme-settings)
            when (and (eq (car-safe setting) 'theme-face)
                      (symbolp (cadr setting)))
            collect (cadr setting))))

(defun ewal-insert-uncustomized-faces (library theme-faces file)
  "Append simple entries for LIBRARY faces missing from THEME-FACES to FILE."
  (let ((faces (ewal-find-uncustomized-faces library theme-faces)))
    (when faces
      (with-temp-buffer
        (insert (format "\n;; --- %s faces -------------------\n" library))
        (dolist (face faces)
          (insert (format "(%S :foreground base4)\n" face)))
        (write-region (point-min) (point-max) file t 'silent)))
    faces))

;;;###autoload
(defun ewal-insert-uncustomized-faces-interactive (theme-faces file)
  "Prompt for a loaded library and append its missing THEME-FACES to FILE."
  (interactive "xTheme faces (as list): \nfTheme file: ")
  (let ((library (intern
                  (completing-read "Library: "
                                   (mapcar #'symbol-name features)
                                   nil t))))
    (ewal-insert-uncustomized-faces library theme-faces file)))

(define-obsolete-function-alias
  'find-uncustomized-faces #'ewal-find-uncustomized-faces "0.3.0")
(define-obsolete-function-alias
  'retrieve-customized-faces #'ewal-theme-customized-faces "0.3.0")
(define-obsolete-function-alias
  'insert-uncustomized-faces #'ewal-insert-uncustomized-faces "0.3.0")
(define-obsolete-function-alias
  'insert-uncustomized-faces-interactive
  #'ewal-insert-uncustomized-faces-interactive "0.3.0")

(provide 'uncustomized-faces)
;;; uncustomized-faces.el ends here
