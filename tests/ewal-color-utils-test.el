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
