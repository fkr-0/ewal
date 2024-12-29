;;; ewal-doom-one-theme.el --- Dread the color of darkness -*- lexical-binding: t; -*-

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

;; An `ewal'-based theme, created using `doom-one' as its base.

;;; Code:
(require 'ewal-doom-themes)



(defgroup ewal-doom-one-theme nil
  "Options for Doom themes based on `ewal'."
  :group 'doom-themes)

(defcustom ewal-doom-one-brighter-modeline nil
  "Use more vivid colors for the mode-line if non-nil."
  :group 'ewal-doom-one-theme
  :type 'boolean)

(defcustom ewal-doom-one-brighter-comments nil
  "Highlight comments in more vivid colors if non-nil."
  :group 'ewal-doom-one-theme
  :type 'boolean)

(defcustom ewal-doom-one-comment-bg ewal-doom-one-brighter-comments
  "Add a subtle background to comments if non-nil."
  :group 'ewal-doom-one-theme
  :type 'boolean)

(defcustom ewal-doom-one-padded-modeline doom-themes-padded-modeline
  "Add padding to the mode-line. Can be an integer for exact padding."
  :group 'ewal-doom-one-theme
  :type '(choice integer boolean))

;;; Load palette
(ewal-load-colors)

;;; Ensure theme colors meet contrast requirements
(let ((warnings (ewal-check-theme-contrast (face-list))))
  (when warnings
    (message "Warning: Low contrast faces detected. Run `ewal-theme-contrast-check` for details.")))

;;; Define theme
(def-doom-theme ewal-doom-one-x
                "A dark theme inspired by Atom One Dark, customized with `ewal'."

                ;; name        default   256       16
                ((bg         (ewal-doom-themes-get-color 'background  0))
                 (bg-alt     (ewal-doom-themes-get-color 'background -3))
                 (base0      (ewal-doom-themes-get-color 'background -5))
                 (base1      (ewal-doom-themes-get-color 'background -4))
                 (base2      (ewal-doom-themes-get-color 'background -2))
                 (base3      (ewal-doom-themes-get-color 'background -1))
                 (base4      (ewal-doom-themes-get-color 'background +1))
                 (base5      (ewal-doom-themes-get-color 'comment     0))
                 (base6      (ewal-doom-themes-get-color 'background +4))
                 (base7      (ewal-doom-themes-get-color 'background +5))
                 (base8      (ewal-doom-themes-get-color 'foreground +1))
                 (fg         (ewal-doom-themes-get-color 'foreground  0))
                 (fg-alt     (ewal-doom-themes-get-color 'foreground -1))

                 (grey       base4)
                 (red        (ewal-doom-themes-get-color 'red      -1))
                 (orange     (ewal-doom-themes-get-color 'red       0))
                 (green      (ewal-doom-themes-get-color 'green    -1))
                 (teal       (ewal-doom-themes-get-color 'green     0))
                 (yellow     (ewal-doom-themes-get-color 'yellow   -1))
                 (blue       (ewal-doom-themes-get-color 'blue      0))
                 (dark-blue  (ewal-doom-themes-get-color 'blue     -1))
                 (magenta    (ewal-doom-themes-get-color 'magenta   0))
                 (violet     (ewal-doom-themes-get-color 'magenta  -1))
                 (cyan       (ewal-doom-themes-get-color 'cyan      0))
                 (dark-cyan  (ewal-doom-themes-get-color 'cyan     -1))

                 ;; face categories
                 (highlight      blue)
                 (vertical-bar   (doom-darken base1 0.1))
                 (selection      dark-blue)
                 (builtin        magenta)
                 (comments       (if ewal-doom-one-brighter-comments dark-cyan base5))
                 (doc-comments   (doom-lighten (if ewal-doom-one-brighter-comments dark-cyan base5) 0.25))
                 (constants      violet)
                 (functions      magenta)
                 (keywords       blue)
                 (methods        cyan)
                 (operators      blue)
                 (type           yellow)
                 (strings        green)
                 (variables      (doom-lighten magenta 0.4))
                 (numbers        orange)
                 (region         `(,(doom-lighten (car bg-alt) 0.15) ,@(doom-lighten (cdr base1) 0.35)))
                 (error          red)
                 (warning        yellow)
                 (success        green)
                 (vc-modified    orange)
                 (vc-added       green)
                 (vc-deleted     red)

                 ;; custom categories
                 (hidden     `(,(car bg) \"black\" \"black\"))
                 (-modeline-bright ewal-doom-one-brighter-modeline)
                 (-modeline-pad
                  (when ewal-doom-one-padded-modeline
                    (if (integerp ewal-doom-one-padded-modeline) ewal-doom-one-padded-modeline 4)))

                 (modeline-fg     nil)
                 (modeline-fg-alt base5)

                 (modeline-bg
                  (if -modeline-bright
                      (doom-darken blue 0.475)
                    `(,(doom-darken (car bg-alt) 0.15) ,@(cdr base0))))
                 (modeline-bg-l
                  (if -modeline-bright
                      (doom-darken blue 0.45)
                    `(,(doom-darken (car bg-alt) 0.1) ,@(cdr base0))))
                 (modeline-bg-inactive   `(,(doom-darken (car bg-alt) 0.1) ,@(cdr bg-alt)))
                 (modeline-bg-inactive-l `(,(car bg-alt) ,@(cdr base1))))

                ;; --- extra faces ------------------------
                ((line-number :foreground base4)
                 (line-number-current-line :foreground fg)
                 (font-lock-comment-face
                  :foreground comments
                  :background (if ewal-doom-one-comment-bg (doom-lighten bg 0.05)))
                 (font-lock-doc-face :inherit 'font-lock-comment-face :foreground doc-comments))

                ;; --- extra variables ---------------------
                ())

(provide-theme 'ewal-doom-one)

;;; ewal-doom-one-theme.el ends here
