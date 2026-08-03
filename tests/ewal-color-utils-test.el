;;; ewal-color-utils-test.el --- Tests for Ewal color safety -*- lexical-binding: t; -*-

(require 'ert)
(require 'ewal)
(require 'ewal-color-utils)

(ert-deftest ewal-color-normalize-parses-hex-without-a-display ()
  "Hex normalization must not depend on terminal color capabilities."
  (should (equal (ewal-color-normalize "#777777") "#777777"))
  (should (equal (ewal-color-normalize "#abc") "#aabbcc"))
  (should (equal (ewal-color-normalize "#111122223333") "#112233")))

(ert-deftest ewal-color-contrast-ratio-matches-wcag-reference-values ()
  "Contrast calculations should use linearized sRGB luminance."
  (should (< (abs (- (ewal-color-contrast-ratio "#000000" "#ffffff")
                     21.0))
             0.0001))
  (should (< (abs (- (ewal-color-contrast-ratio "#777777" "#ffffff")
                     4.478089))
             0.001))
  (should (< (abs (- (ewal-color-contrast-ratio "#111111" "#111111")
                     1.0))
             0.0001)))

(ert-deftest ewal-color-ensure-contrast-repairs-equal-colors ()
  "A contrast-safe result must be distinct and meet the threshold."
  (let ((fixed (ewal-color-ensure-contrast "#222222" "#222222" 4.5)))
    (should (stringp fixed))
    (should-not (ewal-color-equal-p fixed "#222222"))
    (should (>= (ewal-color-contrast-ratio fixed "#222222") 4.5))))

(ert-deftest ewal-finalize-palette-derives-safe-semantic-roles ()
  "Missing semantic roles should be derived and contrast-safe."
  (let* ((background "#222222")
         (palette `((background . ,background)
                    (foreground . ,background)
                    (cursor . ,background)
                    (color8 . ,background)))
         (final (ewal--finalize-palette palette)))
    (dolist (role '(foreground cursor comment highlight))
      (let* ((color (alist-get role final))
             (minimum (if (memq role '(foreground comment)) 4.5 3.0)))
        (should (ewal-color-valid-p color))
        (should-not (ewal-color-equal-p color background))
        (should (>= (ewal-color-contrast-ratio color background) minimum))))))

(ert-deftest ewal-json-source-resolution-prefers-primary-then-fallback ()
  "Palette lookup should preserve pywal compatibility and support colrz fallback."
  (let* ((tmpdir (make-temp-file "ewal-source-" t))
         (primary (expand-file-name "wal/colors.json" tmpdir))
         (fallback (expand-file-name "colrz/current/colors.json" tmpdir))
         (explicit (expand-file-name "explicit/colors.json" tmpdir)))
    (unwind-protect
        (progn
          (make-directory (file-name-directory fallback) t)
          (with-temp-file fallback (insert "{}"))
          (let ((ewal-json-file primary)
                (ewal-json-file-fallbacks (list fallback)))
            (should (equal (ewal--resolve-json-file) fallback))
            (make-directory (file-name-directory primary) t)
            (with-temp-file primary (insert "{}"))
            (should (equal (ewal--resolve-json-file) primary))
            (should (equal (ewal--resolve-json-file explicit) explicit))))
      (delete-directory tmpdir t))))

(defun ewal-test--palette-json (background foreground &optional extra-color)
  "Return minimal pywal JSON using BACKGROUND, FOREGROUND, and EXTRA-COLOR."
  (format
   "{\"special\":{\"background\":\"%s\",\"foreground\":\"%s\"},\"colors\":{\"color0\":\"#111111\"%s}}"
   background foreground
   (if extra-color
       (format ",\"color1\":\"%s\"" extra-color)
     "")))

(ert-deftest ewal-json-reader-accepts-minimal-valid-partial-palette ()
  "A partial palette remains compatible when required sections are valid."
  (let ((file (make-temp-file "ewal-partial-" nil ".json")))
    (unwind-protect
        (progn
          (with-temp-file file
            (insert (ewal-test--palette-json "#101010" "#f0f0f0")))
          (let ((ewal-json-read-retries 0))
            (ewal--parse-json file))
          (should (equal (alist-get 'background ewal-base-palette) "#101010"))
          (should (ewal-color-valid-p (alist-get 'cursor ewal-base-palette))))
      (delete-file file))))

(ert-deftest ewal-load-colors-caches-the-successful-replacement-signature ()
  "A retried load should cache the signature of the replacement it accepted."
  (let* ((file (make-temp-file "ewal-retry-source-" nil ".json"))
         (replacement (ewal-test--palette-json
                       "#252525" "#ffffff" "#abcdef"))
         (replaced nil)
         (ewal-use-built-in-always nil)
         (ewal-json-read-retries 1)
         (ewal-base-palette nil)
         (ewal--loaded-source nil)
         (ewal--json-read-after-read-hook
          (list (lambda ()
                  (unless replaced
                    (setq replaced t)
                    (with-temp-file file
                      (insert replacement)))))))
    (unwind-protect
        (progn
          (with-temp-file file
            (insert (ewal-test--palette-json "#101010" "#eeeeee")))
          (should (ewal-load-colors file t))
          (should replaced)
          (should
           (equal ewal--loaded-source
                  (list 'json file (ewal--json-file-signature file))))
          (should (equal (alist-get 'background ewal-base-palette)
                         "#252525")))
      (delete-file file))))

(ert-deftest ewal-load-colors-detects-atomic-replacement-with-preserved-time ()
  "Source caching should notice replacements even when modification time is kept."
  (let* ((file (make-temp-file "ewal-source-cache-" nil ".json"))
         (replacement (make-temp-file "ewal-source-replacement-" nil ".json"))
         (ewal-use-built-in-always nil)
         (ewal-json-read-retries 0)
         (ewal-base-palette nil)
         (ewal--loaded-source nil))
    (unwind-protect
        (progn
          (with-temp-file file
            (insert (ewal-test--palette-json "#101010" "#eeeeee")))
          (should (ewal-load-colors file t))
          (should (equal (alist-get 'background ewal-base-palette)
                         "#101010"))
          (let ((original-time (nth 5 (file-attributes file))))
            (with-temp-file replacement
              (insert (ewal-test--palette-json
                       "#303030" "#ffffff" "#abcdef")))
            (set-file-times replacement original-time)
            (rename-file replacement file t))
          (should (ewal-load-colors file nil))
          (should (equal (alist-get 'background ewal-base-palette)
                         "#303030")))
      (when (file-exists-p file) (delete-file file))
      (when (file-exists-p replacement) (delete-file replacement)))))

(ert-deftest ewal-load-colors-falls-back-for-malformed-or-incomplete-cache ()
  "Malformed and structurally incomplete cache files must use a built-in palette."
  (dolist (contents '("{"
                      "{\"special\":{\"background\":\"#111111\"}}"))
    (let ((file (make-temp-file "ewal-invalid-" nil ".json"))
          (ewal-json-read-retries 0)
          (ewal-use-built-in-always nil)
          (ewal-built-in-palette "sexy-material")
          (ewal-dark-palette-p t)
          (ewal-base-palette nil)
          (ewal--loaded-source nil)
          fallback-called)
      (unwind-protect
          (progn
            (with-temp-file file (insert contents))
            (let ((original (symbol-function 'ewal--load-built-in-palette)))
              (cl-letf (((symbol-function 'ewal--load-built-in-palette)
                         (lambda ()
                           (setq fallback-called t)
                           (funcall original))))
                (should (ewal-load-colors file t))))
            (should fallback-called)
            (should (ewal-color-valid-p
                     (alist-get 'background ewal-base-palette))))
        (delete-file file)))))

(ert-deftest ewal-json-reader-retries-file-replaced-during-read ()
  "A palette replaced during reading should be retried and loaded consistently."
  (let* ((file (make-temp-file "ewal-replaced-" nil ".json"))
         (replacement (ewal-test--palette-json
                       "#202020" "#fefefe" "#abcdef"))
         (replaced nil)
         (ewal-json-read-retries 1)
         (ewal--json-read-after-read-hook
          (list (lambda ()
                  (unless replaced
                    (setq replaced t)
                    (with-temp-file file
                      (insert replacement)))))))
    (unwind-protect
        (progn
          (with-temp-file file
            (insert (ewal-test--palette-json "#101010" "#eeeeee")))
          (ewal--parse-json file)
          (should replaced)
          (should (equal (alist-get 'background ewal-base-palette)
                         "#202020"))
          (should (equal (alist-get 'color1 ewal-base-palette)
                         "#abcdef")))
      (delete-file file))))

(ert-deftest ewal-built-in-palette-path-is-package-relative-and-loadable ()
  "The default bundled palette location should work outside ~/.emacs.d."
  (should (file-directory-p ewal-built-in-palette-path))
  (let ((ewal-use-built-in-always t)
        (ewal-built-in-palette "sexy-material")
        (ewal-dark-palette-p t)
        (ewal-base-palette nil)
        (ewal--loaded-source nil))
    (should (ewal-load-colors nil t))
    (dolist (role '(background foreground cursor comment highlight))
      (should (ewal-color-valid-p (alist-get role ewal-base-palette))))))

(ert-deftest ewal-all-bundled-palettes-finalize-with-safe-semantic-roles ()
  "Every bundled palette should produce readable semantic color roles."
  (let ((files (directory-files-recursively
                ewal-built-in-palette-path "\\.json\\'"))
        (ewal-base-palette nil))
    (should (> (length files) 0))
    (dolist (file files)
      (ert-info ((format "Palette: %s" file))
        (ewal--parse-json file)
        (let ((background (alist-get 'background ewal-base-palette)))
          (should (ewal-color-valid-p background))
          (dolist (role '(foreground cursor comment highlight))
            (let* ((color (alist-get role ewal-base-palette))
                   (minimum (if (memq role '(foreground comment)) 4.5 3.0)))
              (should (ewal-color-valid-p color))
              (should-not (ewal-color-equal-p color background))
              (should (>= (ewal-color-contrast-ratio color background)
                          minimum)))))))))

;;; ewal-color-utils-test.el ends here
