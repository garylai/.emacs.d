;;; cb-elisp.el --- Configuration for Emacs Lisp.  -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Chris Barrett

;; Author: Chris Barrett <chris+emacs@walrus.cool>

;;; Commentary:

;;; Code:

(eval-when-compile
  (require 'use-package)
  (require 'cb-use-package-extensions)
  (require 'flycheck))

(require 'spacemacs-keys)
(autoload 'evil-define-key "evil-core")

;; Print a message on `eval-buffer'.

(use-package elisp-mode
  :preface
  (defun cb-elisp--message-on-eval-buffer (&rest _)
    (when (called-interactively-p nil)
      (message "Buffer evaluated.")))

  :init
  (progn
    (spacemacs-keys-declare-prefix-for-mode 'emacs-lisp-mode "m e" "Eval")

    (spacemacs-keys-set-leader-keys-for-major-mode 'emacs-lisp-mode
      "eb" #'eval-buffer
      "ee" #'eval-expression))

  :config
  (advice-add #'eval-buffer :after #'cb-elisp--message-on-eval-buffer))


(use-package find-func
  :leader-bind
  (("hfl" . find-library)
   ("hff" . find-function)
   ("hfv" . find-variable)
   ("hfc" . find-face-definition)))

(use-package elisp-slime-nav
  :bind
  (:map emacs-lisp-mode-map
        ("M-." . elisp-slime-nav-find-elisp-thing-at-point))

  :evil-bind
  (:map emacs-lisp-mode-map
        :state normal
        ("M-." . elisp-slime-nav-find-elisp-thing-at-point)
        ("K" . elisp-slime-nav-describe-elisp-thing-at-point))

  :init
  (add-hook 'emacs-lisp-mode-hook #'turn-on-elisp-slime-nav-mode)

  :commands (turn-on-elisp-slime-nav-mode))

(use-package eldoc
  :defer t
  :init
  (add-hook 'emacs-lisp-mode-hook #'eldoc-mode))

(use-package nameless
  :commands nameless-mode
  :init
  (add-hook 'emacs-lisp-mode-hook #'nameless-mode)
  :config
  (progn
    (setq nameless-prefix ":")
    (setq nameless-private-prefix t)))

(use-package evil-surround
  :defer t
  :preface
  (defun cb-elisp--init-evil-surround-pairs ()
    (make-local-variable 'evil-surround-pairs-alist)
    (push '(?\` . ("`" . "'")) evil-surround-pairs-alist))
  :config
  (add-hook 'emacs-lisp-mode-hook #'cb-elisp--init-evil-surround-pairs))

(use-package cb-elisp-sp
  :after smartparens
  :preface
  (progn
    (autoload 'sp-local-pair "smartparens")
    (autoload 'sp-with-modes "smartparens"))
  :config
  (sp-with-modes '(emacs-lisp-mode)
    (sp-local-pair "\"" "\"" :post-handlers '(:add cb-elisp-sp-just-one-space))
    (sp-local-pair "{" "}"   :post-handlers '(:add cb-elisp-sp-just-one-space))
    (sp-local-pair "[" "]"   :post-handlers '(:add cb-elisp-sp-just-one-space))
    (sp-local-pair "(" ")"   :post-handlers '(:add cb-elisp-sp-just-one-space))
    (sp-local-pair "'" nil   :actions nil)))

(use-package cb-elisp-autoinsert
  :defer t
  :after autoinsert
  :config
  (add-to-list 'auto-insert-alist cb-elisp-autoinsert-form)
  :defines (auto-insert-alist))

;; Checkdoc configuration

(use-package flycheck
  :defer t
  :config
  (setq flycheck-emacs-lisp-checkdoc-form
        (flycheck-prepare-emacs-lisp-form
          (setq checkdoc-force-docstrings-flag nil)
          (setq checkdoc-arguments-in-order-flag nil)
          (let ((source (car command-line-args-left))
                ;; Remember the default directory of the process
                (process-default-directory default-directory))
            (with-temp-buffer
              (insert-file-contents source 'visit)
              (setq buffer-file-name source)
              ;; And change back to the process default directory to make file-name
              ;; back-substutition work
              (setq default-directory process-default-directory)
              (with-demoted-errors "Error in checkdoc: %S"
                (checkdoc-current-buffer t)
                (with-current-buffer checkdoc-diagnostic-buffer
                  (princ (buffer-substring-no-properties (point-min) (point-max)))
                  (kill-buffer)))))))

  :functions (flycheck-sexp-to-string))

(use-package checkdoc
  :defer t
  :config
  (progn
    (setq checkdoc-force-docstrings-flag nil)
    (setq checkdoc-arguments-in-order-flag nil)))

(provide 'cb-elisp)

;;; cb-elisp.el ends here
