;;; ewal-spacemacs-classic-theme.el --- Classic Ewal Spacemacs theme -*- lexical-binding: t; no-byte-compile: t; -*-

;;; Commentary:
;;
;; Classic Spacemacs theme entrypoint backed by the current Ewal palette.

;;; Code:

(require 'ewal-spacemacs-themes)
(require 'spacemacs-common)

;; Bind the declared Spacemacs customization dynamically while constructing
;; this theme; do not mutate the package's global customization permanently.
(let ((spacemacs-theme-custom-colors
        (ewal-spacemacs-themes-get-colors t)))
  (deftheme ewal-spacemacs-classic)
  (create-spacemacs-theme 'dark 'ewal-spacemacs-classic))

(provide-theme 'ewal-spacemacs-classic)
(provide 'ewal-spacemacs-classic-theme)
;;; ewal-spacemacs-classic-theme.el ends here
