;;; ewal-generator-and-palette-test.el --- Tests for generator/palette tools -*- lexical-binding: t; -*-

(require 'ert)
(require 'cl-lib)
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

(defun ewal-test--generated-theme-color (value colors)
  "Resolve generated theme VALUE through color binding alist COLORS."
  (if (symbolp value)
      (alist-get value colors)
    value))

(defun ewal-test--generated-theme-face-pair (face face-defs colors)
  "Return explicit foreground/background pair for FACE.

FACE-DEFS and COLORS are taken from a generated `def-doom-theme' form.
Missing face properties inherit the generated default `fg' and `bg' roles."
  (let* ((spec (assq face face-defs))
         (properties (cdr spec))
         (foreground
          (ewal-test--generated-theme-color
           (or (plist-get properties :foreground) 'fg) colors))
         (background
          (ewal-test--generated-theme-color
           (or (plist-get properties :background) 'bg) colors)))
    (should spec)
    (list foreground background)))

(ert-deftest ewal-all-bundled-palettes-generate-readable-doom-faces ()
  "Every bundled palette should generate stable readable representative faces."
  (let ((files (directory-files-recursively
                ewal-built-in-palette-path "\\.json\\'"))
        (faces '(default cursor region highlight error warning success
                 font-lock-comment-face font-lock-function-name-face
                 font-lock-keyword-face font-lock-string-face
                 font-lock-variable-name-face font-lock-type-face)))
    (should (= 256 (length files)))
    (dolist (file files)
      (ert-info ((format "Palette: %s" file))
        (ewal--parse-json file)
        (let* ((form (ewal-generate-doom-theme
                      'ewal-generated-test ewal-base-palette))
               (colors (nth 3 form))
               (face-defs (nth 4 form)))
          (dolist (face faces)
            (pcase-let ((`(,foreground ,background)
                         (ewal-test--generated-theme-face-pair
                          face face-defs colors)))
              (let ((minimum (if (eq face 'cursor) 3.0 4.5)))
                (ert-info ((format "Face: %S (%s on %s)"
                                   face foreground background))
                  (should (ewal-color-valid-p foreground))
                  (should (ewal-color-valid-p background))
                  (should-not (ewal-color-equal-p foreground background))
                  (should (>= (ewal-color-contrast-ratio
                               foreground background)
                              minimum)))))))))))

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

(ert-deftest ewal-palettes-transient-dispatches-interactively ()
  "The optional palette wrapper should invoke the Transient command interactively."
  (let (called)
    (cl-letf (((symbol-function 'require)
               (lambda (feature &optional _filename _noerror)
                 (eq feature 'ewal-palette-transient)))
              ((symbol-function 'call-interactively)
               (lambda (command &rest _arguments)
                 (setq called command))))
      (ewal-palettes-transient))
    (should (eq called 'ewal-palettes-menu))))

;;; ewal-generator-and-palette-test.el ends here
