;;; ewal-color-utils.el --- Contrast-safe color helpers for Ewal -*- lexical-binding: t; -*-

;; Copyright (C) 2026

;; Author: Ewal contributors
;; Keywords: faces
;;; Commentary:
;;
;; Dependency-light color utilities shared by the core palette loader and the
;; Doom, Spacemacs, and Evil cursor adaptors.  Contrast calculations implement
;; the WCAG relative-luminance formula, including sRGB linearization.

;;; Code:

(require 'cl-lib)
(require 'color)
(require 'subr-x)

(defgroup ewal-color nil
  "Color normalization and contrast safety for Ewal."
  :group 'faces)

(defcustom ewal-color-minimum-text-contrast 4.5
  "Default minimum contrast ratio for ordinary text."
  :type 'number
  :group 'ewal-color)

(defun ewal-color--hex-rgb (color)
  "Parse hexadecimal COLOR into an RGB list of floats, or nil.

Recognize Emacs's common #RGB, #RRGGBB, and #RRRRGGGGBBBB forms without
consulting the current display.  This keeps batch and daemon-startup behavior
identical to graphical sessions."
  (when (and (stringp color) (string-prefix-p "#" color))
    (pcase (length color)
      (4
       (when (string-match-p "\\`#[[:xdigit:]]\\{3\\}\\'" color)
         (cl-loop for index from 1 to 3
                  collect (/ (float (string-to-number
                                     (substring color index (1+ index)) 16))
                             15.0))))
      (7
       (when (string-match-p "\\`#[[:xdigit:]]\\{6\\}\\'" color)
         (cl-loop for index in '(1 3 5)
                  collect (/ (float (string-to-number
                                     (substring color index (+ index 2)) 16))
                             255.0))))
      (13
       (when (string-match-p "\\`#[[:xdigit:]]\\{12\\}\\'" color)
         (cl-loop for index in '(1 5 9)
                  collect (/ (float (string-to-number
                                     (substring color index (+ index 4)) 16))
                             65535.0)))))))

(defun ewal-color--rgb (color)
  "Return COLOR as three sRGB floats, or nil when COLOR is invalid."
  (cond
   ((memq color '(nil unspecified unspecified-bg unspecified-fg)) nil)
   ((and (stringp color)
         (member color '("unspecified" "unspecified-bg" "unspecified-fg")))
    nil)
   ((and (consp color) (not (functionp color)))
    (ewal-color--rgb (car color)))
   ((symbolp color)
    (ewal-color--rgb (symbol-name color)))
   ((stringp color)
    (or (ewal-color--hex-rgb color)
        (ignore-errors (color-name-to-rgb color))))
   (t nil)))

(defun ewal-color--clamp-channel (channel)
  "Clamp RGB CHANNEL to the inclusive 0.0–1.0 range."
  (max 0.0 (min 1.0 (float channel))))

(defun ewal-color-rgb-to-hex (rgb)
  "Return RGB floats as a lowercase #RRGGBB string."
  (when (and (listp rgb) (= (length rgb) 3))
    (apply #'format "#%02x%02x%02x"
           (mapcar (lambda (channel)
                     (round (* 255 (ewal-color--clamp-channel channel))))
                   rgb))))

(defcustom ewal-color-minimum-ui-contrast 3.0
  "Default minimum contrast ratio for cursors and UI boundaries."
  :type 'number
  :group 'ewal-color)

(defun ewal-color-normalize (color)
  "Return COLOR as a lowercase #RRGGBB string, or nil when invalid.

COLOR may be a color name, a hex string, a symbol naming a color, or a
Doom-style color list whose first element is the graphical color.  Emacs face
sentinels such as `unspecified' are treated as missing colors."
  (when-let ((rgb (ewal-color--rgb color)))
    (ewal-color-rgb-to-hex rgb)))

(defun ewal-color-valid-p (color)
  "Return non-nil when COLOR can be normalized by Emacs."
  (and (ewal-color-normalize color) t))

(defun ewal-color-equal-p (color-a color-b)
  "Return non-nil when COLOR-A and COLOR-B resolve to the same RGB value."
  (let ((a (ewal-color-normalize color-a))
        (b (ewal-color-normalize color-b)))
    (and a b (string-equal a b))))

(defun ewal-color--linearize-channel (channel)
  "Convert one gamma-encoded sRGB CHANNEL to a linear-light value."
  (if (<= channel 0.04045)
      (/ channel 12.92)
    (expt (/ (+ channel 0.055) 1.055) 2.4)))

(defun ewal-color-relative-luminance (color)
  "Return WCAG relative luminance for COLOR.

Signal `user-error' when COLOR is invalid."
  (let ((rgb (or (ewal-color--rgb color)
                 (user-error "Invalid color: %S" color))))
    (+ (* 0.2126 (ewal-color--linearize-channel (nth 0 rgb)))
       (* 0.7152 (ewal-color--linearize-channel (nth 1 rgb)))
       (* 0.0722 (ewal-color--linearize-channel (nth 2 rgb))))))

(defun ewal-color-contrast-ratio (color-a color-b)
  "Return the WCAG contrast ratio between COLOR-A and COLOR-B."
  (let* ((a (ewal-color-relative-luminance color-a))
         (b (ewal-color-relative-luminance color-b))
         (lighter (max a b))
         (darker (min a b)))
    (/ (+ lighter 0.05) (+ darker 0.05))))

(defun ewal-color-contrast-sufficient-p (foreground background &optional minimum)
  "Return non-nil when FOREGROUND is sufficiently distinct from BACKGROUND.

MINIMUM defaults to `ewal-color-minimum-text-contrast'.  Equal colors never
count as sufficient, even with an unusually low MINIMUM."
  (let ((minimum (or minimum ewal-color-minimum-text-contrast)))
    (and (ewal-color-valid-p foreground)
         (ewal-color-valid-p background)
         (not (ewal-color-equal-p foreground background))
         (>= (ewal-color-contrast-ratio foreground background) minimum))))

(defun ewal-color--adjustment-candidates (foreground background)
  "Return hue-preserving contrast candidates for FOREGROUND on BACKGROUND."
  (let* ((foreground (ewal-color-normalize foreground))
         (background-dark-p
          (< (ewal-color-relative-luminance background) 0.5)))
    (when foreground
      (mapcar (lambda (amount)
                (ewal-color-adjust-lightness
                 foreground (if background-dark-p amount (- amount))))
              '(5 10 15 20 25 30 35 40 50 60 70 80 90 100)))))

(defun ewal-color-adjust-lightness (color percent)
  "Return COLOR lightened or darkened by PERCENT.

Positive PERCENT blends toward white; negative PERCENT blends toward black.
The implementation is display-independent and always returns #RRGGBB."
  (when-let ((rgb (ewal-color--rgb color)))
    (let* ((amount (min 1.0 (/ (float (abs percent)) 100.0)))
           (target (if (>= percent 0) 1.0 0.0)))
      (ewal-color-rgb-to-hex
       (mapcar (lambda (channel)
                 (+ channel (* (- target channel) amount)))
               rgb)))))

(defun ewal-color-blend (color-a color-b alpha)
  "Blend COLOR-A and COLOR-B using ALPHA as COLOR-A's weight.

ALPHA is clamped to 0.0–1.0.  Return #RRGGBB, or nil when either color is
invalid."
  (let ((a (ewal-color--rgb color-a))
        (b (ewal-color--rgb color-b))
        (alpha (max 0.0 (min 1.0 (float alpha)))))
    (when (and a b)
      (ewal-color-rgb-to-hex
       (cl-mapcar (lambda (channel-a channel-b)
                    (+ (* channel-a alpha)
                       (* channel-b (- 1.0 alpha))))
                  a b)))))

(defun ewal-color-best-contrast (background candidates)
  "Return the member of CANDIDATES with greatest contrast on BACKGROUND.

Invalid colors and colors equal to BACKGROUND are ignored."
  (let ((background (ewal-color-normalize background))
        best
        (best-ratio -1.0))
    (when background
      (dolist (candidate candidates best)
        (when-let ((candidate (ewal-color-normalize candidate)))
          (unless (ewal-color-equal-p candidate background)
            (let ((ratio (ewal-color-contrast-ratio candidate background)))
              (when (> ratio best-ratio)
                (setq best candidate
                      best-ratio ratio)))))))))

(defun ewal-color-ensure-contrast
    (foreground background &optional minimum additional-candidates)
  "Return a contrast-safe FOREGROUND for BACKGROUND.

MINIMUM defaults to `ewal-color-minimum-text-contrast'.  Preserve FOREGROUND
when it already meets the threshold.  Otherwise first try hue-preserving
lightness adjustments, then ADDITIONAL-CANDIDATES, black, and white.  The
returned color is always distinct from BACKGROUND when a valid BACKGROUND is
provided."
  (let* ((minimum (or minimum ewal-color-minimum-text-contrast))
         (foreground (ewal-color-normalize foreground))
         (background (ewal-color-normalize background)))
    (cond
     ((null background) foreground)
     ((and foreground
           (ewal-color-contrast-sufficient-p foreground background minimum))
      foreground)
     (t
      (let* ((candidates
              (cl-remove-duplicates
               (delq nil
                     (append (and foreground
                                  (ewal-color--adjustment-candidates
                                   foreground background))
                             additional-candidates
                             '("#000000" "#ffffff")))
               :test #'ewal-color-equal-p))
             (passing
              (cl-find-if
               (lambda (candidate)
                 (ewal-color-contrast-sufficient-p
                  candidate background minimum))
               candidates)))
        (or passing
            (ewal-color-best-contrast background candidates)
            (if (< (ewal-color-relative-luminance background) 0.5)
                "#ffffff"
              "#000000")))))))

(provide 'ewal-color-utils)
;;; ewal-color-utils.el ends here
