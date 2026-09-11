;;; -*- lexical-binding: t -*-
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(Info-additional-directory-list
   '("/opt/homebrew/share/info"
     "/usr/local/texlive/2026/texmf-dist/doc/info"))
 '(ansi-color-names-vector
   ["#212526" "#ff4b4b" "#b4fa70" "#fce94f" "#729fcf" "#ad7fa8" "#8cc4ff"
    "#eeeeec"])
 '(auto-save-visited-interval 3)
 '(auto-save-visited-mode t)
 '(avy-background t)
 '(avy-dispatch-alist
   '((120 . avy-action-kill-move) (88 . avy-action-kill-stay)
     (116 . avy-action-teleport) (109 . avy-action-mark)
     (119 . avy-action-copy) (121 . avy-action-yank)
     (89 . avy-action-yank-line) (122 . avy-action-zap-to-char)))
 '(avy-orders-alist '((avy-goto-char-timer . avy-order-closest)))
 '(backup-directory-alist '(("." . "~/.emacs.d/backup")))
 '(bidi-paragraph-direction 'left-to-right)
 '(blink-cursor-mode nil)
 '(c-basic-offset 4)
 '(column-number-mode t)
 '(comint-process-echoes t)
 '(company-backends '(company-math-symbols-unicode))
 '(company-idle-delay 0.3)
 '(company-minimum-prefix-length 2)
 '(completion-category-overrides '((file (styles basic partial-completion))))
 '(completion-cycle-threshold 3)
 '(completion-pcm-leading-wildcard t)
 '(completion-styles '(orderless basic))
 '(confirm-kill-emacs 'y-or-n-p)
 '(confirm-kill-processes nil)
 '(consult-preview-excluded-files exclude-file-list)
 '(delete-old-versions t)
 '(delete-selection-mode t)
 '(dired-dwim-target 'dired-dwim-target-next)
 '(dired-listing-switches "-alh")
 '(dired-recursive-copies 'always)
 '(dired-recursive-deletes 'always)
 '(display-buffer-alist
   '(("\\*\\(Packages\\|vterm\\|Apropos\\|info\\|Customize .*\\)\\*"
      display-buffer-in-tab)))
 '(display-time-24hr-format t)
 '(display-time-day-and-date t)
 '(display-time-default-load-average nil)
 '(display-time-mode t)
 '(eglot-code-action-indications '(margin))
 '(elisp-fontify-semantically t)
 '(emacs-lisp-mode-hook '(enable-paredit-mode outline-minor-mode))
 '(embark-help-key "?")
 '(embark-indicators
   '(embark--vertico-indicator embark-minimal-indicator
                               embark-highlight-indicator
                               embark-isearch-highlight-indicator))
 '(find-ls-option '("-exec ls -ldh {} +" . "-ldh"))
 '(gap-executable "/usr/local/bin/gap")
 '(gap-start-options '("-f" "-b" "-m" "2m" "-E"))
 '(geiser-chez-binary "chez")
 '(global-auto-revert-mode t)
 '(global-corfu-mode t)
 '(global-corfu-modes '((not lisp-mode) t))
 '(global-hl-line-mode t)
 '(global-jinx-mode t)
 '(grep-command "rg -nS --no-heading ")
 '(help-window-select t)
 '(history-length 200)
 '(icomplete-minibuffer-setup-hook '(my-icomplete-styles))
 '(ielm-mode-hook '(eldoc-mode))
 '(indent-tabs-mode nil)
 '(inhibit-startup-screen t)
 '(initial-scratch-message nil)
 '(latex-run-command "xelatex -shell-escape")
 '(lean4-delete-trailing-whitespace t)
 '(lisp-interaction-mode-hook '(enable-paredit-mode))
 '(lisp-mode-hook
   '(common-lisp-lisp-mode-hook slime-lisp-mode-hook enable-paredit-mode))
 '(ls-lisp-dirs-first t)
 '(ls-lisp-use-insert-directory-program nil)
 '(lsp-headerline-breadcrumb-enable nil)
 '(lsp-modeline-code-action-fallback-icon "✦")
 '(magit-status-margin '(t age magit-log-margin-width nil 18))
 '(major-mode-remap-alist
   '((c-mode . c-ts-mode) (c++-mode . c++-ts-mode)
     (html-mode . html-ts-mode) (markdown-mode . markdown-ts-mode)))
 '(marginalia-mode t)
 '(mode-line-collapse-minor-modes t)
 '(mode-line-collapse-minor-modes-to " ❖")
 '(mode-line-format
   '("%e" mode-line-front-space
     (:eval
      (cond ((and buffer-file-name buffer-read-only) "")
            ((and buffer-file-name (buffer-modified-p))
             (propertize "●" 'face '(:foreground "red")))))
     (:propertize " %b" face mode-line-buffer-id)
     (:eval (my-mode-line-separator 'left)) " %p  %l  %c"
     (:eval (my-mode-line-separator 'left))
     (project-mode-line project-mode-line-format)
     (:eval
      (when vc-mode (concat vc-mode (my-mode-line-separator 'left))))
     mode-line-format-right-align
     (:eval (my-mode-line-separator 'right)) mode-line-modes
     (:eval (my-mode-line-separator 'right)) mode-line-misc-info
     mode-line-end-spaces))
 '(mode-line-modes-delimiters nil)
 '(modus-themes-bold-constructs t)
 '(modus-themes-common-palette-overrides
   '((bg-mode-line-active bg-cyan-subtle)
     (bg-mode-line-inactive bg-mode-line-active)
     (border-mode-line-active unspecified)
     (border-mode-line-inactive unspecified)
     (bg-tab-bar bg-dim) (bg-tab-current bg-mode-line-active)
     (bg-tab-other bg-cyan-nuanced) (fringe unspecified)
     (bg-hl-line bg-cyan-nuanced)))
 '(modus-themes-italic-constructs t)
 '(modus-themes-prompts '(extrabold))
 '(mouse-avoidance-mode 'animate nil (avoid))
 '(mouse-wheel-progressive-speed nil)
 '(ns-alternate-modifier 'super)
 '(ns-command-modifier 'meta)
 '(orderless-matching-styles '(orderless-regexp orderless-literal orderless-prefixes))
 '(org-appear-autoentities t)
 '(org-appear-autosubmarkers t)
 '(org-babel-load-languages '((emacs-lisp . t) (lisp . t)))
 '(org-confirm-babel-evaluate nil)
 '(org-hide-emphasis-markers t)
 '(org-modern-star 'replace)
 '(org-modules
   '(ol-bibtex ol-docview ol-doi ol-eww ol-info org-mouse org-tempo
               ol-w3m))
 '(org-pretty-entities t)
 '(org-startup-folded 'fold)
 '(org-support-shift-select t)
 '(org-tags-column -90)
 '(package-archives
   '(("gnu" . "https://elpa.gnu.org/packages/")
     ("nongnu" . "https://elpa.nongnu.org/nongnu/")
     ("melpa" . "https://melpa.org/packages/")))
 '(package-native-compile t)
 '(package-selected-packages
   '(async-status avy company-coq consult corfu embark embark-consult
                  envrc gap-mode geiser-chez geiser-guile helpful jinx
                  lean4-mode ligature llama lsp-ui magit marginalia
                  ocaml-eglot orderless org-appear org-modern
                  osx-dictionary paredit pdf-tools proof-general
                  racket-mode slime tuareg utop vertico vterm
                  xterm-color yaml-mode))
 '(package-vc-selected-packages
   '((lean4-mode :url
                 "https://github.com/leanprover-community/lean4-mode.git")))
 '(pdf-view-use-imagemagick t)
 '(pdf-view-use-unicode-ligther nil)
 '(pixel-scroll-precision-mode t)
 '(proof-three-window-mode-policy 'hybrid)
 '(python-indent-guess-indent-offset nil)
 '(python-indent-offset 4)
 '(quit-window-kill-buffer t)
 '(read-buffer-completion-ignore-case t)
 '(recentf-exclude '(".+\\.el\\.gz" "~/\\.emacs\\.d/bookmarks"))
 '(recentf-mode t)
 '(repeat-mode t)
 '(save-place-mode t)
 '(savehist-mode t)
 '(scheme-mode-hook '(geiser-mode--maybe-activate enable-paredit-mode) t)
 '(scroll-bar-mode nil)
 '(switch-to-buffer-obey-display-actions t)
 '(tab-always-indent 'complete)
 '(tab-bar-auto-width-max nil)
 '(tab-bar-close-button-show nil)
 '(tab-bar-format '(tab-bar-format-tabs))
 '(tab-bar-history-mode t)
 '(tab-bar-mode t)
 '(tab-bar-new-button-show nil)
 '(tab-bar-new-tab-choice "*scratch*")
 '(tab-bar-new-tab-to 'rightmost)
 '(tab-bar-select-tab-modifiers '(super))
 '(tab-bar-show 1)
 '(tab-bar-tab-hints t)
 '(tool-bar-mode nil)
 '(tramp-syntax 'default nil (tramp))
 '(treesit-font-lock-level 4)
 '(user-full-name "Shengyi Wang")
 '(utop-command "opam exec -- dune utop . -- -emacs")
 '(utop-edit-command nil)
 '(vc-follow-symlinks t)
 '(version-control t)
 '(vertico-count 15)
 '(vertico-cycle t)
 '(vertico-mode t)
 '(vertico-resize t)
 '(visible-bell t)
 '(warning-suppress-log-types '((emacs) (emacs)))
 '(warning-suppress-types '((emacs) (emacs)))
 '(webjump-sites
   '(("Wikipedia"
      . [simple-query "wikipedia.org" "wikipedia.org/wiki/" ""])
     ("Google"
      . [simple-query "www.google.com"
                      "https://www.google.com/search?ie=utf-8&oe=utf-8&q="
                      ""])))
 '(which-key-mode t)
 '(windmove-default-keybindings '(nil super))
 '(windmove-delete-default-keybindings '(nil control super))
 '(windmove-mode t)
 '(windmove-wrap-around t))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:height 180 :family "Iosevka Shengyi"))))
 '(fixed-pitch ((t (:family "Iosevka Shengyi"))))
 '(fixed-pitch-serif ((t (:family "Iosevka Curly Slab"))))
 '(org-modern-symbol ((t (:family "Iosevka Shengyi"))) t)
 '(variable-pitch ((t (:family "Iosevka Aile")))))
