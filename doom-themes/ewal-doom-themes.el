;;; ewal-doom-themes.el --- Dread the colors of darkness -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2020 Uros Perisic

;; Author: Uros Perisic
;; URL: https://gitlab.com/jjzmajic/ewal
;;
;; Version: 0.1
;; Keywords: faces
;; Package-Requires: ((emacs "25") (ewal "0.1") (doom-themes "0.1"))

;; This program is free software: you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation, either version 3 of the License, or (at your option) any later
;; version.

;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
;; details.

;; You should have received a copy of the GNU General Public License along with
;; this program. If not, see <http://www.gnu.org/licenses/>.

;; This file is not part of Emacs.

;;; Commentary:

;; An `ewal'-based theme library, to be used when working with
;; `doom-themes' as a base.

;;; Code:
(require 'ewal)
(require 'doom-themes)

(defun ewal-doom-themes-get-color (color &optional shade shade-percent-difference)
  "Return COLOR of SHADE with SHADE-PERCENT-DIFFERENCE.
Uses `ewal-get-color` to retrieve the color and provides:
  - One accurate hex color.
  - Two TTY approximation colors for compatibility with `def-doom-theme`."
  (let* ((hex-color (ewal-get-color color shade shade-percent-difference))
         (tty-color (let ((ewal-force-tty-colors-p t))
                      (ewal-get-color color shade shade-percent-difference))))
    `(,hex-color ,tty-color ,tty-color)))

(defun ewal-doom-themes-check-theme-contrast (theme-faces)
  "Check contrast for the faces in a Doom theme.
Arguments:
  - THEME-FACES (list): List of face definitions from the theme.

Returns:
  - (list): Faces with low contrast ratios, including problematic definitions."
  (let ((warnings '()))
    (dolist (face theme-faces)
      (let* ((foreground (plist-get face :foreground))
             (background (plist-get face :background))
             (contrast (and foreground background
                            (ewal-theme-contrast-ratio foreground background))))
        (when (and contrast (< contrast 4.5))
          (push (list (plist-get face :name) foreground background contrast) warnings))))
    warnings))

(defun ewal-doom-themes-fix-theme (theme-faces)
  "Interactively fix faces in a Doom theme with contrast issues.
Arguments:
  - THEME-FACES (list): List of face definitions from the theme.

Suggests fixes for each problematic face and allows interactive adjustments."
  (let ((warnings (ewal-doom-themes-check-theme-contrast theme-faces)))
    (if (not warnings)
        (message "All faces have acceptable contrast!")
      (dolist (warning warnings)
        (let* ((face (nth 0 warning))
               (foreground (nth 1 warning))
               (background (nth 2 warning))
               (contrast (nth 3 warning)))
          (when (yes-or-no-p (format "Fix face '%s' with contrast ratio %.2f? " face contrast))
            (let ((new-foreground (color-darken-name foreground 10))
                  (new-background (color-lighten-name background 10)))
              (message "Adjusting '%s': FG -> %s, BG -> %s" face new-foreground new-background)
              (set-face-attribute face nil :foreground new-foreground :background new-background)))))))))

;;;###autoload
(when (and (boundp 'custom-theme-load-path)
           load-file-name)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory
                (file-name-directory load-file-name))))


(provide 'ewal-doom-themes)
;;; ewal-doom-themes.el ends here
