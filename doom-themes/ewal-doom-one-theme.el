;;; ewal-doom-one-theme.el --- Dread the color of darkness -*- lexical-binding: t; no-byte-compile: t; -*-

;; Package-Requires: ((emacs "25") (ewal "0.3.0") (doom-themes "2.3.0"))

;;; Commentary:
;;
;; A Doom theme wired to `ewal` colors, roughly following Atom One Dark
;; / doom-one semantics:
;;
;; - Brighter comments and/or modeline toggles.
;; - Optional padded modeline.
;; - Extra faces for modern completion stack, LSP, diagnostics, etc.

;;; Code:

(require 'ewal-doom-themes)

(defgroup ewal-doom-one-x-theme nil
  "Options for Doom themes based on `ewal` (doom-one-like)."
  :group 'doom-themes)

(defcustom ewal-doom-one-x-brighter-modeline nil
  "Use more vivid colors for the mode-line if non-nil."
  :type 'boolean
  :group 'ewal-doom-one-x-theme)

(defcustom ewal-doom-one-x-brighter-comments nil
  "Highlight comments in more vivid colors if non-nil."
  :type 'boolean
  :group 'ewal-doom-one-x-theme)

(defcustom ewal-doom-one-x-comment-bg ewal-doom-one-x-brighter-comments
  "If non-nil, comments will have a subtle background."
  :type 'boolean
  :group 'ewal-doom-one-x-theme)

(defcustom ewal-doom-one-x-padded-modeline doom-themes-padded-modeline
  "If non-nil, add padding to the mode-line.

When an integer, use that exact padding (line width)."
  :type '(choice integer boolean)
  :group 'ewal-doom-one-x-theme)

(def-doom-theme ewal-doom-one
  "A dark theme inspired by doom-one, customized using `ewal`."

  ;; name        default   256       16
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
    (red        (ewal-doom-themes-get-color 'red      -1))
    (orange     (ewal-doom-themes-get-color 'red       0))
    (green      (ewal-doom-themes-get-color 'green    -1))
    (teal       (ewal-doom-themes-get-color 'green     0))
    (yellow     (ewal-doom-themes-get-color 'yellow   -1))
    (blue       (ewal-doom-themes-get-color 'blue      0))
    (dark-blue  (ewal-doom-themes-get-color 'blue     -1))
    (magenta    (ewal-doom-themes-get-color 'magenta   0))
    (violet     (ewal-doom-themes-get-color 'magenta  -1))
    (cyan       (ewal-doom-themes-get-color 'cyan      0))
    (dark-cyan  (ewal-doom-themes-get-color 'cyan     -1))

    ;; face categories
    (highlight      blue)
    (vertical-bar   (doom-darken base1 0.15))
    (selection      dark-blue)
    (builtin        magenta)
    (comments       (if ewal-doom-one-x-brighter-comments dark-cyan base5))
    (doc-comments   (doom-lighten (if ewal-doom-one-x-brighter-comments dark-cyan base5) 0.25))
    (constants      violet)
    (functions      magenta)
    (keywords       blue)
    (methods        cyan)
    (operators      blue)
    (type           yellow)
    (strings        green)
    (variables      (doom-lighten magenta 0.4))
    (numbers        orange)
    (region         (doom-blend bg-alt blue 0.15))
    (error          red)
    (warning        yellow)
    (success        green)
    (vc-modified    orange)
    (vc-added       green)
    (vc-deleted     red)

    ;; custom categories
    (hidden     `(,(car bg) "black" "black"))
    (-modeline-bright ewal-doom-one-x-brighter-modeline)
    (-modeline-pad
      (when ewal-doom-one-x-padded-modeline
        (if (integerp ewal-doom-one-x-padded-modeline)
          ewal-doom-one-x-padded-modeline
          4)))

    (modeline-bg
      (if -modeline-bright
        (doom-darken blue 0.475)
        (doom-darken bg-alt 0.15)))
    (modeline-bg-l
      (if -modeline-bright
        (doom-darken blue 0.45)
        (doom-darken bg-alt 0.10)))
    (modeline-bg-inactive   (doom-darken bg-alt 0.1))
    (modeline-bg-inactive-l bg-alt)
    (modeline-fg
      (ewal-doom-themes-safe-triple fg modeline-bg 4.5))
    (modeline-fg-alt
      (ewal-doom-themes-safe-triple base5 modeline-bg-inactive 4.5))

    (diff-added-bg   (doom-blend bg green 0.1))
    (diff-removed-bg (doom-blend bg red 0.1))
    (diff-changed-bg (doom-blend bg orange 0.1))
    (diff-added-fg
      (ewal-doom-themes-safe-triple green diff-added-bg 4.5))
    (diff-removed-fg
      (ewal-doom-themes-safe-triple red diff-removed-bg 4.5))
    (diff-changed-fg
      (ewal-doom-themes-safe-triple orange diff-changed-bg 4.5)))

  ;; --- extra faces ------------------------
  ((default :background bg :foreground fg)
    (cursor  :background fg :foreground bg)

    (line-number :foreground base4)
    (line-number-current-line :foreground fg :weight 'bold)

    (font-lock-comment-face
      :foreground comments
      :background (when ewal-doom-one-x-comment-bg
                    (doom-lighten bg-alt 0.05)))
    (font-lock-doc-face
      :inherit 'font-lock-comment-face
      :foreground doc-comments)

    ;; Parens
    (show-paren-match :background blue :foreground base0 :weight 'bold)
    (show-paren-mismatch :background red :foreground base0 :weight 'bold)

    ;; Highlight current line
    (hl-line :background base1)

    ;; Minibuffer & completion (vertico/orderless/marginalia/consult/corfu)
    (minibuffer-prompt :foreground blue :weight 'bold)

    (vertico-current :background base2 :foreground base8 :weight 'bold)
    (vertico-multiline :foreground base5)

    (orderless-match-face-0 :foreground blue :weight 'bold)
    (orderless-match-face-1 :foreground magenta :weight 'bold)
    (orderless-match-face-2 :foreground cyan :weight 'bold)
    (orderless-match-face-3 :foreground yellow :weight 'bold)

    (marginalia-key :foreground green)
    (marginalia-mode :foreground yellow)
    (marginalia-date :foreground base5)
    (marginalia-documentation :foreground base5 :slant 'italic)
    (marginalia-file-name :foreground base7)

    (corfu-border :background base2)
    (corfu-background :background base1)
    (corfu-current :background base3)
    (corfu-bar :background blue)

    ;; Diagnostics (flycheck & flymake)
    (flycheck-error   :underline `(:style wave :color ,red))
    (flycheck-warning :underline `(:style wave :color ,yellow))
    (flycheck-info    :underline `(:style wave :color ,cyan))

    (flymake-error   :underline `(:style wave :color ,red))
    (flymake-warning :underline `(:style wave :color ,yellow))
    (flymake-note    :underline `(:style wave :color ,cyan))

    ;; Diff / VC
    (diff-added   :foreground diff-added-fg :background diff-added-bg)
    (diff-removed :foreground diff-removed-fg :background diff-removed-bg)
    (diff-changed :foreground diff-changed-fg :background diff-changed-bg)

    (diff-hl-insert :background (doom-blend bg green 0.25) :foreground green)
    (diff-hl-delete :background (doom-blend bg red   0.25) :foreground red)
    (diff-hl-change :background (doom-blend bg orange 0.25) :foreground orange)

    ;; Magit
    (magit-section-title :foreground yellow :weight 'bold)
    (magit-branch-current :foreground blue :box t)
    (magit-diff-hunk-heading :background base1 :foreground base4)
    (magit-diff-added :inherit 'diff-added)
    (magit-diff-removed :inherit 'diff-removed)

    ;; Dired
    (dired-directory :foreground blue :weight 'bold)
    (dired-flagged :foreground red)
    (dired-symlink :foreground cyan)

    ;; Treemacs
    (treemacs-root-face :foreground blue :weight 'bold :height 1.2)
    (treemacs-git-modified-face :foreground yellow)
    (treemacs-git-added-face :foreground green)
    (treemacs-git-untracked-face :foreground red)

    ;; Org
    (org-hide :foreground hidden)
    (org-document-title :foreground blue :weight 'bold :height 1.5)
    (org-level-1 :foreground orange :weight 'bold :height 1.3)
    (org-level-2 :foreground magenta :weight 'bold :height 1.2)
    (org-level-3 :foreground blue :weight 'bold :height 1.1)
    (org-checkbox :foreground green :weight 'bold)
    (org-todo :foreground red :weight 'bold)
    (org-done :foreground green :weight 'bold)

    ;; LSP
    (lsp-face-highlight-read :background base2)
    (lsp-face-highlight-write :background base3)
    (lsp-ui-peek-highlight :foreground yellow :weight 'bold)
    (lsp-ui-sideline-symbol-info :foreground base6 :background base1)
    (lsp-ui-doc-header :foreground blue :background base2)
    (lsp-ui-doc-background :background base1)

    ;; SLY / SLIME
    (sly-mrepl-prompt-face :foreground green)
    (sly-mrepl-output-face :foreground base6)
    (slime-repl-inputed-output-face :foreground red)

    ;; ERC
    (erc-current-nick-face :foreground blue :weight 'bold)
    (erc-error-face :foreground red)
    (erc-input-face :foreground base7)

    ;; Mode line
    (mode-line
      :background modeline-bg :foreground modeline-fg
      :box (when -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg)))
    (mode-line-inactive
      :background modeline-bg-inactive :foreground modeline-fg-alt
      :box (when -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive)))
    (mode-line-emphasis :foreground (if -modeline-bright base8 highlight))

    (solaire-mode-line-face
      :inherit 'mode-line
      :background modeline-bg-l
      :box (when -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-l)))
    (solaire-mode-line-inactive-face
      :inherit 'mode-line-inactive
      :background modeline-bg-inactive-l
      :box (when -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive-l))))

  ;; --- extra variables --------------------
  ())

(provide-theme 'ewal-doom-one)

;;; ewal-doom-one-theme.el ends here
