;;;; static.lisp

(in-package :rulisp)

(defparameter *rulisp-ns* "chrome://rulisp/")

(xpath:define-xpath-function colorize (code)
  (code-to-html code))

(xslt:define-xslt-element text2html (self input output)
  (let ((text (xpath:find-string input
                                 (xtree:attribute-value self "select"))))
    (if text
        (html:with-parse-html (doc text)
          (let ((root (or (xpath:find-single-node (xtree:root doc) "body")
                                             (xtree:root doc))))
          (iter (for node in-child-nodes root)
                (xtree:append-child output (xtree:copy node))))))))

(xslt:defxsl *content-xsl* (merge-pathnames "src/xsl/content.xsl" *rulisp-path*))
(xslt:defxsl *articles-xsl* (merge-pathnames "src/xsl/articles.xsl" *rulisp-path*))

(defun apply-xsl (style obj)
  (let ((xpath:*lisp-xpath-functions* `((colorize "colorize" ,*rulisp-ns*)))
        (xslt:*lisp-xslt-elements* `((text2html "text2html" ,*rulisp-ns*)))
        (path (merge-pathnames obj *rulisp-path*)))
    (if (fad:file-exists-p path)
        (in-pool (xslt:transform style
                                         (in-pool (xtree:parse path :xml-parse-noent ))))
        hunchentoot:+HTTP-NOT-FOUND+)))

(define-route main ("")
  (apply-xsl *content-xsl* "content/index.xml"))


(define-route css ("/css/:(theme)/:(file)")
  (skinpath (format nil "css/~A" file)
            theme))

(define-route image ("image/:(file)")
  (staticpath (format nil "image/~A" file)))

(define-route js ("js/:(file)")
  (staticpath (format nil "js/~A" file)))

(define-route articles ("articles/")
  (apply-xsl *content-xsl*
             "content/articles/index.xml"))

(define-route article ("articles/:(afile)")
  (let ((afile-length (length afile)))
    (if (and (> afile-length 4)
             (string= (subseq afile (- afile-length 5))
                      ".html"))
        (restas:redirect 'article :afile (subseq afile 0 (- afile-length 5)))
        (apply-xsl *articles-xsl*
                   (format nil "content/articles/~A.xml" afile)))))

(define-route favicon ("favicon.ico")
  (staticpath "favicon.ico"))

(define-route tools-list ("apps/")
  (in-pool (xtree:parse (tmplpath "apps.xml"))))


(define-route files ("files/:(file)")
  (merge-pathnames file (merge-pathnames "files/" *vardir*)))
