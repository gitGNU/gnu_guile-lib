;; guile-lib
;; Copyright (C) 2004 Andy Wingo <wingo at pobox dot com>

;; This file is based on SSAX's SXML-to-HTML.scm and is in the public
;; domain.

;;; Commentary:
;;
;;A simple interface to XML parsing and serialization.
;;
;;; Code:

(define-module (sxml simple)
  #:use-module (sxml ssax-simple)
  #:use-module (sxml transform)
  #:use-module (ice-9 optargs)
  #:use-module (srfi srfi-13)
  #:use-module (scheme documentation)
  #:export (xml->sxml sxml->xml sxml->string universal-sxslt-rules))

(define* (xml->sxml #:optional (port (current-input-port)))
  "Use SSAX to parse an XML document into SXML. Takes one optional
argument, @var{port}, which defaults to the current input port."
  (ssax:xml->sxml port '()))

;; Universal transformation rules. Works for all XML.
(define-with-docs universal-sxslt-rules
  "A set of @code{pre-post-order} rules that transform any SXML tree
into a form suitable for XML serialization by @code{(sxml transform)}'s
@code{SRV:send-reply}. Used internally by @code{sxml->xml}."
  `((@ 
     ((*default* . ,(lambda (attr-key . value) ((enattr attr-key) value))))
     . ,(lambda (trigger . value) (list '@ value)))
    (*ENTITY*    . ,(lambda (tag name) (list "&" name ";")))
    (*PI*    . ,(lambda (pi tag str) (list "<?" tag " " str "?>")))
    ;; Is this right for entities? I don't have a reference for
    ;; public-id/system-id at the moment...
    (*default*   . ,(lambda (tag . elems) (apply (entag tag) elems)))
    (*text*      . ,(lambda (trigger str) 
                      (if (string? str) (string->escaped-xml str) str)))))

(define* (sxml->xml tree #:optional (port (current-output-port)))
  "Serialize the sxml tree @var{tree} as XML. The output will be written
to the current output port, unless the optional argument @var{port} is
present."
  (with-output-to-port port
    (lambda ()
      (SRV:send-reply
       (post-order
        tree
        universal-sxslt-rules)))))

(define (sxml->string sxml)
  "Detag an sxml tree @var{sxml} into a string. Does not perform any
formatting."
  (string-concatenate-reverse
   (foldts
    (lambda (seed tree)                 ; fdown
      '())
    (lambda (seed kid-seed tree)        ; fup
      (append! kid-seed seed))
    (lambda (seed tree)                 ; fhere
      (if (string? tree) (cons tree seed) seed))
    '()
    sxml)))

;; The following two functions serialize tags and attributes. They are
;; being used in the node handlers for the post-order function, see
;; above.

(define (check-name name)
  (let* ((str (symbol->string name))
         (i (string-index str #\:))
         (head (or (and i (substring str 0 i)) str))
         (tail (and i (substring str (1+ i)))))
    (and i (string-index (substring str (1+ i)) #\:)
         (error "Invalid QName: more than one colon" name))
    (for-each
     (lambda (s)
       (and s
            (or (char-alphabetic? (string-ref s 0))
                (eq? (string-ref s 0) #\_)
                (error "Invalid name starting character" s name))
            (string-for-each
             (lambda (c)
               (or (char-alphabetic? c) (string-index "0123456789.-_" c)
                   (error "Invalid name character" c s name)))
             s)))
     (list head tail))))

(define (entag tag)
  (check-name tag)
  (lambda elems
    (if (and (pair? elems) (pair? (car elems)) (eq? '@ (caar elems)))
        (list #\< tag (cdar elems)
              (if (pair? (cdr elems))
                  (list #\> (cdr elems) "</" tag #\>)
                  " />"))
        (list #\< tag
              (if (pair? elems)
                  (list #\> elems "</" tag #\>)
                  " />")))))
 
(define (enattr attr-key)
  (check-name attr-key)
  (let ((attr-str (symbol->string attr-key)))
    (lambda (value)
      (list #\space attr-str
            "=\"" (and (not (null? value)) value) #\"))))

(define (make-char-quotator char-encoding)
  (let ((bad-chars (map car char-encoding)))
 
    ;; Check to see if str contains one of the characters in charset,
    ;; from the position i onward. If so, return that character's index.
    ;; otherwise, return #f
    (define (index-cset str i charset)
      (let loop ((i i))
        (and (< i (string-length str))
             (if (memv (string-ref str i) charset) i
                 (loop (+ 1 i))))))
 
    ;; The body of the function
    (lambda (str)
      (let ((bad-pos (index-cset str 0 bad-chars)))
        (if (not bad-pos) str   ; str had all good chars
            (string-concatenate-reverse
             (let loop ((from 0) (to bad-pos) (out '()))
               (cond
                ((>= from (string-length str)) out)
                ((not to)
                 (cons (substring str from (string-length str)) out))
                (else
                 (let ((quoted-char
                        (cdr (assv (string-ref str to) char-encoding)))
                       (new-to
                        (index-cset str (+ 1 to) bad-chars)))
                   (loop (1+ to) new-to
                         (if (< from to)
                             (cons* (substring str from to) quoted-char out)
                             (cons quoted-char out)))))))))))

;; Given a string, check to make sure it does not contain characters
;; such as '<' or '&' that require encoding. Return either the original
;; string, or a list of string fragments with special characters
;; replaced by appropriate character entities.

(define string->escaped-xml
  (make-char-quotator
   '((#\< . "&lt;") (#\> . "&gt;") (#\& . "&amp;") (#\" . "&quot;"))))

;;; arch-tag: 9c853b25-d82f-42ef-a959-ae26fdc7d1ac
;;; simple.scm ends here

