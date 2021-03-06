;; guile-lib
;; Copyright (C) 2004 Andy Wingo <wingo at pobox dot com>

;; This program is free software; you can redistribute it and/or    
;; modify it under the terms of the GNU General Public License as   
;; published by the Free Software Foundation; either version 2 of   
;; the License, or (at your option) any later version.              
;;                                                                  
;; This program is distributed in the hope that it will be useful,  
;; but WITHOUT ANY WARRANTY; without even the implied warranty of   
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the    
;; GNU General Public License for more details.                     
;;                                                                  
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, contact:
;;
;; Free Software Foundation           Voice:  +1-617-542-5942
;; 59 Temple Place - Suite 330        Fax:    +1-617-542-2652
;; Boston, MA  02111-1307,  USA       gnu@gnu.org

;;; Commentary:
;;
;; Unit tests for (sxml transform).
;;
;;; Code:

(use-modules (oop goops)
             (unit-test)
             (sxml transform))

(define-class <test-xml-transform> (<test-case>))

(define-method (test-all (self <test-xml-transform>))
  (let* ((tree '(root (n1 (n11) "s12" (n13))
                  "s2"
                  (n2 (n21) "s22")
                  (n3 (n31 (n311))
                      "s32"
                      (n33 (n331) "s332" (n333))
                      "s34"))))
    (define (test pred-begin pred-end expected)
      (assert-equal expected
                    (car (replace-range pred-begin pred-end (list tree)))))

    ;; Remove one node, "s2"
    (test
     (lambda (node)
       (and (equal? node "s2") '()))
     (lambda (node) (list node))
     '(root (n1 (n11) "s12" (n13))
        (n2 (n21) "s22")
        (n3 (n31 (n311)) "s32" (n33 (n331) "s332" (n333)) "s34")))

    ;; Replace one node, "s2" with "s2-new"
    (test 
     (lambda (node)
       (and (equal? node "s2") '("s2-new")))
     (lambda (node) (list node))
     '(root (n1 (n11) "s12" (n13))
        "s2-new"
        (n2 (n21) "s22")
        (n3 (n31 (n311)) "s32" (n33 (n331) "s332" (n333)) "s34")))

    ;; Replace one node, "s2" with "s2-new" and its brother (n-new "s")
    (test 
     (lambda (node)
       (and (equal? node "s2") '("s2-new" (n-new "s"))))
     (lambda (node) (list node))
     '(root (n1 (n11) "s12" (n13))
        "s2-new" (n-new "s")
        (n2 (n21) "s22")
        (n3 (n31 (n311)) "s32" (n33 (n331) "s332" (n333)) "s34")))

    ;; Remove everything from "s2" onward
    (test 
     (lambda (node)
       (and (equal? node "s2") '()))
     (lambda (node) #f)
     '(root (n1 (n11) "s12" (n13))))
   
    ;; Remove everything from "n1" onward
    (test 
     (lambda (node)
       (and (pair? node) (eq? 'n1 (car node)) '()))
     (lambda (node) #f)
     '(root))

    ;; Replace from n1 through n33
    (test 
     (lambda (node)
       (and (pair? node)
            (eq? 'n1 (car node))
            (list node '(n1* "s12*"))))
     (lambda (node)
       (and (pair? node)
            (eq? 'n33 (car node))
            (list node)))
     '(root
          (n1 (n11) "s12" (n13))
        (n1* "s12*")
        (n3 
         (n33 (n331) "s332" (n333))
         "s34")))))

(exit-with-summary (run-all-defined-test-cases))

;;; arch-tag: 67f67d9b-b78f-489a-8963-fc24001c502a
;;; xml.transform.scm ends here
