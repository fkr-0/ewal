;;; ewal-release-metadata-test.el --- Release contract tests -*- lexical-binding: t; -*-

(require 'ert)
(require 'ewal)
(require 'subr-x)

(defconst ewal-release-test-root
  (file-name-directory
   (directory-file-name
    (file-name-directory (or load-file-name buffer-file-name))))
  "Repository root used by release metadata tests.")

(defun ewal-release-test--read-file (path)
  "Return repository-relative PATH as a string."
  (with-temp-buffer
    (insert-file-contents (expand-file-name path ewal-release-test-root))
    (buffer-string)))

(defun ewal-release-test--header-value (path header)
  "Return HEADER value from repository-relative PATH."
  (let ((contents (ewal-release-test--read-file path)))
    (when (string-match
           (format "^;; %s: \\(.+\\)$" (regexp-quote header))
           contents)
      (match-string 1 contents))))

(defun ewal-release-test--ewal-requirement (path)
  "Return the Ewal dependency version declared by repository-relative PATH."
  (let ((contents (ewal-release-test--read-file path)))
    (when (string-match "(ewal \"\\([0-9.]+\\)\")" contents)
      (match-string 1 contents))))

(ert-deftest ewal-release-version-is-canonical-and-semantic ()
  "VERSION, the core header, and `ewal-version' must agree."
  (let ((version (string-trim (ewal-release-test--read-file "VERSION"))))
    (should (string-match-p
             (rx string-start (+ digit) "." (+ digit) "." (+ digit)
                 string-end)
             version))
    (should (equal version ewal-version))
    (should (equal version
                   (ewal-release-test--header-value "ewal.el" "Version")))))

(ert-deftest ewal-release-package-dependency-floors-are-compatible ()
  "Maintained adaptors must require a compatible contrast-safe core release."
  (dolist (path '("doom-themes/ewal-doom-themes.el"
                  "doom-themes/ewal-doom-one-theme.el"
                  "doom-themes/ewal-doom-outrun-electric-theme.el"
                  "doom-themes/ewal-doom-tokyo-night-theme.el"
                  "doom-themes/ewal-doom-vibrant-theme.el"
                  "evil-cursors/ewal-evil-cursors.el"
                  "spacemacs-themes/ewal-spacemacs-themes.el"))
    (let ((requirement (ewal-release-test--ewal-requirement path)))
      (ert-info ((format "Package: %s" path))
        (should requirement)
        (should (version<= "0.3.0" requirement))
        (should (version<= requirement ewal-version))))))

(ert-deftest ewal-release-adaptor-versions-follow-repository-release ()
  "Primary Doom and Spacemacs adaptor packages must follow `ewal-version'."
  (dolist (path '("doom-themes/ewal-doom-themes.el"
                  "spacemacs-themes/ewal-spacemacs-themes.el"))
    (should (equal ewal-version
                   (ewal-release-test--header-value path "Version")))))

(ert-deftest ewal-release-supporting-documents-exist ()
  "Release, development, and planning documents must remain present."
  (dolist (path '("README.org" "CHANGELOG.md" "ROADMAP.md"
                  "release-evidence.yml" ".github/workflows/ci.yml"
                  "bridge.yml" "scripts/package-lint.el"
                  "scripts/package-smoke.sh" "scripts/core-compat.el"
                  "scripts/core-compat.sh"))
    (should (file-readable-p (expand-file-name path ewal-release-test-root)))))

(ert-deftest ewal-release-ci-actions-use-immutable-revisions ()
  "GitHub Actions must be pinned to full immutable commit hashes."
  (let ((workflow (ewal-release-test--read-file ".github/workflows/ci.yml"))
        (position 0)
        (pinned-count 0)
        (uses-count 0))
    (should-not
     (string-match-p "uses: [^\n]+@\\(?:master\\|main\\|v[0-9]+\\)\\s-*$"
                     workflow))
    (while (string-match "uses: [^\n]+@[0-9a-f]\\{40\\}" workflow position)
      (setq pinned-count (1+ pinned-count)
            position (match-end 0)))
    (setq position 0)
    (while (string-match "uses: [^\n]+" workflow position)
      (setq uses-count (1+ uses-count)
            position (match-end 0)))
    (should (>= uses-count 2))
    (should (= uses-count pinned-count))))

(ert-deftest ewal-release-core-floor-is-reproducible-and-immutable ()
  "The Emacs 25.1 core gate must use a digest-pinned container image."
  (let ((script (ewal-release-test--read-file "scripts/core-compat.sh"))
        (workflow (ewal-release-test--read-file ".github/workflows/ci.yml")))
    (should
     (string-match-p
      "silex/emacs@sha256:[0-9a-f]\\{64\\}"
      script))
    (should (string-match-p "Core Emacs 25\\.1" workflow))
    (should (string-match-p "sh scripts/core-compat\\.sh" workflow))))

(ert-deftest ewal-release-obsolete-migration-copies-stay-removed ()
  "Superseded local migration files must not return to the package tree."
  (dolist (path '("cc.el" "update-1.el" "update-2.el"))
    (should-not (file-exists-p (expand-file-name path ewal-release-test-root)))))

(ert-deftest ewal-release-transient-prefixes-stay-behind-wrappers ()
  "Transient prefix macros must not be expanded into generated autoload files."
  (dolist (path '("ewal-palette-transient.el"
                  "ewal-theme-contrast-panel.el"))
    (should-not
     (string-match-p
      ";;;###autoload[\n\r]+(transient-define-prefix"
      (ewal-release-test--read-file path)))))

;;; ewal-release-metadata-test.el ends here
