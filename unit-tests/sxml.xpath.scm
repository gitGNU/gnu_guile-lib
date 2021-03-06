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
;; Unit tests for (sxml xpath).
;;
;;; Code:

(use-modules (oop goops)
             (unit-test)
             (sxml xpath))

(define-class <test-xml-xpath> (<test-case>))

(define tree1 
  '(html
    (head (title "Slides"))
    (body
     (p (@ (align "center"))
	(table (@ (style "font-size: x-large"))
	       (tr
		(td (@ (align "right")) "Talks ")
		(td (@ (align "center")) " = ")
		(td " slides + transition"))
	       (tr (td)
		   (td (@ (align "center")) " = ")
		   (td " data + control"))
	       (tr (td)
		   (td (@ (align "center")) " = ")
		   (td " programs"))))
     (ul
      (li (a (@ (href "slides/slide0001.gif")) "Introduction"))
      (li (a (@ (href "slides/slide0010.gif")) "Summary")))
     )))


;; Example from a posting "Re: DrScheme and XML", 
;; Shriram Krishnamurthi, comp.lang.scheme, Nov. 26. 1999.
;; http://www.deja.com/getdoc.xp?AN=553507805
(define tree3
  '(poem (@ (title "The Lovesong of J. Alfred Prufrock")
	    (poet "T. S. Eliot"))
	 (stanza
	  (line "Let us go then, you and I,")
	  (line "When the evening is spread out against the sky")
	  (line "Like a patient etherized upon a table:"))
	 (stanza
	  (line "In the room the women come and go")
	  (line "Talking of Michaelangelo."))))

(define (run-test selector node expected)
  (assert-equal expected
                (selector node)))

(define-method (test-all (self <test-xml-xpath>))

  ;; Location path, full form: child::para 
  ;; Location path, abbreviated form: para
  ;; selects the para element children of the context node
  (let ((tree
         '(elem (@) (para (@) "para") (br (@)) "cdata" (para (@) "second par"))
         )
        (expected '((para (@) "para") (para (@) "second par")))
        )
    (run-test (select-kids (node-typeof? 'para)) tree expected)
    (run-test (sxpath '(para)) tree expected))

  ;; Location path, full form: child::* 
  ;; Location path, abbreviated form: *
  ;; selects all element children of the context node
  (let ((tree
         '(elem (@) (para (@) "para") (br (@)) "cdata" (para "second par"))
         )
        (expected
         '((para (@) "para") (br (@)) (para "second par")))
        )
    (run-test (select-kids (node-typeof? '*)) tree expected)
    (run-test (sxpath '(*)) tree expected))

  ;; Location path, full form: child::text() 
  ;; Location path, abbreviated form: text()
  ;; selects all text node children of the context node
  (let ((tree
         '(elem (@) (para (@) "para") (br (@)) "cdata" (para "second par"))
         )
        (expected
         '("cdata"))
        )
    (run-test (select-kids (node-typeof? '*text*)) tree expected)
    (run-test (sxpath '(*text*)) tree expected))

  ;; Location path, full form: child::node() 
  ;; Location path, abbreviated form: node()
  ;; selects all the children of the context node, whatever their node type
  (let* ((tree
          '(elem (@) (para (@) "para") (br (@)) "cdata" (para "second par"))
          )
         (expected (cdr tree))
         )
    (run-test (select-kids (node-typeof? '*any*)) tree expected)
    (run-test (sxpath '(*any*)) tree expected)
    )

  ;; Location path, full form: child::*/child::para 
  ;; Location path, abbreviated form: */para
  ;; selects all para grandchildren of the context node

  (let ((tree
         '(elem (@) (para (@) "para") (br (@)) "cdata" (para "second par")
                (div (@ (name "aa")) (para "third para")))
         )
        (expected
         '((para "third para")))
        )
    (run-test
     (node-join (select-kids (node-typeof? '*))
                (select-kids (node-typeof? 'para)))
     tree expected)
    (run-test (sxpath '(* para)) tree expected)
    )


  ;; Location path, full form: attribute::name 
  ;; Location path, abbreviated form: @name
  ;; selects the 'name' attribute of the context node

  (let ((tree
         '(elem (@ (name "elem") (id "idz")) 
                (para (@) "para") (br (@)) "cdata" (para (@) "second par")
                (div (@ (name "aa")) (para (@) "third para")))
         )
        (expected
         '((name "elem")))
        )
    (run-test
     (node-join (select-kids (node-typeof? '@))
                (select-kids (node-typeof? 'name)))
     tree expected)
    (run-test (sxpath '(@ name)) tree expected)
    )

  ;; Location path, full form:  attribute::* 
  ;; Location path, abbreviated form: @*
  ;; selects all the attributes of the context node
  (let ((tree
         '(elem (@ (name "elem") (id "idz")) 
                (para (@) "para") (br (@)) "cdata" (para "second par")
                (div (@ (name "aa")) (para (@) "third para")))
         )
        (expected
         '((name "elem") (id "idz")))
        )
    (run-test
     (node-join (select-kids (node-typeof? '@))
                (select-kids (node-typeof? '*)))
     tree expected)
    (run-test (sxpath '(@ *)) tree expected)
    )


  ;; Location path, full form: descendant::para 
  ;; Location path, abbreviated form: .//para
  ;; selects the para element descendants of the context node

  (let ((tree
         '(elem (@ (name "elem") (id "idz")) 
                (para (@) "para") (br (@)) "cdata" (para "second par")
                (div (@ (name "aa")) (para (@) "third para")))
         )
        (expected
         '((para (@) "para") (para "second par") (para (@) "third para")))
        )
    (run-test
     (node-closure (node-typeof? 'para))
     tree expected)
    (run-test (sxpath '(// para)) tree expected)
    )

  ;; Location path, full form: self::para 
  ;; Location path, abbreviated form: _none_
  ;; selects the context node if it is a para element; otherwise selects nothing

  (let ((tree
         '(elem (@ (name "elem") (id "idz")) 
                (para (@) "para") (br (@)) "cdata" (para "second par")
                (div (@ (name "aa")) (para (@) "third para")))
         )
        )
    (run-test (node-self (node-typeof? 'para)) tree '())
    (run-test (node-self (node-typeof? 'elem)) tree (list tree))
    )

  ;; Location path, full form: descendant-or-self::node()
  ;; Location path, abbreviated form: //
  ;; selects the context node, all the children (including attribute nodes)
  ;; of the context node, and all the children of all the (element)
  ;; descendants of the context node.
  ;; This is _almost_ a powerset of the context node.
  (let* ((tree
          '(para (@ (name "elem") (id "idz")) 
                 (para (@) "para") (br (@)) "cdata" (para "second par")
                 (div (@ (name "aa")) (para (@) "third para")))
          )
         (expected
          (cons tree
                (append (cdr tree)
                        '((@) "para" (@) "second par"
                          (@ (name "aa")) (para (@) "third para")
                          (@) "third para"))))
         )
    (run-test
     (node-or
      (node-self (node-typeof? '*any*))
      (node-closure (node-typeof? '*any*)))
     tree expected)
    (run-test (sxpath '(//)) tree expected)
    )

  ;; Location path, full form: ancestor::div 
  ;; Location path, abbreviated form: _none_
  ;; selects all div ancestors of the context node
  ;; This Location expression is equivalent to the following:
                                        ;	/descendant-or-self::div[descendant::node() = curr_node]
  ;; This shows that the ancestor:: axis is actually redundant. Still,
  ;; it can be emulated as the following SXPath expression demonstrates.

  ;; The insight behind "ancestor::div" -- selecting all "div" ancestors
  ;; of the current node -- is
  ;;  S[ancestor::div] context_node =
  ;;    { y | y=subnode*(root), context_node=subnode(subnode*(y)),
  ;;          isElement(y), name(y) = "div" }
  ;; We observe that
  ;;    { y | y=subnode*(root), pred(y) }
  ;; can be expressed in SXPath as 
  ;;    ((node-or (node-self pred) (node-closure pred)) root-node)
  ;; The composite predicate 'isElement(y) & name(y) = "div"' corresponds to 
  ;; (node-self (node-typeof? 'div)) in SXPath. Finally, filter
  ;; context_node=subnode(subnode*(y)) is tantamount to
  ;; (node-closure (node-eq? context-node)), whereas node-reduce denotes the
  ;; the composition of converters-predicates in the filtering context.

  (let*
      ((root
           '(div (@ (name "elem") (id "idz")) 
                 (para (@) "para") (br (@)) "cdata" (para (@) "second par")
                 (div (@ (name "aa")) (para (@) "third para"))))
       (context-node ; /descendant::any()[child::text() == "third para"]
        (car
         ((node-closure 
           (select-kids
            (node-equal? "third para")))
          root)))
       (pred
        (node-reduce (node-self (node-typeof? 'div))
                     (node-closure (node-eq? context-node))
                     ))
       )
    (run-test
     (node-or
      (node-self pred)
      (node-closure pred))
     root 
     (cons root
           '((div (@ (name "aa")) (para (@) "third para")))))
    )



  ;; Location path, full form: child::div/descendant::para 
  ;; Location path, abbreviated form: div//para
  ;; selects the para element descendants of the div element
  ;; children of the context node

  (let ((tree
         '(elem (@ (name "elem") (id "idz")) 
                (para (@) "para") (br (@)) "cdata" (para "second par")
                (div (@ (name "aa")) (para (@) "third para")
                     (div (para "fourth para"))))
         )
        (expected
         '((para (@) "third para") (para "fourth para")))
        )
    (run-test
     (node-join 
      (select-kids (node-typeof? 'div))
      (node-closure (node-typeof? 'para)))
     tree expected)
    (run-test (sxpath '(div // para)) tree expected)
    )


  ;; Location path, full form: /descendant::olist/child::item 
  ;; Location path, abbreviated form: //olist/item
  ;; selects all the item elements that have an olist parent (which is not root)
  ;; and that are in the same document as the context node
  ;; See the following test.

  ;; Location path, full form: /descendant::td/attribute::align 
  ;; Location path, abbreviated form: //td/@align
  ;; Selects 'align' attributes of all 'td' elements in tree1
  (let ((tree tree1)
        (expected
         '((align "right") (align "center") (align "center") (align "center"))
         ))
    (run-test
     (node-join 
      (node-closure (node-typeof? 'td))
      (select-kids (node-typeof? '@))
      (select-kids (node-typeof? 'align)))
     tree expected)
    (run-test (sxpath '(// td @ align)) tree expected)
    )


  ;; Location path, full form: /descendant::td[attribute::align] 
  ;; Location path, abbreviated form: //td[@align]
  ;; Selects all td elements that have an attribute 'align' in tree1
  (let ((tree tree1)
        (expected
         '((td (@ (align "right")) "Talks ") (td (@ (align "center")) " = ")
           (td (@ (align "center")) " = ") (td (@ (align "center")) " = "))
         ))
    (run-test
     (node-reduce 
      (node-closure (node-typeof? 'td))
      (filter
       (node-join
        (select-kids (node-typeof? '@))
        (select-kids (node-typeof? 'align)))))
     tree expected)
    (run-test (sxpath `(// td ,(node-self (sxpath '(@ align)))))  tree expected)
    (run-test (sxpath '(// (td (@ align)))) tree expected)
    (run-test (sxpath '(// ((td) (@ align)))) tree expected)
    ;; note! (sxpath ...) is a converter. Therefore, it can be used
    ;; as any other converter, for example, in the full-form SXPath.
    ;; Thus we can mix the full and abbreviated form SXPath's freely.
    (run-test
     (node-reduce 
      (node-closure (node-typeof? 'td))
      (filter
       (sxpath '(@ align))))
     tree expected)
    )


  ;; Location path, full form: /descendant::td[attribute::align = "right"] 
  ;; Location path, abbreviated form: //td[@align = "right"]
  ;; Selects all td elements that have an attribute align = "right" in tree1
  (let ((tree tree1)
        (expected
         '((td (@ (align "right")) "Talks "))
         ))
    (run-test
     (node-reduce 
      (node-closure (node-typeof? 'td))
      (filter
       (node-join
        (select-kids (node-typeof? '@))
        (select-kids (node-equal? '(align "right"))))))
     tree expected)
    (run-test (sxpath '(// (td (@ (equal? (align "right")))))) tree expected)
    )

  ;; Location path, full form: child::para[position()=1] 
  ;; Location path, abbreviated form: para[1]
  ;; selects the first para child of the context node
  (let ((tree
         '(elem (@ (name "elem") (id "idz")) 
                (para (@) "para") (br (@)) "cdata" (para "second par")
                (div (@ (name "aa")) (para (@) "third para")))
         )
        (expected
         '((para (@) "para"))
         ))
    (run-test
     (node-reduce
      (select-kids (node-typeof? 'para))
      (node-pos 1))
     tree expected)
    (run-test (sxpath '((para 1))) tree expected)
    )

  ;; Location path, full form: child::para[position()=last()] 
  ;; Location path, abbreviated form: para[last()]
  ;; selects the last para child of the context node
  (let ((tree
         '(elem (@ (name "elem") (id "idz")) 
                (para (@) "para") (br (@)) "cdata" (para "second par")
                (div (@ (name "aa")) (para (@) "third para")))
         )
        (expected
         '((para "second par"))
         ))
    (run-test
     (node-reduce
      (select-kids (node-typeof? 'para))
      (node-pos -1))
     tree expected)
    (run-test (sxpath '((para -1))) tree expected)
    )

  ;; Illustrating the following Note of Sec 2.5 of XPath:
  ;; "NOTE: The location path //para[1] does not mean the same as the
  ;; location path /descendant::para[1]. The latter selects the first
  ;; descendant para element; the former selects all descendant para
  ;; elements that are the first para children of their parents."

  (let ((tree
         '(elem (@ (name "elem") (id "idz")) 
                (para (@) "para") (br (@)) "cdata" (para "second par")
                (div (@ (name "aa")) (para (@) "third para")))
         )
        )
    (run-test
     (node-reduce                       ; /descendant::para[1] in SXPath
      (node-closure (node-typeof? 'para))
      (node-pos 1))
     tree '((para (@) "para")))
    (run-test (sxpath '(// (para 1))) tree
              '((para (@) "para") (para (@) "third para")))
    )

  ;; Location path, full form: parent::node()
  ;; Location path, abbreviated form: ..
  ;; selects the parent of the context node. The context node may be
  ;; an attribute node!
  ;; For the last test:
  ;; Location path, full form: parent::*/attribute::name
  ;; Location path, abbreviated form: ../@name
  ;; Selects the name attribute of the parent of the context node

  (let* ((tree
          '(elem (@ (name "elem") (id "idz")) 
                 (para (@) "para") (br (@)) "cdata" (para "second par")
                 (div (@ (name "aa")) (para (@) "third para")))
          )
         (para1                         ; the first para node
          (car ((sxpath '(para)) tree)))
         (para3                         ; the third para node
          (car ((sxpath '(div para)) tree)))
         (div                           ; div node
          (car ((sxpath '(// div)) tree)))
         )
    (run-test
     (node-parent tree)
     para1 (list tree))
    (run-test
     (node-parent tree)
     para3 (list div))
    (run-test                 ; checking the parent of an attribute node
     (node-parent tree)
     ((sxpath '(@ name)) div) (list div))
    (run-test
     (node-join
      (node-parent tree)
      (select-kids (node-typeof? '@))
      (select-kids (node-typeof? 'name)))
     para3 '((name "aa")))
    (run-test
     (sxpath `(,(node-parent tree) @ name))
     para3 '((name "aa")))
    )

  ;; Location path, full form: following-sibling::chapter[position()=1]
  ;; Location path, abbreviated form: none
  ;; selects the next chapter sibling of the context node
  ;; The path is equivalent to
  ;;  let cnode = context-node
  ;;    in
  ;;	parent::* / child::chapter [take-after node_eq(self::*,cnode)] 
  ;;		[position()=1]
  (let* ((tree
          '(document
            (preface "preface")
            (chapter (@ (id "one")) "Chap 1 text")
            (chapter (@ (id "two")) "Chap 2 text")
            (chapter (@ (id "three")) "Chap 3 text")
            (chapter (@ (id "four")) "Chap 4 text")
            (epilogue "Epilogue text")
            (appendix (@ (id "A")) "App A text")
            (References "References"))
          )
         (a-node                        ; to be used as a context node
          (car ((sxpath '(// (chapter (@ (equal? (id "two")))))) tree)))
         (expected
          '((chapter (@ (id "three")) "Chap 3 text")))
         )
    (run-test
     (node-reduce
      (node-join
       (node-parent tree)
       (select-kids (node-typeof? 'chapter)))
      (take-after (node-eq? a-node))
      (node-pos 1)
      )
     a-node expected)
    )

  ;; preceding-sibling::chapter[position()=1]
  ;; selects the previous chapter sibling of the context node
  ;; The path is equivalent to
  ;;  let cnode = context-node
  ;;    in
  ;;	parent::* / child::chapter [take-until node_eq(self::*,cnode)] 
  ;;		[position()=-1]
  (let* ((tree
          '(document
            (preface "preface")
            (chapter (@ (id "one")) "Chap 1 text")
            (chapter (@ (id "two")) "Chap 2 text")
            (chapter (@ (id "three")) "Chap 3 text")
            (chapter (@ (id "four")) "Chap 4 text")
            (epilogue "Epilogue text")
            (appendix (@ (id "A")) "App A text")
            (References "References"))
          )
         (a-node                        ; to be used as a context node
          (car ((sxpath '(// (chapter (@ (equal? (id "three")))))) tree)))
         (expected
          '((chapter (@ (id "two")) "Chap 2 text")))
         )
    (run-test
     (node-reduce
      (node-join
       (node-parent tree)
       (select-kids (node-typeof? 'chapter)))
      (take-until (node-eq? a-node))
      (node-pos -1)
      )
     a-node expected)
    )


  ;; /descendant::figure[position()=42]
  ;; selects the forty-second figure element in the document
  ;; See the next example, which is more general.

  ;; Location path, full form:
  ;;    child::table/child::tr[position()=2]/child::td[position()=3] 
  ;; Location path, abbreviated form: table/tr[2]/td[3]
  ;; selects the third td of the second tr of the table
  (let ((tree ((node-closure (node-typeof? 'p)) tree1))
        (expected
         '((td " data + control"))
         ))
    (run-test
     (node-join
      (select-kids (node-typeof? 'table))
      (node-reduce (select-kids (node-typeof? 'tr))
                   (node-pos 2))
      (node-reduce (select-kids (node-typeof? 'td))
                   (node-pos 3)))
     tree expected)
    (run-test (sxpath '(table (tr 2) (td 3))) tree expected)
    )


  ;; Location path, full form:
  ;;		child::para[attribute::type='warning'][position()=5] 
  ;; Location path, abbreviated form: para[@type='warning'][5]
  ;; selects the fifth para child of the context node that has a type
  ;; attribute with value warning
  (let ((tree
         '(chapter
           (para "para1")
           (para (@ (type "warning")) "para 2")
           (para (@ (type "warning")) "para 3")
           (para (@ (type "warning")) "para 4")
           (para (@ (type "warning")) "para 5")
           (para (@ (type "warning")) "para 6"))
         )
        (expected
         '((para (@ (type "warning")) "para 6"))
         ))
    (run-test
     (node-reduce
      (select-kids (node-typeof? 'para))
      (filter
       (node-join
        (select-kids (node-typeof? '@))
        (select-kids (node-equal? '(type "warning")))))
      (node-pos 5))
     tree expected)
    (run-test (sxpath '( (((para (@ (equal? (type "warning"))))) 5 )  ))
              tree expected)
    (run-test (sxpath '( (para (@ (equal? (type "warning"))) 5 )  ))
              tree expected)
    )


  ;; Location path, full form:
  ;;		child::para[position()=5][attribute::type='warning'] 
  ;; Location path, abbreviated form: para[5][@type='warning']
  ;; selects the fifth para child of the context node if that child has a 'type'
  ;; attribute with value warning
  (let ((tree
         '(chapter
           (para "para1")
           (para (@ (type "warning")) "para 2")
           (para (@ (type "warning")) "para 3")
           (para (@ (type "warning")) "para 4")
           (para (@ (type "warning")) "para 5")
           (para (@ (type "warning")) "para 6"))
         )
        (expected
         '((para (@ (type "warning")) "para 5"))
         ))
    (run-test
     (node-reduce
      (select-kids (node-typeof? 'para))
      (node-pos 5)
      (filter
       (node-join
        (select-kids (node-typeof? '@))
        (select-kids (node-equal? '(type "warning"))))))
     tree expected)
    (run-test (sxpath '( (( (para 5))  (@ (equal? (type "warning"))))))
              tree expected)
    (run-test (sxpath '( (para 5 (@ (equal? (type "warning")))) ))
              tree expected)
    )

  ;; Location path, full form:
  ;;		child::*[self::chapter or self::appendix]
  ;; Location path, semi-abbreviated form: *[self::chapter or self::appendix]
  ;; selects the chapter and appendix children of the context node
  (let ((tree
         '(document
           (preface "preface")
           (chapter (@ (id "one")) "Chap 1 text")
           (chapter (@ (id "two")) "Chap 2 text")
           (chapter (@ (id "three")) "Chap 3 text")
           (epilogue "Epilogue text")
           (appendix (@ (id "A")) "App A text")
           (References "References"))
         )
        (expected
         '((chapter (@ (id "one")) "Chap 1 text")
           (chapter (@ (id "two")) "Chap 2 text")
           (chapter (@ (id "three")) "Chap 3 text")
           (appendix (@ (id "A")) "App A text"))
         ))
    (run-test
     (node-join
      (select-kids (node-typeof? '*))
      (filter
       (node-or
        (node-self (node-typeof? 'chapter))
        (node-self (node-typeof? 'appendix)))))
     tree expected)
    (run-test (sxpath `(* ,(node-or (node-self (node-typeof? 'chapter))
                                    (node-self (node-typeof? 'appendix)))))
              tree expected)
    )


  ;; Location path, full form: child::chapter[child::title='Introduction'] 
  ;; Location path, abbreviated form: chapter[title = 'Introduction']
  ;; selects the chapter children of the context node that have one or more
  ;; title children with string-value equal to Introduction
  ;; See a similar example: //td[@align = "right"] above.

  ;; Location path, full form: child::chapter[child::title] 
  ;; Location path, abbreviated form: chapter[title]
  ;; selects the chapter children of the context node that have one or
  ;; more title children
  ;; See a similar example //td[@align] above.

  (let ((tree tree3)
        (expected
         '("Let us go then, you and I," "In the room the women come and go")
         ))
    (run-test
     (node-join
      (node-closure (node-typeof? 'stanza))
      (node-reduce 
       (select-kids (node-typeof? 'line)) (node-pos 1))
      (select-kids (node-typeof? '*text*)))
     tree expected)
    (run-test (sxpath '(// stanza (line 1) *text*)) tree expected)
    )
  )

(exit-with-summary (run-all-defined-test-cases))

;;; arch-tag: db5ae4a2-edc0-4bc1-bc6d-44fa91af182e
;;; xml.xpath.scm ends here
