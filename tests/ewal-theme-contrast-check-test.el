;;; ewal-theme-contrast-check-test.el --- Tests for contrast reporting -*- lexical-binding: t; -*-

(require 'ert)
(require 'cl-lib)
(require 'ewal-theme-contrast-check)

(ert-deftest ewal-contrast-warnings-preview-empty ()
  "Preview should be empty when WARNINGS is nil."
  (should (string= (ewal-contrast-warnings-preview nil) "")))

(ert-deftest ewal-contrast-warnings-preview-honors-limit ()
  "Preview should include only LIMIT warnings."
  (let* ((warnings '((face-a "#111111" "#222222" 1.20)
                      (face-b "#333333" "#444444" 1.80)
                      (face-c "#555555" "#666666" 2.40)))
         (preview (ewal-contrast-warnings-preview warnings 2)))
    (should (string-match-p "^face-a\\s-+1\\.20\\s-+#111111\\s-+on\\s-+#222222" preview))
    (should (string-match-p "^face-b\\s-+1\\.80\\s-+#333333\\s-+on\\s-+#444444" preview))
    (should-not (string-match-p "face-c" preview))))

(ert-deftest ewal-contrast-warnings-preview-default-limit ()
  "Default preview limit should include up to five rows."
  (let* ((warnings (mapcar (lambda (n)
                             (list (intern (format "face-%d" n))
                                   "#111111" "#ffffff" (+ 1.0 (* n 0.1))))
                           (number-sequence 1 6)))
         (preview (ewal-contrast-warnings-preview warnings)))
    (should (string-match-p "face-5" preview))
    (should-not (string-match-p "face-6" preview))))

(ert-deftest ewal-display-contrast-warnings-adds-preview-overlays ()
  "Rendered warning rows should include overlays for fg/bg preview."
  (let ((warnings '((sample-face "#111111" "#222222" 1.2))))
    (ewal-display-contrast-warnings warnings)
    (with-current-buffer "*Theme Contrast Warnings*"
      (should (search-forward "Preview" nil t))
      (goto-char (point-min))
      (should-not (search-forward "low-contrast sample" nil t))
      (should (> (length (overlays-in (point-min) (point-max))) 0)))))

(ert-deftest ewal-build-autocorrections-finds-improved-replacement ()
  "Autocorrection should propose a better single-property replacement."
  (let* ((ewal-base-palette '((background . "#101010")
                               (foreground . "#121212")
                               (accent . "#ffffff")))
          (warnings '((sample-face "#111111" "#121212" 1.01)))
          (corrections (ewal-build-autocorrections warnings 4.5))
          (entry (car corrections)))
    (should (= (length corrections) 1))
    (should (memq (nth 4 entry) '(:foreground :background)))
    (should (stringp (nth 5 entry)))
    (should (> (nth 6 entry) (nth 3 entry)))))

(ert-deftest ewal-contrast-store-override-merges-face-properties ()
  "Overrides should merge properties for same theme/face."
  (let ((ewal-contrast-user-overrides nil))
    (ewal-contrast-store-override
     'sample-theme 'sample-face '((:foreground . "#123456")))
    (ewal-contrast-store-override
     'sample-theme 'sample-face '((:background . "#abcdef")))
    (let* ((theme (assoc 'sample-theme ewal-contrast-user-overrides))
           (face (assoc 'sample-face (cdr theme)))
           (plist (cdr face)))
      (should (equal (plist-get plist :foreground) "#123456"))
      (should (equal (plist-get plist :background) "#abcdef")))))

(ert-deftest ewal-contrast-overrides-use-package-sexp-includes-data ()
  "Generated snippet should include use-package and stored overrides."
  (let ((ewal-contrast-user-overrides
         '((sample-theme . ((sample-face . (:foreground "#111111")))))))
    (let ((snippet (ewal-contrast-overrides-use-package-sexp)))
      (should (string-match-p "(use-package ewal-theme-contrast-check" snippet))
      (should (string-match-p "setq ewal-contrast-user-overrides\\s-+'\\(\\|\\s-\\)*((sample-theme" snippet))
      (should (string-match-p "sample-theme" snippet))
      (should (string-match-p "sample-face" snippet)))))

(ert-deftest ewal-contrast-cycle-strategy-rotates-values ()
  "Strategy cycle should rotate default -> palette -> black-white -> default."
  (let ((ewal-contrast-suggestion-strategy 'default))
    (cl-letf (((symbol-function 'ewal-contrast-preview-suggestions) (lambda (&rest _) nil)))
      (ewal-contrast-cycle-strategy)
      (should (eq ewal-contrast-suggestion-strategy 'palette))
      (ewal-contrast-cycle-strategy)
      (should (eq ewal-contrast-suggestion-strategy 'black-white))
      (ewal-contrast-cycle-strategy)
      (should (eq ewal-contrast-suggestion-strategy 'default)))))

(ert-deftest ewal-contrast-panel-wrapper-dispatches-interactively ()
  "The optional contrast wrapper should invoke its Transient command interactively."
  (let (called)
    (cl-letf (((symbol-function 'require)
               (lambda (feature &optional _filename _noerror)
                 (eq feature 'ewal-theme-contrast-panel)))
              ((symbol-function 'call-interactively)
               (lambda (command &rest _arguments)
                 (setq called command))))
      (ewal-check-contrast-panel))
    (should (eq called 'ewal-theme-contrast-panel))))

;;; ewal-theme-contrast-check-test.el ends here
