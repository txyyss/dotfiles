;;; my-tools.el --- Personal utility commands -*- lexical-binding: t; -*-

;;; Commentary:
;; Everyday commands for temperature and text conversion.

;;; Code:

(defun f2c (fahrenheit)
  "Convert degrees Fahrenheit (FAHRENHEIT) to degrees Celsius."
  (interactive "nFahrenheit (°F): ")
  (message "%s °C" (/ (* 5 (- fahrenheit 32)) 9.0)))

(defun c2f (celsius)
  "Convert degrees Celsius (CELSIUS) to degrees Fahrenheit."
  (interactive "nCelsius (°C): ")
  (message "%s °F" (+ (/ (* celsius 9.0) 5.0) 32)))

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

(provide 'my-tools)
;;; my-tools.el ends here
