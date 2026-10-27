;;; huarong.el --- SVG Huarong Dao puzzle -*- lexical-binding: t; -*-

;;; Commentary:

;; A small Huarong Dao game rendered with SVG.  Run `M-x huarong'.

;;; Code:

(require 'cl-lib)
(require 'svg)

(defgroup huarong nil
  "Play Huarong Dao in Emacs."
  :group 'games)

(defcustom huarong-playback-delay 0.14
  "Seconds between moves during automatic solving."
  :type 'number
  :group 'huarong)

(defconst huarong--columns 4)
(defconst huarong--rows 5)
(defconst huarong--base-cell-size 72)
(defconst huarong--base-padding 10)
(defconst huarong--base-gap 4)
(defconst huarong--buffer-name "*Huarong Dao*")

(defconst huarong--layouts
  '(("横刀立马"
     ((goal 2 2 1 0)
      (v1 1 2 0 0) (v2 1 2 3 0) (v3 1 2 0 2) (v4 1 2 3 2)
      (h1 2 1 1 2)
      (s1 1 1 1 3) (s2 1 1 2 3) (s3 1 1 0 4) (s4 1 1 3 4)))
    ("指挥若定"
     ((goal 2 2 1 0)
      (v1 1 2 0 0) (v2 1 2 3 0) (v3 1 2 0 3) (v4 1 2 3 3)
      (h1 2 1 1 2)
      (s1 1 1 0 2) (s2 1 1 3 2) (s3 1 1 1 3) (s4 1 1 2 3)))
    ("兵分三路"
     ((goal 2 2 1 0)
      (v1 1 2 0 1) (v2 1 2 3 1) (v3 1 2 0 3) (v4 1 2 3 3)
      (h1 2 1 1 2)
      (s1 1 1 0 0) (s2 1 1 3 0) (s3 1 1 1 3) (s4 1 1 2 3)))
    ("将拥曹营"
     ((goal 2 2 1 0)
      (v1 1 2 0 1) (v2 1 2 3 1) (v3 1 2 1 2) (v4 1 2 2 2)
      (h1 2 1 0 4)
      (s1 1 1 0 3) (s2 1 1 3 3) (s3 1 1 2 4) (s4 1 1 3 4)))
    ("齐头并进"
     ((goal 2 2 1 0)
      (v1 1 2 0 0) (v2 1 2 3 0) (v3 1 2 0 3) (v4 1 2 3 3)
      (h1 2 1 1 3)
      (s1 1 1 0 2) (s2 1 1 1 2) (s3 1 1 2 2) (s4 1 1 3 2)))
    ("插翅难飞"
     ((goal 2 2 1 0)
      (v1 1 2 0 0) (v2 1 2 0 3) (v3 1 2 3 3)
      (h1 2 1 0 2) (h2 2 1 1 3)
      (s1 1 1 3 0) (s2 1 1 3 1) (s3 1 1 2 2) (s4 1 1 3 2)))
    ("层层设防"
     ((goal 2 2 1 0)
      (v1 1 2 0 0) (v2 1 2 3 0)
      (h1 2 1 1 2) (h2 2 1 1 3) (h3 2 1 1 4)
      (s1 1 1 0 2) (s2 1 1 3 2) (s3 1 1 0 3) (s4 1 1 3 3)))
    ("水泄不通"
     ((goal 2 2 1 0)
      (v1 1 2 0 0)
      (h1 2 1 0 2) (h2 2 1 2 2) (h3 2 1 0 3) (h4 2 1 2 3)
      (s1 1 1 3 0) (s2 1 1 3 1) (s3 1 1 0 4) (s4 1 1 3 4)))
    ("勇闯五关"
     ((goal 2 2 1 0)
      (h1 2 1 0 2) (h2 2 1 2 2) (h3 2 1 0 3)
      (h4 2 1 2 3) (h5 2 1 1 4)
      (s1 1 1 0 0) (s2 1 1 3 0) (s3 1 1 0 1) (s4 1 1 3 1)))
    ("四面楚歌"
     ((goal 2 2 1 1)
      (v1 1 2 0 0) (v2 1 2 3 0) (v3 1 2 3 2) (v4 1 2 0 3)
      (h1 2 1 1 3)
      (s1 1 1 1 0) (s2 1 1 2 0) (s3 1 1 0 2) (s4 1 1 3 4)))
    ("前呼后拥"
     ((goal 2 2 2 0)
      (h1 2 1 0 1) (h2 2 1 0 2) (h3 2 1 2 2)
      (h4 2 1 0 3) (h5 2 1 2 3)
      (s1 1 1 0 0) (s2 1 1 1 0) (s3 1 1 2 4) (s4 1 1 3 4)))
    ("近在咫尺"
     ((goal 2 2 2 3)
      (v1 1 2 1 0) (v2 1 2 2 0) (v3 1 2 3 0)
      (h1 2 1 0 2) (h2 2 1 0 3)
      (s1 1 1 0 0) (s2 1 1 0 1) (s3 1 1 2 2) (s4 1 1 3 2)))
    ("峰回路转"
     ((goal 2 2 0 1)
      (v1 1 2 3 0) (v2 1 2 2 1) (v3 1 2 3 2)
      (h1 2 1 1 3) (h2 2 1 2 4)
      (s1 1 1 0 0) (s2 1 1 1 0) (s3 1 1 2 0) (s4 1 1 1 4))))
  "Built-in Huarong Dao layouts.")

(cl-defstruct (huarong--piece
               (:constructor huarong--make-piece (id width height)))
  id width height)

(defvar-local huarong--layout-index 0)
(defvar-local huarong--pieces nil)
(defvar-local huarong--state nil)
(defvar-local huarong--cell-size huarong--base-cell-size)
(defvar-local huarong--padding huarong--base-padding)
(defvar-local huarong--gap huarong--base-gap)
(defvar-local huarong--selected 0)
(defvar-local huarong--history nil)
(defvar-local huarong--status nil)
(defvar-local huarong--playback nil)
(defvar-local huarong--timer nil)

(defconst huarong--directions
  '((0 -1 "上") (0 1 "下") (-1 0 "左") (1 0 "右")))

(defvar-keymap huarong-mode-map
  :doc "Keymap for Huarong Dao."
  :parent special-mode-map
  "<left>" #'huarong-move-left
  "<right>" #'huarong-move-right
  "<up>" #'huarong-move-up
  "<down>" #'huarong-move-down
  "C-b" #'huarong-move-left
  "C-f" #'huarong-move-right
  "C-p" #'huarong-move-up
  "C-n" #'huarong-move-down
  "M-<left>" #'huarong-select-left
  "M-<right>" #'huarong-select-right
  "M-<up>" #'huarong-select-up
  "M-<down>" #'huarong-select-down
  "w" #'huarong-select-up
  "a" #'huarong-select-left
  "s" #'huarong-select-down
  "d" #'huarong-select-right
  "TAB" #'huarong-select-next
  "<backtab>" #'huarong-select-previous
  "<mouse-1>" #'huarong-mouse-select
  "u" #'huarong-undo
  "r" #'huarong-restart
  "n" #'huarong-next-layout
  "l" #'huarong-choose-layout
  "h" #'huarong-hint
  "S" #'huarong-solve
  "SPC" #'huarong-stop
  "q" #'huarong-quit
  "?" #'describe-mode)

(define-derived-mode huarong-mode special-mode "Huarong"
  "Major mode for playing Huarong Dao."
  :interactive nil
  (buffer-disable-undo)
  (setq-local cursor-type nil
              truncate-lines t
              mode-line-process
              '(:eval (format "  %s · %d 步"
                              (car (nth huarong--layout-index
                                        huarong--layouts))
                              (length huarong--history))))
  (add-hook 'window-size-change-functions #'huarong--render nil t)
  (add-hook 'kill-buffer-hook #'huarong--cancel-playback nil t))

(defun huarong--piece-kind (piece)
  "Return the display kind of PIECE."
  (cond
   ((eq (huarong--piece-id piece) 'goal) 'goal)
   ((= (huarong--piece-width piece) 2) 'horizontal)
   ((= (huarong--piece-height piece) 2) 'vertical)
   (t 'soldier)))

(defun huarong--load-layout (index)
  "Load layout at INDEX into the current game buffer."
  (huarong--cancel-playback)
  (setq huarong--layout-index index)
  (let ((entries (cadr (nth index huarong--layouts))))
    (setq huarong--pieces
          (vconcat
           (mapcar (lambda (entry)
                     (pcase-let ((`(,id ,width ,height ,_ ,_) entry))
                       (huarong--make-piece id width height)))
                   entries))
          huarong--state
          (vconcat
           (mapcar (lambda (entry)
                     (pcase-let ((`(,_ ,_ ,_ ,x ,y) entry))
                       (cons x y)))
                   entries))))
  (setq huarong--selected 0
        huarong--history nil
        huarong--status nil)
  (huarong--render))

(defun huarong--occupancy (state)
  "Return a board occupancy vector for STATE."
  (let ((board (make-vector (* huarong--columns huarong--rows) -1)))
    (dotimes (index (length state))
      (let* ((piece (aref huarong--pieces index))
             (position (aref state index))
             (x (car position))
             (y (cdr position)))
        (dotimes (dy (huarong--piece-height piece))
          (dotimes (dx (huarong--piece-width piece))
            (aset board (+ x dx (* huarong--columns (+ y dy))) index)))))
    board))

(defun huarong--legal-move-p (state index dx dy &optional board)
  "Return non-nil when PIECE at INDEX can move DX and DY in STATE."
  (let* ((piece (aref huarong--pieces index))
         (position (aref state index))
         (x (+ (car position) dx))
         (y (+ (cdr position) dy))
         (width (huarong--piece-width piece))
         (height (huarong--piece-height piece))
         (board (or board (huarong--occupancy state)))
         (legal (and (>= x 0) (>= y 0)
                     (<= (+ x width) huarong--columns)
                     (<= (+ y height) huarong--rows))))
    (when legal
      (dotimes (py height)
        (dotimes (px width)
          (let ((occupant
                 (aref board (+ x px (* huarong--columns (+ y py))))))
            (unless (or (= occupant -1) (= occupant index))
              (setq legal nil))))))
    legal))

(defun huarong--moved-state (state index dx dy)
  "Return a copy of STATE with PIECE at INDEX moved by DX and DY."
  (let* ((next (copy-sequence state))
         (position (aref state index)))
    (aset next index (cons (+ (car position) dx)
                           (+ (cdr position) dy)))
    next))

(defun huarong--all-moves (state)
  "Return all legal one-cell moves from STATE."
  (let ((board (huarong--occupancy state))
        moves)
    (dotimes (index (length state))
      (dolist (direction huarong--directions)
        (pcase-let ((`(,dx ,dy ,_) direction))
          (when (huarong--legal-move-p state index dx dy board)
            (push (list index dx dy) moves)))))
    moves))

(defun huarong--goal-p (state)
  "Return non-nil when STATE has reached the exit."
  (equal (aref state 0) '(1 . 3)))

(defun huarong--state-key (state)
  "Return a canonical hash key for STATE.
Pieces of the same shape are treated as interchangeable."
  (let ((key (make-string (* huarong--columns huarong--rows) ?.)))
    (dotimes (index (length state))
      (let ((position (aref state index)))
        (aset key
              (+ (car position) (* huarong--columns (cdr position)))
              (pcase (huarong--piece-kind (aref huarong--pieces index))
                ('goal ?G)
                ('horizontal ?H)
                ('vertical ?V)
                ('soldier ?S)))))
    key))

(defun huarong--solve-state (start)
  "Return a shortest sequence of moves from START to the goal."
  (let* ((start-key (huarong--state-key start))
         (front (list start-key))
         back goal-key
         (states (make-hash-table :test #'equal))
         (parents (make-hash-table :test #'equal)))
    (puthash start-key start states)
    (setq goal-key
          (catch 'solved
            (while (or front back)
              (unless front
                (setq front (nreverse back)
                      back nil))
              (let* ((key (pop front))
                     (state (gethash key states)))
                (when (huarong--goal-p state)
                  (throw 'solved key))
                (dolist (move (huarong--all-moves state))
                  (pcase-let ((`(,index ,dx ,dy) move))
                    (let* ((next (huarong--moved-state state index dx dy))
                           (next-key (huarong--state-key next)))
                      (unless (gethash next-key states)
                        (puthash next-key next states)
                        (puthash next-key (vector key move) parents)
                        (push next-key back)))))))))
    (let (moves)
      (while (not (equal goal-key start-key))
        (let ((parent (gethash goal-key parents)))
          (push (aref parent 1) moves)
          (setq goal-key (aref parent 0))))
      moves)))

(defun huarong--piece-color (piece)
  "Return the fill color for PIECE."
  (pcase (huarong--piece-kind piece)
    ('goal "#f38ba8")
    ('horizontal "#fab387")
    ('vertical "#89b4fa")
    ('soldier "#a6e3a1")))

(defun huarong--fit-board (window)
  "Set the SVG board dimensions to fit WINDOW."
  (let* ((frame (window-frame window))
         (base-width (+ (* 2 huarong--base-padding)
                        (* huarong--columns huarong--base-cell-size)))
         (base-height (+ (* 2 huarong--base-padding)
                         (* huarong--rows huarong--base-cell-size)))
         (available-width
          (- (window-body-width window t) (* 4 (frame-char-width frame))))
         (available-height
          (- (window-body-height window t) (* 10 (frame-char-height frame))))
         (scale (max 0.35
                     (min (/ (float available-width) base-width)
                          (/ (float available-height) base-height)))))
    (setq huarong--cell-size (round (* huarong--base-cell-size scale))
          huarong--padding (round (* huarong--base-padding scale))
          huarong--gap (max 2 (round (* huarong--base-gap scale))))))

(defun huarong--svg-image ()
  "Render the current board and return an SVG image."
  (let* ((cell huarong--cell-size)
         (width (+ (* 2 huarong--padding) (* huarong--columns cell)))
         (height (+ (* 2 huarong--padding) (* huarong--rows cell)))
         (svg (svg-create width height)))
    (svg-rectangle svg 0 0 width height
                   :fill-color "#181825" :rx 16 :ry 16)
    (dotimes (column (1+ huarong--columns))
      (svg-line svg
                (+ huarong--padding (* column cell)) huarong--padding
                (+ huarong--padding (* column cell)) (- height huarong--padding)
                :stroke-color "#313244" :stroke-width 1))
    (dotimes (row (1+ huarong--rows))
      (svg-line svg
                huarong--padding (+ huarong--padding (* row cell))
                (- width huarong--padding) (+ huarong--padding (* row cell))
                :stroke-color "#313244" :stroke-width 1))
    (svg-line svg
              (+ huarong--padding cell) (- height 3)
              (+ huarong--padding (* 3 cell)) (- height 3)
              :stroke-color "#a6e3a1" :stroke-width 5)
    (dotimes (index (length huarong--pieces))
      (let* ((piece (aref huarong--pieces index))
             (position (aref huarong--state index))
             (selected (= index huarong--selected)))
        (svg-rectangle
         svg
         (+ huarong--padding (* (car position) cell) huarong--gap)
         (+ huarong--padding (* (cdr position) cell) huarong--gap)
         (- (* (huarong--piece-width piece) cell) (* 2 huarong--gap))
         (- (* (huarong--piece-height piece) cell) (* 2 huarong--gap))
         :fill-color (huarong--piece-color piece)
         :stroke-color (if selected "#f9e2af" "#45475a")
         :stroke-width (if selected 5 2)
         :rx 10 :ry 10)))
    (svg-image svg :scale 1.0 :pointer 'hand)))

(defun huarong--insert-centered (text)
  "Insert TEXT centered in the selected window."
  (let ((half-width (/ (string-pixel-width text) 2)))
    (insert (propertize " " 'display
                        `(space :align-to (- center (,half-width)))))
    (insert text "\n")))

(defun huarong--insert-board ()
  "Insert the current SVG board centered in the selected window."
  (let ((width (+ (* 2 huarong--padding)
                  (* huarong--columns huarong--cell-size))))
    (insert (propertize " " 'display
                        `(space :align-to (- center (,(floor width 2))))))
    (insert-image (huarong--svg-image) " ")
    (insert "\n")))

(defun huarong--render (&optional window)
  "Render the game for WINDOW in the current buffer."
  (huarong--fit-board
   (or window (get-buffer-window (current-buffer) t) (selected-window)))
  (let ((inhibit-read-only t)
        (title (format "华容道 · %s · %d 步"
                       (car (nth huarong--layout-index huarong--layouts))
                       (length huarong--history))))
    (erase-buffer)
    (insert "\n")
    (huarong--insert-centered (propertize title 'face '(:height 1.25 :weight bold)))
    (insert "\n")
    (huarong--insert-board)
    (insert "\n")
    (huarong--insert-centered "M-方向键 / WASD 选择 · 方向键移动 · 鼠标选择")
    (huarong--insert-centered
     "[h] 提示  [S] 自动求解  [SPC] 停止  [u] 撤销")
    (huarong--insert-centered
     "[r] 重开  [n] 下一局  [l] 选择布局  [q] 退出")
    (insert "\n")
    (huarong--insert-centered
     (if huarong--status
         (propertize huarong--status 'face 'font-lock-keyword-face)
       " "))
    (goto-char (point-min))
    (set-buffer-modified-p nil)
    (force-mode-line-update)))

(defun huarong--cancel-playback ()
  "Cancel automatic playback in the current buffer."
  (when huarong--timer
    (cancel-timer huarong--timer))
  (setq huarong--timer nil
        huarong--playback nil))

(defun huarong--apply-move (move)
  "Apply MOVE to the game."
  (pcase-let ((`(,index ,dx ,dy) move))
    (push huarong--state huarong--history)
    (setq huarong--state (huarong--moved-state huarong--state index dx dy)
          huarong--selected index
          huarong--status
          (cond
           ((huarong--goal-p huarong--state)
            (format "完成！共移动 %d 步。" (length huarong--history)))
           (huarong--playback
            (format "自动求解：还剩 %d 步" (length huarong--playback)))
           (t nil))))
  (huarong--render))

(defun huarong--move-selected (dx dy)
  "Move the selected piece by DX and DY."
  (huarong--cancel-playback)
  (if (huarong--legal-move-p huarong--state huarong--selected dx dy)
      (huarong--apply-move (list huarong--selected dx dy))
    (message "这个棋块不能向该方向移动")))

(defun huarong-move-left ()
  "Move the selected piece left."
  (interactive)
  (huarong--move-selected -1 0))

(defun huarong-move-right ()
  "Move the selected piece right."
  (interactive)
  (huarong--move-selected 1 0))

(defun huarong-move-up ()
  "Move the selected piece up."
  (interactive)
  (huarong--move-selected 0 -1))

(defun huarong-move-down ()
  "Move the selected piece down."
  (interactive)
  (huarong--move-selected 0 1))

(defun huarong--select (offset)
  "Select another piece OFFSET places away."
  (huarong--cancel-playback)
  (setq huarong--selected
        (mod (+ huarong--selected offset) (length huarong--pieces))
        huarong--status nil)
  (huarong--render))

(defun huarong-select-next ()
  "Select the next piece."
  (interactive)
  (huarong--select 1))

(defun huarong-select-previous ()
  "Select the previous piece."
  (interactive)
  (huarong--select -1))

(defun huarong--piece-center (index)
  "Return the center position of the piece at INDEX."
  (let ((piece (aref huarong--pieces index))
        (position (aref huarong--state index)))
    (cons (+ (car position) (/ (huarong--piece-width piece) 2.0))
          (+ (cdr position) (/ (huarong--piece-height piece) 2.0)))))

(defun huarong--select-direction (dx dy)
  "Select the nearest piece in direction DX and DY."
  (huarong--cancel-playback)
  (let* ((origin (huarong--piece-center huarong--selected))
         best best-score)
    (dotimes (index (length huarong--pieces))
      (unless (= index huarong--selected)
        (let* ((center (huarong--piece-center index))
               (delta-x (- (car center) (car origin)))
               (delta-y (- (cdr center) (cdr origin)))
               (forward (+ (* dx delta-x) (* dy delta-y)))
               (sideways (abs (- (* dx delta-y) (* dy delta-x))))
               (score (+ (* forward forward) (* 4 sideways sideways))))
          (when (and (> forward 0)
                     (or (null best-score) (< score best-score)))
            (setq best index
                  best-score score)))))
    (if best
        (progn
          (setq huarong--selected best
                huarong--status nil)
          (huarong--render))
      (message "这个方向没有其他棋块"))))

(defun huarong-select-left ()
  "Select a piece to the left."
  (interactive)
  (huarong--select-direction -1 0))

(defun huarong-select-right ()
  "Select a piece to the right."
  (interactive)
  (huarong--select-direction 1 0))

(defun huarong-select-up ()
  "Select a piece above."
  (interactive)
  (huarong--select-direction 0 -1))

(defun huarong-select-down ()
  "Select a piece below."
  (interactive)
  (huarong--select-direction 0 1))

(defun huarong-mouse-select (event)
  "Select the piece clicked in mouse EVENT."
  (interactive "e")
  (let ((xy (posn-object-x-y (event-start event))))
    (when (consp xy)
      (let ((x (floor (/ (- (car xy) huarong--padding)
                         (float huarong--cell-size))))
            (y (floor (/ (- (cdr xy) huarong--padding)
                         (float huarong--cell-size)))))
        (when (and (>= x 0) (< x huarong--columns)
                   (>= y 0) (< y huarong--rows))
          (let ((index (aref (huarong--occupancy huarong--state)
                             (+ x (* huarong--columns y)))))
            (when (>= index 0)
              (huarong--cancel-playback)
              (setq huarong--selected index
                    huarong--status nil)
              (huarong--render))))))))

(defun huarong-undo ()
  "Undo one game move."
  (interactive)
  (huarong--cancel-playback)
  (if huarong--history
      (setq huarong--state (pop huarong--history)
            huarong--status nil)
    (message "没有可以撤销的移动"))
  (huarong--render))

(defun huarong-restart ()
  "Restart the current layout."
  (interactive)
  (huarong--load-layout huarong--layout-index))

(defun huarong-next-layout ()
  "Load the next built-in layout."
  (interactive)
  (huarong--load-layout
   (mod (1+ huarong--layout-index) (length huarong--layouts))))

(defun huarong-choose-layout ()
  "Choose and load a built-in layout."
  (interactive)
  (let* ((names (mapcar #'car huarong--layouts))
         (name (completing-read "布局: " names nil t nil nil
                                (nth huarong--layout-index names))))
    (huarong--load-layout (cl-position name names :test #'equal))))

(defun huarong--direction-name (move)
  "Return the Chinese direction name for MOVE."
  (pcase-let ((`(,_ ,dx ,dy) move))
    (caddr (cl-find-if (lambda (direction)
                         (and (= dx (car direction))
                              (= dy (cadr direction))))
                       huarong--directions))))

(defun huarong-hint ()
  "Highlight the next piece in a shortest solution."
  (interactive)
  (huarong--cancel-playback)
  (if (huarong--goal-p huarong--state)
      (message "这一局已经完成")
    (message "正在求解……")
    (let* ((moves (huarong--solve-state huarong--state))
           (move (car moves)))
      (setq huarong--selected (car move)
            huarong--status
            (format "提示：选中的棋块向%s移动（最短解还需 %d 步）"
                    (huarong--direction-name move) (length moves)))
      (huarong--render))))

(defun huarong--playback-step (buffer)
  "Play one automatic move in BUFFER."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (setq huarong--timer nil)
      (huarong--apply-move (pop huarong--playback))
      (when huarong--playback
        (setq huarong--timer
              (run-at-time huarong-playback-delay nil
                           #'huarong--playback-step buffer))))))

(defun huarong-solve ()
  "Find a shortest solution and play it automatically."
  (interactive)
  (huarong--cancel-playback)
  (if (huarong--goal-p huarong--state)
      (message "这一局已经完成")
    (message "正在求解……")
    (setq huarong--playback (huarong--solve-state huarong--state)
          huarong--status
          (format "已找到最短解：%d 步" (length huarong--playback)))
    (huarong--render)
    (setq huarong--timer
          (run-at-time huarong-playback-delay nil
                       #'huarong--playback-step (current-buffer)))))

(defun huarong-stop ()
  "Stop automatic playback."
  (interactive)
  (huarong--cancel-playback)
  (setq huarong--status "自动播放已停止")
  (huarong--render))

(defun huarong-quit ()
  "Quit the Huarong Dao window."
  (interactive)
  (huarong--cancel-playback)
  (quit-window))

;;;###autoload
(defun huarong ()
  "Create or show the Huarong Dao game buffer."
  (interactive)
  (let ((buffer (get-buffer-create huarong--buffer-name)))
    (with-current-buffer buffer
      (unless (derived-mode-p 'huarong-mode)
        (huarong-mode)
        (huarong--load-layout 0)))
    (pop-to-buffer buffer)))

(provide 'huarong)

;;; huarong.el ends here
