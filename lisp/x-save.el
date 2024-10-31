;;; x-save.el --- Auto save files when idle

;; 1. 定时存储当前buffer.
;;    只要关联了文件,并且不是正在敲代码,有代码提示. 有修改就保存.
;;    不在保存时候自动格式化代码,会导致写代码写一半,光标跑了.
;;    如果需要,可以手动格式化代码
;; 2. 在切换buffer时候自动格式化代码.如果有修改就保存修改.

(defgroup x-save nil
  "Auto save file when emacs idle, switch buffer, lose focus etc."
  :group 'x-save)

(defcustom x-save-idle 1
  "The idle seconds to auto save file."
  :type 'integer
  :group 'x-save)

(defcustom x-save-silent nil
  "Nothing to dirty minibuffer if this option is non-nil."
  :type 'boolean
  :group 'x-save)

(defcustom x-save-delete-trailing-whitespace nil
  "Delete trailing whitespace when save if this option is non-nil.
Note, this option is non-nil, will delete all training whitespace execpet current line,
avoid delete current indent space when you programming."
  :type 'boolean
  :group 'x-save)

(defvar x-save-disable-predicates
  nil "disable auto save in these case.")

(defvar x-save-format-hook nil
  "auto save format hook, call when save buffers")

(defvar x-save--last-buffer (current-buffer)
  "last save buffer")


;; copy from flycheck and modify
;; 切换buffer时候格式化上一个buffer.有修改就保存
(defun x-save-handle-buffer-switch ()
  "auto save buffer when switch buffer"
  (unless (or (equal x-save--last-buffer (window-buffer))
			  (minibufferp))
	;; last buffer
	(when (and
		   (buffer-file-name x-save--last-buffer)
		   (verify-visited-file-modtime x-save--last-buffer)) ;; 忽略磁盘已经更改的文件, 磁盘文件已修改,会revert,再去格式化会导致文件异常(格式化的是buffer内容).
	  (ignore-errors
		(with-current-buffer x-save--last-buffer
		  (save-excursion
			(run-hooks 'x-save-format-hook)
			(if (buffer-modified-p)
				  (basic-save-buffer))))))
	(setq x-save--last-buffer (window-buffer))
	;; new buffer
	(if (and (buffer-file-name)
		 (buffer-modified-p x-save--last-buffer))
		(message "current buffer modified,%s" (buffer-file-name)))
	))


;; 保存当前buffer, copy from auto-save.el 每秒钟定时执行
(defun x-save-current-buffer ()
  ;; 非当前buffer,buffer无修改,磁盘有修改的, 自动revert
  (dolist (buf (buffer-list))
	(when (and (buffer-file-name buf)
			   (not (verify-visited-file-modtime buf))
			   (not (buffer-modified-p buf))
			   (not (equal (current-buffer) buf)))
	  (ignore-errors
		  (revert-buffer buf t t t))
	  ))
  ;; current buffer
  (ignore-errors
    (save-excursion
      (when (and
             ;; Buffer associate with a filename?
             (buffer-file-name)
             ;; Buffer is modifiable?
             (buffer-modified-p)
			 ;; ;; 忽略磁盘已经更改的文件, 定时器内会导致循环,然后卡死操作.
			 (verify-visited-file-modtime)
             ;; Yassnippet is not active?
             (or (not (boundp 'yas--active-snippets))
                 (not yas--active-snippets))
             ;; Company is not active?
             (or (not (boundp 'company-candidates))
                 (not company-candidates))
             ;; tell auto-save don't save
             (not (seq-some (lambda (predicate)
                              (funcall predicate))
                            x-save-disable-predicates)))
		(if x-save-silent
			;; `inhibit-message' can shut up Emacs, but we want
			;; it doesn't clean up echo area during saving
			(with-temp-message ""
			  (let ((inhibit-message t))
				(basic-save-buffer)))
		  (basic-save-buffer))
		;;(x-save--buffer-change 0 0 0)
        )
      )))


(defun x-save-delete-trailing-whitespace-except-current-line ()
  (interactive)
  (when x-save-delete-trailing-whitespace
    (let ((begin (line-beginning-position))
          (end (line-end-position)))
      (save-excursion
        (when (< (point-min) begin)
          (save-restriction
            (narrow-to-region (point-min) (1- begin))
            (delete-trailing-whitespace)))
        (when (> (point-max) end)
          (save-restriction
            (narrow-to-region (1+ end) (point-max))
            (delete-trailing-whitespace)))))))

(defvar x-save--timer nil)

(defun x-save-set-timer ()
  "Set the auto-save timer.
Cancel any previous timer."
  (x-save-cancel-timer)
  (setq x-save--timer
        (run-with-idle-timer x-save-idle t 'x-save-current-buffer)))

(defun x-save-cancel-timer ()
  (when x-save--timer
    (cancel-timer x-save--timer)
    (setq x-save--timer nil)))

(defun x-save-enable ()
  (interactive)
  (x-save-set-timer)
  (add-hook 'before-save-hook 'x-save-delete-trailing-whitespace-except-current-line)
  (add-hook 'before-save-hook 'font-lock-flush)
  (add-hook 'buffer-list-update-hook 'x-save-handle-buffer-switch)
  (message "开启自动保存")
  )

(defun x-save-disable ()
  (interactive)
  (x-save-cancel-timer)
  (remove-hook 'before-save-hook 'x-save-delete-trailing-whitespace-except-current-line)
  (remove-hook 'before-save-hook 'font-lock-flush)
  (remove-hook 'buffer-list-update-hook 'x-save-handle-buffer-switch)
  (message "关闭自动保存")
  )

;;(add-hook 'x-save-format-hook 'x-save-delete-trailing-whitespace-except-current-line)
;;(remove-hook 'x-save-format-hook 'x-save-delete-trailing-whitespace-except-current-line)

(provide 'x-save)

;;; x-save.el ends here
