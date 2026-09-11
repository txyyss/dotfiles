;;; my-box.el --- Box-style Emacs windows -*- lexical-binding: t; -*-

;;; Commentary:

;; Draw each ordinary window as a panel on a shared dark canvas.

;;; Code:

(require 'face-remap)
(require 'modus-themes)

(defgroup my-box nil
  "Box-style window appearance."
  :group 'faces)

(defcustom my-box-spacing 10
  "Space around and between Box windows in Emacs display pixels.
This sets both frame padding and horizontal and vertical window gaps.
It is independent of `my-box-border-width'."
  :type 'integer
  :group 'my-box
  :initialize #'custom-initialize-default
  :set (lambda (symbol value)
         (set-default symbol value)
         (my-box-enable)))

(defcustom my-box-border-width 2
  "Width of Box borders in Emacs display pixels.
Use a positive integer, normally 2 or larger.  This controls the top,
sides, and bottom strip in windows without a mode line.  Inset horizontal
strokes on native mode and header lines remain one pixel."
  :type 'integer
  :group 'my-box
  :initialize #'custom-initialize-default
  :set (lambda (symbol value)
         (set-default symbol value)
         (my-box-enable)))

(defconst my-box--strip-format
  (list (propertize " " 'display
                    '(space :align-to right :height (my-box-border-width) :ascent 100)))
  "Shared format for the top border and the bottom strip without a mode line.")

(defvar-local my-box--mode-line-remapping nil)

(defun my-box--set-faces ()
  "Apply the Box and Tab Bar faces."
  (let* ((canvas (modus-themes-get-color-value 'bg-dim :with-overrides))
         (border (modus-themes-get-color-value 'bg-mode-line-active :with-overrides))
         ;; Inset horizontal strokes merge into the mode-line background.
         (sides `(:line-width (,my-box-border-width . -1) :color ,border)))
    (dolist (face '(window-divider window-divider-first-pixel
                   window-divider-last-pixel))
      (set-face-foreground face canvas))
    (set-face-background 'internal-border canvas)
    (dolist (face '(mode-line-active mode-line-inactive))
      (set-face-attribute face nil
                          :background border :height 'unspecified :box sides
                          :overline nil :underline `(:color ,border :position t)))
    (dolist (face '(header-line-active header-line-inactive))
      (set-face-attribute face nil :box sides))
    (dolist (face '(tab-line-active tab-line-inactive))
      (set-face-attribute face nil
                          :background border :foreground border :height 10
                          :box nil :underline nil :overline nil))
    (set-face-background 'tab-bar canvas)
    (set-face-attribute 'tab-bar-tab nil
                        :background (modus-themes-get-color-value
                                     'bg-tab-current :with-overrides)
                        :box nil)
    (set-face-attribute 'tab-bar-tab-inactive nil
                        :background (modus-themes-get-color-value
                                     'bg-tab-other :with-overrides)
                        :box nil)))

(defun my-box--style-window (window)
  "Apply Box styling to WINDOW, preserving its native status and header lines."
  (with-current-buffer (window-buffer window)
    (setq-local mode-line-right-align-edge 'right-fringe)
    (face-remap-set-base 'fringe 'tab-line-active)
    (cond
     (mode-line-format
      (mapc #'face-remap-remove-relative my-box--mode-line-remapping)
      (setq my-box--mode-line-remapping nil))
     ((null my-box--mode-line-remapping)
      (setq my-box--mode-line-remapping
            (mapcar (lambda (face)
                      (face-remap-add-relative face :height 10 :box nil :underline nil))
                    '(mode-line-active mode-line-inactive)))))
    (set-window-fringes window my-box-border-width my-box-border-width t)
    (set-window-parameter window 'tab-line-format my-box--strip-format)
    (set-window-parameter window 'mode-line-format
                          (unless mode-line-format my-box--strip-format))))

(defun my-box-refresh (&optional frame)
  "Refresh Box styling in FRAME."
  (let ((frame (or frame (selected-frame))))
    (when (and (display-graphic-p frame) (not (frame-parent frame)))
      (dolist (window (window-list frame 'no-minibuffer))
        (my-box--style-window window))
      (set-window-fringes (minibuffer-window frame) 0 0 nil t))))

(defun my-box-enable ()
  "Enable Box-style windows."
  (setq window-divider-default-places t
        window-divider-default-right-width my-box-spacing
        window-divider-default-bottom-width my-box-spacing)
  (unless window-divider-mode
    (window-divider-mode 1))
  (my-box--set-faces)
  (add-hook 'modus-themes-after-load-theme-hook #'my-box--set-faces)
  (add-hook 'window-buffer-change-functions #'my-box-refresh)
  (add-hook 'after-change-major-mode-hook #'my-box-refresh)
  (let ((parameters `((internal-border-width . ,my-box-spacing)
                      (right-divider-width . ,my-box-spacing)
                      (bottom-divider-width . ,my-box-spacing))))
    (dolist (parameter parameters)
      (setf (alist-get (car parameter) default-frame-alist) (cdr parameter)))
    (dolist (frame (frame-list))
      (when (and (display-graphic-p frame) (not (frame-parent frame)))
        (modify-frame-parameters frame parameters)
        (my-box-refresh frame)))))

(provide 'my-box)

;;; my-box.el ends here
