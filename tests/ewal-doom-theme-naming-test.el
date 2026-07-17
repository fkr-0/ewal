;;; ewal-doom-theme-naming-test.el --- Theme naming checks -*- lexical-binding: t; -*-

(require 'ert)

(defun ewal-test--file-string (path)
  "Return file content from PATH as a string."
  (with-temp-buffer
    (insert-file-contents path)
    (buffer-string)))

(ert-deftest ewal-doom-one-theme-name-is-stable ()
  "The doom-one file should define and provide `ewal-doom-one`."
  (let ((contents (ewal-test--file-string "doom-themes/ewal-doom-one-theme.el")))
    (should (string-match-p "(def-doom-theme\\s-+ewal-doom-one\\_>" contents))
    (should (string-match-p "(provide-theme\\s-+'ewal-doom-one\\_>" contents))))

(ert-deftest ewal-doom-vibrant-theme-name-is-stable ()
  "The doom-vibrant file should define and provide `ewal-doom-vibrant`."
  (let ((contents (ewal-test--file-string "doom-themes/ewal-doom-vibrant-theme.el")))
    (should (string-match-p "(def-doom-theme\\s-+ewal-doom-vibrant\\_>" contents))
    (should (string-match-p "(provide-theme\\s-+'ewal-doom-vibrant\\_>" contents))))

(ert-deftest ewal-doom-tokyo-night-theme-name-is-stable ()
  "The tokyo-night file should define and provide `ewal-doom-tokyo-night`."
  (let ((contents (ewal-test--file-string "doom-themes/ewal-doom-tokyo-night-theme.el")))
    (should (string-match-p "(def-doom-theme\\s-+ewal-doom-tokyo-night\\_>" contents))
    (should (string-match-p "(provide-theme\\s-+'ewal-doom-tokyo-night\\_>" contents))))

(ert-deftest ewal-doom-outrun-electric-theme-name-is-stable ()
  "The outrun-electric file should define and provide `ewal-doom-outrun-electric`."
  (let ((contents (ewal-test--file-string "doom-themes/ewal-doom-outrun-electric-theme.el")))
    (should (string-match-p "(def-doom-theme\\s-+ewal-doom-outrun-electric\\_>" contents))
    (should (string-match-p "(provide-theme\\s-+'ewal-doom-outrun-electric\\_>" contents))))

;;; ewal-doom-theme-naming-test.el ends here
