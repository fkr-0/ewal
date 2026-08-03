;;; package-lint.el --- Lint Ewal package boundaries -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Repository-local package-lint entrypoint.  Ewal is a multi-package tree, so
;; the core and each published adaptor must be linted as its own package file.

;;; Code:

(require 'package)
(require 'package-lint)

(defconst ewal-package-lint-files
  '("ewal.el"
    "doom-themes/ewal-doom-themes.el"
    "spacemacs-themes/ewal-spacemacs-themes.el"
    "evil-cursors/ewal-evil-cursors.el")
  "Published package entrypoints checked by package-lint.")

(defun ewal-package-lint--descriptor (file)
  "Return the package descriptor declared by FILE."
  (with-temp-buffer
    (insert-file-contents file)
    (package-buffer-info)))

;; Adaptors depend on the core package from this same repository.  Register its
;; local descriptor so package-lint can validate the version floor without
;; requiring a previously published archive release.
(setf (alist-get 'ewal package-alist)
      (list (ewal-package-lint--descriptor "ewal.el")))

;; The historical package name `ewal-spacemacs-themes' necessarily includes
;; “emacs”; retain compatibility and report that naming warning without making
;; warnings fatal.  All package-lint errors remain release-blocking.
(let ((package-lint-batch-fail-on-warnings nil))
  (unless (package-lint-batch-and-exit-1 ewal-package-lint-files)
    (kill-emacs 1)))

;;; package-lint.el ends here
