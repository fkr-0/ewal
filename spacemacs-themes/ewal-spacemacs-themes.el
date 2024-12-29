;;; ewal-spacemacs-themes.el --- Ride the rainbow spaceship -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Uros Perisic

;; Author: Uros Perisic
;; URL: https://gitlab.com/jjzmajic/ewal
;;
;; Version: 0.1
;; Keywords: faces
;; Package-Requires: ((emacs "25") (ewal "0.1") (spacemacs-theme "0.1"))

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

;; An `ewal'-based theme pack, created using `spacemacs-theme'
;; <https://github.com/nashamri/spacemacs-theme> as its base.  Emulate
;; this file if you want to contribute other `ewal' customized themes.

;;; Code:
;;; ewal-spacemacs-themes.el --- Refactored ewal-spacemacs-themes -*- lexical-binding: t; -*-

(require 'ewal-palette-utils)
(require 'color)

(defvar ewal-spacemacs-themes-colors nil
  "`spacemacs-theme' compatible colors extracted from the current `ewal' theme.")

(defun ewal-spacemacs-themes--generate-colors (&optional borders)
  "Generate theme colorscheme from palette. If BORDERS is non-nil, use `ewal-primary-accent-color` for borders."
  (let ((bg1 (ewal-get-color 'background 0))
        (bg2 (ewal-get-color 'background -2))
        (bg3 (ewal-get-color 'background -3))
        (bg4 (ewal-get-color 'background -4))
        (act1 (ewal-get-color 'background -3))
        (act2 (ewal-get-color ewal-primary-accent-color 0))
        (base (ewal-get-color 'foreground 0))
        (base-dim (ewal-get-color 'foreground -4))
        (comment (ewal-get-color 'comment 0))
        (border (ewal-get-color (if borders ewal-primary-accent-color 'background) 0))
        (highlight (ewal-get-color 'background 4))
        (red (ewal-get-color 'red 0))
        (green (ewal-get-color 'green 0))
        (cyan (ewal-get-color 'cyan 0))
        (yellow (ewal-get-color 'yellow 0))
        (blue (ewal-get-color 'blue 0))
        (magenta (ewal-get-color 'magenta 0)))
    `((bg1 . ,bg1)
      (bg2 . ,bg2)
      (bg3 . ,bg3)
      (bg4 . ,bg4)
      (act1 . ,act1)
      (act2 . ,act2)
      (base . ,base)
      (base-dim . ,base-dim)
      (comment . ,comment)
      (border . ,border)
      (highlight . ,highlight)
      (red . ,red)
      (green . ,green)
      (cyan . ,cyan)
      (yellow . ,yellow)
      (blue . ,blue)
      (magenta . ,magenta))))

;;;###autoload
(cl-defun ewal-spacemacs-themes-get-colors (&optional borders)
  "Get colors for `spacemacs-theme'.
If BORDERS is non-nil, includes border settings."
  (ewal-load-colors)
  (setq ewal-spacemacs-themes-colors
        (ewal-spacemacs-themes--generate-colors borders))
  ewal-spacemacs-themes-colors)

(defun ewal-spacemacs-themes-check-contrast ()
  "Check contrast for all defined colors in `ewal-spacemacs-themes-colors'.
Returns a list of problematic colors with contrast issues."
  (let ((warnings '()))
    (dolist (entry ewal-spacemacs-themes-colors)
      (let* ((name (car entry))
             (color (cdr entry))
             (contrast (ewal-theme-contrast-ratio color (alist-get 'bg1 ewal-spacemacs-themes-colors))))
        (when (< contrast 4.5)
          (push (list name color contrast) warnings))))
    warnings))

(defun ewal-spacemacs-themes-fix-contrast ()
  "Interactively fix contrast issues for `ewal-spacemacs-themes-colors'."
  (let ((warnings (ewal-spacemacs-themes-check-contrast)))
    (if (not warnings)
        (message "All colors have acceptable contrast!")
      (dolist (warning warnings)
        (let ((name (nth 0 warning))
              (color (nth 1 warning))
              (contrast (nth 2 warning)))
          (when (yes-or-no-p (format "Fix color '%s' with contrast %.2f? " name contrast))
            (let ((new-color (if (< contrast 4.5)
                                 (color-darken-name color 10)
                               (color-lighten-name color 10))))
              (setf (alist-get name ewal-spacemacs-themes-colors) new-color)
              (message "Adjusted '%s' to '%s'" name new-color))))))))

(defun ewal-spacemacs-themes-modernize-theme (theme)
  "Modernize a spacemacs theme by applying the `ewal-spacemacs-themes-colors`.
Arguments:
  - THEME (symbol): The name of the theme to modernize."
  (let ((class '((class color) (min-colors 89))))
    (custom-theme-set-faces
     theme
     `(default ((,class (:background ,(alist-get 'bg1 ewal-spacemacs-themes-colors)
                         :foreground ,(alist-get 'base ewal-spacemacs-themes-colors)))))
     `(cursor ((,class (:background ,(alist-get 'highlight ewal-spacemacs-themes-colors)))))
     `(line-number ((,class (:foreground ,(alist-get 'comment ewal-spacemacs-themes-colors)
                             :background ,(alist-get 'bg2 ewal-spacemacs-themes-colors)))))
     `(region ((,class (:background ,(alist-get 'bg3 ewal-spacemacs-themes-colors))))))))
(defun ewal-spacemacs-themes-reload ()
  "Reload the Spacemacs theme with the current `ewal` palette."
  (interactive)
  (ewal-spacemacs-themes-get-colors)
  (ewal-spacemacs-themes-modernize-theme 'spacemacs))

(provide 'ewal-spacemacs-themes)
;;; ewal-spacemacs-themes.el ends here
