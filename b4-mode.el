;;; b4-mode.el --- Emacs interface to the “b4” patch‑tool  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Johannes Thumshirn <jth@kernel.org>

;; Author: Johannes Thumshirn <jth@kernel.org>
;; Url: https://github.com/morbidrsa/b4-mode
;; Keywords: Org, convenience, outlines
;; Version: 0.0.1
;; Package-Requires: (emacs "25")

;; This file is NOT part of GNU Emacs.
;;; Commentary:

;; b4-mode is a small Emacs major mode that provides a convenient
;; interface to the `b4` patch‑tool (https://github.com/mricon/b4)
;; The most useful command is `b4-shazam`, which runs
;;   b4 shazam <msgid>
;; The command is bound to `C-c b s` in the mode.
;;
;; The mode checks for the presence of the `b4` executable in your PATH
;; and will signal an error if it is missing.

(require 'cl-lib)

(defcustom b4-mode-executable "b4"
  "The name of the `b4` executable on your system."
  :type 'string
  :group 'b4-mode)

(defun b4-mode--executable ()
  "Return the absolute path to the `b4` executable or signal an error."
  (or (executable-find b4-mode-executable)
      (error "Could not find the `b4` executable.  Make sure `%s` is in your PATH."
             b4-mode-executable)))

;;; Mode definition -----------------------------------------------------------

(defvar b4-mode-map
  (let ((map (make-sparse-keymap)))
    ;; Simple key binding:  C-c b s  →  b4-shazam
    (define-key map (kbd "C-c b s") #'b4-shazam)
    ;; Simple key binding:  C-c b a  →  b4-am
    (define-key map (kbd "C-c b a") #'b4-am)
    map)
  "Keymap for `b4-mode`.")

(define-derived-mode b4-mode diff-mode "b4"
  "Major mode for editing Linux kernel patches that integrates with b4."
  (set (make-local-variable 'comment-start) "#")
  (set (make-local-variable 'comment-end) "")
  ;; You can add more mode‑specific settings here.
  (setq-local font-lock-defaults nil)
  (setq-local auto-fill-function nil)
  (message "b4-mode: ready"))

;;; Helper --------------------------------------------------------------------

(defun b4--output-buffer (name)
  "Return a buffer named NAME, creating it if necessary.
The buffer is switched to `compilation-mode` so that error patterns
are automatically recognised."
  (let ((buf (get-buffer-create name)))
    (with-current-buffer buf
      (unless (eq major-mode 'compilation-mode)
        (compilation-mode))
      (setq buffer-read-only t))
    buf))

;;; Interactive command -------------------------------------------------------

(defun b4-shazam (msgid)
  "Run `b4 shazam` on the given MSGID and display the result.
If called without a prefix argument the command will try to guess the
message id from the word at point."
  (interactive
   (list (read-string "Message ID: "
                      nil nil
                      (or (thing-at-point 'word) ""))))
  (unless msgid
    (user-error "No message id supplied"))
  (let* ((b4-exec (b4-mode--executable))
         (outbuf (b4--output-buffer "*b4-shazam*"))
         (args (list "shazam" msgid)))
    (with-current-buffer outbuf
      (setq buffer-read-only nil)
      (erase-buffer)
      (insert (format "Running: %s %s\n\n" b4-exec (string-join args " "))))
    (start-process "b4-shazam" outbuf b4-exec "shazam" msgid)
    (display-buffer outbuf)
    (message "b4: shazam %s launched" msgid)))

(defun b4-am (msgid)
  "Run `b4 am` on the given MSGID and display the result.
If called without a prefix argument the command will try to guess the
message id from the word at point."
  (interactive
   (list (read-string "Message ID: "
                      nil nil
                      (or (thing-at-point 'word) ""))))
  (unless msgid
    (user-error "No message id supplied"))
  (let* ((b4-exec (b4-mode--executable))
         (outbuf (b4--output-buffer "*b4-am*"))
         (args (list "am" msgid)))
    (with-current-buffer outbuf
      (setq buffer-read-only nil)
      (erase-buffer)
      (insert (format "Running: %s %s\n\n" b4-exec (string-join args " "))))
    (start-process "b4-am" outbuf b4-exec "am" msgid)
    (display-buffer outbuf)
    (message "b4: am %s launched" msgid)))


;;; Minor‑mode fallback -------------------------------------------------------

;; In case somebody wants to use the same interface on non‑patch files.
(defun b4-mode--maybe-check-exec ()
  "Warn the user if `b4` is missing, but keep the buffer open."
  (unless (executable-find b4-mode-executable)
    (message "Warning: b4 executable not found in PATH.")))

(add-hook 'b4-mode-hook #'b4-mode--maybe-check-exec)

;;; Provide ------------------------------------------------------------------

(provide 'b4-mode)

;;; b4-mode.el ends here
