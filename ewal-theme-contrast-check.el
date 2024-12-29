;;; ewal-theme-contrast-check.el --- Theme contrast checking and suggestions -*- lexical-binding: t; -*-

(require 'color)
(require 'face-remap)

(defun ewal-theme-contrast-ratio (color1 color2)
  "Calculate the contrast ratio between two colors.

Arguments:
  - COLOR1 (string): First color in hex format.
  - COLOR2 (string): Second color in hex format.

Returns:
  - (float): The contrast ratio, where a higher value indicates better contrast."
  (let ((l1 (color-luminance (color-name-to-rgb color1)))
        (l2 (color-luminance (color-name-to-rgb color2))))
    (if (> l1 l2)
        (/ (+ l1 0.05) (+ l2 0.05))
      (/ (+ l2 0.05) (+ l1 0.05)))))
(defun ewal-check-contrast (face-attributes &optional min-contrast)
  "Check contrast for a list of FACE-ATTRIBUTES.
Arguments:
  - FACE-ATTRIBUTES (list): A list of faces and their `:foreground` and `:background` attributes.
  - MIN-CONTRAST (float): Minimum acceptable contrast ratio. Defaults to 4.5.

Returns:
  - (list): List of faces with contrast issues."
  (let ((min-contrast (or min-contrast 4.5))
        (warnings '()))
    (dolist (entry face-attributes)
      (let* ((face (plist-get entry :name))
             (foreground (plist-get entry :foreground))
             (background (plist-get entry :background))
             (contrast (and foreground background
                            (ewal-theme-contrast-ratio foreground background))))
        (when (and contrast (< contrast min-contrast))
          (push (list face foreground background contrast) warnings))))
    warnings))

(defun ewal-check-theme-contrast (theme-faces &optional min-contrast)
  "Check contrast suitability for faces in a theme.

Arguments:
  - THEME-FACES (list): List of faces to evaluate.
  - MIN-CONTRAST (float, optional): Minimum acceptable contrast ratio.
    Defaults to 4.5.

Returns:
  - (list): List of warnings for faces with low contrast ratios."
  (let ((min-contrast (or min-contrast 4.5))
        (warnings '()))
    (dolist (face theme-faces)
      (let* ((face-attrs (face-attribute face :all nil))
             (foreground (face-attribute face :foreground nil))
             (background (face-attribute face :background nil))
             (contrast (and foreground background
                            (ewal-theme-contrast-ratio foreground background))))
        (when (and contrast (< contrast min-contrast))
          (push (list face foreground background contrast) warnings))))
    warnings))

(defun ewal-display-contrast-warnings (warnings)
  "Display contrast warnings and provide interactive options.

Arguments:
  - WARNINGS (list): List of problematic faces and their attributes."
  (let ((buffer (get-buffer-create "*Theme Contrast Warnings*")))
    (with-current-buffer buffer
      (erase-buffer)
      (insert "Faces with Low Contrast:\n\n")
      (dolist (warning warnings)
        (let ((face (nth 0 warning))
              (foreground (nth 1 warning))
              (background (nth 2 warning))
              (contrast (nth 3 warning)))
          (insert (format "Face: %s\n" face))
          (insert (format "  Foreground: %s\n" foreground))
          (insert (format "  Background: %s\n" background))
          (insert (format "  Contrast Ratio: %.2f\n\n" contrast)))))
    (pop-to-buffer buffer)))

(defun ewal-suggest-face-fix (face)
  "Suggest fixes for a face with low contrast.

Arguments:
  - FACE (symbol): The face to suggest fixes for.

Returns:
  - (list): Suggested improvements for the face."
  (let* ((foreground (face-attribute face :foreground nil))
         (background (face-attribute face :background nil))
         (contrast (and foreground background
                        (ewal-theme-contrast-ratio foreground background)))
         (suggestions '()))
    (when (and foreground background contrast (< contrast 4.5))
      (push (list :foreground (color-darken-name foreground 10)) suggestions)
      (push (list :background (color-lighten-name background 10)) suggestions))
    suggestions))

(defun ewal-fix-face (face fix)
  "Apply a suggested fix to a face.

Arguments:
  - FACE (symbol): The face to modify.
  - FIX (list): List of properties and values to apply."
  (dolist (prop fix)
    (set-face-attribute face nil (car prop) (cdr prop))))

(defun ewal-check-and-fix-theme (theme-faces)
  "Check a theme for contrast issues and interactively fix them.

Arguments:
  - THEME-FACES (list): List of faces to check."
  (let ((warnings (ewal-check-theme-contrast theme-faces)))
    (if (not warnings)
        (message "No contrast issues found!")
      (ewal-display-contrast-warnings warnings)
      (dolist (warning warnings)
        (let ((face (nth 0 warning)))
          (when (yes-or-no-p (format "Fix face %s? " face))
            (let ((fixes (ewal-suggest-face-fix face)))
              (dolist (fix fixes)
                (ewal-fix-face face fix)))))))))

(provide 'ewal-theme-contrast-check)
;;; ewal-theme-contrast-check.el ends here
