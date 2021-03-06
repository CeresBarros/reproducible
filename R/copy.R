#' Make a temporary sub-directory
#'
#' Create a temporary subdirectory in \code{tempdir()}.
#'
#' @param sub Character string, length 1. Can be a result of
#'   \code{file.path("smth", "smth2")} for nested temporary sub
#'   directories.
#'
#' @export
tempdir2 <- function(sub) {
  checkPath(file.path(tempdir(), sub), create = TRUE)
}

#' Recursive copying of nested environments, and other "hard to copy" objects
#'
#' When copying environments and all the objects contained within them, there are
#' no copies made: it is a pass-by-reference operation. Sometimes, a deep copy is
#' needed, and sometimes, this must be recursive (i.e., environments inside
#' environments).
#'
#' @param object  An R object (likely containing environments) or an environment.
#'
#' @param filebackedDir A directory to copy any files that are backing R objects,
#'                      currently only valid for \code{Raster} classes. Defaults
#'                      to \code{tempdir()}, which is unlikely to be very useful.
#'                      Can be \code{NULL}, which means that the file will not be
#'                      copied and could therefore cause a collision as the
#'                      pre-copied object and post-copied object would have the same
#'                      file backing them.
#'
#' @param ... Only used for custom Methods
#'
#' @author Eliot McIntire
#' @export
#' @importFrom data.table copy
#' @rdname Copy
#' @seealso \code{\link{.robustDigest}}
#'
#' @examples
#' e <- new.env()
#' e$abc <- letters
#' e$one <- 1L
#' e$lst <- list(W = 1:10, X = runif(10), Y = rnorm(10), Z = LETTERS[1:10])
#' ls(e)
#'
#' # 'normal' copy
#' f <- e
#' ls(f)
#' f$one
#' f$one <- 2L
#' f$one
#' e$one ## uh oh, e has changed!
#'
#' # deep copy
#' e$one <- 1L
#' g <- Copy(e)
#' ls(g)
#' g$one
#' g$one <- 3L
#' g$one
#' f$one
#' e$one
#'
setGeneric("Copy", function(object, filebackedDir, ...) {
  standardGeneric("Copy")
})

#' @rdname Copy
setMethod(
  "Copy",
  signature(object = "ANY"),
  definition = function(object, filebackedDir, ...) {
    return(object)
  })

#' @rdname Copy
setMethod("Copy",
          signature(object = "data.table"),
          definition = function(object, ...) {
            data.table::copy(object)
          })

#' @rdname Copy
setMethod("Copy",
          signature(object = "environment"),
          definition = function(object,  filebackedDir, ...) {
            if (missing(filebackedDir)) {
              filebackedDir <- tempdir2(rndstr(1, 8))
            }
            listVersion <- Copy(as.list(object, all.names = TRUE),
                                filebackedDir = filebackedDir, ...)
            #as.environment(listVersion)
            parentEnv <- parent.env(object)
            newEnv <- new.env(parent = parentEnv)
            list2env(listVersion, envir = newEnv)
            attr(newEnv, "name") <- attr(object, "name")
            newEnv
          })

#' @rdname Copy
setMethod("Copy",
          signature(object = "list"),
          definition = function(object,  filebackedDir, ...) {
            if (missing(filebackedDir)) {
              filebackedDir <- tempdir2(rndstr(1, 8))
            }

            lapply(object, function(x) Copy(x, filebackedDir, ...))
          })

#' @rdname Copy
setMethod("Copy",
          signature(object = "data.frame"),
          definition = function(object,  filebackedDir, ...) {
            object
          })

#' @rdname Copy
setMethod("Copy",
          signature(object = "Raster"),
          definition = function(object, filebackedDir, ...) {
            if (missing(filebackedDir)) {
              filebackedDir <- tempdir2(rndstr(1, 8))
            }
            if (!is.null(filebackedDir))
              object <- .prepareFileBackedRaster(object, repoDir = filebackedDir)
            object
          })

