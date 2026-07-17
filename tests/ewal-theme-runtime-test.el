;;; ewal-theme-runtime-test.el --- Runtime tests for Ewal themes -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'ert)
(require 'ewal)
(require 'ewal-color-utils)

(add-to-list 'custom-theme-load-path
             (expand-file-name "doom-themes" default-directory))
(add-to-list 'custom-theme-load-path
             (expand-file-name "spacemacs-themes" default-directory))

(defconst ewal-theme-runtime-test-themes
  '(ewal-doom-one
    ewal-doom-outrun-electric
    ewal-doom-tokyo-night
    ewal-doom-vibrant
    ewal-spacemacs-classic
    ewal-spacemacs-modern)
  "Theme entrypoints that must load in an isolated package environment.")

(defun ewal-theme-runtime-test--prepare-palette ()
  "Configure a stable bundled palette for runtime theme tests."
  (setq ewal-use-built-in-always t
        ewal-built-in-palette "sexy-material"
        ewal-dark-palette-p t
        ewal-base-palette nil
        ewal--loaded-source nil)
  (ewal-load-colors nil t))

(defun ewal-theme-runtime-test--face-colors (theme face)
  "Return explicit graphical foreground/background colors for FACE in THEME."
  (let* ((setting
          (cl-find-if
           (lambda (entry)
             (and (eq (car-safe entry) 'theme-face)
                  (eq (nth 1 entry) face)))
           (get theme 'theme-settings)))
         (first-clause (and setting (car (nth 3 setting))))
         (attributes (and first-clause (cadr first-clause))))
    (list (plist-get attributes :foreground)
          (plist-get attributes :background))))

(ert-deftest ewal-theme-entrypoints-load-and-register ()
  "Every shipped Doom and Spacemacs theme should load and register."
  (ewal-theme-runtime-test--prepare-palette)
  (dolist (theme ewal-theme-runtime-test-themes)
    (ert-info ((format "Theme: %S" theme))
      (load-theme theme t t)
      (should (custom-theme-p theme)))))

(ert-deftest ewal-theme-text-pairs-meet-runtime-contrast-thresholds ()
  "Explicit text-bearing face pairs should remain distinct and readable."
  (ewal-theme-runtime-test--prepare-palette)
  (dolist (theme ewal-theme-runtime-test-themes)
    (load-theme theme t t)
    (dolist (face '(default
                    font-lock-comment-face
                    font-lock-doc-face
                    mode-line
                    mode-line-inactive
                    diff-added
                    diff-removed
                    diff-changed))
      (pcase-let ((`(,foreground ,background)
                   (ewal-theme-runtime-test--face-colors theme face)))
        (when (and (stringp foreground)
                   (stringp background)
                   (ewal-color-valid-p foreground)
                   (ewal-color-valid-p background))
          (ert-info ((format "Theme/face: %S/%S (%s on %s)"
                             theme face foreground background))
            (should-not (ewal-color-equal-p foreground background))
            (should (>= (ewal-color-contrast-ratio foreground background)
                        4.5))))))))

(provide 'ewal-theme-runtime-test)
;;; ewal-theme-runtime-test.el ends here
