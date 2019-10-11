#lang scribble/manual
@require[@for-label[search-upward
                    racket/base]]

@title{Searching for Files Approaching Root Directory}
@author{Sage Gerard}

@defmodule[search-upward]

A small library for searching for a specific file or directory
by walking up directories until hitting the root of the associated
filesystem.

@defthing[upward-matcher/c (-> directory-exists? (or/c path? #f))]{
A procedure that accepts a path to a directory @italic{D} and returns a path
indicating a matching directory or file in @italic{D}, or @racket[#f] if
no match is found.
}

@defproc[(search-upward [include? upward-matcher/c]
                        [start path? (current-directory)])
                        (listof path?)]{
Apply @tt{include?} to @tt{start}, @tt{start/..}, @tt{start/../..}, and so on up
until the applicable root directory. Returns a list of all paths from
@tt{include?}, ordered by number of path elements (descending).

Returns an empty list if no match is found.

@racketinput[
(search-upward
  (λ (base) (directory-exists? (build-path base "node_modules")))
  "/home/user/js-project/packageA/src/subpackageB")        
]
@verbatim{
'(#<path:/home/user/js-project/packageA/src/subpackageB/node_modules>
  #<path:/home/user/js-project/packageA/node_modules>
  #<path:/home/user/js-project/node_modules>)
}
}

@defproc[(search-upward/first [include? upward-matcher/c]
                            [start path? (current-directory)])
                            (or/c path? #f)]{
Like @racket[search-upward], except the search will stop
on the first match and return the path for that match. Returns
@racket[#f] if there is no match at the applicable root directory.
}

@deftogether[(
@defproc[(directory-by-exact-name [name path-string?]) upward-matcher/c]
@defproc[(file-by-exact-name [name path-string?]) upward-matcher/c]
@defproc[(by-exact-name [name path-string?]) upward-matcher/c]
)]{
Each of these procedures return an @racket[upward-matcher/c] that
checks if @tt{name} exists in the given directory @italic{and} is readable.

@itemlist[
@item{@racket[directory-by-exact-name] will only match if the name is for a directory.
      @racketblock[(search-upward (directory-by-exact-name "node_modules"))]}
@item{@racket[file-by-exact-name] will only match files.
      @racketblock[(search-upward (file-by-exact-name ".gitattributes"))]}
@item{@racket[by-exact-name] will match either files or directories.
      @racketblock[(search-upward (by-exact-name ".config"))]}]
}

