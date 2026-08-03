;;; ewal-evil-cursors.el --- `ewal'-colored evil cursor for Emacs and Spacemacs -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Uros Perisic

;; Author: Uros Perisic
;; URL: https://github.com/fkr-0/ewal
;;
;; Version: 1.1.0
;; Keywords: faces
;; Package-Requires: ((emacs "25") (ewal "0.3.0"))

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
;; An `ewal'-based `evil' cursor colorscheme in both Spacemacs and
;; vanilla Emacs format.
;;
;; This version is:
;; - Palette-driven: all colors resolved via `ewal-get-color' or safe fallbacks.
;; - Backwards compatible with Doom/Spacemacs calls to
;;   `ewal-evil-cursors-get-colors'.
;; - Optionally tints per-state modeline faces.

;;; Code:

(require 'cl-lib)
(require 'color)
(require 'ewal)
(require 'ewal-color-utils)

(defvar evil-state)
(defvar evil-previous-state)
(defvar evil-local-mode)
(defvar spacemacs-evil-cursors)
(defvar spaceline-evil-state-faces)
(defvar spaceline-highlight-face-func)
(declare-function spaceline-highlight-face-default "ext:noop")

(defgroup ewal-evil-cursors nil
  "Evil cursor and modeline theming driven by `ewal' palettes."
  :group 'faces)

(defcustom ewal-evil-cursors-modeline-per-state t
  "If non-nil, tint modeline highlight faces per evil state.

This uses `ewal-evil-cursors-evil-state-faces' to decide which
faces to change, and uses the :background color from the style
for that state."
  :type 'boolean
  :group 'ewal-evil-cursors)

(defcustom ewal-evil-cursors-track-evil-mode-line t
  "If non-nil, update mode-line backgrounds when Evil state changes."
  :type 'boolean
  :group 'ewal-evil-cursors)

(defcustom ewal-evil-cursors-mode-line-faces
  '(mode-line mode-line-active doom-modeline-bar)
  "Faces whose background should follow the current Evil state color."
  :type '(repeat symbol)
  :group 'ewal-evil-cursors)

(defcustom ewal-evil-cursors-mode-line-text-faces
  '(mode-line mode-line-active)
  "Faces that should also receive contrast-aware foreground updates."
  :type '(repeat symbol)
  :group 'ewal-evil-cursors)

(defcustom ewal-evil-cursors-mode-line-max-luminance 0.35
  "Maximum luminance allowed for Evil-driven mode-line backgrounds."
  :type 'number
  :group 'ewal-evil-cursors)

(defcustom ewal-evil-cursors-mode-line-darken-step 20
  "Percent used per darkening step while normalizing mode-line background."
  :type 'integer
  :group 'ewal-evil-cursors)

(defcustom ewal-evil-cursors-darken-cursor-backgrounds t
  "If non-nil, normalize cursor state backgrounds away from very bright values."
  :type 'boolean
  :group 'ewal-evil-cursors)

(defcustom ewal-evil-cursors-cursor-max-luminance 0.45
  "Maximum luminance allowed for cursor state background colors."
  :type 'number
  :group 'ewal-evil-cursors)

(defcustom ewal-evil-cursors-cursor-darken-step 15
  "Percent used per darkening step while normalizing cursor colors."
  :type 'integer
  :group 'ewal-evil-cursors)

(defcustom ewal-evil-cursors-obey-evil-p t
  "Whether to respect evil's operator/insert/hybrid semantics.

Currently only affects how `ewal-evil-cursors-highlight-face'
chooses the state (operator uses previous state)."
  :type 'boolean
  :group 'ewal-evil-cursors)

(defvar ewal-evil-cursors-spacemacs-colors nil
  "`spacemacs-evil-cursors' compatible colors.
Extracted from current `ewal' palette.")

(defvar ewal-evil-cursors-emacs-colors nil
  "Vanilla Emacs Evil compatible colors.
Extracted from current `ewal' palette, and stored as an alist.")

(defvar ewal-evil-cursors-evil-state-faces
  '((normal . ewal-evil-cursors-normal-state)
     (insert . ewal-evil-cursors-insert-state)
     (emacs . ewal-evil-cursors-emacs-state)
     (hybrid . ewal-evil-cursors-hybrid-state)
     (replace . ewal-evil-cursors-replace-state)
     (visual . ewal-evil-cursors-visual-state)
     (motion . ewal-evil-cursors-motion-state)
     (lisp . ewal-evil-cursors-lisp-state)
     (iedit . ewal-evil-cursors-iedit-state)
     (iedit-insert . ewal-evil-cursors-iedit-state))
  "Association list mapping evil states to their corresponding highlight faces.
Used by modeline tinting and by spaceline integrations.")

(defvar ewal-evil-cursors--saved-mode-line-face-attrs nil
  "Saved mode-line face attributes for restoring when mode is disabled.")


;;; Internal helpers

(defun ewal-evil-cursors--resolve-color (role &optional fallback)
  "Resolve ROLE into a hex color string.

ROLE may be:
  - a hex string   → returned as-is
  - a symbol       → looked up via `ewal-get-color'
                     (e.g. `green', `blue', `cursor', `foreground')
  - anything else  → FALLBACK

If `ewal-get-color' returns nil, FALLBACK is used.  If both fail,
we return a hardcoded safe default."
  (ewal-load-colors)
  (cond
    ((and (stringp role)
       (string-prefix-p "#" role))
      role)
    ((symbolp role)
      (or (ewal-get-color role 0)
        ;; white/black convenience for palettes without those keys
        (pcase role
          ('white "#ffffff")
          ('black "#000000")
          (_ fallback))
        fallback
        "#ffffff"))
    (t
      (or fallback "#ffffff"))))

(defun ewal-evil-cursors--safe-blend (c1 c2 alpha)
  "Blend colors C1 and C2 by ALPHA, but tolerate missing values.

If one of the colors is nil, fallback to the other; if both are
nil, use white.  ALPHA is a float between 0 and 1."
  (let* ((c1 (or c1 "#ffffff"))
          (c2 (or c2 "#000000")))
    (condition-case _
      (ewal-blend-colors c1 c2 alpha)
      (error c1))))

(defun ewal-evil-cursors--to-hex6 (color-name &optional fallback)
  "Normalize COLOR-NAME into #RRGGBB, using FALLBACK when invalid."
  (or (ewal-color-normalize color-name)
      (ewal-color-normalize fallback)
      "#000000"))

(defun ewal-evil-cursors--darken-hex (color percent)
  "Darken COLOR by PERCENT using deterministic RGB scaling."
  (ewal-color-adjust-lightness color (- (abs percent))))

(defun ewal-evil-cursors--relative-luminance (color-name)
  "Return relative luminance for COLOR-NAME."
  (ewal-color-relative-luminance color-name))

(defun ewal-evil-cursors--contrast-ratio (a b)
  "Return WCAG contrast ratio between colors A and B."
  (ewal-color-contrast-ratio a b))

(defun ewal-evil-cursors--normalize-modeline-background (background)
  "Return darker variant of BACKGROUND for mode-line readability."
  (let ((result (ewal-evil-cursors--to-hex6 background background))
        (step (max 1 ewal-evil-cursors-mode-line-darken-step))
        (i 0))
    (while (and (< i 6)
                (> (ewal-evil-cursors--relative-luminance result)
                   ewal-evil-cursors-mode-line-max-luminance))
      (setq result (ewal-evil-cursors--to-hex6
                    (ewal-evil-cursors--darken-hex result step)
                    result))
      (setq i (1+ i)))
    result))

(defun ewal-evil-cursors--normalize-cursor-background (background)
  "Return normalized cursor BACKGROUND based on luminance settings."
  (let ((result (ewal-evil-cursors--to-hex6 background background))
        (step (max 1 ewal-evil-cursors-cursor-darken-step))
        (i 0))
    (when ewal-evil-cursors-darken-cursor-backgrounds
      (while (and (< i 6)
                  (> (ewal-evil-cursors--relative-luminance result)
                     ewal-evil-cursors-cursor-max-luminance))
        (setq result (ewal-evil-cursors--to-hex6
                      (ewal-evil-cursors--darken-hex result step)
                      result)
              i (1+ i))))
    (let ((editor-background
           (or (ewal-color-normalize
                (face-attribute 'default :background nil 'default))
               (ewal-get-color 'background)
               "#000000")))
      (ewal-color-ensure-contrast
       result editor-background ewal-color-minimum-ui-contrast
       (ewal-palette-color-values ewal-base-palette)))))

(defun ewal-evil-cursors--best-text-foreground (background)
  "Return best readable foreground for BACKGROUND."
  (let ((default-fg
         (or (ewal-color-normalize
              (face-attribute 'mode-line :foreground nil 'default))
             "#ffffff")))
    (ewal-color-ensure-contrast
     default-fg background ewal-color-minimum-text-contrast
     (ewal-palette-color-values ewal-base-palette))))

(defun ewal-evil-cursors--mode-line-colors (background)
  "Return plist with contrast-safe mode-line colors from BACKGROUND."
  (let* ((bg (ewal-evil-cursors--normalize-modeline-background background))
         (fg (ewal-evil-cursors--best-text-foreground bg)))
    (list :background bg :foreground fg)))

(defun ewal-evil-cursors--normalize-style-backgrounds (styles)
  "Return STYLES with normalized cursor backgrounds."
  (mapcar
   (lambda (entry)
     (let* ((state (car entry))
            (attrs (copy-sequence (cdr entry)))
            (bg (plist-get attrs :background))
            (norm-bg (ewal-evil-cursors--normalize-cursor-background bg)))
       (cons state (plist-put attrs :background norm-bg))))
   styles))


;;; Style generation

(defun ewal-evil-cursors--generate-styles ()
  "Generate cursor styles dynamically based on the current `ewal' palette.

Returns an alist of the form:
  ((STATE . (:background \"#rrggbb\" :cursor-style SHAPE)) ...)

STATE is an evil state symbol, SHAPE is one of `box', `bar',
`hbar'."
  (ewal-load-colors)
  (let* ((default-fg (or (ewal-get-color 'foreground 0) "#f2f3f7"))
          (cursor     (ewal-evil-cursors--resolve-color 'cursor default-fg))
          (green      (ewal-evil-cursors--resolve-color 'green "#98be65"))
          (blue       (ewal-evil-cursors--resolve-color 'blue "#51afef"))
          (red        (ewal-evil-cursors--resolve-color 'red "#ff6c6b"))
          (magenta    (ewal-evil-cursors--resolve-color 'magenta "#c678dd"))
          (accent     (ewal-evil-cursors--resolve-color ewal-primary-accent-color magenta))
          (white      (ewal-evil-cursors--resolve-color 'foreground "#ffffff"))
          (visual-bg  (ewal-evil-cursors--safe-blend white cursor 0.35))
          (replace-bg (ewal-evil-cursors--safe-blend red cursor 0.4))
          (lisp-bg    (ewal-evil-cursors--safe-blend magenta cursor 0.5)))
    (let ((styles `((normal       :background ,cursor    :cursor-style box)
                    (insert       :background ,green     :cursor-style bar)
                    (emacs        :background ,blue      :cursor-style box)
                    (hybrid       :background ,blue      :cursor-style bar)
                    (evilified    :background ,red       :cursor-style box)
                    (visual       :background ,visual-bg :cursor-style hbar)
                    (motion       :background ,accent    :cursor-style box)
                    (replace      :background ,replace-bg :cursor-style hbar)
                    (lisp         :background ,lisp-bg   :cursor-style box)
                    (iedit        :background ,lisp-bg   :cursor-style box)
                    (iedit-insert :background ,lisp-bg   :cursor-style bar))))
      (ewal-evil-cursors--normalize-style-backgrounds styles))))

(defun ewal-evil-cursors--apply-modeline-faces (styles)
  "Apply per-state modeline faces based on STYLES.

STYLES is the alist returned by `ewal-evil-cursors--generate-styles'.

For each entry:
  - find the corresponding face in `ewal-evil-cursors-evil-state-faces'
  - set its :background to the style's :background
  - keep the modeline's default foreground color
  - make it bold for visibility

This is gated by `ewal-evil-cursors-modeline-per-state'."
  (when ewal-evil-cursors-modeline-per-state
    (let ((default-fg (face-attribute 'mode-line :foreground nil 'default)))
      (dolist (entry styles)
        (let* ((state (car entry))
                (attrs (cdr entry))
                (bg    (plist-get attrs :background))
                (colors (ewal-evil-cursors--mode-line-colors bg))
                (face  (cdr (assq state ewal-evil-cursors-evil-state-faces))))
          (when (and face (facep face) (stringp bg))
            (set-face-attribute face nil
              :background (plist-get colors :background)
              :foreground (or (plist-get colors :foreground) default-fg)
              :weight 'bold)))))))

(defun ewal-evil-cursors--effective-state ()
  "Return effective Evil state for cursor/modeline highlighting."
  (let ((state (and (boundp 'evil-state) evil-state))
        (previous-state (and (boundp 'evil-previous-state) evil-previous-state)))
    (if (and ewal-evil-cursors-obey-evil-p
             (eq 'operator state))
        previous-state
      state)))

(defun ewal-evil-cursors--face-background (face)
  "Return FACE background or nil when unavailable."
  (when (facep face)
    (face-attribute face :background nil t)))

(defun ewal-evil-cursors--face-foreground (face)
  "Return FACE foreground or nil when unavailable."
  (when (facep face)
    (face-attribute face :foreground nil t)))

(defun ewal-evil-cursors--save-mode-line-backgrounds ()
  "Store original backgrounds for faces in `ewal-evil-cursors-mode-line-faces`."
  (setq ewal-evil-cursors--saved-mode-line-face-attrs
        (cl-loop for face in ewal-evil-cursors-mode-line-faces
                 when (facep face)
                 collect (list face
                               :background (ewal-evil-cursors--face-background face)
                               :foreground (ewal-evil-cursors--face-foreground face)))))

(defun ewal-evil-cursors--restore-mode-line-backgrounds ()
  "Restore mode-line colors saved by the Ewal cursor integration."
  (dolist (entry ewal-evil-cursors--saved-mode-line-face-attrs)
    (let ((face (nth 0 entry)))
      (when (facep face)
        (set-face-attribute face nil
                            :background (plist-get (cdr entry) :background)
                            :foreground (plist-get (cdr entry) :foreground)))))
  (setq ewal-evil-cursors--saved-mode-line-face-attrs nil))

(defun ewal-evil-cursors--evil-state-hooks ()
  "Return Evil state entry hook symbols."
  '(evil-normal-state-entry-hook
     evil-insert-state-entry-hook
     evil-visual-state-entry-hook
     evil-emacs-state-entry-hook))

(defun ewal-evil-cursors--set-mode-line-bg (background)
  "Set mode-line background to BACKGROUND for configured faces.

The background is normalized toward darker values for readability and
foreground is chosen for contrast on text-carrying mode-line faces."
  (let* ((colors (ewal-evil-cursors--mode-line-colors background))
         (bg (plist-get colors :background))
         (fg (plist-get colors :foreground)))
    (dolist (face ewal-evil-cursors-mode-line-faces)
      (when (facep face)
        (if (memq face ewal-evil-cursors-mode-line-text-faces)
            (set-face-attribute face nil :background bg :foreground fg)
          (set-face-attribute face nil :background bg))))))

;;;###autoload
(defun ewal-evil-cursors-apply-current-state-modeline-bg ()
  "Apply current Evil state color to mode-line backgrounds."
  (when ewal-evil-cursors-track-evil-mode-line
    (let* ((state (ewal-evil-cursors--effective-state))
           (attrs (cdr (assq state ewal-evil-cursors-emacs-colors)))
           (background (plist-get attrs :background)))
      (when (and state (stringp background))
        (ewal-evil-cursors--set-mode-line-bg background)))))

(defun ewal-evil-cursors--enable-state-hooks ()
  "Register Evil state hooks to update live mode-line backgrounds."
  (dolist (hook (ewal-evil-cursors--evil-state-hooks))
    (when (boundp hook)
      (add-hook hook #'ewal-evil-cursors-apply-current-state-modeline-bg))))

(defun ewal-evil-cursors--disable-state-hooks ()
  "Unregister Evil state hooks that update live mode-line backgrounds."
  (dolist (hook (ewal-evil-cursors--evil-state-hooks))
    (when (boundp hook)
      (remove-hook hook #'ewal-evil-cursors-apply-current-state-modeline-bg))))


;;; Public API

(defun ewal-evil-cursors-apply-colors (&optional spacemacs)
  "Apply `ewal-evil-cursors' colors to Emacs or Spacemacs.

When SPACEMACS is non-nil, also configure Spacemacs-specific
cursor tables and spaceline faces.

Return the styles alist used."
  (ewal-load-colors)
  (let ((styles (ewal-evil-cursors--generate-styles)))
    ;; Always keep a copy
    (setq ewal-evil-cursors-emacs-colors styles)
    ;; Modeline faces (ours, not evil's built-in ones)
    (ewal-evil-cursors--apply-modeline-faces styles)
    ;; Active mode-line background tracks the current evil state
    (ewal-evil-cursors-apply-current-state-modeline-bg)
    ;; Wire cursors
    (if spacemacs
      (progn
        (setq ewal-evil-cursors-spacemacs-colors styles)
        (if (boundp 'spacemacs/add-evil-cursor)
          (when (functionp 'spacemacs/add-evil-cursor)
            (cl-loop for (state . attrs) in styles
              do (apply #'spacemacs/add-evil-cursor
                   (list (symbol-name state)
                     (plist-get attrs :background)
                     (plist-get attrs :cursor-style)))))
          (setq spacemacs-evil-cursors ewal-evil-cursors-spacemacs-colors)))
      ;; Vanilla evil cursor variables
      (cl-loop for (state . attrs) in styles
        do (set (intern (format "evil-%s-state-cursor" (symbol-name state)))
             (list (plist-get attrs :background)
               (plist-get attrs :cursor-style)))))
    styles))

(defun ewal-evil-cursors-highlight-face ()
  "Return the highlight face for the current evil state.

This is intended to be plugged into `spaceline-highlight-face-func'
or a similar integration.  It uses `ewal-evil-cursors-evil-state-faces' as
the mapping and falls back to `spaceline-highlight-face-default'."
  (ewal-load-colors)
  ;; Ensure styles & faces are in sync at least once
  (setq ewal-evil-cursors-emacs-colors (ewal-evil-cursors--generate-styles))
  (if (bound-and-true-p evil-local-mode)
    (let* ((state (ewal-evil-cursors--effective-state))
            (face (cdr (assq state ewal-evil-cursors-evil-state-faces))))
      (if (and face (facep face))
        face
        (spaceline-highlight-face-default)))
    (spaceline-highlight-face-default)))

;;;###autoload
(defun ewal-evil-cursors-get-colors (&rest args)
  "Get and optionally apply `ewal-evil-cursors' colors.

ARGS accepts either the legacy positional form or keyword arguments.

This function is *backwards compatible* with the original
positional API and also supports keyword arguments.

Positional forms (legacy):

  (ewal-evil-cursors-get-colors)
    ;; → return styles only

  (ewal-evil-cursors-get-colors t)
    ;; → apply styles globally (Evil cursors)

  (ewal-evil-cursors-get-colors t t)
    ;; → apply styles globally AND configure Spacemacs integration

Keyword forms (preferred):

  (ewal-evil-cursors-get-colors :apply t)
  (ewal-evil-cursors-get-colors :apply t :spacemacs t)

Return value:

  The styles alist produced by
  `ewal-evil-cursors--generate-styles'."
  ;; First parse keyword-style args
  (let* ((apply     (plist-get args :apply))
          (spacemacs (plist-get args :spacemacs)))
    ;; Support positional legacy calls:
    ;; (ewal-evil-cursors-get-colors t)
    ;; (ewal-evil-cursors-get-colors t t)
    (when (and args (not (keywordp (car args))))
      (setq apply     (or apply (nth 0 args))
        spacemacs (or spacemacs (nth 1 args))))
    (let ((styles (ewal-evil-cursors--generate-styles)))
      (when apply
        (ewal-evil-cursors-apply-colors spacemacs))
      styles)))


;;; Minor mode

;;;###autoload
(define-minor-mode ewal-evil-cursors-mode
  "Global mode applying `ewal' palette to Evil cursors and modeline.

When enabled, cursor colors and shapes are driven by the current
`ewal' palette, and (optionally) per-state modeline faces are
tinted using `ewal-evil-cursors-evil-state-faces'."
  :global t
  :group 'ewal-evil-cursors
  (if ewal-evil-cursors-mode
    (progn
      (ewal-evil-cursors--save-mode-line-backgrounds)
      (ewal-evil-cursors-apply-colors)
      (ewal-evil-cursors--enable-state-hooks)
      ;; If spaceline is active and user wants it, wire highlight func
      (when (boundp 'spaceline-highlight-face-func)
        (setq spaceline-highlight-face-func #'ewal-evil-cursors-highlight-face)))
    ;; disabling mode: we don't forcibly reset user faces;
    ;; caller can reload theme/modeline if desired.
    (ewal-evil-cursors--disable-state-hooks)
    (ewal-evil-cursors--restore-mode-line-backgrounds)))

(provide 'ewal-evil-cursors)

;;; ewal-evil-cursors.el ends here
;; == end/ewal-evil-cursors.el ==
