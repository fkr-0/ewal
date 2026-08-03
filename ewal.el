;;; ewal.el --- A pywal-based theme generator -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Uros Perisic
;; Copyright (C) 2019 Grant Shangreaux
;; Copyright (C) 2016-2018 Henrik Lissner

;; Author: Uros Perisic
;; URL: https://github.com/fkr-0/ewal
;;
;; Version: 0.3.0
;; Keywords: faces
;; Package-Requires: ((emacs "25.1"))

;; This program is free software: you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation, either version 3 of the License, or (at your option) any later
;; version.

;;; Commentary:
;;
;; Core `ewal` functionality:
;;
;; - Load colors from a pywal JSON file or a built-in palette.
;; - Provide a simple API for retrieving colors with shade adjustment.
;; - Provide helpers for blending and generating shade series.
;; - Provide a small “element style” DSL used by other modules
;;   (e.g. `ewal-evil-cursors`).
;;
;; This file is intentionally theme-agnostic.  Doom, Spacemacs, and Evil
;; integration lives in separate files.

;;; Code:

(require 'cl-lib)
(require 'color)
(require 'json)
(require 'ewal-color-utils)

(defgroup ewal nil
  "Customizations for ewal theme generator."
  :group 'faces)

(defconst ewal-version "0.3.0"
  "Current Ewal release version.")

(defcustom ewal-json-file "~/.cache/wal/colors.json"
  "Primary pywal-compatible JSON palette file."
  :type 'file
  :group 'ewal)

(defcustom ewal-json-file-fallbacks
  '("~/.cache/colrz/current/colors.json")
  "Fallback pywal-compatible JSON palette files.

Files are checked in order when `ewal-json-file' does not exist.  An explicit
JSON-FILE passed to `ewal-load-colors' always takes precedence."
  :type '(repeat file)
  :group 'ewal)

(defconst ewal--library-directory
  (file-name-directory
   (or load-file-name
       (locate-library "ewal")
       default-directory))
  "Directory containing the installed Ewal library.")

(defcustom ewal-built-in-palette-path
  (expand-file-name "palettes/" ewal--library-directory)
  "Base directory for built-in palettes."
  :type 'directory
  :group 'ewal)

(defcustom ewal-built-in-palette-suffix ".json"
  "File extension for built-in palette files."
  :type 'string
  :group 'ewal)

(defcustom ewal-use-built-in-always nil
  "If non-nil, use built-in palettes instead of reading pywal cache."
  :type 'boolean
  :group 'ewal)

(defcustom ewal-built-in-palette "sexy-material"
  "Default built-in palette basename (without suffix)."
  :type 'string
  :group 'ewal)

(defcustom ewal-dark-palette-p t
  "If non-nil, use a dark palette subdirectory (`dark/`)."
  :type 'boolean
  :group 'ewal)

(defcustom ewal-primary-accent-color 'magenta
  "Primary accent color name (ANSI-like) used for borders / highlights."
  :type '(choice (const :tag "Red" red)
           (const :tag "Green" green)
           (const :tag "Yellow" yellow)
           (const :tag "Blue" blue)
           (const :tag "Magenta" magenta)
           (const :tag "Cyan" cyan))
  :group 'ewal)

(defcustom ewal-shade-percent-difference 5
  "Percentage difference per shade step.

A shade step of N gives a total adjustment of
N * `ewal-shade-percent-difference` percent."
  :type 'integer
  :group 'ewal)

(defvar ewal-base-palette nil
  "Base palette extracted from pywal JSON or built-in sources.

This is a flat alist mapping symbols to hex strings.

Typical keys:
  - `background`, `foreground`, `cursor` (from \"special\")
  - `color0`..`color15` (from \"colors\")
  - ANSI-ish aliases: `black`, `red`, `green`, ... etc.")

(defvar ewal--loaded-source nil
  "Description of the source used to populate `ewal-base-palette'.")

(defun ewal-palette-color-values (palette)
  "Return valid color values from flat PALETTE."
  (cl-loop for (_key . value) in palette
           when (ewal-color-valid-p value)
           collect (ewal-color-normalize value)))

(defun ewal--finalize-palette (palette)
  "Return PALETTE with contrast-safe semantic color roles.

The pywal format defines `background', `foreground', and `cursor', but theme
adaptors also need stable `comment' and `highlight' roles.  Derive missing
roles and guarantee that text and cursor colors are distinct from the base
background."
  (let* ((palette (copy-tree palette))
         (background (or (ewal-color-normalize
                          (alist-get 'background palette))
                         "#000000"))
         (candidates (ewal-palette-color-values palette))
         (foreground
          (ewal-color-ensure-contrast
           (or (alist-get 'foreground palette) "#ffffff")
           background
           ewal-color-minimum-text-contrast
           candidates))
         (cursor
          (ewal-color-ensure-contrast
           (or (alist-get 'cursor palette)
               (alist-get ewal-primary-accent-color palette)
               foreground)
           background
           ewal-color-minimum-ui-contrast
           candidates))
         (comment
          (ewal-color-ensure-contrast
           (or (alist-get 'comment palette)
               (alist-get 'bright-black palette)
               (alist-get 'color8 palette)
               foreground)
           background
           ewal-color-minimum-text-contrast
           candidates))
         (highlight
          (ewal-color-ensure-contrast
           (or (alist-get 'highlight palette) cursor)
           background
           ewal-color-minimum-ui-contrast
           candidates)))
    (setf (alist-get 'background palette) background
          (alist-get 'foreground palette) foreground
          (alist-get 'cursor palette) cursor
          (alist-get 'comment palette) comment
          (alist-get 'highlight palette) highlight)
    palette))

(define-obsolete-function-alias
  'ewal--palette-color-values #'ewal-palette-color-values "0.3.0")

(defun ewal--resolve-json-file (&optional json-file)
  "Return the pywal-compatible palette file selected for JSON-FILE.

When JSON-FILE is non-nil, return its expanded path even when it does not yet
exist.  Otherwise prefer `ewal-json-file', then the first existing path in
`ewal-json-file-fallbacks'.  If none exists, return the expanded primary path
so diagnostics remain predictable."
  (if json-file
      (expand-file-name json-file)
    (let* ((primary (expand-file-name ewal-json-file))
           (candidates
            (cons primary (mapcar #'expand-file-name
                                  ewal-json-file-fallbacks))))
      (or (cl-find-if #'file-exists-p candidates)
          primary))))

(defun ewal--parse-json (file)
  "Parse pywal JSON FILE and populate `ewal-base-palette`."
  (let* ((json-object-type 'alist)
          (json-array-type 'list)
          (colors (json-read-file file)))
    (setq ewal-base-palette
          (ewal--finalize-palette
           (append (alist-get 'special colors)
                   (ewal--build-ansi-color-alist
                    (alist-get 'colors colors)))))))

(defun ewal--ansi-symbol-for-index (idx)
  "Return ANSI color symbol for pywal color IDX, or nil."
  (let ((table [black   red     green   yellow
                 blue    magenta cyan    white
                 bright-black bright-red bright-green bright-yellow
                 bright-blue bright-magenta bright-cyan bright-white]))
    (when (and (integerp idx)
            (>= idx 0)
            (< idx (length table)))
      (aref table idx))))

(defun ewal--build-ansi-color-alist (colors)
  "Return COLORS extended with ANSI role aliases for color0 through color15."
  (let (result)
    ;; aliases
    (dolist (entry colors)
      (let* ((name (car entry))
              (value (cdr entry))
              (name-str (symbol-name name)))
        (when (string-match "^color\\([0-9]+\\)$" name-str)
          (let* ((idx (string-to-number (match-string 1 name-str)))
                  (sym (ewal--ansi-symbol-for-index idx)))
            (when sym (push (cons sym value) result))))))
    ;; originals
    (dolist (entry colors)
      (push entry result))
    (nreverse result)))


(defun ewal--load-built-in-palette ()
  "Load the built-in palette based on `ewal-built-in-palette`."
  (let ((file (concat ewal-built-in-palette-path
                (if ewal-dark-palette-p "dark/" "light/")
                ewal-built-in-palette
                ewal-built-in-palette-suffix)))
    (if (file-exists-p file)
      (ewal--parse-json file)
      (message "[ewal] Built-in palette not found: %s" file)
      (setq ewal-base-palette nil))))

;;;###autoload
(defun ewal-load-colors (&optional json-file force)
  "Load colors from JSON-FILE or fallback to built-in palettes.

When JSON-FILE is nil, use `ewal-json-file`.

With FORCE non-nil, reload even when the selected source has not changed.

Return the resulting `ewal-base-palette` alist.  On any error, log a message
and fall back to built-in palettes."
  (let* ((file (ewal--resolve-json-file json-file))
         (source
          (if (and (not ewal-use-built-in-always)
                   (file-exists-p file))
              (list 'json file (nth 5 (file-attributes file)))
            (list 'built-in ewal-dark-palette-p ewal-built-in-palette
                  (expand-file-name ewal-built-in-palette-path)))))
    (when (or force
              (null ewal-base-palette)
              (not (equal source ewal--loaded-source)))
      (condition-case err
          (if (eq (car source) 'json)
              (ewal--parse-json file)
            (ewal--load-built-in-palette))
        (error
         (message "[ewal] Failed to load colors: %S" err)
         (ewal--load-built-in-palette)))
      (setq ewal--loaded-source source)))
  ewal-base-palette)
(defalias 'ewal--normalize-color #'ewal-color-normalize)

(defun ewal--adjust-shade (color shade &optional shade-percent-diff)
  "Return COLOR adjusted by SHADE using SHADE-PERCENT-DIFF per step.

SHADE > 0  → lighten COLOR.
SHADE < 0  → darken COLOR.
SHADE = 0 or nil → return COLOR unchanged (normalized to hex)."
  (let* ((hex (ewal--normalize-color color))
         (step (or shade-percent-diff ewal-shade-percent-difference))
         (amount (* (or shade 0) step)))
    (if (not hex)
        color
      (if (zerop amount)
          hex
        (ewal-color-adjust-lightness hex amount)))))

;;;###autoload
(defun ewal-get-color (color &optional shade shade-percent-difference)
  "Retrieve COLOR from the `ewal-base-palette`, optionally adjusting SHADE.

COLOR is a symbol like `background`, `foreground`, `red`, etc.

SHADE is a signed integer indicating steps; each step is
`ewal-shade-percent-difference` percent, unless SHADE-PERCENT-DIFFERENCE
is provided.

Return a hex color string (e.g. \"#1a1b26\") or nil if COLOR is unknown."
  (ewal-load-colors)
  (let ((base (alist-get color ewal-base-palette)))
    (when base
      (ewal--adjust-shade base shade shade-percent-difference))))

(defun ewal-get-colors (colors &optional shade)
  "Retrieve a list of COLORS from `ewal-base-palette`, adjusting SHADE."
  (mapcar (lambda (c) (ewal-get-color c shade)) colors))
(defun ewal-blend-colors (color1 color2 alpha)
  "Blend COLOR1 and COLOR2 by ALPHA (0–1).  Return hex or nil."
  (ewal-color-blend color1 color2 alpha))

(defun ewal-generate-shades (color &optional steps adjustment)
  "Generate lighter and darker shades for COLOR.

Return an alist like:

  ((:light-1 . \"#XXXXXX\") (:light-2 . \"#XXXXXX\")
   (:dark-1  . \"#XXXXXX\") (:dark-2  . \"#XXXXXX\"))

STEPS defaults to 2, ADJUSTMENT (percent per step) defaults to 10."
  (let ((steps (or steps 2))
         (adjustment (or adjustment 10))
         (shades '()))
    (dotimes (i steps)
      (let ((amount (* adjustment (1+ i))))
        (push (cons (intern (format ":light-%d" (1+ i)))
                    (ewal-color-adjust-lightness color amount))
          shades)
        (push (cons (intern (format ":dark-%d" (1+ i)))
                    (ewal-color-adjust-lightness color (- amount)))
          shades)))
    (nreverse shades)))

(defun ewal-generate-element-styles (specs)
  "Resolve SPECS into an alist of styles based on the current `ewal` palette.

SPECS is a list of forms like:

  (STATE :background COLOR-ID [:foreground COLOR-ID] [:shade N] ...)

COLOR-ID may be:
  - a palette key symbol (`cursor`, `green`, `background`, ...)
  - a literal color string (\"#RRGGBB\" or named color).

Return an alist:
  ((STATE . (:background \"#...\" :cursor-style bar ...)) ...)

The :shade property is consumed (used to lighten/darken) and is
removed from the resulting plist."
  (ewal-load-colors)
  (let (result)
    (dolist (spec specs (nreverse result))
      (let* ((state (car spec))
              (plist (cdr spec))
              (shade (plist-get plist :shade))
              (bg-id (plist-get plist :background))
              (fg-id (plist-get plist :foreground))
              (bg (cond
                    ((and bg-id (symbolp bg-id))
                      (ewal-get-color bg-id shade))
                    ((stringp bg-id)
                      (ewal--adjust-shade bg-id shade))
                    (t nil)))
              (fg (cond
                    ((and fg-id (symbolp fg-id))
                      (ewal-get-color fg-id shade))
                    ((stringp fg-id)
                      (ewal--adjust-shade fg-id shade))
                    (t nil)))
              ;; rebuild plist without :shade
              (plist (cl-loop for (key val) on plist by #'cddr
                       unless (eq key :shade)
                       append (list key val))))
        (when bg (setq plist (plist-put plist :background bg)))
        (when fg (setq plist (plist-put plist :foreground fg)))
        (push (cons state plist) result)))))

(provide 'ewal)

;;; ewal.el ends here
