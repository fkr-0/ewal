;;; ewal-generate-doom-theme.el --- Generate Doom theme dynamically -*- lexical-binding: t; -*-

(require 'ewal-palette-utils)

(defun ewal-generate-doom-theme (name palette)
  "Generate a Doom theme definition dynamically based on the `ewal` PALETTE.

Arguments:
  - NAME (symbol): The name of the Doom theme.
  - PALETTE (alist): An alist containing base colors for the theme.

Automatically derives lighter and darker shades for each base color."
  (let* ((bg (alist-get 'background palette))
         (fg (alist-get 'foreground palette))
         ;; Generate dynamic shades for background and foreground
         (bg-shades (ewal-generate-shades bg 3 10))
         (fg-shades (ewal-generate-shades fg 3 10))
         ;; Extract specific shades from the generated shades
         (bg-light (alist-get :light-1 bg-shades))
         (bg-lighter (alist-get :light-2 bg-shades))
         (bg-dark (alist-get :dark-1 bg-shades))
         (bg-darker (alist-get :dark-2 bg-shades))
         (fg-light (alist-get :light-1 fg-shades))
         (fg-dark (alist-get :dark-1 fg-shades))
         ;; Use base palette values
         (highlight (alist-get 'highlight palette))
         (red (alist-get 'red palette))
         (green (alist-get 'green palette))
         (yellow (alist-get 'yellow palette))
         (blue (alist-get 'blue palette))
         (magenta (alist-get 'magenta palette))
         (cyan (alist-get 'cyan palette)))
    `(def-doom-theme ,name
                     "A dynamically generated Doom theme using ewal."

                     ;; Color Definitions
                     ((bg         . ,bg)
                      (bg-light   . ,bg-light)
                      (bg-lighter . ,bg-lighter)
                      (bg-dark    . ,bg-dark)
                      (bg-darker  . ,bg-darker)
                      (fg         . ,fg)
                      (fg-light   . ,fg-light)
                      (fg-dark    . ,fg-dark)
                      (highlight  . ,highlight)
                      (red        . ,red)
                      (green      . ,green)
                      (yellow     . ,yellow)
                      (blue       . ,blue)
                      (magenta    . ,magenta)
                      (cyan       . ,cyan))

                     ;; Face Definitions
                     ((default :background bg :foreground fg)
                      (cursor :background fg :foreground bg)
                      (region :background bg-dark :foreground fg-light)
                      (highlight :background highlight)
                      (error :foreground red :weight 'bold)
                      (warning :foreground yellow :weight 'bold)
                      (success :foreground green :weight 'bold)
                      (font-lock-comment-face :foreground bg-darker :slant 'italic)
                      (font-lock-function-name-face :foreground blue :weight 'bold)
                      (font-lock-keyword-face :foreground magenta :weight 'bold)
                      (font-lock-string-face :foreground green)
                      (font-lock-variable-name-face :foreground yellow)
                      (font-lock-type-face :foreground cyan))

                     ;; Extra Variables
                     ())))

;; (defun ewal-generate-doom-theme (name palette)
;;   "Generate a Doom theme definition dynamically based on the `ewal` PALETTE.

;; Arguments:
;;   - NAME (symbol): The name of the Doom theme.
;;   - PALETTE (alist): An alist containing colors for the theme.

;; This function creates a `def-doom-theme` block with generated colors and faces."
;;   (let* ((bg (alist-get 'background palette))
;;          (fg (alist-get 'foreground palette))
;;          (highlight (alist-get 'highlight palette))
;;          (red (alist-get 'red palette))
;;          (green (alist-get 'green palette))
;;          (yellow (alist-get 'yellow palette))
;;          (blue (alist-get 'blue palette))
;;          (magenta (alist-get 'magenta palette))
;;          (cyan (alist-get 'cyan palette))
;;          (base0 (ewal-get-color 'background -5))
;;          (base1 (ewal-get-color 'background -4))
;;          (base2 (ewal-get-color 'background -3))
;;          (base3 (ewal-get-color 'background -2))
;;          (base4 (ewal-get-color 'comment 0))
;;          (base5 (ewal-get-color 'background 0))
;;          (base6 (ewal-get-color 'background 3))
;;          (base7 (ewal-get-color 'foreground -1))
;;          (base8 (ewal-get-color 'foreground 1)))
;;     `(def-doom-theme ,name
;;                      "A dynamically generated Doom theme using ewal."

;;                      ;; Color Definitions
;;                      ((bg         . ,bg)
;;                       (fg         . ,fg)
;;                       (highlight  . ,highlight)
;;                       (base0      . ,base0)
;;                       (base1      . ,base1)
;;                       (base2      . ,base2)
;;                       (base3      . ,base3)
;;                       (base4      . ,base4)
;;                       (base5      . ,base5)
;;                       (base6      . ,base6)
;;                       (base7      . ,base7)
;;                       (base8      . ,base8)
;;                       (red        . ,red)
;;                       (green      . ,green)
;;                       (yellow     . ,yellow)
;;                       (blue       . ,blue)
;;                       (magenta    . ,magenta)
;;                       (cyan       . ,cyan))

;;                      ;; Face Definitions
;;                      ((default :background bg :foreground fg)
;;                       (cursor :background fg :foreground bg)
;;                       (region :background base3 :foreground fg)
;;                       (highlight :background highlight)
;;                       (error :foreground red :weight 'bold)
;;                       (warning :foreground yellow :weight 'bold)
;;                       (success :foreground green :weight 'bold)
;;                       (font-lock-comment-face :foreground base4 :slant 'italic)
;;                       (font-lock-function-name-face :foreground blue :weight 'bold)
;;                       (font-lock-keyword-face :foreground magenta :weight 'bold)
;;                       (font-lock-string-face :foreground green)
;;                       (font-lock-variable-name-face :foreground yellow)
;;                       (font-lock-type-face :foreground cyan))

;;                      ;; Extra Variables
;;                      ()))))

(defun ewal-generate-doom-theme-interactive ()
  "Interactively generate a Doom theme using an `ewal` palette."
  (interactive)
  (let ((theme-name (intern (read-string "Enter theme name: ")))
        (palette (ewal-load-palette (read-file-name "Select palette JSON: "))))
    (eval (ewal-generate-doom-theme theme-name palette))
    (message "Generated Doom theme '%s'!" theme-name)))

(provide 'ewal-generate-doom-theme)
;;; ewal-generate-doom-theme.el ends here
