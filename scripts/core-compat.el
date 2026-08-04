;;; core-compat.el --- Verify dependency-free Ewal on Emacs 25.1 -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Compile the dependency-free Ewal core with warnings as errors and run the
;; core-only ERT subset.  `scripts/core-compat.sh' invokes this file from a
;; clean source tree inside the pinned Emacs 25.1 container.

;;; Code:

(require 'ert)
(require 'subr-x)

(defconst ewal-core-compat-root
  (file-name-directory
   (directory-file-name
    (file-name-directory (or load-file-name buffer-file-name))))
  "Repository root used by the core compatibility gate.")

(unless (string-prefix-p "25.1" emacs-version)
  (error "Core compatibility gate requires Emacs 25.1, got %s" emacs-version))

(add-to-list 'load-path ewal-core-compat-root)
(add-to-list 'load-path (expand-file-name "tests" ewal-core-compat-root))

(defconst ewal-core-compat-files
  '("ewal-color-utils.el"
    "ewal.el"
    "ewal-palette-utils.el"
    "ewal-theme-contrast-check.el"
    "uncustomized-faces.el"
    "ewal-uncustomized-faces.el")
  "Dependency-free libraries compiled by the Emacs 25.1 gate.")

(defconst ewal-core-compat-tests
  '("tests/ewal-color-utils-test.el"
    "tests/ewal-theme-contrast-check-test.el"
    "tests/ewal-release-metadata-test.el")
  "Core-only ERT files loaded by the Emacs 25.1 gate.")

(dolist (file ewal-core-compat-files)
  (let ((byte-compile-error-on-warn t))
    (unless (byte-compile-file (expand-file-name file ewal-core-compat-root))
      (error "Failed to compile %s" file))))

(dolist (file ewal-core-compat-tests)
  (load (expand-file-name file ewal-core-compat-root) nil nil t))

(princ (format "core-compat Emacs=%s Ewal=%s files=%d tests=%d\n"
               emacs-version ewal-version
               (length ewal-core-compat-files)
               (length ewal-core-compat-tests)))

(ert-run-tests-batch-and-exit t)

;;; core-compat.el ends here
