;;; ewal-evil-cursors-test.el --- Tests for ewal evil cursor integration -*- lexical-binding: t; -*-

(require 'ert)
(require 'cl-lib)
(require 'ewal-evil-cursors)

(ert-deftest ewal-evil-cursors-apply-current-state-modeline-bg ()
  "Mode-line background should follow current Evil state color."
  (let ((orig-mode-line-bg (face-attribute 'mode-line :background nil t))
        (orig-active-bg (when (facep 'mode-line-active)
                          (face-attribute 'mode-line-active :background nil t)))
        (old-evil-state (and (boundp 'evil-state) evil-state)))
    (unwind-protect
        (let ((ewal-evil-cursors-track-evil-mode-line t)
              (ewal-evil-cursors-mode-line-faces '(mode-line))
              (ewal-evil-cursors-emacs-colors
                '((normal :background "#111111" :cursor-style box)
                   (insert :background "#22aa22" :cursor-style bar)
                   (visual :background "#4444cc" :cursor-style hbar)
                   (emacs :background "#aa7722" :cursor-style box))))
          (setq evil-state 'insert)
          (ewal-evil-cursors-apply-current-state-modeline-bg)
          (let* ((bg (face-background 'mode-line nil t))
                 (fg (or (face-foreground 'mode-line nil t) "#ffffff")))
            (should (stringp bg))
            (should (< (ewal-evil-cursors--relative-luminance bg)
                       (+ ewal-evil-cursors-mode-line-max-luminance 0.01)))
            (should (> (ewal-evil-cursors--contrast-ratio fg bg) 4.5))))
      (setq evil-state old-evil-state)
      (set-face-attribute 'mode-line nil :background orig-mode-line-bg)
      (when (and (facep 'mode-line-active) orig-active-bg)
        (set-face-attribute 'mode-line-active nil :background orig-active-bg)))))

(ert-deftest ewal-evil-cursors-modeline-colors-darken-bright-background ()
  "Mode-line color normalization should darken overly bright state colors."
  (let ((ewal-evil-cursors-mode-line-max-luminance 0.35)
        (ewal-evil-cursors-mode-line-darken-step 20))
    (let* ((colors (ewal-evil-cursors--mode-line-colors "#f8f8f8"))
           (bg (plist-get colors :background)))
      (should (stringp bg))
      (should (< (ewal-evil-cursors--relative-luminance bg) 0.36)))))

(ert-deftest ewal-evil-cursors-modeline-colors-pick-readable-foreground ()
  "Mode-line text foreground should contrast with adjusted background."
  (let* ((colors (ewal-evil-cursors--mode-line-colors "#f8f8f8"))
         (bg (plist-get colors :background))
         (fg (plist-get colors :foreground)))
    (should (stringp fg))
    (should (> (ewal-evil-cursors--contrast-ratio fg bg) 4.5))))

(ert-deftest ewal-evil-cursors-generate-styles-darken-bright-cursors ()
  "Cursor styles should be normalized away from overly bright backgrounds."
  (let ((ewal-evil-cursors-darken-cursor-backgrounds t)
        (ewal-evil-cursors-cursor-max-luminance 0.45))
    (cl-letf (((symbol-function 'ewal-load-colors) (lambda (&rest _) nil))
              ((symbol-function 'ewal-get-color)
               (lambda (_role &optional _shade _spd) "#f8f8f8")))
      (dolist (entry (ewal-evil-cursors--generate-styles))
        (let ((bg (plist-get (cdr entry) :background)))
          (should (stringp bg))
          (should (< (ewal-evil-cursors--relative-luminance bg) 0.46)))))))

;;; ewal-evil-cursors-test.el ends here
