;;; mu4e-hacks.el --- Hacks for mu4e.  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'el-patch)

(el-patch-feature mu4e)

(cl-eval-when (compile)
  (require 'mu4e))

(with-eval-after-load 'mu4e
  (el-patch-defun mu4e-context-label ()
    "Propertized string with the current context name, or \"\" if
  there is none."
    (if (el-patch-wrap 1 1 (and (mu4e-context-current)
                                (derived-mode-p 'mu4e-main-mode 'mu4e-headers-mode
                                                'mu4e-view-mode 'mu4e-compose-mode)))
        (concat "[" (propertize (mu4e~quote-for-modeline
                                 (mu4e-context-name (mu4e-context-current)))
                                'face 'mu4e-context-face) "]")
      ""))

  (el-patch-defun mu4e~main-view ()
    "Create the mu4e main-view, and switch to it."
    (if (eq mu4e-split-view 'single-window)
        (if (buffer-live-p (mu4e-get-headers-buffer))
            (switch-to-buffer (mu4e-get-headers-buffer))
          (mu4e~main-menu))
      (mu4e~main-view-real nil nil)
      ((el-patch-swap switch-to-buffer display-buffer) mu4e~main-buffer-name)
      (goto-char (point-min)))
    (add-to-list 'global-mode-string '(:eval (mu4e-context-label)))))

(provide 'mu4e-hacks)

;;; mu4e-hacks.el ends here