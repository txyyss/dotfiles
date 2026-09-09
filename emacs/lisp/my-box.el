;;; my-box.el --- Box-style Emacs windows -*- lexical-binding: t; -*-

;;; Commentary:

;; Draw each ordinary window as a panel on a shared dark canvas.

;;; Code:

(require 'tab-line)
(require 'modus-themes)

(defconst my-box--border
  (modus-themes-get-color-value 'border :with-overrides))
(defconst my-box--canvas
  (modus-themes-get-color-value 'bg-dim :with-overrides))
(defconst my-box--edge
  (propertize " " 'face `(:background ,my-box--border)
              'display '(space :width (2))))
(defconst my-box--strip
  (propertize " " 'face `(:background ,my-box--border)
              'display '(space :align-to right :height (2) :ascent 100)))

(defvar-local my-box--header-installed nil)
(defvar my-box--original-header-line-map
  (lookup-key (current-global-map) [header-line]))

(defun my-box--mode-line-binding (event &optional type)
  "Return the mode-line binding at EVENT, optionally for TYPE."
  (let ((binding
         (keymap-lookup
          (remq (current-global-map)
                (current-active-maps nil (event-start event)))
          (key-description (vector 'mode-line (or type (car event)))) t)))
    (unless (numberp binding) binding)))

(defun my-box--header-line-event (event)
  "Use EVENT's mode-line binding when the header line has none."
  (interactive "e")
  (let* ((type (car event))
         (managed
          (buffer-local-value
           'my-box--header-installed
           (window-buffer (posn-window (event-start event)))))
         (modifiers (event-modifiers type))
         (release (and (memq 'down modifiers)
                       (event-convert-list
                        (append (remq 'down modifiers)
                                (list (event-basic-type type))))))
         (mode-binding (and managed (my-box--mode-line-binding event)))
         (release-binding
          (and managed release (not mode-binding)
               (my-box--mode-line-binding event release))))
    (cond
     (mode-binding
      (let ((copy (copy-tree event)))
        (dolist (position (cdr copy))
          (when (posnp position)
            (setf (cadr position) 'mode-line)))
        (push (cons 'no-record copy) unread-command-events)))
     (release-binding nil)
     (t
      (let ((binding
             (lookup-key my-box--original-header-line-map (vector type) t)))
        (cond ((keymapp binding) (popup-menu binding event))
              ((commandp binding)
               (call-interactively binding nil (vector event)))))))))

(defvar my-box--header-line-map
  (define-keymap "<t>" #'my-box--header-line-event))

(defun my-box--set-faces ()
  "Apply the Box and Tab Bar faces."
  (dolist (face '(window-divider window-divider-first-pixel
                  window-divider-last-pixel))
    (set-face-foreground face my-box--canvas))
  (set-face-background 'internal-border my-box--canvas)
  (set-face-background 'fringe my-box--border)
  (dolist (face '(mode-line-active mode-line-inactive
                  tab-line tab-line-active tab-line-inactive))
    (set-face-attribute face nil
                        :background my-box--border
                        :foreground my-box--border
                        :height 10 :box nil :underline nil :overline nil))
  (set-face-attribute 'header-line-active nil
                      :background (modus-themes-get-color-value 'bg-active)
                      :box nil :overline nil)
  (set-face-attribute 'header-line-inactive nil
                      :background (modus-themes-get-color-value 'bg-inactive)
                      :box nil :overline nil)
  (set-face-attribute 'tab-bar nil :background my-box--canvas)
  (set-face-attribute 'tab-bar-tab nil
                      :background (modus-themes-get-color-value 'bg-active)
                      :box nil)
  (set-face-attribute 'tab-bar-tab-inactive nil
                      :background (modus-themes-get-color-value 'bg-inactive)
                      :box nil))

(defun my-box--style-window (window)
  "Apply Box styling to WINDOW."
  (with-current-buffer (window-buffer window)
    (when (and mode-line-format (not my-box--header-installed))
      (setq-local mode-line-format
                  (append (list my-box--edge) mode-line-format
                          (list my-box--edge))
                  header-line-format mode-line-format
                  my-box--header-installed t))
    (set-window-fringes window 2 2 t)
    (set-window-parameter window 'tab-line-format (list my-box--strip))
    (set-window-parameter window 'mode-line-format (list my-box--strip))))

(defun my-box-refresh (&optional frame)
  "Refresh Box styling in FRAME."
  (let ((frame (or frame (selected-frame))))
    (dolist (window (window-list frame 'no-minibuffer))
      (my-box--style-window window))
    (set-window-fringes (minibuffer-window frame) 0 0 nil t))
  (force-mode-line-update t))

(defun my-box-enable ()
  "Enable Box-style windows."
  (setq window-divider-default-places t
        window-divider-default-right-width 12
        window-divider-default-bottom-width 12)
  (modify-all-frames-parameters '((internal-border-width . 8)))
  (define-key (current-global-map) [header-line] my-box--header-line-map)
  (window-divider-mode 1)
  (my-box--set-faces)
  (add-hook 'modus-themes-after-load-theme-hook #'my-box--set-faces)
  (add-hook 'window-buffer-change-functions #'my-box-refresh)
  (add-hook 'after-change-major-mode-hook #'my-box-refresh)
  (my-box-refresh))

(provide 'my-box)

;;; my-box.el ends here
