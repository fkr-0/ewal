;;; ewal-adaptor-contrast-test.el --- Contrast tests for Ewal adaptors -*- lexical-binding: t; -*-

(require 'ert)
(require 'ewal)
(require 'ewal-color-utils)

(add-to-list 'load-path
             (expand-file-name "doom-themes"
                               (file-name-directory
                                (directory-file-name default-directory))))
(add-to-list 'load-path
             (expand-file-name "spacemacs-themes"
                               (file-name-directory
                                (directory-file-name default-directory))))

;; Helper modules do not use Doom's theme macros themselves, so a feature stub
;; keeps this test runnable under plain `emacs -Q' as well as Eldev.
(unless (require 'doom-themes nil t)
  (provide 'doom-themes))

(require 'ewal-doom-themes)
(require 'ewal-spacemacs-themes)
(require 'ewal-generate-doom-theme)

(defun ewal-test--load-built-in-palette ()
  "Load a stable bundled palette for adaptor tests."
  (setq ewal-use-built-in-always t
        ewal-built-in-palette "sexy-material"
        ewal-dark-palette-p t
        ewal-base-palette nil
        ewal--loaded-source nil)
  (ewal-load-colors nil t))

(ert-deftest ewal-doom-adaptor-colors-contrast-with-background ()
  "Doom semantic colors must never equal the base background."
  (let ((ewal-doom-themes-min-contrast 4.5)
        (ewal-doom-themes-min-ui-contrast 3.0))
    (ewal-test--load-built-in-palette)
    (let ((background (car (ewal-doom-themes-get-color 'background))))
      (dolist (role '(foreground red green yellow blue magenta cyan
                      comment cursor highlight))
        (let* ((color (car (ewal-doom-themes-get-color role)))
               (minimum (if (memq role '(cursor highlight)) 3.0 4.5)))
          (should (ewal-color-valid-p color))
          (should-not (ewal-color-equal-p color background))
          (should (>= (ewal-color-contrast-ratio color background)
                      minimum)))))))

(ert-deftest ewal-spacemacs-adaptor-enforces-role-thresholds ()
  "Spacemacs text and UI roles should meet their configured thresholds."
  (let ((ewal-spacemacs-themes-min-contrast 4.5)
        (ewal-spacemacs-themes-min-ui-contrast 3.0))
    (ewal-test--load-built-in-palette)
    (let* ((colors (ewal-spacemacs-themes--generate-colors))
           (background (alist-get 'bg1 colors)))
      (dolist (role ewal-spacemacs-themes--text-roles)
        (let ((color (alist-get role colors)))
          (should-not (ewal-color-equal-p color background))
          (should (>= (ewal-color-contrast-ratio color background) 4.5))))
      (dolist (role ewal-spacemacs-themes--ui-roles)
        (let ((color (alist-get role colors)))
          (should-not (ewal-color-equal-p color background))
          (should (>= (ewal-color-contrast-ratio color background) 3.0)))))))

(ert-deftest ewal-generated-doom-palette-repairs-duplicate-colors ()
  "A generator input with duplicate roles should be normalized before use."
  (let* ((duplicate "#222222")
         (palette (mapcar (lambda (role) (cons role duplicate))
                          ewal-doom-theme-required-palette-keys))
         (normalized (ewal-normalize-doom-theme-palette palette))
         (background (alist-get 'background normalized)))
    (dolist (role '(foreground red green yellow blue magenta cyan))
      (let ((color (alist-get role normalized)))
        (should-not (ewal-color-equal-p color background))
        (should (>= (ewal-color-contrast-ratio color background) 4.5))))
    (let ((highlight (alist-get 'highlight normalized)))
      (should-not (ewal-color-equal-p highlight background))
      (should (>= (ewal-color-contrast-ratio highlight background) 3.0)))))

;;; ewal-adaptor-contrast-test.el ends here
