;;; yas-funcs.el --- Functions for yasnippets.  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Chris Barrett

;; Author: Chris Barrett <chris@walrus.cool>

;;; Commentary:

;;; Code:

(require 'dash)
(require 'f)
(require 's)
(require 'subr-x)
(require 'thingatpt)

;; Declaration of dynamic variable to satisfy byte-compiler.
(defvar yas-text nil)

(defun yas-funcs-bolp ()
  "Non-nil if point is on an empty line or at the first word.
The rest of the line must be blank."
  (s-matches? (rx bol (* space) (* word) (* space) eol)
              (buffer-substring (line-beginning-position) (line-end-position))))


;;; Haskell

(cl-defun yas-funcs-hs-constructor-name (&optional (text yas-text))
  (car (s-split (rx space) text)))



;;; Elisp

(defun yas-funcs-el-custom-group ()
  "Find the first group defined in the current file.
Fall back to the file name sans extension."
  (or
   (cadr (s-match (rx "(defgroup" (+ space) (group (+ (not
                                                       space))))
                  (buffer-string)))
   (cadr (s-match (rx ":group" (+ space) "'" (group (+ (any "-" alnum))))
                  (buffer-string)))
   (file-name-sans-extension (file-name-nondirectory buffer-file-name))))

(defun yas-funcs-el-autoload-file (sym)
  (if-let* ((file (symbol-file (if (stringp sym) (intern sym) sym))))
      (file-name-sans-extension (file-name-nondirectory file))
    ""))

(defun yas-funcs-el-at-line-above-decl-p ()
  (save-excursion
    (forward-line)
    (back-to-indentation)
    (thing-at-point-looking-at (rx (* space) "("
                                   (or "cl-defun" "defun" "defvar" "defconst"
                                       "define-minor-mode"
                                       "define-globalized-minor-mode"
                                       "define-derived-mode")))))



;;; JS

(cl-defun yas-funcs-js-module-name-for-binding (&optional (text yas-text))
  (pcase text
    ('nil      "")
    (""        "")
    ("Promise" "bluebird")
    ("assert"  "power-assert")
    ("_"       "lodash")

    ((guard (s-contains? "{" text))
     "")
    (s
     (s-downcase (s-dashed-words s)))))

(defun yas-funcs-js-ctor-body (argstring)
  (when argstring
    (thread-last argstring
      (s-split (rx (or "," ".")))
      (-map #'s-trim)
      (-remove #'s-blank?)
      (--map (format "this.%s = %s;" it it))
      (s-join "\n"))))


;;; Rust

(defun yas-funcs-rs-bol-or-after-access-kw-p ()
  (save-excursion
    (save-restriction
      ;; Move past access modifier.
      (goto-char (line-beginning-position))
      (search-forward-regexp (rx bow "pub" eow (* space)) (line-end-position) t)
      (narrow-to-region (point) (line-end-position))
      (yas-funcs-bolp))))

(defun yas-funcs-rs-relevant-struct-name ()
  "Search backward for the name of the last struct defined in this file."
  (save-match-data
    (if (search-backward-regexp (rx (or "enum" "struct") (+ space)
                                    (group (+ (not (any ";" "(" "{")))))
                                nil t)
        (s-trim (match-string 1))
      "Name")))


;;; Scala

(defun yas-funcs-scala-test-fixture-name ()
  (or (ignore-errors (f-filename (f-no-ext (buffer-file-name))))
      "TestFixture"))


(provide 'yas-funcs)

;;; yas-funcs.el ends here
