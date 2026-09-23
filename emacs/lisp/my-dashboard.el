;;; my-dashboard.el --- Personal startup dashboard -*- lexical-binding: t; -*-

;;; Commentary:

;; A small, dependency-free startup dashboard with a native Emacs copy of
;; the Fastfetch artwork and shortcuts for frequently used commands.

;;; Code:

(require 'button)
(require 'subr-x)
(require 'my-dashboard-logo)

(declare-function corfu-mode "corfu" (&optional arg))
(declare-function global-hl-line-unhighlight "hl-line" ())
(declare-function jinx-mode "jinx" (&optional arg))

(defface my-dashboard-button-face
  '((t (:inherit (fixed-pitch link)
        :weight semi-bold
        :underline nil)))
  "Face used for dashboard action buttons."
  :group 'faces)

(defconst my-dashboard-buffer-name "*Dashboard*"
  "Name of the dashboard buffer.")

(defvar-local my-dashboard--recent-files nil
  "Recent files currently displayed on the dashboard.")

(defconst my-dashboard--action-rows
  '((("b/B" "Switch Buffer" my-dashboard--switch-buffer)
     ("d/D" "Dired" my-dashboard--open-dired)
     ("f/F" "Open File" my-dashboard--find-file))
    (("g" "Refresh" my-dashboard--refresh)
     ("s" "Scratch" my-dashboard--open-scratch)
     ("t" "VTerm" my-dashboard--open-vterm)))
  "Rows of dashboard actions.
Each action is a list of its key hint, label, and interactive command.")

(defvar-keymap my-dashboard--mode-map
  :doc "Keymap for the internal dashboard mode."
  :parent special-mode-map
  "f" #'my-dashboard--find-file
  "F" (lambda () (interactive) (my-dashboard--find-file t))
  "s" #'my-dashboard--open-scratch
  "b" #'my-dashboard--switch-buffer
  "B" (lambda () (interactive) (my-dashboard--switch-buffer t))
  "d" #'my-dashboard--open-dired
  "D" (lambda () (interactive) (my-dashboard--open-dired t))
  "t" #'my-dashboard--open-vterm
  "g" #'my-dashboard--refresh
  "RET" #'push-button
  "<tab>" #'forward-button
  "<backtab>" #'backward-button)

(dotimes (index 9)
  (keymap-set my-dashboard--mode-map
              (number-to-string (1+ index))
              #'my-dashboard--open-recent-file))

(define-derived-mode my-dashboard--mode special-mode "Dashboard"
  "Major mode for the personal startup dashboard."
  :interactive nil
  (setq-local header-line-format nil
              line-spacing 0
              truncate-lines t
              word-wrap nil
              show-trailing-whitespace nil
              default-directory (expand-file-name "~/")))

(defun my-dashboard--disable-local-modes ()
  "Disable global minor modes that are distracting on the dashboard."
  (setq-local global-hl-line-buffers nil)
  (when (fboundp 'global-hl-line-unhighlight)
    (global-hl-line-unhighlight))
  (when (bound-and-true-p hl-line-mode)
    (hl-line-mode -1))
  (when (bound-and-true-p corfu-mode)
    (corfu-mode -1))
  (when (bound-and-true-p jinx-mode)
    (jinx-mode -1)))

(add-hook 'my-dashboard--mode-hook #'my-dashboard--disable-local-modes)

(defun my-dashboard--find-file (&optional current-tab)
  "Open a file via the minibuffer, in a new tab unless CURRENT-TAB is non-nil."
  (interactive)
  (let ((use-file-dialog nil))
    (call-interactively (if current-tab #'find-file #'find-file-other-tab))))

(defun my-dashboard--open-dired (&optional current-tab)
  "Open Dired via the minibuffer, in a new tab unless CURRENT-TAB is non-nil."
  (interactive)
  (let ((use-file-dialog nil))
    (call-interactively (if current-tab #'dired #'dired-other-tab))))

(defun my-dashboard--open-scratch ()
  "Open the scratch buffer in another tab."
  (interactive)
  (switch-to-buffer-other-tab (get-scratch-buffer-create)))

(defun my-dashboard--open-recent-file (&optional button)
  "Open the recent file selected by BUTTON or a number key."
  (interactive)
  (let ((file (if button
                  (button-get button 'my-dashboard-file)
                (nth (- last-command-event ?1)
                     my-dashboard--recent-files))))
    (if file
        (find-file-other-tab file)
      (user-error "No recent file assigned to this key"))))

(defun my-dashboard--switch-buffer (&optional current-tab)
  "Switch buffers in a new tab unless CURRENT-TAB is non-nil."
  (interactive)
  (let ((command (if current-tab #'consult-buffer #'consult-buffer-other-tab)))
    (call-interactively
     (if (fboundp command)
         command
       (if current-tab #'switch-to-buffer #'switch-to-buffer-other-tab)))))

(defun my-dashboard--open-vterm ()
  "Open VTerm when it is available."
  (interactive)
  (if (fboundp 'vterm)
      (call-interactively #'vterm)
    (user-error "VTerm is not available")))

(defun my-dashboard--button-action (button)
  "Run the interactive command stored in BUTTON."
  (call-interactively (button-get button 'my-dashboard-command)))

(defun my-dashboard--action-label (action)
  "Return the displayed label for ACTION."
  (pcase-let ((`(,key ,label ,_) action))
    (format "[%s] %s" key label)))

(defun my-dashboard--action-button (action)
  "Return a text button for ACTION."
  (pcase-let ((`(,key ,label ,command) action))
    (make-text-button
     (my-dashboard--action-label action) nil
     'action #'my-dashboard--button-action
     'my-dashboard-command command
     'follow-link t
     'face 'my-dashboard-button-face
     'help-echo (format "%s: %s" key label))))

(defun my-dashboard--insert-centered (text)
  "Insert TEXT centered in the selected window."
  (if (display-graphic-p)
      (let ((half-width
             (/ (string-pixel-width text (current-buffer)) 2)))
        (insert
         (propertize
          " " 'display
          `(space :align-to (- center (,half-width))))))
    (insert
     (make-string
      (max 0 (/ (- (window-body-width) (string-width text)) 2))
      ?\s)))
  (insert text "\n"))

(defun my-dashboard--logo-fits-p ()
  "Return non-nil when the logo fits in the selected window."
  (and (display-graphic-p)
       (>= (window-body-height) 35)
       (let ((logo-width
              (apply #'max
                     (mapcar
                      (lambda (line)
                        (string-pixel-width line (current-buffer)))
                      my-dashboard-logo-lines))))
         (<= (+ logo-width (* 4 (frame-char-width)))
             (window-body-width nil t)))))

(defun my-dashboard--top-padding (content-height)
  "Return upper padding for a dashboard of CONTENT-HEIGHT lines."
  (max 2
       (min 6
            (/ (max 0 (- (window-body-height) content-height)) 4))))

(defun my-dashboard--text-fits-p (text)
  "Return non-nil when TEXT fits horizontally in the selected window."
  (if (display-graphic-p)
      (<= (+ (string-pixel-width text (current-buffer))
             (* 2 (frame-char-width)))
          (window-body-width nil t))
    (<= (+ (string-width text) 2)
        (window-body-width))))

(defun my-dashboard--fixed-spaces (count)
  "Return COUNT spaces displayed with the fixed-pitch face."
  (propertize (make-string count ?\s) 'face 'fixed-pitch))

(defun my-dashboard--action-column-widths ()
  "Return the maximum label width of each dashboard action column."
  (let ((widths
         (make-vector
          (apply #'max 0 (mapcar #'length my-dashboard--action-rows))
          0)))
    (dolist (actions my-dashboard--action-rows)
      (let ((column 0))
        (dolist (action actions)
          (aset widths column
                (max (aref widths column)
                     (string-width (my-dashboard--action-label action))))
          (setq column (1+ column)))))
    widths))

(defun my-dashboard--aligned-action-row (actions column-widths)
  "Return ACTIONS aligned to COLUMN-WIDTHS as one fixed-pitch row."
  (let ((column 0)
        cells)
    (dolist (action actions)
      (let* ((label (my-dashboard--action-label action))
             (padding
              (- (aref column-widths column) (string-width label))))
        (push
         (concat (my-dashboard--action-button action)
                 (my-dashboard--fixed-spaces padding))
         cells))
      (setq column (1+ column)))
    (mapconcat #'identity
               (nreverse cells)
               (my-dashboard--fixed-spaces 6))))

(defun my-dashboard--insert-actions ()
  "Insert dashboard actions as aligned rows or individual buttons."
  (let* ((column-widths (my-dashboard--action-column-widths))
         (rows
          (mapcar
           (lambda (actions)
             (my-dashboard--aligned-action-row actions column-widths))
           my-dashboard--action-rows)))
    (if (not (memq nil (mapcar #'my-dashboard--text-fits-p rows)))
        (dolist (row rows)
          (my-dashboard--insert-centered row))
      (dolist (actions my-dashboard--action-rows)
        (dolist (action actions)
          (my-dashboard--insert-centered
           (my-dashboard--action-button action)))))))

(defun my-dashboard--insert-recent-files ()
  "Insert the nine most recent files."
  (my-dashboard--insert-centered
   (propertize "Recent Files" 'face '(:inherit fixed-pitch :weight bold)))
  (let ((index 1)
        (width (apply #'max 0 (mapcar #'string-width my-dashboard--recent-files))))
    (dolist (file my-dashboard--recent-files)
      (my-dashboard--insert-centered
       (make-text-button
        (concat (format "[%d] %s" index file)
                (make-string (- width (string-width file)) ?\s)) nil
        'action #'my-dashboard--open-recent-file
        'my-dashboard-file file
        'follow-link t
        'face 'my-dashboard-button-face
        'help-echo file))
      (setq index (1+ index)))))

(defun my-dashboard--refresh ()
  "Render the dashboard in the current buffer."
  (interactive)
  (unless (and (derived-mode-p 'my-dashboard--mode)
               (equal (buffer-name) my-dashboard-buffer-name))
    (user-error "Dashboard refresh is only available in %s"
                my-dashboard-buffer-name))
  (let ((inhibit-message t)
        (inhibit-read-only t)
        (show-logo (my-dashboard--logo-fits-p)))
    (recentf-cleanup)
    (setq my-dashboard--recent-files (seq-take recentf-list 9))
    (erase-buffer)
    (insert
     (make-string
      (my-dashboard--top-padding (if show-logo 33 16))
      ?\n))
    (if show-logo
        (dolist (line my-dashboard-logo-lines)
          (my-dashboard--insert-centered line))
      (my-dashboard--insert-centered
       (propertize "Emacs" 'face '(:inherit fixed-pitch :weight bold))))
    (insert "\n\n")
    (my-dashboard--insert-actions)
    (insert "\n")
    (my-dashboard--insert-recent-files)
    (goto-char (point-min))
    (ignore-errors (forward-button 1))
    (set-buffer-modified-p nil)))

;;;###autoload
(defun my-dashboard ()
  "Show the personal dashboard, creating it when necessary."
  (interactive)
  (let ((buffer (get-buffer my-dashboard-buffer-name)))
    (when buffer
      (unless (with-current-buffer buffer
                (derived-mode-p 'my-dashboard--mode))
        (user-error "Buffer %s is already in use"
                    my-dashboard-buffer-name))))
  (switch-to-buffer (get-buffer-create my-dashboard-buffer-name))
  (unless (derived-mode-p 'my-dashboard--mode)
    (my-dashboard--mode))
  (my-dashboard--refresh))

(defun my-dashboard--maybe-show ()
  "Show the dashboard for an empty, ordinary graphical startup."
  (when (and (display-graphic-p)
             (not (daemonp))
             (eq (current-buffer) (get-buffer "*scratch*"))
             (zerop (buffer-size)))
    (my-dashboard)))

(provide 'my-dashboard)

;;; my-dashboard.el ends here
