;;; my-box.el --- Box-style Emacs windows -*- lexical-binding: t; -*-

;;; Commentary:

;; Draw each ordinary window as a panel on a shared dark canvas,
;; with at least one column of padding on either side of the text.

;;; Code:

(require 'face-remap)
(require 'svg)
(eval-and-compile
  (require-theme 'modus-themes))

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
strokes on native mode lines remain one pixel."
  :type 'integer
  :group 'my-box
  :initialize #'custom-initialize-default
  :set (lambda (symbol value)
         (set-default symbol value)
         (my-box-enable)))

(defcustom my-box-corner-radius 11
  "Radius of the upper Box corners in Emacs display pixels.
The top strip occupies the greater of this radius and `my-box-border-width'.
Zero restores square corners.  Bottom corners and side padding are unchanged."
  :type 'natnum
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

(defun my-box--top-format ()
  "Return the top border, caching one SVG per window."
  (if (zerop my-box-corner-radius)
      my-box--strip-format
    (let* ((window (selected-window))
           (frame (window-frame window))
           (width (- (window-pixel-width window)
                     (window-right-divider-width window)))
           (radius (min my-box-corner-radius (/ width 2)))
           (border my-box-border-width)
           (height (max radius border))
           (canvas (face-background 'internal-border frame t))
           (color (face-background 'tab-line-active frame t))
           (background (face-background
                        (if header-line-format
                            (if (mode-line-window-selected-p)
                                'header-line-active
                              'header-line-inactive)
                          'default)
                        frame t))
           (key (list width radius border canvas color background))
           (cache (window-parameter window 'my-box-top-cache)))
      (unless (equal key (car cache))
        (let ((svg (svg-create width height))
              (inner-radius (max 0 (- radius border))))
          (svg-rectangle svg 0 0 width height :fill canvas)
          ;; Clip the lower half of each rounded rectangle: only the top
          ;; corners curve, ending at the same width as the side fringes.
          (svg-rectangle svg 0 0 width (* 2 height)
                         :rx radius :ry radius :fill color)
          (svg-rectangle svg border border (- width (* 2 border)) (* 2 height)
                         :rx inner-radius :ry inner-radius :fill background)
          (setq cache
                (cons key (propertize " " 'display
                                      (svg-image svg :ascent 100 :scale 1))))
          (set-window-parameter window 'my-box-top-cache cache)))
      (cdr cache))))

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
    ;; Redisplay checks the base face to decide whether to draw the right
    ;; edge.  The per-buffer remapping below supplies its border color.
    (dolist (face '(header-line-active header-line-inactive))
      (set-face-attribute face nil :box (cons my-box-border-width 0)))
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
    ;; Anonymous faces allow zero horizontal box width, keeping just the
    ;; native header's sides without a seam below the rounded top.
    (dolist (face '(header-line-active header-line-inactive))
      (face-remap-set-base
       face `(:box (:line-width (,my-box-border-width . 0)
                   :color ,(face-background 'tab-line-active (window-frame window) t)))
       face))
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
    (let ((margins (window-margins window)))
      (set-window-margins window
                          (max 1 (or (car margins) 0))
                          (max 1 (or (cdr margins) 0))))
    (set-window-parameter window 'tab-line-format '(:eval (my-box--top-format)))
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
  (add-hook 'modus-themes-after-load-theme-hook #'my-box-enable)
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
