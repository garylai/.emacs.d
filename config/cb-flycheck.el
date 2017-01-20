;;; cb-flycheck.el --- Flycheck configuration. -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Chris Barrett

;; Author: Chris Barrett <chris+emacs@walrus.cool>

;;; Commentary:

;;; Code:

(eval-when-compile
  (require 'use-package))

(autoload 'evil-define-key "evil-core")

(require 'spacemacs-keys)

(use-package flycheck
  :ensure t ; load with package.el
  :defer 1
  :commands (global-flycheck-mode)

  :init
  (spacemacs-keys-declare-prefix "e" "errors")

  :config
  (progn
    (global-flycheck-mode +1)

    (setq flycheck-display-errors-function 'flycheck-display-error-messages-unless-error-list)
    (setq flycheck-display-errors-delay 0.5)
    (setq flycheck-emacs-lisp-load-path 'inherit)

    (setq flycheck-global-modes
          '(not sbt-file-mode
                ;; restclient buffers
                js-mode))

    (spacemacs-keys-set-leader-keys
      "ec" 'flycheck-clear
      "eh" 'flycheck-describe-checker
      "el" 'flycheck-list-errors
      "ee" 'flycheck-explain-error-at-point
      "en" 'flycheck-next-error
      "eN" 'flycheck-next-error
      "ep" 'flycheck-previous-error
      "es" 'flycheck-select-checker
      "eS" 'flycheck-set-checker-executable
      "ev" 'flycheck-verify-setup)

    (with-eval-after-load 'evil
      (evil-define-key 'normal flycheck-error-list-mode-map (kbd "q") #'quit-window))

    (bind-key "M-n" 'flycheck-next-error flycheck-mode-map)
    (bind-key "M-p" 'flycheck-previous-error flycheck-mode-map)
    (bind-key "M-j" 'flycheck-next-error flycheck-mode-map)
    (bind-key "M-k" 'flycheck-previous-error flycheck-mode-map)

    (add-to-list 'display-buffer-alist
                 `(,(rx bos "*Flycheck errors*" eos)
                   (display-buffer-reuse-window
                    display-buffer-in-side-window)
                   (reusable-frames . visible)
                   (side            . bottom)
                   (window-height   . 0.2)))))

(provide 'cb-flycheck)

;;; cb-flycheck.el ends here
