;;; config-themes.el --- Typeface and syntax highlighting config.  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(eval-when-compile
  (require 'use-package))

(require 'parameters)

(use-package menu-bar
  :general ("C-c e e" #'toggle-debug-on-error))

;; page-break-lines shows a horizontal separator in buffers instead of a
;; page-break control character (^L).

(use-package page-break-lines
  :commands (global-page-break-lines-mode)
  :demand t
  :config
  (progn
    (setq page-break-lines-modes
          '(prog-mode
            ibuffer-mode
            text-mode
            ledger-report-mode
            compilation-mode
            help-mode
            org-agenda-mode))

    (global-page-break-lines-mode)))

;; paren-face applies a separate face for parens, allowing them to be
;; de-emphasised.

(use-package paren-face
  :hook (after-init . global-paren-face-mode)
  :config
  (progn
    (set-face-attribute 'parenthesis nil
                        :inherit 'font-lock-comment-face
                        :weight 'light
                        :italic nil
                        :background nil)

    (add-to-list 'paren-face-modes 'scala-mode)
    (add-to-list 'paren-face-modes 'js-mode)
    (add-to-list 'paren-face-modes 'typescript-mode)
    (add-to-list 'paren-face-modes 'rust-mode)
    (add-to-list 'paren-face-modes 'yaml-mode)

    (setq paren-face-regexp (rx (any "{}();,")))

    (font-lock-add-keywords 'js-mode `((,(rx (any ":")) 0 'parenthesis)))
    (font-lock-add-keywords 'typescript-mode `((,(rx (any ":")) 0 'parenthesis)))

    (font-lock-add-keywords 'rust-mode
                    `(;; Type assertions
                      (,(rx (any ":")) 0 'parenthesis)
                      ;; Generic type parameters
                      (,(rx (group "<") symbol-start) 1 'parenthesis)
                      (,(rx symbol-end (group (+ ">"))) 1 'parenthesis)
                      ;; Lambda parameter delimiters
                      (,(rx (group "|") (not (any "|"))) 1 'parenthesis)))

    (font-lock-add-keywords 'scala-mode
                    `(;; Type assertions
                      (,(rx (any ":")) 0 'parenthesis)
                      ;; Generic type parameters
                      (,(rx (group "[") symbol-start) 1 'parenthesis)
                      (,(rx symbol-end (group (+ "]"))) 1 'parenthesis)))))

;; hl-todo applies a separate face for todo keywords so they can be highlighted.

(use-package hl-todo
  :hook (prog-mode . hl-todo-mode)

  :preface
  (defun config-themes--enable-hl-todo-unless-org-buffer ()
    (unless (derived-mode-p 'org-mode)
      (hl-todo-mode)))

  :init
  (progn
    (setq hl-todo-keyword-faces
          (--map (cons it 'hl-todo)
                 '("TODO"
                   "NEXT"
                   "HACK"
                   "FIXME"
                   "KLUDGE"
                   "PATCH"
                   "NOTE")))
    (add-hook 'text-mode-hook #'config-themes--enable-hl-todo-unless-org-buffer)))

;; all-the-icons provides a set of icons that can be rendered by Emacs.

(use-package all-the-icons
  :defer t
  :init
  (defvar all-the-icons-scale-factor 1.0)
  :config
  (progn
    ;; HACK: Declare variable which is unsafely referenced inside lib.
    (defvar web-mode-content-type nil)
    (dolist (spec '((nix-mode all-the-icons-faicon "linux" :face all-the-icons-purple)
                    (ledger-mode all-the-icons-material "account_balance")
                    (makefile-mode all-the-icons-fileicon "gnu" :face all-the-icons-dorange)
                    (makefile-bsdmake-mode all-the-icons-fileicon "gnu" :face all-the-icons-dorange)
                    (gfm-mode all-the-icons-faicon "github-alt" :v-adjust 0.0 :face all-the-icons-lblue)
                    (helpful-mode all-the-icons-icon-for-mode help-mode)
                    (debugger-mode all-the-icons-faicon "stack-overflow" :v-adjust 0.05 :face all-the-icons-pink)))
      (add-to-list 'all-the-icons-mode-icon-alist spec))))

;; hydra provides keyboard-driven UI elements.

(use-package hydra
  :preface
  (defun config-themes--set-up-hydra-buffer (&rest _)
    (when-let* ((buf (get-buffer " *LV*")))
      (when (buffer-live-p buf)
        (with-current-buffer buf
          (setq-local mode-line-format nil)
          (setq-local header-line-format nil)
          (force-mode-line-update)))))
  :config
  (advice-add 'lv-window :after #'config-themes--set-up-hydra-buffer))

;; which-key displays available key bindings under the current prefix.

(use-package which-key
  :defer t
  :hook (after-init . which-key-mode)
  :config
  (progn
    (setq which-key-idle-delay 0.4)
    (setq which-key-replacement-alist
          (let ((custom-regex
                 (rx bos
                     ;; strip hydra prefix
                     (? (and (+? nonl) "/"))
                     (? (or
                         ;; feature names
                         "counsel"
                         "evil")
                        "-")
                     (group (+ nonl)))))
            `((("<left>") . ("←"))
              (("<right>") . ("→"))
              (("<\\([[:alnum:]-]+\\)>") . ("\\1"))
              ((nil . "Prefix Command") . (nil . "prefix"))
              ((nil . "\\`\\?\\?\\'") . (nil . "lambda"))
              ((nil . "which-key-show-next-page-no-cycle") . (nil . "wk next pg"))
              ((nil . ,custom-regex) . (nil . "\\1")))))))

;; prettify-symbols-mode allows characters to be displayed in a different way.

(use-package prettify-symbols-mode
  :hook (prog-mode . prettify-symbols-mode)
  :preface
  (defun config-themes--set-up-prettify-symbols ()
    (cond
     ((derived-mode-p 'emacs-lisp-mode 'lisp-mode 'scheme-mode)
      (setq-local prettify-symbols-alist '(("lambda" . ?λ))))))
  :config
  (add-hook 'prettify-symbols-mode-hook #'config-themes--set-up-prettify-symbols))

;; emojify adds support for rendering emojis.

(use-package emojify
  :hook (after-init . global-emojify-mode)
  :custom
  ((emojify-emoji-styles '(github unicode))
   (emojify-program-contexts '(comments string))
   (emojify-point-entered-behaviour 'uncover)
   (emojify-user-emojis
    '((":check:" . (("emoji" . ":white_check_mark:")
                    ("name" . "White Heavy Check Mark")
                    ("unicode" . "✅")
                    ("image" . "2705.png")
                    ("style" . "github"))))))
  :preface
  (defun config-themes-at-org-drawer-p (_match beg _end)
    (when (memq major-mode '(org-mode org-agenda-mode))
      (save-excursion
        (goto-char (line-beginning-position))
        (or (org-at-drawer-p) (org-at-property-p)))))
  :config
  (add-to-list 'emojify-inhibit-functions #'config-themes-at-org-drawer-p))

;; doom-modeline is a custom modeline.

(use-package doom-modeline
  :hook (after-init . doom-modeline-mode)
  :custom ((doom-modeline-major-mode-icon nil)
           (doom-modeline-buffer-encoding nil)
           (doom-modeline-icon t)
           (doom-modeline-enable-word-count t))
  :preface
  (defun config-themes--update-all-modelines ()
    "Ensure we update the header line in addition to the mode-line."
    (force-mode-line-update t))

  :config
  (progn
    (defun config-themes--right-top-window-p (must-be-fullscreen-p)
      (--find (and (if must-be-fullscreen-p (frame-parameter it 'fullscreen) t)
                   (or (equal 1 (length (window-list it 'never)))
                       (and (window-at-side-p (selected-window) 'right)
                            (window-at-side-p (selected-window) 'top))))
              (frame-list)))

    (setq org-clock-clocked-in-display nil)
    (add-hook 'org-clock-out-hook #'config-themes--update-all-modelines)
    (add-hook 'org-clock-in-hook #'config-themes--update-all-modelines)
    (add-hook 'org-clock-cancel-hook #'config-themes--update-all-modelines)

    (doom-modeline-def-segment org-clock
      (when (and (fboundp 'org-clocking-p) (org-clocking-p) (config-themes--right-top-window-p nil))
        (propertize (concat (org-clock-get-clock-string)
                            (doom-modeline-spc))
                    'face 'org-agenda-clocking)))

    (doom-modeline-def-segment space
      (doom-modeline-spc))

    (doom-modeline-def-segment system
      "Mode line construct for miscellaneous information.
By default, this shows the information specified by `global-mode-string'."
      (when (config-themes--right-top-window-p t)
        (let ((time (string-join (-map (-compose #'string-trim #'format-time-string)
                                       '("%a" "%e" "%b %R")) " ")))
          (propertize (concat (doom-modeline-spc) time (doom-modeline-spc))
                      'face `(:background ,(face-background 'region))))))

    ;; override default modeline
    (doom-modeline-def-modeline 'main
      '(bar workspace-name window-number modals matches buffer-info remote-host buffer-position parrot selection-info)
      '(objed-state misc-info persp-name grip irc github debug lsp minor-modes input-method indent-info buffer-encoding
                    ;; major-mode
                    process vcs
                    checker
                    space
                    org-clock
                    system))))

;; `hide-mode-line' provides a mode that hides the modeline.

(use-package hide-mode-line
  :hook (doom-modeline-mode . global-hide-mode-line-mode)
  :custom ((hide-mode-line-excluded-modes nil)))

;; doom-themes provides the main doom theme sets.

(use-package doom-themes
  :defer t
  :hook (after-init . (lambda () (require 'doom-themes)))
  :init
  (general-setq doom-themes-enable-bold t
                doom-themes-enable-italic t)
  :init
  (defface posframe-border
    '((t ()))
    "Face for posframe borders."
    :group 'config-themes)

  :preface
  (progn
    (defun config-themes-dark ()
      (config-themes-toggle 'doom-one))

    (defun config-themes-light ()
      (config-themes-toggle 'doom-solarized-light))

    (defun config-themes-set-extends-attrs ()
      ;; KLUDGE: Emacs 27 changes the default behaviour of faces so they don't
      ;; extend to the end of the line unless the `:extend' attribute is set.
      ;; Update some common faces to use this.
      (when (>= emacs-major-version 27)
        (dolist (face (face-list))
          (when (or (memq face '(org-quote
                                 org-block
                                 markdown-code-face
                                 hl-line
                                 ledger-font-xact-highlight-face))
                    (string-match-p (rx (or "region" "magit" "ediff" "diff" "highlight" "selection"))
                                    (symbol-name face)))
            (set-face-attribute face nil :extend t)))))

    (defun config-themes-toggle (&optional theme)
      (interactive)
      (let* ((current-theme (car custom-enabled-themes))
             (new-theme (or theme (if (equal 'doom-one current-theme)
                                      'doom-solarized-light
                                    'doom-one))))
        (enable-theme new-theme)
        (config-themes-override-themes new-theme)
        (config-themes-set-extends-attrs))
      ;; HACK: Make sure bullets are re-fontified.
      (when (bound-and-true-p org-bullets-mode)
        (font-lock-ensure)))

    (defun config-themes-override-themes (theme)
      (let* ((bg         (pcase theme
                           ('doom-solarized-light "#FDF6E3")
                           ('doom-one "#282c34")))
             (bg-alt     (pcase theme
                           ('doom-solarized-light "#FFFBEA")
                           ('doom-one "#21242b")))
             (base0      (pcase theme
                           ('doom-solarized-light "#FFFBF0")
                           ('doom-one "#1B2229")))
             (base1      (pcase theme
                           ('doom-solarized-light "#FCF8ED")
                           ('doom-one "#1c1f24")))
             (base2      (pcase theme
                           ('doom-solarized-light "#FCF7E8")
                           ('doom-one "#202328")))
             (base3      (pcase theme
                           ('doom-solarized-light "#F2E6CE")
                           ('doom-one "#23272e")))
             (base4      (pcase theme
                           ('doom-solarized-light "#E1DBCD")
                           ('doom-one "#3f444a")))
             (base5      (pcase theme
                           ('doom-solarized-light "#D6D6D6")
                           ('doom-one "#5B6268")))
             (base6      (pcase theme
                           ('doom-solarized-light "#96A7A9")
                           ('doom-one "#73797e")))
             (base7      (pcase theme
                           ('doom-solarized-light "#788484")
                           ('doom-one "#9ca0a4")))
             (base8      (pcase theme
                           ('doom-solarized-light "#626C6C")
                           ('doom-one "#DFDFDF")))
             (fg         (pcase theme
                           ('doom-solarized-light "#556b72")
                           ('doom-one "#bbc2cf")))
             (fg-alt     (pcase theme
                           ('doom-solarized-light "#7B8787")
                           ('doom-one "#5B6268")))
             (bg-alt-l   (pcase theme
                           ('doom-solarized-light (doom-darken bg 0.05))
                           ('doom-one bg-alt)))
             (green      (pcase theme
                           ('doom-solarized-light "#859900")
                           ('doom-one "#98be65")))
             (orange     (pcase theme
                           ('doom-solarized-light "#cb4b16")
                           ('doom-one "#da8548")))
             (red       (pcase theme
                          ('doom-solarized-light "#dc322f")
                          ('doom-one "#ff6c6b")))
             (blue       (pcase theme
                           ('doom-solarized-light "#268bd2")
                           ('doom-one "#51afef")))
             (dim-bg
              (pcase theme
                ('doom-solarized-light base3)
                ('doom-one base4)))

             (dim-fg
              (pcase theme
                ('doom-solarized-light "#9c9c9c")
                ('doom-one "#787878"))))

        (set-face-attribute 'default nil :family parameters-default-font-family)
        (set-face-attribute 'default nil :height parameters-default-text-height)
        (set-face-attribute 'variable-pitch nil :height parameters-variable-pitch-text-height)
        (set-face-attribute 'font-lock-keyword-face nil :weight 'light)
        (set-face-attribute 'font-lock-string-face nil :weight 'light)

        (apply 'custom-theme-set-faces theme
               (append

                ;; Common settings

                `((diredp-omit-file-name ((t ((:inherit diredp-ignored-file-name)))))
                  (header-line ((t :inherit mode-line)))
                  (doom-modeline-project-dir ((t (:inherit font-lock-string-face :weight normal :bold t))))
                  (doom-modeline-project-parent-dir ((t (:foreground ,dim-fg :bold t))))
                  (doom-modeline-evil-insert-state ((t (:foreground ,orange :bold t))))
                  (font-lock-comment-face ((t (:weight bold))))
                  (hydra-posframe-border-face ((t (:inherit posframe-border))))
                  (hydra-posframe-face ((t (:background ,bg-alt-l))))
                  (ivy-posframe-border ((t (:inherit posframe-border))))
                  (ledger-occur-xact-face ((t :inherit region)))
                  (ledger-report-negative-amount ((t :foreground ,red)))
                  (link ((t :underline t :foreground ,blue)))
                  (lsp-ui-sideline-current-symbol ((t (:inherit lsp-face-highlight-read :height 0.99))))
                  (lsp-ui-sideline-symbol ((t :height 0.99)))
                  (lsp-ui-sideline-symbol-info ((t :foreground "grey" :slant italic :height 0.99 :weight light)))
                  (markdown-list-face ((t :inherit markdown-blockquote-face)))
                  (mu4e-header-highlight-face ((t (:bold nil :foreground ,fg :extend t :background ,(doom-blend blue bg 0.2)))))
                  (mu4e-replied-face ((t :foreground ,green)))
                  (mu4e-unread-face ((t :foreground ,blue :bold t)))
                  (mu4e-highlight-face ((t :foreground ,blue :bold t)))
                  (org-agenda-clocking ((t (:bold nil :extend t :foreground ,fg :background ,(doom-blend blue bg 0.2)))))
                  (org-agenda-current-time ((t :foreground ,orange)))
                  (org-agenda-done ((t (:bold nil :inherit org-done))))
                  (org-block-begin-line ((t :extend t :inherit shadow)))
                  (org-block-end-line ((t :extend t :inherit shadow)))
                  (org-upcoming-deadline ((t :foreground ,orange)))
                  (org-drawer ((t :inherit shadow)))
                  (org-formula ((t :inherit shadow)))
                  (org-funcs-agenda-note ((t (:inherit font-lock-string-face :italic t))))
                  (org-meta-line ((t :inherit shadow)))
                  (org-roam-link ((t :inherit org-link :foreground ,orange)))
                  (org-roam-link-current ((t :inherit org-link :foreground ,orange :bold t)))
                  (outline-1 ((t (:weight bold :foreground ,blue))))
                  (parenthesis ((t (:foreground ,dim-fg :weight light))))
                  (secondary-selection ((t (:background ,dim-bg))))
                  (vterm-color-black ((t (:foreground ,bg :background ,base5))))
                  (woman-italic ((t (:foreground ,fg :slant italic))))

                  ;; we need to set ivy colours to dark manually.
                  (ivy-minibuffer-match-face-1 ((t (:foreground ,bg :background ,base7 :weight bold))))
                  (ivy-minibuffer-match-face-2 ((t (:foreground ,bg :background ,base6 :weight bold))))
                  (ivy-minibuffer-match-face-3 ((t (:foreground ,fg :background ,base4 :weight bold))))
                  (ivy-minibuffer-match-face-4 ((t (:foreground ,bg :background ,base8))))))))))
  :config
  (progn
    (require 'doom-themes-ext-org)
    (doom-themes-org-config)

    ;; Customise themes.

    (dolist (theme '(doom-one doom-solarized-light))
      (load-theme theme t t)
      (config-themes-override-themes theme))

    ;; Enable theme.

    (config-themes-toggle parameters-default-theme)))


(defun config-themes--after-enable-theme (&rest _)
  ;; Delete posframes after changing themes.
  (when (fboundp 'posframe-delete-all)
    (posframe-delete-all))
  ;; Force org buffers to refontify to fix org-bullet properties.
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (derived-mode-p 'org-mode)
        (font-lock-flush (point-min) (point-max))))))

(advice-add 'enable-theme :after #'config-themes--after-enable-theme)

;; customise transient so that it looks right when using a header line.

(use-package transient
  :defer t
  :custom
  ((transient-mode-line-format nil))
  :preface
  (defun config-git--ad-transient-header-line-fixes (&rest _)
    (with-selected-window transient--window
      (save-excursion
        (goto-char (point-min))
        (insert (propertize "__" 'face 'transient-separator
                            'display '(space :height (1))))
        (insert (propertize "\n" 'face 'transient-separator 'line-height t)))
      (setq header-line-format nil)))
  :config
  (advice-add 'transient--show :after #'config-git--ad-transient-header-line-fixes))

(provide 'config-themes)

;;; config-themes.el ends here
