;;; paths.el --- Variables relating to core Emacs functionality. -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Chris Barrett

;; Author: Chris Barrett <chris+emacs@walrus.cool>

;;; Commentary:

;;; Code:

(require 'subr-x)
(require 'seq)



(defconst paths-cache-directory
  (concat user-emacs-directory ".cache"))

(defconst paths-autosave-directory
  (concat user-emacs-directory "autosave"))

(defconst paths-lisp-directory
  (concat user-emacs-directory "lisp"))

(defconst paths-elpa-directory
  (concat user-emacs-directory "elpa"))

(defconst paths-config-directory
  (concat user-emacs-directory "config"))

(defconst paths-themes-directory
  (concat user-emacs-directory "themes"))

(defconst paths-site-lisp-directory "~/.nix-profile/share/emacs/site-lisp")



(defun paths-initialise (&optional interactive-p)
  "Add select subdirs of `user-emacs-directory' to the `load-path'.

If argument INTERACTIVE-P is set, log additional information."
  (interactive "p")
  (let* ((before load-path)
         (git-subtrees
          (seq-filter #'file-directory-p
                      (directory-files paths-lisp-directory t "^[^.]")))
         (config-subtrees
          (seq-filter #'file-directory-p
                      (directory-files paths-config-directory t "^[^.]")))

         (updated-load-path
          (append (list
                   paths-lisp-directory
                   paths-config-directory
                   paths-themes-directory
                   paths-site-lisp-directory)
                  config-subtrees
                  git-subtrees
                  load-path)))

    (setq load-path (seq-filter #'file-directory-p updated-load-path))

    (when interactive-p
      (if-let* ((added (seq-difference load-path before)))
          (message "Load path updated. Added: %S" added)
        (message "No change to load-path")))))


(provide 'paths)

;;; paths.el ends here