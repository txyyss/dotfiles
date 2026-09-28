;;; my-tools.el --- Personal utility commands -*- lexical-binding: t; -*-

;;; Commentary:
;; Everyday commands for temperature and text conversion.

;;; Code:

(require 'seq)

(defun f2c (fahrenheit)
  "Convert degrees Fahrenheit (FAHRENHEIT) to degrees Celsius."
  (interactive "nFahrenheit (°F): ")
  (message "%s °C" (/ (* 5 (- fahrenheit 32)) 9.0)))

(defun c2f (celsius)
  "Convert degrees Celsius (CELSIUS) to degrees Fahrenheit."
  (interactive "nCelsius (°C): ")
  (message "%s °F" (+ (/ (* celsius 9.0) 5.0) 32)))

(defconst my-tools--unicode-alphabets
  '((bold . "𝐀𝐁𝐂𝐃𝐄𝐅𝐆𝐇𝐈𝐉𝐊𝐋𝐌𝐍𝐎𝐏𝐐𝐑𝐒𝐓𝐔𝐕𝐖𝐗𝐘𝐙𝐚𝐛𝐜𝐝𝐞𝐟𝐠𝐡𝐢𝐣𝐤𝐥𝐦𝐧𝐨𝐩𝐪𝐫𝐬𝐭𝐮𝐯𝐰𝐱𝐲𝐳")
    (italic . "𝐴𝐵𝐶𝐷𝐸𝐹𝐺𝐻𝐼𝐽𝐾𝐿𝑀𝑁𝑂𝑃𝑄𝑅𝑆𝑇𝑈𝑉𝑊𝑋𝑌𝑍𝑎𝑏𝑐𝑑𝑒𝑓𝑔ℎ𝑖𝑗𝑘𝑙𝑚𝑛𝑜𝑝𝑞𝑟𝑠𝑡𝑢𝑣𝑤𝑥𝑦𝑧")
    (bold-italic . "𝑨𝑩𝑪𝑫𝑬𝑭𝑮𝑯𝑰𝑱𝑲𝑳𝑴𝑵𝑶𝑷𝑸𝑹𝑺𝑻𝑼𝑽𝑾𝑿𝒀𝒁𝒂𝒃𝒄𝒅𝒆𝒇𝒈𝒉𝒊𝒋𝒌𝒍𝒎𝒏𝒐𝒑𝒒𝒓𝒔𝒕𝒖𝒗𝒘𝒙𝒚𝒛")
    (fraktur . "𝔄𝔅ℭ𝔇𝔈𝔉𝔊ℌℑ𝔍𝔎𝔏𝔐𝔑𝔒𝔓𝔔ℜ𝔖𝔗𝔘𝔙𝔚𝔛𝔜ℨ𝔞𝔟𝔠𝔡𝔢𝔣𝔤𝔥𝔦𝔧𝔨𝔩𝔪𝔫𝔬𝔭𝔮𝔯𝔰𝔱𝔲𝔳𝔴𝔵𝔶𝔷")
    (bold-fraktur . "𝕬𝕭𝕮𝕯𝕰𝕱𝕲𝕳𝕴𝕵𝕶𝕷𝕸𝕹𝕺𝕻𝕼𝕽𝕾𝕿𝖀𝖁𝖂𝖃𝖄𝖅𝖆𝖇𝖈𝖉𝖊𝖋𝖌𝖍𝖎𝖏𝖐𝖑𝖒𝖓𝖔𝖕𝖖𝖗𝖘𝖙𝖚𝖛𝖜𝖝𝖞𝖟")
    (double-struck . "𝔸𝔹ℂ𝔻𝔼𝔽𝔾ℍ𝕀𝕁𝕂𝕃𝕄ℕ𝕆ℙℚℝ𝕊𝕋𝕌𝕍𝕎𝕏𝕐ℤ𝕒𝕓𝕔𝕕𝕖𝕗𝕘𝕙𝕚𝕛𝕜𝕝𝕞𝕟𝕠𝕡𝕢𝕣𝕤𝕥𝕦𝕧𝕨𝕩𝕪𝕫")
    (smallcaps . "ABCDEFGHIJKLMNOPQRSTUVWXYZᴀʙᴄᴅᴇꜰɢʜɪᴊᴋʟᴍɴᴏᴘꞯʀꜱᴛᴜᴠᴡxʏᴢ"))
  "Style alphabets corresponding to ASCII A-Z followed by a-z.
Small caps leave uppercase letters and x unchanged for reversible mapping.")

(defvar my-tools--unicode-tables nil
  "Cached forward and reverse character tables for each Unicode style.")

(defun toggle-unicode-style (style)
  "Toggle ASCII letters and Unicode STYLE in the region or prompted input.
If any letters of STYLE are present, decode them; otherwise encode ASCII
letters.  Other styles, digits, and nonletters remain unchanged.
Without an active region, prompt for text, insert it, and copy it to the
kill ring.  Small caps convert only lowercase letters, leaving x unchanged."
  (interactive
   (list (intern (completing-read "Unicode style: "
                                  my-tools--unicode-alphabets nil t
                                  nil nil "bold"))))
  (let ((pair (alist-get style my-tools--unicode-tables)))
    (unless pair
      (setq pair (cons (make-char-table 'translation-table nil)
                       (make-char-table 'translation-table nil)))
      (let ((ascii "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
            (styled (alist-get style my-tools--unicode-alphabets)))
        (dotimes (i (length ascii))
          (let ((from (aref ascii i)) (to (aref styled i)))
            ;; Unchanged letters must not trigger decoding.
            (unless (= from to)
              (aset (car pair) from to)
              (aset (cdr pair) to from)))))
      (setf (alist-get style my-tools--unicode-tables) pair))
    (let* ((region (use-region-p))
           (text (if region
                     (buffer-substring-no-properties
                      (region-beginning) (region-end))
                   (read-string (format "Text to toggle (%s): " style))))
           (decode (seq-some (lambda (ch) (aref (cdr pair) ch)) text))
           (table (if decode (cdr pair) (car pair))))
      (if region
          (translate-region (region-beginning) (region-end) table)
        (let ((out (apply #'string
                          (mapcar (lambda (ch) (or (aref table ch) ch))
                                  (string-to-list text)))))
          (kill-new out)
          (insert out)))
      (message "%s %s%s" (if decode "Removed" "Applied") style
               (if region "." "; inserted and copied.")))))

(defun toggle-bold ()
  "Toggle ASCII letters and Unicode bold."
  (interactive)
  (toggle-unicode-style 'bold))

(defun toggle-italic ()
  "Toggle ASCII letters and Unicode italic."
  (interactive)
  (toggle-unicode-style 'italic))

(defun toggle-bold-italic ()
  "Toggle ASCII letters and Unicode bold italic."
  (interactive)
  (toggle-unicode-style 'bold-italic))

(defun toggle-fraktur ()
  "Toggle ASCII letters and Unicode Fraktur."
  (interactive)
  (toggle-unicode-style 'fraktur))

(defun toggle-bold-fraktur ()
  "Toggle ASCII letters and Unicode bold Fraktur."
  (interactive)
  (toggle-unicode-style 'bold-fraktur))

(defun toggle-double-struck ()
  "Toggle ASCII letters and Unicode double-struck letters."
  (interactive)
  (toggle-unicode-style 'double-struck))

(defun toggle-smallcaps ()
  "Toggle lowercase ASCII letters and small caps; uppercase and x stay as is."
  (interactive)
  (toggle-unicode-style 'smallcaps))

(provide 'my-tools)
;;; my-tools.el ends here
