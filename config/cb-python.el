;;; cb-python.el --- Configuration for python.  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(eval-when-compile
  (require 'use-package))

(require 'cb-emacs)
(require 'spacemacs-keys)
(require 'evil)
(autoload 'xref-push-marker-stack "xref")

(use-package python
  :defer t
  :preface
  (progn
    (autoload 'python-indent-dedent-line "python")
    (autoload 'sp-backward-delete-char "smartparens")

    (defun cb-python--init-python-mode ()
      (setq-local tab-width 4)
      (setq-local evil-shift-width 4))

    (defun cb-python-backspace ()
      (interactive)
      (if (equal (char-before) ?\s)
          (unless (python-indent-dedent-line)
            (backward-delete-char-untabify 1))
        (sp-backward-delete-char))))

  :init
  (add-hook 'python-mode-hook #'cb-python--init-python-mode)

  :config
  (progn
    (setq python-indent-guess-indent-offset nil)
    (setq python-indent-offset 4)
    (define-key python-mode-map [remap python-indent-dedent-line-backspace]  #'cb-python-backspace)))

(with-eval-after-load 'which-key
  (with-no-warnings
    (push `((nil . ,(rx bos "anaconda-mode-" (group (+ nonl)))) . (nil . "\\1"))
          which-key-replacement-alist)))

(with-eval-after-load 'flycheck
  (with-no-warnings
    (setq flycheck-python-pycompile-executable "python3")))

(use-package anaconda-mode
  :ensure t
  :commands (anaconda-mode)
  :preface
  (progn
    (autoload 'anaconda-mode-find-definitions "anaconda-mode")

    (defun cb-python--push-mark (&rest _)
      (xref-push-marker-stack)))

  :init
  (progn
    (add-hook 'python-mode-hook 'anaconda-mode)
    (add-hook 'python-mode-hook 'anaconda-eldoc-mode))
  :config
  (progn
    (setq anaconda-mode-installation-directory
          (f-join cb-emacs-cache-directory "anaconda-mode"))

    ;; Main keybindings

    (spacemacs-keys-set-leader-keys-for-major-mode 'python-mode
      "a" 'anaconda-mode-find-assignments
      "b" 'anaconda-mode-go-back
      "r" 'anaconda-mode-find-references)

    (evil-define-key 'normal anaconda-mode-map (kbd "K") #'anaconda-mode-show-doc)
    (evil-define-key 'normal anaconda-mode-map (kbd "M-.") #'anaconda-mode-find-definitions)
    (evil-define-key 'normal anaconda-mode-map (kbd "M-,") #'pop-tag-mark)
    (define-key anaconda-mode-map (kbd "M-.") #'anaconda-mode-find-definitions)
    (define-key anaconda-mode-map (kbd "M-,") #'pop-tag-mark)

    (evil-set-initial-state 'anaconda-mode-view-mode 'motion)
    (evil-define-key 'motion anaconda-mode-view-mode-map (kbd "q") 'quit-window)

    ;; Advice

    (advice-add 'anaconda-mode-find-assignments :before #'cb-python--push-mark)
    (advice-add 'anaconda-mode-find-definitions :before #'cb-python--push-mark)))

(use-package company-anaconda
  :ensure t
  :defer t
  :preface
  (defun cb-python--enable-company-anaconda ()
    (with-no-warnings
      (add-to-list 'company-backends 'company-anaconda)))
  :config
  (add-hook 'anaconda-mode-hook #'cb-python--enable-company-anaconda))

;; pip install isort

(use-package py-isort
  :defer t
  :after 'python
  :init
  (add-hook 'before-save-hook 'py-isort-before-save))

;; pip install yapf

(use-package py-yapf
  :defer t
  :after 'python
  :init
  (add-hook 'python-mode-hook 'py-yapf-enable-on-save))


(provide 'cb-python)

;;; cb-python.el ends here
