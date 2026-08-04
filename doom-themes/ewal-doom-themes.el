;;; ewal-doom-themes.el --- Doom theme helpers for ewal -*- lexical-binding: t; -*-

;; Version: 0.3.3
;; Package-Requires: ((emacs "25") (ewal "0.3.0") (doom-themes "2.3.0"))
;; URL: https://github.com/fkr-0/ewal

;;; Commentary:
;;
;; Shared palette conversion, contrast enforcement, and audit commands for the
;; Ewal Doom theme entrypoints.

;;; Code:

(require 'ewal)
(require 'cl-lib)
(require 'doom-themes)
(require 'ewal-color-utils)
(require 'ewal-theme-contrast-check)

(defgroup ewal-doom-themes nil
  "Doom theme helpers for `ewal`."
  :group 'doom-themes)

(defcustom ewal-doom-themes-min-contrast 4.5
  "Minimum acceptable contrast ratio for generated text colors and audits."
  :type 'number
  :group 'ewal-doom-themes)

(defcustom ewal-doom-themes-preview-limit 8
  "How many low-contrast entries to show in preview messages."
  :type 'integer
  :group 'ewal-doom-themes)

(defcustom ewal-doom-themes-min-ui-contrast 3.0
  "Minimum contrast for cursors, comments, and non-text UI accents."
  :type 'number
  :group 'ewal-doom-themes)

(defun ewal-doom-themes--palette-candidates ()
  "Return concrete colors from the currently loaded Ewal palette."
  (ewal-load-colors)
  (ewal-palette-color-values ewal-base-palette))

(defun ewal-doom-themes--minimum-for-role (role)
  "Return the contrast threshold appropriate for semantic color ROLE."
  (if (memq role '(cursor highlight bright-black color8))
      ewal-doom-themes-min-ui-contrast
    ewal-doom-themes-min-contrast))

(defun ewal-doom-themes-safe-color (foreground background &optional minimum)
  "Return a contrast-safe FOREGROUND for BACKGROUND.

FOREGROUND and BACKGROUND may be color strings or Doom color triples.
MINIMUM defaults to `ewal-doom-themes-min-contrast'."
  (ewal-color-ensure-contrast
   foreground background
   (or minimum ewal-doom-themes-min-contrast)
   (ewal-doom-themes--palette-candidates)))

(defun ewal-doom-themes-safe-triple (foreground background &optional minimum)
  "Return a Doom color triple safe for FOREGROUND on BACKGROUND.

Use MINIMUM as the contrast threshold when non-nil."
  (let ((color (ewal-doom-themes-safe-color foreground background minimum)))
    (list color color color)))

(defun ewal-doom-themes-get-color (color &optional shade shade-percent-difference)
  "Return COLOR as a Doom-compatible triple.

Internally use `ewal-get-color' for COLOR and SHADE.  Override the global
per-step shade percentage with SHADE-PERCENT-DIFFERENCE when non-nil.  Return
a list of three entries:

  (GUI-COLOR TTY-COLOR TTY-COLOR)

The two TTY entries are identical and allow Doom to approximate
colors on 256 / 16 color terminals."
  (let* ((hex-color (ewal-get-color color shade shade-percent-difference))
         (background (ewal-get-color 'background))
         (hex-color
          (if (or (eq color 'background) (null hex-color) (null background))
              hex-color
            (ewal-doom-themes-safe-color
             hex-color background (ewal-doom-themes--minimum-for-role color))))
         (tty-color hex-color))
    `(,hex-color ,tty-color ,tty-color)))

;;;###autoload
(when (and (boundp 'custom-theme-load-path)
        load-file-name)
  (add-to-list 'custom-theme-load-path
    (file-name-as-directory
      (file-name-directory load-file-name))))

;;;###autoload
(defun ewal-doom-themes-check-contrast (&optional min-contrast)
  "Check contrast for the current Doom theme built from `ewal`.

MIN-CONTRAST defaults to 4.5."
  (interactive "P")
  (ewal-check-current-theme-contrast
    (or min-contrast ewal-doom-themes-min-contrast)
    ewal-doom-themes-preview-limit))

(provide 'ewal-doom-themes)
;;; ewal-doom-themes.el ends here
