;;; ewal-spacemacs-modern-theme.el --- Modern Ewal Spacemacs theme -*- lexical-binding: t; no-byte-compile: t; -*-

;;; Commentary:
;;
;; Modern Spacemacs theme entrypoint backed by the current Ewal palette.

;;; Code:

(require 'ewal-spacemacs-themes)
(require 'spacemacs-common)

;; Bind the declared Spacemacs customizations while constructing this theme,
;; without mutating the package's global configuration permanently.
(let ((spacemacs-theme-org-highlight t)
      (spacemacs-theme-custom-colors
       (ewal-spacemacs-themes-get-colors)))
  (deftheme ewal-spacemacs-modern)
  ;; must be run before `create-spacemacs-theme'
  (ewal-spacemacs-themes-modernize-theme 'ewal-spacemacs-modern)
  (create-spacemacs-theme 'dark 'ewal-spacemacs-modern))

(provide-theme 'ewal-spacemacs-modern)
(provide 'ewal-spacemacs-modern-theme)
;;; ewal-spacemacs-modern-theme.el ends here
