;;; ewal-doom-tokyo-night-theme.el --- ewal adaptation of doom-tokyo-night -*- lexical-binding: t; no-byte-compile: t; -*-

;; Package-Requires: ((emacs "25") (ewal "0.3") (doom-themes "2.3.0"))

;;; Commentary:
;;
;; Tokyo-night flavored Doom theme backed by `ewal` colors.

;;; Code:

(require 'ewal-doom-themes)

(defgroup ewal-doom-tokyo-night-theme nil
  "Options for ewal doom-tokyo-night-like theme."
  :group 'doom-themes)

(defcustom ewal-doom-tokyo-night-brighter-modeline t
  "If non-nil, use a more vivid mode-line background."
  :type 'boolean
  :group 'ewal-doom-tokyo-night-theme)

(defcustom ewal-doom-tokyo-night-padded-modeline doom-themes-padded-modeline
  "If non-nil, add padding to the mode-line.  Integer sets exact width."
  :type '(choice integer boolean)
  :group 'ewal-doom-tokyo-night-theme)

(def-doom-theme ewal-doom-tokyo-night
  "A cool, midnight blue ewal Doom theme inspired by Tokyo Night."

  ((bg         (ewal-doom-themes-get-color 'background 0))
    (bg-alt     (ewal-doom-themes-get-color 'background -2))
    (base0      (ewal-doom-themes-get-color 'background -4))
    (base1      (ewal-doom-themes-get-color 'background -3))
    (base2      (ewal-doom-themes-get-color 'background -1))
    (base3      (ewal-doom-themes-get-color 'background 1))
    (base4      (ewal-doom-themes-get-color 'background 2))
    (base5      (ewal-doom-themes-get-color 'comment 0))
    (base6      (ewal-doom-themes-get-color 'foreground -2))
    (base7      (ewal-doom-themes-get-color 'foreground -1))
    (base8      (ewal-doom-themes-get-color 'foreground 1))
    (fg         (ewal-doom-themes-get-color 'foreground 0))
    (fg-alt     (ewal-doom-themes-get-color 'foreground -1))

    (grey       base4)
    (red        (ewal-doom-themes-get-color 'red -1))
    (orange     (ewal-doom-themes-get-color 'yellow -2))
    (green      (ewal-doom-themes-get-color 'green -1))
    (teal       (ewal-doom-themes-get-color 'cyan -1))
    (yellow     (ewal-doom-themes-get-color 'yellow -1))
    (blue       (ewal-doom-themes-get-color 'blue 0))
    (dark-blue  (ewal-doom-themes-get-color 'blue -2))
    (magenta    (ewal-doom-themes-get-color 'magenta 0))
    (violet     (ewal-doom-themes-get-color 'magenta -1))
    (cyan       (ewal-doom-themes-get-color 'cyan 0))
    (dark-cyan  (ewal-doom-themes-get-color 'cyan -2))

    (highlight      blue)
    (vertical-bar   base1)
    (selection      (doom-blend dark-blue bg 0.35))
    (builtin        magenta)
    (comments       base5)
    (doc-comments   (doom-lighten base5 0.2))
    (constants      violet)
    (functions      blue)
    (keywords       magenta)
    (methods        cyan)
    (operators      cyan)
    (type           yellow)
    (strings        green)
    (variables      fg)
    (numbers        orange)
    (region         (doom-blend bg-alt blue 0.18))
    (error          red)
    (warning        yellow)
    (success        green)
    (vc-modified    orange)
    (vc-added       green)
    (vc-deleted     red)

    (-modeline-pad
      (when ewal-doom-tokyo-night-padded-modeline
        (if (integerp ewal-doom-tokyo-night-padded-modeline)
          ewal-doom-tokyo-night-padded-modeline
          4)))

    (modeline-bg
      (if ewal-doom-tokyo-night-brighter-modeline
        (doom-blend bg-alt blue 0.30)
        (doom-darken bg-alt 0.08)))
    (modeline-bg-l (doom-lighten modeline-bg 0.04))
    (modeline-bg-inactive (doom-darken bg-alt 0.06))
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
    (line-number-current-line :foreground fg :weight 'bold)

    (mode-line
      :background modeline-bg :foreground modeline-fg
      :box (when -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg)))
    (mode-line-inactive
      :background modeline-bg-inactive :foreground modeline-fg-alt
      :box (when -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive)))
    (mode-line-emphasis :foreground base8)

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

    (show-paren-match :background blue :foreground base0 :weight 'bold)
    (hl-line :background base1)

    (vertico-current :background base2 :foreground base8 :weight 'bold)
    (orderless-match-face-0 :foreground blue :weight 'bold)
    (orderless-match-face-1 :foreground magenta :weight 'bold)
    (orderless-match-face-2 :foreground cyan :weight 'bold)
    (orderless-match-face-3 :foreground yellow :weight 'bold)

    (lsp-ui-sideline-symbol-info :foreground base6 :background base1)

    (magit-section-highlight :background base1)
    (magit-branch-current :foreground blue :box t)
    (magit-diff-hunk-heading :background base1 :foreground base4)

    (diff-added :foreground diff-added-fg :background diff-added-bg)
    (diff-removed :foreground diff-removed-fg :background diff-removed-bg)
    (diff-changed :foreground diff-changed-fg :background diff-changed-bg))

  ())

(provide-theme 'ewal-doom-tokyo-night)
;;; ewal-doom-tokyo-night-theme.el ends here
