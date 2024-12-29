;;; ewal-evil-cursors.el --- `ewal'-colored evil cursor for Emacs and Spacemacs -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Uros Perisic

;; Author: Uros Perisic
;; URL: https://gitlab.com/jjzmajic/ewal
;;
;; Version: 1.0
;; Keywords: faces
;; Package-Requires: ((emacs "25") (ewal "0.1"))

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

;;; Code:
(require 'ewal)

(defvar evil-state)
(defvar evil-previous-state)
(defvar spacemacs-evil-cursors)
(defvar spaceline-evil-state-faces)
(defvar spaceline-highlight-face-func)
(declare-function #'spaceline-highlight-face-default "ext:noop")

(defvar ewal-evil-cursors-spacemacs-colors nil
  "`spacemacs-evil-cursors' compatible colors.
Extracted from current `ewal' palette.")

(defvar ewal-evil-cursors-emacs-colors nil
  "Vanilla Emacs Evil compatible colors.
Extracted from current `ewal' palette, and stored in a plist for
easy application.")

(defvar ewal-evil-cursors-obey-evil-p t
  "Whether to respect evil settings.
I.e. call insert state hybrid state if insert bindings are
disabled.")

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
Used by `ewal-evil-cursors-highlight-face-evil-state'.")

(defun ewal-evil-cursors--generate-styles ()
  "Generate cursor styles dynamically based on `ewal` palette.
Returns:
  - (alist): Styles for all Evil states with `ewal` colors applied."
  (ewal-generate-element-styles
   '((normal :background cursor)
     (insert :background green :cursor-style bar)
     (emacs :background blue :cursor-style box)
     (hybrid :background blue :cursor-style bar)
     (evilified :background red :cursor-style box)
     (visual :background white :shade -4 :cursor-style hbar)
     (motion :background ewal-primary-accent-color :cursor-style box)
     (replace :background red :shade -4 :cursor-style hbar)
     (lisp :background magenta :shade 4 :cursor-style box)
     (iedit :background magenta :shade -4 :cursor-style box)
     (iedit-insert :background magenta :shade -4 :cursor-style bar))))

(defun ewal-evil-cursors-apply-colors (&optional spacemacs)
  "Apply `ewal-evil-cursors' colors to Emacs or Spacemacs.
Arguments:
  - spacemacs (boolean): If non-nil, apply styles to Spacemacs configuration.
Returns:
  - (alist): Applied styles for Emacs or Spacemacs."
  (ewal-load-colors)
  (let ((styles (ewal-evil-cursors--generate-styles)))
    (if spacemacs
        (progn
          (setq ewal-evil-cursors-spacemacs-colors styles)
          (if (boundp 'spacemacs/add-evil-cursor)
              (when (functionp 'spacemacs/add-evil-cursor)
                (cl-loop for (state . attrs) in styles
                         do (apply 'spacemacs/add-evil-cursor
                                   (list (symbol-name state)
                                         (alist-get :background attrs)
                                         (alist-get :cursor-style attrs)))))
            (setq spacemacs-evil-cursors ewal-evil-cursors-spacemacs-colors)))
      (progn
        (setq ewal-evil-cursors-emacs-colors styles)
        (cl-loop for (key . attrs) in styles
                 do (set (intern (format "evil-%s-state-cursor" (symbol-name key)))
                         (list (alist-get :background attrs)
                               (alist-get :cursor-style attrs))))))
    styles))

(defun ewal-evil-cursors-highlight-face ()
  "Set highlight face depending on the Evil state.
Integrates with Spacemacs and Emacs modes using `spaceline`."
  (ewal-load-colors)
  (setq ewal-evil-cursors-emacs-colors (ewal-evil-cursors--generate-styles))
  (if (bound-and-true-p evil-local-mode)
      (let* ((state (if (eq 'operator evil-state) evil-previous-state evil-state))
             (face (cdr (assq state ewal-evil-cursors-evil-state-faces))))
        (if face face (spaceline-highlight-face-default)))
    (spaceline-highlight-face-default)))

;;;###autoload
(defun ewal-evil-cursors-get-colors (&key apply spacemacs)
  "Get and optionally apply `ewal-evil-cursors' colors.
Arguments:
  - apply (boolean): Apply the generated colors.
  - spacemacs (boolean): If true, apply styles for Spacemacs.
Returns:
  - (alist): The generated or applied styles."
  (let ((colors (ewal-evil-cursors--generate-styles)))
    (when apply
      (ewal-evil-cursors-apply-colors spacemacs))
    colors))

(provide 'ewal-evil-cursors)

;;; ewal-evil-cursors.el ends here
