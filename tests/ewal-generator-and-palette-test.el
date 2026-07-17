;;; ewal-generator-and-palette-test.el --- Tests for generator/palette tools -*- lexical-binding: t; -*-

(require 'ert)
(require 'ewal-palette-utils)

;; `doom-themes` is not available in the batch test environment.
(unless (featurep 'doom-themes)
  (provide 'doom-themes))

(add-to-list 'load-path
             (expand-file-name "doom-themes"
                               (file-name-directory (directory-file-name default-directory))))
(require 'ewal-generate-doom-theme)

(ert-deftest ewal-generate-doom-theme-validates-required-keys ()
  "Generator should signal a user error when required keys are missing."
  (should-error
   (ewal-validate-doom-theme-palette
    '((background . "#111111")
      (foreground . "#eeeeee")
      (red . "#ff0000")))
   :type 'user-error))

(ert-deftest ewal-audit-palettes-contrast-sorts-by-worst-ratio ()
  "Palette contrast audit should rank files by worst (lowest) ratio."
  (let ((tmpdir (make-temp-file "ewal-audit-" t)))
    (unwind-protect
        (progn
          (with-temp-file (expand-file-name "bad.json" tmpdir)
            (insert
             "{\"special\":{\"background\":\"#111111\",\"foreground\":\"#222222\",\"cursor\":\"#333333\"},\"colors\":{}}"))
          (with-temp-file (expand-file-name "good.json" tmpdir)
            (insert
             "{\"special\":{\"background\":\"#111111\",\"foreground\":\"#fefefe\",\"cursor\":\"#ffffff\"},\"colors\":{}}"))
          (let ((entries (ewal-palette-audit-directory tmpdir)))
            (should (= 2 (length entries)))
            (should (string-suffix-p "bad.json" (alist-get 'file (car entries))))
            (should (string-suffix-p "good.json" (alist-get 'file (cadr entries))))))
      (delete-directory tmpdir t))))

;;; ewal-generator-and-palette-test.el ends here
