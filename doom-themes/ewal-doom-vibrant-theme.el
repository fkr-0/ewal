;;; ewal-doom-vibrant-theme.el --- Dread the vibrancy of darkness -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2020 Uros Perisic

;; Author: Uros Perisic
;; URL: https://gitlab.com/jjzmajic/ewal
;;
;; Version: 0.1
;; Keywords: faces
;; Package-Requires: ((emacs "25") (ewal "0.1") (doom-themes "0.1"))

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

;; An `ewal'-based theme, created using `doom-vibrant' as its base.

;;; Code:
(require 'ewal-doom-themes)
;; === Custom Group Definitions ===============================================
(defgroup ewal-doom-vibrant-theme nil
  "Options for doom-themes."
  :group 'doom-themes)

;; === Custom Variables =======================================================
(defcustom ewal-doom-vibrant-brighter-modeline 't
  "If non-nil, more vivid colors will be used to style the mode-line."
  :group 'ewal-doom-vibrant-theme
  :type 'boolean)

;; ... (Other custom variables)

;; === Load Colors and Workarounds ============================================
(ewal-load-colors)
;; HACK: fixes bytecode overflow
(defvar ewal-doom-one-hack
  (ewal-doom-themes-get-color 'background 0))


;; === Custom Variables =======================================================
(defcustom ewal-doom-vibrant-brighter-modeline 't
  "If non-nil, more vivid colors will be used to style the mode-line."
  :group 'ewal-doom-vibrant-theme
  :type 'boolean)

(defcustom ewal-doom-vibrant-brighter-comments 't
  "If non-nil, comments will be highlighted in more vivid colors."
  :group 'ewal-doom-vibrant-theme
  :type 'boolean)

(defcustom ewal-doom-vibrant-comment-bg ewal-doom-vibrant-brighter-comments
  "If non-nil, comments will have a subtle, darker background."
  :group 'ewal-doom-vibrant-theme
  :type 'boolean)

(defcustom ewal-doom-vibrant-padded-modeline doom-themes-padded-modeline
  "If non-nil, adds a 4px padding to the mode-line. Can be an integer."
  :group 'ewal-doom-vibrant-theme
  :type '(choice integer boolean))

;; === Load Colors and Workarounds ============================================
(ewal-load-colors)

;; HACK: fixes bytecode overflow
(defvar ewal-doom-one-hack
  (ewal-doom-themes-get-color 'background 0))

;; === Theme Definition =======================================================
;; (def-doom-theme ewal-doom-vibrant
;;   "A dark theme based off of doom-one with more vibrant `ewal' colors."
;;   ;; Color Definitions
;;   ((bg  (ewal-doom-themes-get-color 'background  0))
;;    ;; ... (other color definitions)
;;    (vc-deleted     red)
;;    ;; ... (custom categories)
;;   )
;;   ;; --- extra faces ------------------------
;;   ((elscreen-tab-other-screen-face :background base8 :foreground base0)
;;    ;; ... (other face definitions)
;;   )
;;   ;; --- extra variables --------------------
;;   ;; ()
;;   )

;; (defgroup ewal-doom-vibrant-theme nil
;;   "Options for doom-themes"
;;   :group 'doom-themes)

;; (defcustom ewal-doom-vibrant-brighter-modeline nil
;;   "If non-nil, more vivid colors will be used to style the mode-line."
;;   :group 'ewal-doom-vibrant-theme
;;   :type 'boolean)

;; (defcustom ewal-doom-vibrant-brighter-comments nil
;;   "If non-nil, comments will be highlighted in more vivid colors."
;;   :group 'ewal-doom-vibrant-theme
;;   :type 'boolean)

;; (defcustom ewal-doom-vibrant-comment-bg ewal-doom-vibrant-brighter-comments
;;   "If non-nil, comments will have a subtle, darker background."
;;   :group 'ewal-doom-vibrant-theme
;;   :type 'boolean)

;; (defcustom ewal-doom-vibrant-padded-modeline doom-themes-padded-modeline
;;   "If non-nil, adds a 4px padding to the mode-line.
;; Can be an integer to determine the exact padding."
;;   :group 'ewal-doom-vibrant-theme
;;   :type '(choice integer boolean))

;; (ewal-load-colors)

;; ;; HACK: fixes bytecode overflow
;; (defvar ewal-doom-one-hack
;;   (ewal-doom-themes-get-color 'background 0))

;; === Theme Definition =======================================================
(def-doom-theme ewal-doom-vibrant-x
  "A dark theme based off of doom-one with more vibrant `ewal' colors."

  ;; Color Definitions
  ((bg         (ewal-doom-themes-get-color 'background  +0))
    ;; (bg-alt     (ewal-doom-themes-get-color 'background -1))
    (bg-alt     (ewal-doom-themes-get-color 'background -3))
    (base0      (ewal-doom-themes-get-color 'background -5))
    (base1      (ewal-doom-themes-get-color 'background -4))
    (base2      (ewal-doom-themes-get-color 'background -2))
    (base3      (ewal-doom-themes-get-color 'background -1))
    (base4      (ewal-doom-themes-get-color 'background +1))
    (base5      (ewal-doom-themes-get-color 'comment     0))
    (base6      (ewal-doom-themes-get-color 'background +4))
    (base7      (ewal-doom-themes-get-color 'background +5))
    (base8      (ewal-doom-themes-get-color 'foreground +1))
    (fg         (ewal-doom-themes-get-color 'foreground  0))
    (fg-alt     (ewal-doom-themes-get-color 'foreground -1))

    (grey       base4)
    (red        (ewal-doom-themes-get-color 'red      -2))
    (orange     (ewal-doom-themes-get-color 'red       0))
    (green      (ewal-doom-themes-get-color 'green    -2))
    (teal       (ewal-doom-themes-get-color 'green     0))
    (yellow     (ewal-doom-themes-get-color 'yellow   -2))
    (blue       (ewal-doom-themes-get-color 'blue      0))
    (dark-blue  (ewal-doom-themes-get-color 'blue     -2))
    (magenta    (ewal-doom-themes-get-color 'magenta   0))
    (violet     (ewal-doom-themes-get-color 'magenta  -2))
    (cyan       (ewal-doom-themes-get-color 'cyan      0))
    (dark-cyan  (ewal-doom-themes-get-color 'cyan     -2))

    ;; --- Basic Face Definitions -----------------------------------------------
    ;; face categories
    (highlight      blue)
    (vertical-bar   base0)
    (selection      dark-blue)
    (builtin        magenta)
    (comments       (if ewal-doom-vibrant-brighter-comments dark-cyan (doom-lighten base5 0.6)))
    (doc-comments   (if ewal-doom-vibrant-brighter-comments (doom-lighten cyan 0.15) (doom-lighten base4 0.6)))
    (constants      violet)
    (functions      cyan)
    (keywords       blue)
    (methods        violet)
    (operators      magenta)
    (type           yellow)
    (strings        green)
    (variables      (doom-lighten magenta 0.3))
    (numbers        orange)
    (region         "#3d4451")
    (error          red)
    (warning        yellow)
    (success        green)

    (vc-modified    yellow)
    (vc-added       green)
    (vc-deleted     red)

    ;; custom categories
    (hidden     `(,(car bg) "black" "black"))
    (hidden-alt `(,(car bg-alt) "black" "black"))
    ;; --- Modeline & Headerline -----------------------------------------------
    (-modeline-pad
      (when ewal-doom-vibrant-padded-modeline
        (if (integerp ewal-doom-vibrant-padded-modeline) ewal-doom-vibrant-padded-modeline 4)))

    (modeline-fg     (ewal-get-color 'foreground 0))
    (modeline-fg-alt (doom-blend blue grey (if ewal-doom-vibrant-brighter-modeline 0.4 0.08)))

    (modeline-bg
      (if ewal-doom-vibrant-brighter-modeline
        `(,(car bg-alt) ,@(cdr base1))
        `(,(car bg-alt) ,@(cdr base0))))
    (modeline-bg-l
      (if ewal-doom-vibrant-brighter-modeline
        modeline-bg
        `(,(doom-darken (car bg) 0.15) ,@(cdr base1))))
    (modeline-bg-inactive   (doom-darken bg 0.25))
    (modeline-bg-inactive-l `(,(doom-darken (car bg-alt) 0.2) ,@(cdr base0))))


  ;; --- extra faces ------------------------
  ((elscreen-tab-other-screen-face :background base8 :foreground base0)

    ((line-number &override) :foreground base4)
    ((line-number-current-line &override) :foreground blue :bold bold)

    (doom-modeline-bar :background (if ewal-doom-vibrant-brighter-modeline modeline-bg highlight))
    (doom-modeline-buffer-path :foreground (if ewal-doom-vibrant-brighter-modeline base8 blue) :bold bold)

    (mode-line
      :background modeline-bg :foreground modeline-fg
      :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg)))
    (mode-line-inactive
      :background modeline-bg-inactive :foreground modeline-fg-alt
      :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive)))
    (mode-line-emphasis
      :foreground (if ewal-doom-vibrant-brighter-modeline base8 highlight))

    (solaire-mode-line-face
      :inherit 'mode-line
      :background modeline-bg-l
      :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-l)))
    (solaire-mode-line-inactive-face
      :inherit 'mode-line-inactive
      :background modeline-bg-inactive-l
      :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive-l)))
    ;; Basic Text Formatting Faces
    (default :background bg :foreground fg)
    (cursor :background fg :foreground bg)
    (bold :weight 'bold)
    (italic :slant 'italic)
    (underline :underline t)
    ;; --- Syntax Highlighting --------------------------------------------------
    ;; General Syntax Highlighting Faces
    (font-lock-builtin-face :foreground builtin)
    (font-lock-comment-face
      :foreground (doom-lighten comments 0.15)
      :background (if ewal-doom-vibrant-comment-bg (doom-darken bg-alt 0.095) (doom-lighten hidden-alt 0.44)))
    (font-lock-doc-face
      :inherit 'font-lock-comment-face
      :foreground doc-comments)

    (whitespace-empty :background base2)

    ;; --- major-mode faces -------------------
    ;; css-mode / scss-mode
    (css-proprietary-property :foreground orange)
    (css-property             :foreground green)
    (css-selector             :foreground blue)

    ;; markdown-mode
    (markdown-header-face :inherit 'bold :foreground red)
    (markdown-header-face-1 :foreground magenta :weight 'bold :height 1.5)
    (markdown-header-face-2 :foreground violet :weight 'bold :height 1.4)

    ;; --- Org Mode Faces -------------------------------------------------------
    ;; Basic org-mode faces for headers, lists, and more.
    (org-hide :foreground hidden)
    (solaire-org-hide-face :foreground hidden-alt)
    (org-document-title :foreground blue :weight 'bold :height 1.5)
    (org-level-1 :foreground orange :weight 'bold :height 1.3)
    (org-level-2 :foreground magenta :weight 'bold :height 1.2)
    (org-checkbox :foreground green :weight 'bold)
    (org-todo :foreground red :weight 'bold)
    (org-done :foreground green :weight 'bold)
    ;; ... (Other org-mode faces)

    ;; --- Dired Mode -----------------------------------------------------------
    ;; Faces specific to the Dired file manager.
    (dired-directory :foreground blue :weight 'bold)
    (dired-flagged :foreground red)
    ;; ... (Other dired faces)

    ;; --- Magit Mode -----------------------------------------------------------
    ;; Faces for the Magit Git client.
    (magit-section-title :foreground yellow :weight 'bold)
    (magit-branch :foreground orange :weight 'bold)
    ;; ... (Other magit faces)

    ;; --- Company Mode ---------------------------------------------------------
    ;; Faces for the Company autocompletion popup.
    ;; (company-tooltip :foreground black :background yellow)
    ;; (company-tooltip-selection :foreground black :background orange)
    ;; ... (Other company-mode faces)

    ;; --- Helm Faces -----------------------------------------------------------
    ;; Customize Helm faces
    (helm-header :foreground base4 :background base1 :underline nil :box nil)
    (helm-source-header :foreground base1 :background base4 :weight 'bold :height 1.3)
    (helm-selection :foreground base8 :background base2 :underline nil)
    ;; ... (Other helm faces)

    ;; --- Treemacs Faces -------------------------------------------------------
    ;; Customize Treemacs faces
    (treemacs-root-face :foreground blue :weight 'bold :height 1.2)
    (treemacs-git-modified-face :foreground yellow)
    (treemacs-git-added-face :foreground green)
    (treemacs-git-untracked-face :foreground red)
    ;; ... (Other treemacs faces)

    ;; --- Which-Key Faces ------------------------------------------------------
    ;; Customize which-key faces
    (which-key-key-face :foreground green)
    (which-key-group-description-face :foreground blue)
    (which-key-command-description-face :foreground magenta)
    ;; ... (Other which-key faces)

    ;; --- LSP Mode Faces ------------------------------------------------------
    ;; Customize faces for LSP (Language Server Protocol)
    (lsp-face-highlight-read :background base2)
    (lsp-face-highlight-write :background base3)
    (lsp-ui-peek-highlight :foreground yellow :weight 'bold)
    (lsp-ui-sideline-symbol-info :foreground base6 :background base1)
    (lsp-ui-sideline-current-symbol :foreground base7 :weight 'bold)
    (lsp-ui-doc-header :foreground blue :background base2)
    (lsp-ui-doc-url :underline t :foreground blue)
    (lsp-ui-peek-filename :foreground magenta)
    ;; ... (Other lsp-mode faces)

    ;; --- SLY/SLIME Faces -----------------------------------------------------
    ;; Custom faces for SLY/SLIME (Common Lisp IDE)
    (sly-mrepl-prompt-face :foreground green)
    (sly-mrepl-output-face :foreground base6)
    (slime-repl-inputed-output-face :foreground red)
    ;; (slime-error-face :underline (:style wave :color red))
    ;; ... (Other SLY/SLIME faces)

    ;; --- Python Mode Faces ---------------------------------------------------
    ;; Custom faces for Python mode
    (python-builtins-face :foreground violet)
    (python-exception-face :foreground red :weight 'bold)
    (python-function-call-face :foreground cyan)
    ;; ... (Other Python mode faces)
    ;; --- Magit Faces --------------------------------------------------------
    ;; Custom faces for Magit
    (magit-section-highlight :background base1)
    (magit-branch-current :foreground blue :box t)
    (magit-diff-hunk-heading :background base1 :foreground base4)
    ;; ... (Other Magit faces)

    ;; --- Dired Mode Faces ---------------------------------------------------
    ;; Custom faces for Dired mode
    (dired-directory :foreground blue)
    (dired-flagged :foreground red)
    (dired-symlink :foreground cyan)
    ;; ... (Other Dired faces)

    ;; --- ERC Faces ----------------------------------------------------------
    ;; Custom faces for ERC (IRC client for Emacs)
    (erc-current-nick-face :foreground blue :weight 'bold)
    (erc-error-face :foreground red)
    (erc-input-face :foreground base7)
    ;; ... (Other ERC faces)

    ;; --- General UI Faces ---------------------------------------------------
    ;; Faces for common Emacs functionality
    (hl-line :background base1)
    (show-paren-match :background blue)
    (vertical-border :foreground base4)
    ;; ... (Other general UI faces)

    ;; --- Shell Mode Faces ----------------------------------------------------
    ;; Custom faces for Shell mode
    (sh-quoted-exec :foreground orange)
    (sh-heredoc :foreground yellow)
    (sh-escaped-newline :foreground green)
    ;; ... (Other Shell mode faces)

    ;; --- Custom Faces ---------------------------------------------------------
    ;; Add custom faces for other miscellaneous modes or plugins.
    (some-other-custom-face :foreground yellow :background base3)
    ;; ... (Other custom faces)
    ;; --- Org-Roam Faces ------------------------------------------------------
    ;; Customize faces for org-roam
    (org-roam-link :foreground blue :underline t)
    (org-roam-link-current :foreground green :underline t)
    (org-roam-link-invalid :foreground red :underline t)
    ;; ... (Other org-roam faces)

    ;; --- Vertico Faces -------------------------------------------------------
    ;; Customize faces for Vertico
    (vertico-current :foreground yellow :weight 'bold :background base1)
    (vertico-multiline :foreground base5)
    ;; ... (Other vertico faces)

    ;; --- Marginalia Faces ----------------------------------------------------
    ;; Customize faces for Marginalia
    (marginalia-key :foreground green)
    (marginalia-mode :foreground yellow)
    (marginalia-date :foreground base5)
    ;; ... (Other marginalia faces)

    ;; --- Consult Faces -------------------------------------------------------
    ;; Customize faces for Consult
    (consult-annotation :foreground magenta)
    (consult-file :foreground blue)
    (consult-line-number :foreground base4)
    (consult-preview-line :foreground base5)
    ;; ... (Other consult faces)

    ;; --- LSP Mode Faces (Continuation) ---------------------------------------
    ;; More faces for LSP (Language Server Protocol)
    (lsp-ui-doc-background :background base1)
    (lsp-ui-doc-header :foreground blue :weight 'bold)
    (lsp-ui-sideline-code-action :foreground yellow))
  ;; ... (Other lsp-mode faces, if available)

  ;; --- extra variables --------------------
  ())
(setq current-theme 'ewal-doom-vibrant-x)
(setq doom-theme 'ewal-doom-vibrant-x)
(provide-theme 'ewal-doom-vibrant-x)

;;; ewal-doom-vibrant-theme.el ends here
