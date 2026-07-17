;;; ewal-doom-vibrant-theme.el --- Dread the vibrancy of darkness -*- lexical-binding: t; no-byte-compile: t; -*-

;; Package-Requires: ((emacs "25") (ewal "0.3") (doom-themes "2.3.0"))

;;; Commentary:
;;
;; A more saturated, contrasty Doom theme wired to `ewal` colors.
;; Think “doom-one, but caffeinated”.

;;; Code:

(require 'ewal-doom-themes)

(defgroup ewal-doom-vibrant-theme nil
  "Options for doom-one-vibrant-like `ewal` theme."
  :group 'doom-themes)

(defcustom ewal-doom-vibrant-brighter-modeline t
  "If non-nil, use a brighter modeline background."
  :type 'boolean
  :group 'ewal-doom-vibrant-theme)

(defcustom ewal-doom-vibrant-brighter-comments t
  "If non-nil, comments will be highlighted more vividly."
  :type 'boolean
  :group 'ewal-doom-vibrant-theme)

(defcustom ewal-doom-vibrant-comment-bg t
  "If non-nil, comments have a subtle darker background."
  :type 'boolean
  :group 'ewal-doom-vibrant-theme)

(defcustom ewal-doom-vibrant-padded-modeline doom-themes-padded-modeline
  "If non-nil, add padding to the modeline.  Integer = exact padding."
  :type '(choice integer boolean)
  :group 'ewal-doom-vibrant-theme)

;; HACK (preserved from upstream): forces byte-compiler to keep some color
(defvar ewal-doom-one-hack
  (ewal-doom-themes-get-color 'background 0))

(def-doom-theme ewal-doom-vibrant
  "A dark, vibrant Doom theme based on `ewal`."

  ;; Color Definitions
  ((bg         (ewal-doom-themes-get-color 'background  0))
    (bg-alt     (ewal-doom-themes-get-color 'background -3))
    (base0      (ewal-doom-themes-get-color 'background -5))
    (base1      (ewal-doom-themes-get-color 'background -4))
    (base2      (ewal-doom-themes-get-color 'background -2))
    (base3      (ewal-doom-themes-get-color 'background -1))
    (base4      (ewal-doom-themes-get-color 'background  1))
    (base5      (ewal-doom-themes-get-color 'comment     0))
    (base6      (ewal-doom-themes-get-color 'background  4))
    (base7      (ewal-doom-themes-get-color 'background  5))
    (base8      (ewal-doom-themes-get-color 'foreground  1))
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

    ;; face categories
    (highlight      blue)
    (vertical-bar   base0)
    (selection      dark-blue)
    (builtin        magenta)
    (comments       (if ewal-doom-vibrant-brighter-comments
                      dark-cyan
                      (doom-lighten base5 0.6)))
    (doc-comments   (if ewal-doom-vibrant-brighter-comments
                      (doom-lighten cyan 0.15)
                      (doom-lighten base4 0.6)))
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

    (-modeline-pad
      (when ewal-doom-vibrant-padded-modeline
        (if (integerp ewal-doom-vibrant-padded-modeline)
          ewal-doom-vibrant-padded-modeline
          4)))

    (modeline-bg
      (if ewal-doom-vibrant-brighter-modeline
        `(,(car bg-alt) ,@(cdr base1))
        `(,(car bg-alt) ,@(cdr base0))))
    (modeline-bg-l
      (if ewal-doom-vibrant-brighter-modeline
        modeline-bg
        `(,(doom-darken (car bg) 0.15) ,@(cdr base1))))
    (modeline-bg-inactive   (doom-darken bg 0.25))
    (modeline-bg-inactive-l `(,(doom-darken (car bg-alt) 0.2) ,@(cdr base0)))
    (modeline-fg
      (ewal-doom-themes-safe-triple fg modeline-bg 4.5))
    (modeline-fg-alt
      (ewal-doom-themes-safe-triple
       (doom-blend blue grey
                   (if ewal-doom-vibrant-brighter-modeline 0.4 0.08))
       modeline-bg-inactive 4.5)))

  ;; --- faces ------------------------------
  ((default :background bg :foreground fg)
    (cursor :background fg :foreground bg)

    ((line-number &override) :foreground base4)
    ((line-number-current-line &override) :foreground blue :bold t)

    (doom-modeline-bar :background (if ewal-doom-vibrant-brighter-modeline modeline-bg highlight))
    (doom-modeline-buffer-path :foreground (if ewal-doom-vibrant-brighter-modeline base8 blue)
      :bold t)

    (mode-line
      :background modeline-bg :foreground modeline-fg
      :box (when -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg)))
    (mode-line-inactive
      :background modeline-bg-inactive :foreground modeline-fg-alt
      :box (when -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive)))
    (mode-line-emphasis :foreground (if ewal-doom-vibrant-brighter-modeline base8 highlight))

    (solaire-mode-line-face
      :inherit 'mode-line
      :background modeline-bg-l
      :box (when -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-l)))
    (solaire-mode-line-inactive-face
      :inherit 'mode-line-inactive
      :background modeline-bg-inactive-l
      :box (when -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive-l)))

    ;; Syntax
    (font-lock-builtin-face :foreground builtin)
    (font-lock-comment-face
      :foreground (doom-lighten comments 0.15)
      :background (if ewal-doom-vibrant-comment-bg
                    (doom-darken bg-alt 0.095)
                    (doom-lighten hidden-alt 0.44)))
    (font-lock-doc-face
      :inherit 'font-lock-comment-face
      :foreground doc-comments)

    ;; HL line
    (hl-line :background base1)

    ;; Show paren
    (show-paren-match :background blue :foreground base0 :weight 'bold)

    ;; Completion (same as one-x)
    (vertico-current :foreground yellow :weight 'bold :background base1)
    (vertico-multiline :foreground base5)

    (orderless-match-face-0 :foreground blue :weight 'bold)
    (orderless-match-face-1 :foreground magenta :weight 'bold)
    (orderless-match-face-2 :foreground cyan :weight 'bold)
    (orderless-match-face-3 :foreground yellow :weight 'bold)

    ;; Org / Dired / Magit / ERC etc. – reuse same semantics as one-x, but with
    ;; more vivid base colors (they are shared constants).
    (org-hide :foreground hidden)
    (org-document-title :foreground blue :weight 'bold :height 1.5)
    (org-level-1 :foreground orange :weight 'bold :height 1.3)
    (org-level-2 :foreground magenta :weight 'bold :height 1.2)
    (org-checkbox :foreground green :weight 'bold)
    (org-todo :foreground red :weight 'bold)
    (org-done :foreground green :weight 'bold)

    (dired-directory :foreground blue)
    (dired-flagged :foreground red)
    (dired-symlink :foreground cyan)

    (magit-section-highlight :background base1)
    (magit-branch-current :foreground blue :box t)
    (magit-diff-hunk-heading :background base1 :foreground base4)

    (erc-current-nick-face :foreground blue :weight 'bold)
    (erc-error-face :foreground red)
    (erc-input-face :foreground base7)

    ;; LSP & diagnostics as in one-x
    (lsp-face-highlight-read :background base2)
    (lsp-face-highlight-write :background base3)
    (lsp-ui-peek-highlight :foreground yellow :weight 'bold)
    (lsp-ui-sideline-symbol-info :foreground base6 :background base1)

    (flycheck-error   :underline `(:style wave :color ,red))
    (flycheck-warning :underline `(:style wave :color ,yellow))
    (flycheck-info    :underline `(:style wave :color ,cyan)))

  ;; --- extra variables --------------------
  ())

(provide-theme 'ewal-doom-vibrant)
;;; ewal-doom-vibrant-theme.el ends here
