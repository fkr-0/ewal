;;; ewal.el --- A pywal-based theme generator -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Uros Perisic
;; Copyright (C) 2019 Grant Shangreaux
;; Copyright (C) 2016-2018 Henrik Lissner

;; Author: Uros Perisic
;; URL: https://gitlab.com/jjzmajic/ewal
;;
;; Version: 0.2
;; Keywords: faces
;; Package-Requires: ((emacs "25.1"))

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

;; A dependency-free, pywal-based, automatic, terminal-aware Emacs
;; color-picker and theme generator.

;; My hope is that `ewal' will remain theme agnostic, with people
;; contributing functions like `ewal-get-spacemacs-theme-colors' from
;; `ewal-spacemacs-themes' for other popular themes such as
;; `solarized-emacs' <https://github.com/bbatsov/solarized-emacs>,
;; making it easy to keep the style of different themes, while
;; adapting them to the rest of your theming setup.  No problem should
;; ever have to be solved twice!

;;; Code:

;; deps
;; (require 'term/tty-colors)
(add-to-list 'load-path (expand-file-name "ewal" user-emacs-directory))
(require 'cl-lib)
(require 'color)
(require 'json)

(require 'ewal-theme-contrast-check)
(require 'ewal-palette-utils)
(require 'uncustomized-faces)
(require 'ewal-uncustomized-faces)

(defgroup ewal nil
  "Customizations for ewal theme."
  :group 'faces)

(defcustom ewal-json-file "~/.cache/wal/colors.json"
  "Location of the Pywal-generated theme in JSON format."
  :type 'string
  :group 'ewal)

(defcustom ewal-built-in-palette-path "~/.emacs.d/ewal/palettes/"
  "Base directory for built-in palettes."
  :type 'string
  :group 'ewal)

(defcustom ewal-built-in-palette-suffix ".json"
  "File extension for built-in palette files."
  :type 'string
  :group 'ewal)

(defcustom ewal-use-built-in-always nil
  "Always use built-in palettes instead of reading Pywal cache."
  :type 'boolean
  :group 'ewal)

(defcustom ewal-built-in-palette "sexy-material"
  "Default built-in palette to use."
  :type 'string
  :group 'ewal)

(defcustom ewal-dark-palette-p t
  "Use a dark palette by default."
  :type 'boolean
  :group 'ewal)

(defcustom ewal-primary-accent-color 'magenta
  "Primary accent color. Must be one of the ANSI color names."
  :type 'symbol
  :group 'ewal)

(defvar ewal-base-palette nil
  "Base palette extracted from Pywal JSON or built-in sources.")

(defvar ewal-shade-percent-difference 5
  "Percentage difference between shades.")

;;;###autoload
(defun ewal-load-colors (&optional json-file)
  "Load colors from the Pywal JSON file or fallback to built-in palettes.

Arguments:
  - json-file (string or nil): Path to the Pywal JSON file. Defaults to `ewal-json-file`.

Returns:
  - (alist or nil): Alist of colors loaded from the file or built-in palette.

Potential Errors:
  - Signals an error if JSON parsing fails or the file cannot be accessed.
  - Logs a message and uses the built-in palette on failure.
  "
  (let ((file (or json-file ewal-json-file)))
    (condition-case err
        (if (and (not ewal-use-built-in-always) (file-exists-p file))
            (ewal--parse-json file)
          (ewal--load-built-in-palette))
      (error (message "[ewal] Failed to load colors: %s" err)
             (ewal--load-built-in-palette))))
  ewal-base-palette)

(defun ewal--parse-json (file)
  "Parse the Pywal JSON FILE and populate `ewal-base-palette`.

Arguments:
  - file (string): Path to the JSON file.

Returns:
  - (alist): Alist of colors extracted from the JSON file.

Potential Errors:
  - Signals an error if the file is not a valid JSON or cannot be read.
  "
  (let* ((json-object-type 'alist)
         (json-array-type 'list)
         (colors (json-read-file file)))
    (setq ewal-base-palette
          (append (alist-get 'special colors)
                  (ewal--build-ansi-color-alist (alist-get 'colors colors))))))

(defun ewal--build-ansi-color-alist (colors)
  "Build an alist of ANSI color names and their values from COLORS.

Arguments:
  - colors (alist): List of color pairs (name . value).

Returns:
  - (alist): Alist mapping ANSI color names to their values.
  "
  (cl-loop for (name . value) in colors
           collect (cons (intern name) value)))

(defun ewal--load-built-in-palette ()
  "Load the built-in palette based on `ewal-built-in-palette`.

Returns:
  - (alist or nil): Alist of colors if the palette file is found and valid, otherwise nil.

Potential Errors:
  - Logs a message if the built-in palette file does not exist.
  "
  (let ((file (concat ewal-built-in-palette-path
                      (if ewal-dark-palette-p "dark/" "light/")
                      ewal-built-in-palette
                      ewal-built-in-palette-suffix)))
    (if (file-exists-p file)
        (ewal--parse-json file)
      (message "[ewal] Built-in palette not found: %s" file)
      nil)))

(defun ewal-get-color (color &optional shade)
  "Retrieve COLOR from `ewal-base-palette`, optionally adjusting SHADE.

Arguments:
  - color (symbol): Color name to retrieve.
  - shade (float or nil): Adjustment value for shade (positive for lighter, negative for darker).

Returns:
  - (string): Hexadecimal color string.

Potential Errors:
  - Returns nil if the color is not found in `ewal-base-palette`.
  "
  (let ((base-color (alist-get color ewal-base-palette)))
    (if shade
        (ewal--adjust-shade base-color shade)
      base-color)))

(defun ewal--adjust-shade (color shade)
  "Adjust the SHADE of COLOR (a hexadecimal string).

Arguments:
  - color (string): Hexadecimal color string.
  - shade (float): Adjustment value for shade (positive for lighter, negative for darker).

Returns:
  - (string): Adjusted hexadecimal color string.

Potential Errors:
  - Returns the input color if it is not a valid hexadecimal string.
  "
  (if (and color (string-prefix-p "#" color))
      (apply #'color-rgb-to-hex
             (cl-loop for component in (color-name-to-rgb color)
                      collect (min 1.0 (max 0.0 (+ component shade)))))
    color))

(defun ewal-blend-colors (color1 color2 alpha)
  "Blend COLOR1 and COLOR2 by ALPHA (a value between 0 and 1).

Arguments:
  - color1 (string): First hexadecimal color string.
  - color2 (string): Second hexadecimal color string.
  - alpha (float): Blending ratio, where 0 uses only COLOR2 and 1 uses only COLOR1.

Returns:
  - (string): Blended hexadecimal color string.

Potential Errors:
  - Signals an error if either color is not a valid hexadecimal string.
  "
  (apply #'color-rgb-to-hex
         (cl-mapcar (lambda (c1 c2)
                      (+ (* c1 alpha) (* c2 (- 1 alpha))))
                    (color-name-to-rgb color1)
                    (color-name-to-rgb color2))))
(defun ewal-generate-shades (color &optional steps adjustment)
  "Generate a list of lighter and darker shades for COLOR.

Arguments:
  - COLOR (string): Base color in hex format.
  - STEPS (integer, optional): Number of shades to generate in each direction.
    Defaults to 2.
  - ADJUSTMENT (integer, optional): Percentage adjustment per step.
    Defaults to 10.

Returns:
  - (alist): List of shades in the format:
    ((:light-1 . \"#XXXXXX\") (:light-2 . \"#XXXXXX\")
     (:dark-1 . \"#XXXXXX\") (:dark-2 . \"#XXXXXX\"))"
  (let ((steps (or steps 2))
        (adjustment (or adjustment 10))
        (shades '()))
    (dotimes (i steps)
      (let ((amount (* adjustment (1+ i))))
        (push (cons (intern (format ":light-%d" (1+ i))) (color-lighten-name color amount)) shades)
        (push (cons (intern (format ":dark-%d" (1+ i))) (color-darken-name color amount)) shades)))
    (reverse shades)))
(provide 'ewal)

;;; ewal.el ends here
