(defun dot-name (exp)
  (substitute-if #\_ (complement #'alphanumericp) (prin1-to-string exp)))

(defparameter *max-label-length* 40)
(defun dot-label (exp)
  (if exp
    (let ((label (remove-if #'listp exp)))
      (let ((s (remove-if (lambda (x) (or (eq '#\( x) (eq '#\) x))) (write-to-string label :pretty nil :escape nil))))
        (if (> (length s) *max-label-length*)
            (concatenate 'string (subseq s 0 (- *max-label-length* 3)) "...")
            s)))
    ""))

(defun dot-attrs (exp)
  (if exp
    (let ((attrs (remove-if-not #'listp exp)))
      (dot-attributes attrs))
    ""))

;; format a list of 2-element-lists
;; '((penwidth 2.0) (fillcolor blue) (style filled))
;; becomes
;; " penwidth=2.0 fillcolor=blue style=filled "
;; for convenience, spaces are emitted at both ends of the result
(defun dot-attributes (attributes)
  (apply #'concatenate (cons 'string (mapcar #'dot-attribute attributes))))

(defun dot-attribute (attr)
 (concatenate 'string " "
                      (write-to-string (car attr) :case :downcase)
                      "="
                      (write-to-string (cadr attr) :case :downcase)
                      " "))

(defun nodes->dot (nodes)
  (mapc (lambda (node)
          (fresh-line)
          (princ (dot-name (car node)))
          (princ "[label=\"")
          (princ (dot-label node))
          (princ "\"")
          (princ (dot-attrs node))
          (princ "];"))
         nodes))

(defun edges->dot (edges)
  (mapc (lambda (node)
          (mapc (lambda (edge)
                  (fresh-line)
                  (princ (dot-name (car node)))
                  (princ "->")
                  (princ (dot-name (car edge)))
                  (princ "[label=\"")
                  (princ (dot-label (cdr edge)))
                  (princ "\"]"))
                (cdr node)))
        edges))

(defun graph->dot (nodes edges)
  (princ "digraph{")
  (nodes->dot nodes)
  (edges->dot edges)
  (princ "}"))

(defun dot->png (fname thunk)
  (with-open-file (*standard-output*
                   fname
                   :direction :output
                   :if-exists :supersede)
    (funcall thunk))
  (ext:shell (concatenate 'string "dot -Tsvg -O " fname)))

(defun graph->png (fname nodes edges)
  (dot->png fname (lambda () (graph->dot nodes edges))))

(defun uedges->dot (edges)
  (maplist (lambda (lst)
             (mapc (lambda (edge)
                     (unless (assoc (car edge) (cdr lst))
                       (fresh-line)
                       (princ (dot-name (caar lst)))
                       (princ "--")
                       (princ (dot-name (car edge)))
                       (princ "[label=\"")
                       (princ (dot-label (cdr edge)))
                       (princ "\"];")))
                   (cdar lst)))
           edges))

(defun ugraph->dot (nodes edges)
  (princ "graph{")
  (nodes->dot nodes)
  (uedges->dot edges)
  (princ "}"))

(defun ugraph->png (fname nodes edges)
  (dot->png fname (lambda () (ugraph->dot nodes edges))))
