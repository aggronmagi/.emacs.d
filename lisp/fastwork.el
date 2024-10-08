

(defgroup fastwork nil
  "Fast Create record file"
  :group 'fastwork)

(defcustom fastwork-file '(format-time-string "%Y%m%d.org")
  "快速打开的文件名称"
  :group 'fastwork)

(defcustom fastwork-dir "~/org/work/record/"
  "文件目录"
  :type 'directory
  :group 'fastwork)

(defcustom fastwork-work "~/org/work/work.org"
  "工作文件"
  :group 'fastwork)

(defcustom fastwork-file-title '(concat "#+startup: showall\n"
										"#+title: " (format-time-string "%Y-%m-%d\n"))
  "文件头"
  :group 'fastwork)

;; (setq fastwork-file-title '(concat "#+startup:  content\n"
;; 									 "#+title: " (format-time-string "%Y-%m-%d记录\n\n* ")))
;; (setq fastwork-file '(format-time-string "%Y%m%d.org"))
;; (message (eval fastwork-file-title))
;; (message (expand-file-name (concat fastwork-dir (eval fastwork-file))))


(defun fastwork-open-log()
  "打开日志文件，每天一个独立文件"
  (let ((file-name (expand-file-name (concat fastwork-dir (eval fastwork-file)))))
    (if (file-exists-p file-name)
		(find-file file-name)
	  (find-file file-name)
	  (insert (eval fastwork-file-title))
	  (save-buffer)
	  (goto-char (point-max)))
    file-name))

;;;###autoload
(defun fastwork-open()
  "打开文件"
  (interactive)
  (let ((sel (completing-read "Open: " '("Work" "Log"))))
    (if (string-equal sel "Work")
		(find-file fastwork-work)
	  (fastwork-open-log))
  ;; (let* ((cur (eval fastwork-file))
  ;; 		 (selection (completing-read "选择打开的文件: " '("" 'cur))))
  ;;   (message "你选择了: %s %s" selection cur))
  ))


(global-set-key (kbd "<f8>") 'fastwork-open)

(provide 'fastwork)

