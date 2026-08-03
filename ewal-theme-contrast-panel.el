;;; ewal-theme-contrast-panel.el --- Transient contrast UI for Ewal -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Optional Transient front end for `ewal-theme-contrast-check'.

;;; Code:

(require 'ewal-theme-contrast-check)
(require 'transient)

(transient-define-prefix ewal-theme-contrast-panel ()
  "Inspect and repair theme contrast."
  [["Context"
    ("i" "Show current state" ewal-contrast-show-status :transient t)
    ("T" ewal-contrast-set-theme
     :description ewal-contrast--theme-description :transient t)
    ("m" "Set minimum contrast" ewal-contrast-set-min-contrast :transient t)]
   ["Strategy"
    ("1" ewal-contrast-set-strategy-default
     :description ewal-contrast--strategy-default-description :transient t)
    ("2" ewal-contrast-set-strategy-palette
     :description ewal-contrast--strategy-palette-description :transient t)
    ("3" ewal-contrast-set-strategy-black-white
     :description ewal-contrast--strategy-black-white-description :transient t)
    ("s" "Cycle strategy" ewal-contrast-cycle-strategy :transient t)]
   ["Actions"
    ("c" ewal-contrast-check-refresh
     :description ewal-contrast--refresh-description :transient t)
    ("v" ewal-contrast-preview-suggestions
     :description ewal-contrast--preview-description :transient t)
    ("a" ewal-contrast-apply-suggestions
     :description ewal-contrast--apply-description :transient t)]
   ["Persist"
    ("o" "Apply saved overrides" ewal-apply-theme-face-overrides :transient t)
    ("y" "Copy use-package snippet" ewal-contrast-copy-use-package-snippet)]])

(provide 'ewal-theme-contrast-panel)
;;; ewal-theme-contrast-panel.el ends here
