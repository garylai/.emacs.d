;;; ledger-format.el --- Buffer formatting commands for ledger files.  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 's)

(autoload 'ledger-mode-clean-buffer "ledger-mode")

(defvar ledger-post-amount-alignment-column 52)

(defun ledger-format--align-price-assertion ()
  (when (s-matches? (rx (+ space) "=" (* space) (not (any digit)))
                    (buffer-substring (line-beginning-position) (line-end-position)))
    (unwind-protect
        (progn
          (goto-char (line-beginning-position))
          (search-forward "=")
          (goto-char (match-beginning 0))
          (indent-to (1+ ledger-post-amount-alignment-column))
          (skip-chars-forward " =")
          (just-one-space))
      (goto-char (line-end-position)))))

;;;###autoload
(defun ledger-format-buffer ()
  "Reformat the buffer."
  (interactive "*")
  (let ((pos (point)))
    (ignore-errors
      (ledger-mode-clean-buffer))
    (goto-char (point-min))
    (while (search-forward-regexp (rx (>= 2 space) "=") nil t)
      (ledger-format--align-price-assertion))
    (goto-char pos)))

(provide 'ledger-format)

;;; ledger-format.el ends here
