#lang racket/base

(require racket/contract)
(define upward-matcher/c (-> path? (or/c path? #f)))
(provide upward-matcher/c
         (contract-out [search-upward/first
                        (-> upward-matcher/c directory-exists? (or/c path? #f))]

                       [search-upward
                        (-> upward-matcher/c directory-exists? (listof path?))]

                       [file-by-exact-name
                        (-> path-string? upward-matcher/c)]

                       [directory-by-exact-name
                        (-> path-string? upward-matcher/c)]

                       [by-exact-name
                        (-> path-string? upward-matcher/c)]))


(define (search-upward predicate [start (current-directory)] [matches '()])
  (define matches+
    (let ([res (predicate start)])
      (if res
          (cons res matches)
          matches)))

  (define up (simplify-path (build-path start "..")))
  (if (equal? start up)
      (reverse matches+)
      (search-upward predicate up matches+)))

(define (search-upward/first predicate [start (current-directory)])
  (define result (predicate start))
  (if result
      result
      (let ([up (simplify-path (build-path start ".."))])
        (if (equal? start up)
            #f
            (search-upward/first predicate up)))))

(define (file-by-exact-name name)
  (λ (base)
    (define path (build-path base name))
    (and (file-exists? path)
         (member 'read (file-or-directory-permissions path))
         path)))

(define (directory-by-exact-name name)
  (λ (base)
    (define path (build-path base name))
    (and (directory-exists? path)
         (member 'read (file-or-directory-permissions path))
         path)))

(define (by-exact-name name)
  (define d (directory-by-exact-name name))
  (define f (file-by-exact-name name))
  (λ (base) (or (d base) (f base))))

(module+ test
  (require rackunit
           racket/file)
  (define basedir (make-temporary-file "upward-test-~a" 'directory))
  (define (mkpath . els) (apply build-path basedir els))
  (define (mkdir . els) (make-directory* (apply mkpath els)))
  (define (mkfile . els) (display-to-file "" (apply mkpath els)))
  (define x-marks-the-spot (by-exact-name "x"))
 
  (dynamic-wind
    (λ _
      (mkdir "q/r/s")
      (mkdir "a/b/c")
      (mkfile "x")
      (mkfile "q/r/x")
      (mkfile "a/b/c/x")
      (mkfile "a/x"))
    (λ _
      (test-case "Finding multiple matches"
        (test-equal? "Can collect all matching files"
                     (search-upward x-marks-the-spot
                                  (mkpath "a/b/c"))
                     `(,(mkpath "a/b/c/x")
                       ,(mkpath "a/x")
                       ,(mkpath "x")))
        (test-equal? "No matches produces an empty list"
                     (search-upward x-marks-the-spot
                                  (build-path "/does/not/exist"))
                     '()))
      (test-case "Finding one match"
        (test-equal? "Can find the one most specific file"
                     (search-upward/first x-marks-the-spot
                                        (mkpath "q/r"))
                     (mkpath "q/r/x"))
        (test-false "No matches? Return #f"
                    (search-upward/first x-marks-the-spot
                                       (build-path "/no/where")))))
    (λ _ (delete-directory/files basedir))))
