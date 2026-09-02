;;; package --- Summary -*- lexical-binding: t;-*-

;;; Commentary
;; My Init Settings for Emacs
;; C-c @ C-q 展示大纲模式，隐藏其它
;; C-c @ C-s 显示子节点

;;; Custom Files
(setq custom-file (locate-user-emacs-file "custom.el"))

(defconst my-emacs-config-directory
  (file-name-directory
   (file-truename (or load-file-name user-init-file)))
  "Directory containing the real init file behind its symbolic link.")

(add-to-list 'load-path
             (expand-file-name "lisp" my-emacs-config-directory))

(defun my-mode-line-separator (side)
  "Return a mode-line separator for SIDE.
SIDE should be either the symbol \='left or \='right."
  (let ((bg (face-attribute 'default :background))
        (sep (pcase side
               ('left  " ")
               ('right " ")
               (_      " ")))) ; fallback
    (propertize sep 'face `(:foreground ,bg))))

(load custom-file 'noerror 'nomessage) ; missing-ok, nomessage

;;; 设置语言
(setenv "LC_ALL" "en_US.UTF-8")
(set-default-coding-systems 'utf-8)
(set-buffer-file-coding-system 'utf-8)
(setq default-process-coding-system '(utf-8 . utf-8))
(setq system-time-locale "C")

;;; Startup Message
(defun display-startup-echo-area-message ()
  "Override the default one with my name and welcome."
  (message "Welcome back, Shengyi!"))

(require 'my-dashboard)
(add-hook 'window-setup-hook #'my-dashboard--maybe-show)
(autoload 'huarong "huarong" nil t)

(defun restart ()
  "Restart Emacs."
  (interactive)
  (when (y-or-n-p "Restart Emacs?")
    (let ((confirm-kill-emacs nil))
      (when (frame-parameter nil 'fullscreen)
        (set-frame-parameter nil 'fullscreen nil))
      (restart-emacs))))

(defun dired-show-only (regexp)
  "In Dired, show only files whose names match REGEXP.
Other lines are removed from the listing (buffer-only; files are untouched).
Use `revert-buffer' (\\[revert-buffer]) to restore the original listing."
  (interactive "sFiles to show (regexp): ")
  (dired-mark-files-regexp regexp)
  (dired-toggle-marks)
  (dired-do-kill-lines)
  (message "Dired: showing only files matching %s" regexp))

;;; Close tab after kill buffer
(defun kill-buffer-and-close-tab ()
  "Kill the current buffer and close its tab when appropriate."
  (interactive)
  (let ((tab-index (1+ (tab-bar--current-tab-index)))
        (last-tab-p (= 1 (length (funcall tab-bar-tabs-function))))
        (multiple-windows-p
         (< 1 (length (delete-dups (mapcar #'window-buffer (window-list)))))))
    (when (kill-current-buffer)
      (unless (or last-tab-p multiple-windows-p)
        (tab-bar-close-tab tab-index)))))

;;; 常用设置
(setq ns-use-thin-smoothing t)
(add-to-list 'default-frame-alist '(ns-transparent-titlebar . t))
(add-to-list 'default-frame-alist '(ns-appearance . dark))
(setq default-directory "~/")
(setq completion-ignore-case t)
(setq read-process-output-max 1048576)
(with-eval-after-load 'dired
  (require 'ls-lisp)
  (require 'dired-x)
  (keymap-set dired-mode-map "% s" #'dired-show-only)
  (keymap-set dired-mode-map "," #'browse-url-of-dired-file)
  (with-eval-after-load 'which-key
    ;; Show a friendly name for "% s".
    (which-key-add-keymap-based-replacements
     dired-mode-map "% s" "show only (regexp)")))
(add-hook 'dired-mode-hook
          (lambda ()
            ;; Set dired-x buffer-local variables here.  For example:
            (dired-omit-mode 1)
            ))
(add-hook 'c-mode-common-hook 'hs-minor-mode)
(add-hook 'c-ts-mode-common-hook 'hs-minor-mode)

(defvar-keymap my-spell-map
  :doc "Spell commands"
  "c" #'jinx-correct
  "n" #'jinx-next
  "p" #'jinx-previous)
(keymap-global-unset "s-j")
(keymap-global-set "s-j" my-spell-map)

(keymap-global-set "<f16>" #'toggle-frame-fullscreen)
(keymap-global-set "<f17>" #'restart)
(keymap-global-set "<f18>" #'list-packages)
(keymap-global-set "<f19>" #'save-buffers-kill-terminal)
(keymap-global-set "C-," #'embark-act)
(keymap-global-set "C-;" #'embark-dwim)
(keymap-global-set "C-c l" #'org-store-link)
(keymap-global-set "C-h B" #'embark-bindings)
(keymap-global-set "C-x /" #'webjump)
(keymap-global-set "C-x C-b" #'ibuffer)
(keymap-global-set "C-x M-r" #'consult-recent-file)
(keymap-global-set "C-x b" #'consult-buffer)
(keymap-global-set "C-x t b" #'consult-buffer-other-tab)
(keymap-global-set "C-x t k" #'tab-bar-close-tab-by-name)
(keymap-global-set "M-[" #'tab-bar-switch-to-prev-tab)
(keymap-global-set "M-]" #'tab-bar-switch-to-next-tab)
(keymap-global-set "M-o" #'occur)
(keymap-global-set "s-," #'customize-option)
(keymap-global-set "s-/" #'consult-line)
(keymap-global-set "s-;" #'avy-goto-char-timer)
(keymap-global-set "s-<return>" #'magit-status)
(keymap-global-set "s-<tab>" #'tab-switch)
(keymap-global-set "s-B" #'consult-buffer)
(keymap-global-set "s-D" #'dired)
(keymap-global-set "s-F" #'find-file)
(keymap-global-set "s-K" #'kill-current-buffer)
(keymap-global-set "s-R" #'consult-recent-file)
(keymap-global-set "s-[" #'tab-bar-switch-to-prev-tab)
(keymap-global-set "s-]" #'tab-bar-switch-to-next-tab)
(keymap-global-set "s-b" #'consult-buffer-other-tab)
(keymap-global-set "s-d" #'dired-other-tab)
(keymap-global-set "s-e" #'consult-flymake)
(keymap-global-set "s-f" #'find-file-other-tab)
(keymap-global-set "s-h" #'consult-org-heading)
(keymap-global-set "s-i" #'osx-dictionary-search-word-at-point)
(keymap-global-set "s-k" #'kill-buffer-and-close-tab)
(keymap-global-set "s-l" #'consult-goto-line)
(keymap-global-set "s-m" #'delete-other-windows)
(keymap-global-set "s-r" #'consult-ripgrep)
(keymap-global-set "s-s" #'consult-fd)
(keymap-global-set "s-t" #'tab-bar-new-tab)
(keymap-global-set "s-w" #'tab-bar-close-tab)
(keymap-global-set "s-z" #'delete-window)
(keymap-global-set "s-{" #'tab-bar-history-back)
(keymap-global-set "s-}" #'tab-bar-history-forward)
(keymap-global-unset "M-<down-mouse-1>")
(keymap-global-unset "M-<drag-mouse-1>")
(keymap-global-unset "M-<mouse-1>")
(keymap-global-unset "M-<mouse-2>")
(keymap-global-unset "M-<mouse-3>")
(keymap-global-unset "s-o")
(keymap-set minibuffer-local-map "C-l" #'embark-export)
(keymap-set emacs-lisp-mode-map "C-c C-n" #'emacs-lisp-native-compile)
(defalias 'elisp-repl 'ielm)
(with-eval-after-load 'paredit
  (keymap-unset paredit-mode-map "C-j")
  (keymap-unset paredit-mode-map "RET"))
(setq kill-buffer-query-functions
      (delq 'process-kill-buffer-query-function kill-buffer-query-functions))

(defun my-compile-init-after-save ()
  "Compile the user init file after saving it."
  (when (file-equal-p buffer-file-name user-init-file)
    (let ((source (file-truename buffer-file-name)))
      (when (byte-compile-file source)
        (native-compile-async source)))))

(add-hook 'before-save-hook
          (lambda ()
            (when (and (not (string-match ".*makefile.*" (message "%s" major-mode)))
                       (or (derived-mode-p 'prog-mode)
                           (eq major-mode 'coq-mode)
                           (eq major-mode 'org-mode)))
              (delete-trailing-whitespace))))
(add-hook 'after-save-hook
          #'executable-make-buffer-file-executable-if-script-p)
(add-hook 'after-save-hook #'my-compile-init-after-save)

;;; Spell checking
(modify-syntax-entry '(#x4E00 . #x9FFF) "_" (standard-syntax-table))

;; Trick: Use M-RET to confirm without the matching existed.

;;; Eglot
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((c++-mode c-mode c++-ts-mode c-ts-mode)
                 "clangd"))

  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode)
                 "basedpyright-langserver" "--stdio"))

  (keymap-set eglot-mode-map "s-E" #'eglot-code-actions)
  (keymap-set eglot-mode-map "s-i" #'eldoc-doc-buffer))

(dolist (hook '(c-mode-hook
                c++-mode-hook
                c-ts-mode-hook
                c++-ts-mode-hook
                python-mode-hook
                python-ts-mode-hook))
  (add-hook hook #'eglot-ensure))

;;; Useful Definitions
(defconst exclude-file-list '("\\`/[^/|:]+:" ".+\\.v"))

(defun my-icomplete-styles ()
  "Customize my icomplete styles."
  (setq-local completion-styles '(basic partial-completion flex)))

;;; Org Mode
(add-hook 'org-mode-hook 'org-appear-mode)
(with-eval-after-load 'org
  (global-org-modern-mode 1))

;;; Coq Settings
(defun allow-consult-preview ()
  "Allow consult preview when at least one .v file is opened."
  (when (and (boundp 'consult-preview-excluded-files)
             (member ".+\\.v" consult-preview-excluded-files))
    (delete ".+\\.v" consult-preview-excluded-files)))

(add-hook 'coq-mode-hook #'company-coq-mode)
(add-hook 'coq-mode-hook #'allow-consult-preview)

(setq coq-highlight-hyps-cited-in-response nil)

;;; Lisp
(add-hook 'slime-repl-mode-hook #'enable-paredit-mode)
(setq inferior-lisp-program "sbcl")
(setq common-lisp-hyperspec-root
      (concat "file://" (expand-file-name "~/Dropbox/Documents/HyperSpec/")))

;;; Vertico
(with-eval-after-load 'vertico
  (require 'vertico-directory)
  (require 'vertico-quick)

  (keymap-set vertico-map "s-;" #'vertico-quick-exit)
  (keymap-set vertico-map "DEL" #'vertico-directory-delete-char)
  (keymap-set vertico-map "M-DEL" #'vertico-directory-delete-word)
  (keymap-set vertico-map "RET" #'vertico-directory-enter)
  (add-hook 'rfn-eshadow-update-overlay-hook #'vertico-directory-tidy))

;;; 设置sokoban
;; (autoload 'sokoban "sokoban.el"
;;   "Start a new game of Sokoban." t)
;; (autoload 'sokoban-mode "sokoban.el"
;;   "Play Sokoban in current buffer." t)
;; (setq sokoban-levels-dir "c:/Useful/Open/emacs/site-lisp/sokoban-levels")

;;; 杂项
(defun zh-count-word ()
  "Count Chinese words."
  (interactive)
  (let ((beg (point-min)) (end (point-max))
        (eng 0) (non-eng 0))
    (if mark-active
        (setq beg (region-beginning)
              end (region-end)))
    (save-excursion
      (goto-char beg)
      (while (< (point) end)
        (cond ((not (equal (car (syntax-after (point))) 2))
               (forward-char))
              ((< (char-after) 128)
               (progn
                 (setq eng (1+ eng))
                 (forward-word)))
              (t
               (setq non-eng (1+ non-eng))
               (forward-char)))))
    (message "English words: %d\nNon-English characters: %d"
             eng non-eng)))

;;; 设置字体
(dolist (script '(latin greek cyrillic symbol))
  (set-fontset-font t script (font-spec :family "Iosevka Curly") nil 'prepend))
(dolist (script '(han kana hangul cjk-misc bopomofo))
  (set-fontset-font t script (font-spec :family "LXGW WenKai") nil 'prepend))
(set-fontset-font t '(#xe000 . #xf8ff) (font-spec :family "Iosevka Curly") nil 'prepend)
;; Iosevka Version = 34.8.1
;; Download from https://github.com/be5invis/Iosevka/releases


(defun f2c (fahrenheit)
  "Convert degrees Fahrenheit (FAHRENHEIT) to degrees Celsius."
  (interactive "nFahrenheit (°F): ")
  (message "%s °C" (/ (* 5 (- fahrenheit 32)) 9.0)))

(defun c2f (celsius)
  "Convert degrees Celsius (CELSIUS) to degrees Fahrenheit."
  (interactive "nCelsius (°C): ")
  (message "%s °F" (+ (/ (* celsius 9.0) 5.0) 32)))

(defvar ligatures-iosevka
  '("-<<" "-<" "-<-" "<--" "<---" "<<-" "<-" "->" "->>" "--->" "-->" "->-" ">-" ">>-"
    "=<<" "=<" "=<=" "<==" "<===" "<<=" "<=" "=>" "=>>" "===>" "==>" "=>=" ">=" ">>="
    "<->" "<-->" "<--->" "<---->" "<=>" "<==>" "<===>" "<====>" "::" ":::" "__"
    "<~~" "</" "</>" "/>" "~~>" "==" "!=" "<>" "===" "!==" "!==="
    "<:" ":=" "*=" "*+" "<*" "<*>" "*>" "<|" "<|>" "|>" "<." "<.>" ".>" "+*" "=*" "=:" ":>"
    "(*" "*)" "/*" "*/" "[|" "|]" "{|" "|}" "++" "+++" "\\/" "/\\" "|-" "-|" "<!--" "<!---"))

(use-package ligature
  :config
  (ligature-set-ligatures 'emacs-lisp-mode ligatures-iosevka)
  (ligature-set-ligatures 'coq-mode ligatures-iosevka)
  (ligature-set-ligatures 'lean4-mode ligatures-iosevka))

(pdf-loader-install)

;; Closure capturing private state so we only expose one public function.
(let ((encode-table nil)   ;; ASCII -> Fraktur (built on first use)
      (decode-table nil)   ;; Fraktur -> ASCII (built on first use)
      (fraktur-set  nil))  ;; membership set for detection
  (defun toggle-fraktur (beg end)
    "Toggle ASCII <-> Fraktur for region or prompted input.

If a region is active, detect its content: if it contains any Fraktur
letters, decode them back to ASCII; otherwise encode ASCII letters to
Fraktur. Without a region, prompt for a string, apply the same rule,
insert the result at point, and copy it to the kill-ring.

Note: Correct rendering depends on your font's support for these
Unicode code points."
    (interactive
     (if (use-region-p)
         (list (region-beginning) (region-end))
       (list nil nil)))
    ;; Initialize tables and membership set once.
    (unless encode-table
      (let ((lower-src "abcdefghijklmnopqrstuvwxyz")
            (lower-dst "𝖆𝖇𝖈𝖉𝖊𝖋𝖌𝖍𝖎𝖏𝖐𝖑𝖒𝖓𝖔𝖕𝖖𝖗𝖘𝖙𝖚𝖛𝖜𝖝𝖞𝖟")
            (upper-src "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
            (upper-dst "𝕬𝕭𝕮𝕯𝕰𝕱𝕲𝕳𝕴𝕵𝕶𝕷𝕸𝕹𝕺𝕻𝕼𝕽𝕾𝕿𝖀𝖁𝖂𝖃𝖄𝖅"))
        (setq encode-table (make-char-table 'translation-table nil)
              decode-table (make-char-table 'translation-table nil)
              fraktur-set  (make-char-table 'binary nil))
        ;; Lowercase map + membership
        (dotimes (i (length lower-src))
          (let ((a (aref lower-src i)) (f (aref lower-dst i)))
            (aset encode-table a f)
            (aset decode-table f a)
            (aset fraktur-set  f t)))
        ;; Uppercase map + membership
        (dotimes (i (length upper-src))
          (let ((a (aref upper-src i)) (f (aref upper-dst i)))
            (aset encode-table a f)
            (aset decode-table f a)
            (aset fraktur-set  f t)))))
    ;; Local helper: does S contain any Fraktur chars?
    (let ((has-fraktur?
           (lambda (s)
             (catch 'found
               (mapc (lambda (ch)
                       (when (aref fraktur-set ch)
                         (throw 'found t)))
                     (string-to-list s))
               nil))))
      (if (and beg end)
          ;; Region case
          (let* ((s (buffer-substring-no-properties beg end))
                 (decode? (funcall has-fraktur? s)))
            (translate-region beg end (if decode? decode-table encode-table))
            (message (if decode? "Decoded region from Fraktur to ASCII." "Encoded region from ASCII to Fraktur.")))
        ;; Prompted input case
        (let* ((s (read-string "Text to toggle (ASCII/Fraktur): "))
               (decode? (funcall has-fraktur? s))
               (tbl (if decode? decode-table encode-table))
               (out (apply #'string
                           (mapcar (lambda (ch) (or (aref tbl ch) ch))
                                   (string-to-list s)))))
          (kill-new out)
          (insert out)
          (message (if decode? "Decoded and yanked." "Encoded and yanked.")))))))

(use-package lsp-ui
  :ensure t
  :hook (lsp-mode . lsp-ui-mode))

;;; OCaml

(with-eval-after-load 'project
  (add-to-list 'project-vc-extra-root-markers "dune-project"))

(with-eval-after-load 'tuareg-opam
  (require 'flymake-proc))

(use-package utop
  :ensure t)

(use-package tuareg
  :ensure t
  :hook
  (tuareg-mode . utop-minor-mode))

(use-package eglot
  :ensure nil
  :bind (:map eglot-mode-map
              ("C-c C-f" . eglot-format)))

(use-package ocaml-eglot
  :ensure t
  :after tuareg
  :hook
  (tuareg-mode . ocaml-eglot-mode)
  (ocaml-eglot-mode . eglot-ensure))

;;; VTerm
(use-package vterm
  :ensure t
  :hook (vterm-mode . my/disable-hl-line)
  :config
  (defun my/disable-hl-line ()
    "Disable hl-line in vterm buffers."
    (when (bound-and-true-p global-hl-line-mode)
      (setq-local global-hl-line-mode nil))
    (hl-line-mode -1)))

;;; Helpful
(use-package helpful
  :ensure t
  :bind
  (("C-h f" . helpful-callable)
   ("C-h v" . helpful-variable)
   ("C-h k" . helpful-key)
   ("C-h x" . helpful-command)
   ("C-h ." . helpful-at-point)))

;;; 杂项

(add-hook 'after-init-hook 'envrc-global-mode)
(load-theme 'modus-vivendi)
(require 'my-box)
(my-box-enable)
(with-eval-after-load 'tab-bar
  (keymap-unset tab-bar-mode-map "s-0"))
(server-start)
(provide 'init)

;;; init.el ends here
