;;; config-eshell.el --- Configuration for eshell.  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(eval-when-compile
  (require 'use-package))

(require 'dash)
(require 'eshell-hacks)
(require 'f)
(require 'general)
(require 'paths)

(defconst config-eshell-etc-directory (f-join paths-etc-directory "eshell"))
(autoload 'evil-local-set-key "evil-core")
(autoload 'page-break-lines-mode "page-break-lines")



;; eshell implements a shell in emacs lisp.

(use-package eshell
  :commands (eshell)

  :preface
  (progn
    ;; HACK eshell mode map is set as a local variable in its mode function.
    ;; deep cry. ( -̩̩̩͡˛ -̩̩̩͡ )
    (defun config-eshell-setup-keybindings ()
      (evil-local-set-key 'insert (kbd "C-e") 'end-of-line)
      (evil-local-set-key 'insert (kbd "C-a") 'eshell-bol)))

  :config
  (progn
    (require 'pusheen)
    (setq eshell-banner-message (format "%13s\n%15s\n\n" (pusheen 'winky)
                                        (propertize "O hai!" 'face '(:height 400))))
    (add-hook 'eshell-mode-hook #'config-eshell-setup-keybindings)
    (add-hook 'eshell-mode-hook #'pusheen-animate-all)

    ;; keep aliases under etc directory, which is tracked by git.

    (f-mkdir config-eshell-etc-directory)
    (general-setq eshell-aliases-file (f-join config-eshell-etc-directory  "aliases"))))

;; fasd teaches Emacs to update to fasd cache as files and dirs are opened.

(use-package fasd
  :straight
  (:type git :repo "https://framagit.org/steckerhalter/emacs-fasd.git")
  :config
  (progn
    ;; Add recentf list to fasd DB.
    (apply #'start-process "*fasd*" nil "fasd" "--add" (seq-map #'shell-quote-argument recentf-list))
    (global-fasd-mode +1)))

;; pretty-eshell defines some utility fns for building a nice prompt.

(use-package pretty-eshell
  :after eshell
  :preface
  (progn
    (defface eshell-dimmed
      '((t :inherit default))
      "Face for dimmed text in eshell."
      :group 'config-eshell)

    (defface eshell-timestamp
      '((t :inherit eshell-dimmed :height 0.7))
      "Face for timestamps in eshell."
      :group 'config-eshell)

    (defun config-eshell--dim-commands-on-submission ()
      (let ((start eshell-last-output-start)
            (end (line-end-position)))
        (let ((inhibit-read-only t))
          (save-excursion
            (goto-char start)
            (search-forward "\u000c")
            (put-text-property (point) end 'face 'eshell-dimmed)))))

    (defun config-eshell--inhibit-submission-on-empty (f &rest args)
      (let* ((start eshell-last-output-end)
             (end (line-end-position))
             (input (buffer-substring-no-properties start end)))
        (if (string-empty-p (string-trim input))
            (delete-region start end)
          (config-eshell--dim-commands-on-submission)
          (apply f args)))))

  :config
  (progn
    ;; Show a horizontal rule and timestamp between commands.

    (defvar-local config-eshell--previous-time nil)

    (setq pretty-eshell-header-fun
          (let ((page-break "\u000c")
                (horizontal-tab "\u0009"))
            (lambda ()
              (let* ((time (format-time-string "%H:%M" (current-time)))
                     (timestamp (concat
                                 horizontal-tab
                                 (propertize time 'face 'eshell-timestamp))))
                (prog1 (concat timestamp "\n" page-break "\n")
                  (setq config-eshell--previous-time time))))))

    (add-hook 'eshell-mode-hook 'page-break-lines-mode)

    ;; Prevent command submission if there's no text to submit.

    (advice-add 'eshell-send-input :around #'config-eshell--inhibit-submission-on-empty)

    ;; Change the prompt, depending on the previous command's exit code.

    (setq eshell-prompt-function 'pretty-eshell-prompt-func)
    (setq pretty-eshell-prompt-string-fun (lambda ()
                                            (concat " " (if (eshell-exit-success-p)
                                                            ">"
                                                          (propertize "✘" 'face 'error))
                                                    " ")))
    (setq eshell-prompt-regexp (rx bol (* space) (or ">" "✘") space))

    ;; Customise the prompt header.

    ;; Directory
    (pretty-eshell-define-section config-eshell-dir
      ""
      (abbreviate-file-name (eshell/pwd))
      '(:inherit eshell-ls-directory :weight light))

    ;; NOTE: Load just this feature, instead of all of magit.
    (autoload 'magit-get-current-branch "magit-git")
    (autoload 'magit-process-file "magit-process")

    ;; Git Branch
    (pretty-eshell-define-section config-eshell-git
      ""
      (magit-get-current-branch)
      '(:foreground "#cb4b16" :weight light))

    (setq pretty-eshell-funcs (list config-eshell-dir config-eshell-git))))


;; Horrific hack to right-align the timestamp in the eshell prompt using C-i
;; control character.
;;
;; Adapted from the implementation of page-break-lines.

(defun eshell-timestamp--update-display-table (window)
  ;; KLUDGE: Make sure page-break-lines recomposition is applied appropriately.
  (page-break-lines--update-display-table window)
  (with-current-buffer (window-buffer window)
    (with-selected-window window
      (unless buffer-display-table
        (setq buffer-display-table (make-display-table)))
      (let* ((space-char 32)
             (timestamp-width 5) ; HH:MM
             (spaces-count (- (1+ (window-width)) timestamp-width))
             (width (* (char-width space-char) spaces-count))
             (new-display-entry (vconcat (make-list width space-char))))
        (unless (equal new-display-entry (elt buffer-display-table ?\^I))
          (aset buffer-display-table ?\^I new-display-entry))))))

(defun eshell-timestamp--update-display-tables  (&optional frame)
  (unless (minibufferp)
    (mapc 'eshell-timestamp--update-display-table
          (window-list frame 'no-minibuffer))))

(defun eshell-timestamp--configure-hooks ()
  (dolist (hook '(window-configuration-change-hook
                  window-size-change-functions
                  after-setting-font-hook))
    (add-hook hook 'eshell-timestamp--update-display-tables t t)))

(add-hook 'eshell-mode-hook #'eshell-timestamp--configure-hooks)



;; proced provides a top-like process manager.

(use-package proced
  :commands (proced)
  :general
  (:keymaps 'proced-mode-map
   :states 'normal
   "r" 'proced-refine
   "R" 'proced-renice)
  :config
  (progn
    (setf (nth 1 (alist-get 'comm proced-grammar-alist))
          "%-20s")

    (setq-default proced-format
                  '(comm pid state pcpu vsize pmem user))))

;; eshell functions are defined in this lib.

(use-package cb-eshell-funcs
  :after eshell)

(provide 'config-eshell)

;;; config-eshell.el ends here
