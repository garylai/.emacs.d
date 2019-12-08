;;; config-terminal.el --- Config for terminal emulators.  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(eval-when-compile
  (require 'use-package))

(use-package vterm
  :straight t
  :general
  (:keymaps 'vterm-mode-map :states 'normal "P" 'vterm-yank)
  (:keymaps 'vterm-mode-map :states '(normal insert) "s-v" 'vterm-yank)
  :config
  ;; Prevent vterm from handling function keys.
  (dotimes (n 12)
    (define-key vterm-mode-map (kbd (format "<f%s>" (1+ n))) nil)))

(use-package vterm-toggle
  :straight (:host github :repo "jixiuf/vterm-toggle")
  :general ("<f10>" #'vterm-toggle
            "<S-f10>" #'vterm-toggle-cd))

(provide 'config-terminal)

;;; config-terminal.el ends here
