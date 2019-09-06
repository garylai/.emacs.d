;;; flycheck-posframe-hacks.el --- Hacks for flycheck-posframe  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'el-patch)

(el-patch-feature flycheck-posframe)

(defvar flycheck-posframe-override-parameters nil)
(defvar flycheck-posframe-internal-border-width nil)


;; Provide a nice way to override posframe parameters.

(with-eval-after-load 'flycheck-posframe
  (with-no-warnings
    (el-patch-defun flycheck-posframe-show-posframe (errors)
      "Display ERRORS, using posframe.el library."
      (flycheck-posframe-hide-posframe)
      (when (and errors
                 (not (run-hook-with-args-until-success 'flycheck-posframe-inhibit-functions)))
        (let ((poshandler (intern (format "posframe-poshandler-%s" flycheck-posframe-position))))
          (unless (functionp poshandler)
            (setq poshandler nil))
          (posframe-show
           flycheck-posframe-buffer
           :string (flycheck-posframe-format-errors errors)
           :background-color (face-background 'flycheck-posframe-background-face nil t)
           :position (point)
           :internal-border-width flycheck-posframe-border-width :internal-border-color
           (face-foreground 'flycheck-posframe-border-face nil t)
           :poshandler poshandler
           (el-patch-add
             :internal-border-width flycheck-posframe-internal-border-width
             :override-parameters flycheck-posframe-override-parameters)))
        (dolist (hook flycheck-posframe-hide-posframe-hooks)
          (add-hook hook #'flycheck-posframe-hide-posframe nil t))))))

(provide 'flycheck-posframe-hacks)

;;; flycheck-posframe-hacks.el ends here
