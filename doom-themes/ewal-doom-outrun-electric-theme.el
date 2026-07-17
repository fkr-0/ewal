;;; ewal-doom-outrun-electric-theme.el --- ewal adaptation of doom-outrun-electric -*- lexical-binding: t; no-byte-compile: t; -*-

;; Package-Requires: ((emacs "25") (ewal "0.3") (doom-themes "2.3.0"))

;;; Commentary:
;;
;; Outrun-electric flavored Doom theme backed by `ewal` colors.

;;; Code:

(require 'ewal-doom-themes)

(defgroup ewal-doom-outrun-electric-theme nil
  "Options for ewal doom-outrun-electric-like theme."
  :group 'doom-themes)

(defcustom ewal-doom-outrun-electric-brighter-modeline t
  "If non-nil, use neon modeline accents."
  :type 'boolean
  :group 'ewal-doom-outrun-electric-theme)

(defcustom ewal-doom-outrun-electric-padded-modeline doom-themes-padded-modeline
  "If non-nil, add padding to the mode-line.  Integer sets exact width."
  :type '(choice integer boolean)
  :group 'ewal-doom-outrun-electric-theme)

(def-doom-theme ewal-doom-outrun-electric
  "A neon ewal Doom theme inspired by Outrun Electric."

  ((bg         (ewal-doom-themes-get-color 'background 0))
    (bg-alt     (ewal-doom-themes-get-color 'background -3))
    (base0      (ewal-doom-themes-get-color 'background -5))
    (base1      (ewal-doom-themes-get-color 'background -4))
    (base2      (ewal-doom-themes-get-color 'background -2))
    (base3      (ewal-doom-themes-get-color 'background -1))
    (base4      (ewal-doom-themes-get-color 'background 1))
    (base5      (ewal-doom-themes-get-color 'comment 0))
    (base6      (ewal-doom-themes-get-color 'foreground -2))
    (base7      (ewal-doom-themes-get-color 'foreground -1))
    (base8      (ewal-doom-themes-get-color 'foreground 1))
    (fg         (ewal-doom-themes-get-color 'foreground 0))
    (fg-alt     (ewal-doom-themes-get-color 'foreground -1))

    (grey       base4)
    (red        (ewal-doom-themes-get-color 'red 0))
    (orange     (ewal-doom-themes-get-color 'yellow -1))
    (green      (ewal-doom-themes-get-color 'green -1))
    (teal       (ewal-doom-themes-get-color 'cyan 0))
    (yellow     (ewal-doom-themes-get-color 'yellow 0))
    (blue       (ewal-doom-themes-get-color 'blue 0))
    (dark-blue  (ewal-doom-themes-get-color 'blue -2))
    (magenta    (ewal-doom-themes-get-color 'magenta 0))
    (violet     (ewal-doom-themes-get-color 'magenta -1))
    (cyan       (ewal-doom-themes-get-color 'cyan 0))
    (dark-cyan  (ewal-doom-themes-get-color 'cyan -2))

    (highlight      magenta)
    (vertical-bar   base1)
    (selection      (doom-blend magenta bg 0.25))
    (builtin        cyan)
    (comments       (doom-lighten base5 0.10))
    (doc-comments   (doom-lighten base5 0.30))
    (constants      yellow)
    (functions      magenta)
    (keywords       cyan)
    (methods        violet)
    (operators      magenta)
    (type           yellow)
    (strings        green)
    (variables      fg)
    (numbers        orange)
    (region         (doom-blend bg-alt magenta 0.23))
    (error          red)
    (warning        yellow)
    (success        green)
    (vc-modified    orange)
    (vc-added       green)
    (vc-deleted     red)

    (-modeline-pad
      (when ewal-doom-outrun-electric-padded-modeline
        (if (integerp ewal-doom-outrun-electric-padded-modeline)
          ewal-doom-outrun-electric-padded-modeline
          4)))

    (modeline-bg
      (if ewal-doom-outrun-electric-brighter-modeline
        (doom-blend bg-alt magenta 0.38)
        (doom-blend bg-alt blue 0.18)))
    (modeline-bg-l (doom-lighten modeline-bg 0.07))
    (modeline-bg-inactive (doom-darken bg-alt 0.10))
    (modeline-bg-inactive-l bg-alt)
    (modeline-fg
      (ewal-doom-themes-safe-triple fg modeline-bg 4.5))
    (modeline-fg-alt
      (ewal-doom-themes-safe-triple base6 modeline-bg-inactive 4.5))

    (diff-added-bg   (doom-blend bg green 0.10))
    (diff-removed-bg (doom-blend bg red 0.10))
    (diff-changed-bg (doom-blend bg orange 0.10))
    (diff-added-fg
      (ewal-doom-themes-safe-triple green diff-added-bg 4.5))
    (diff-removed-fg
      (ewal-doom-themes-safe-triple red diff-removed-bg 4.5))
    (diff-changed-fg
      (ewal-doom-themes-safe-triple orange diff-changed-bg 4.5)))

  ((default :background bg :foreground fg)
    (cursor :background fg :foreground bg)

    (line-number :foreground base4)
    (line-number-current-line :foreground magenta :weight 'bold)

    (mode-line
      :background modeline-bg :foreground modeline-fg
      :box (when -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg)))
    (mode-line-inactive
      :background modeline-bg-inactive :foreground modeline-fg-alt
      :box (when -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive)))
    (mode-line-emphasis :foreground highlight)

    (solaire-mode-line-face
      :inherit 'mode-line
      :background modeline-bg-l
      :box (when -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-l)))
    (solaire-mode-line-inactive-face
      :inherit 'mode-line-inactive
      :background modeline-bg-inactive-l
      :box (when -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive-l)))

    (font-lock-comment-face :foreground comments)
    (font-lock-doc-face :foreground doc-comments)

    (show-paren-match :background cyan :foreground base0 :weight 'bold)
    (hl-line :background base1)

    (vertico-current :background base2 :foreground base8 :weight 'bold)
    (orderless-match-face-0 :foreground cyan :weight 'bold)
    (orderless-match-face-1 :foreground magenta :weight 'bold)
    (orderless-match-face-2 :foreground yellow :weight 'bold)
    (orderless-match-face-3 :foreground green :weight 'bold)

    (lsp-ui-sideline-symbol-info :foreground base6 :background base1)

    (magit-section-highlight :background base1)
    (magit-branch-current :foreground cyan :box t)
    (magit-diff-hunk-heading :background base1 :foreground base4)

    (diff-added :foreground diff-added-fg :background diff-added-bg)
    (diff-removed :foreground diff-removed-fg :background diff-removed-bg)
    (diff-changed :foreground diff-changed-fg :background diff-changed-bg))

  ())

(provide-theme 'ewal-doom-outrun-electric)
;;; ewal-doom-outrun-electric-theme.el ends here
