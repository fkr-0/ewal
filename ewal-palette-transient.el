;;; ewal-palette-transient.el --- Transient palette browser for Ewal -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Optional Transient front end for `ewal-palette-utils'.

;;; Code:

(require 'ewal-palette-utils)
(require 'transient)

;;;###autoload
(transient-define-prefix ewal-palettes-menu ()
  "Browse and preview loaded Ewal palettes."
  ["Navigation"
   ("j" "Next palette" ewal-palette-next)
   ("k" "Previous palette" ewal-palette-previous)
   ("q" "Quit" ewal-palette-preview-quit)])

(provide 'ewal-palette-transient)
;;; ewal-palette-transient.el ends here
