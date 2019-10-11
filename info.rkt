#lang info
(define collection "search-upward")
(define deps '("base"))
(define build-deps '("scribble-lib" "racket-doc" "rackunit-lib"))
(define scribblings '(("scribblings/search-upward.scrbl" ())))
(define pkg-desc "Search for files and/or directories leading up to the root directory")
(define version "0.0")
(define pkg-authors '("Sage Gerard"))
