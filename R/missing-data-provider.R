#' MissingDataProvider
#'
#' @export
#' @keywords internal
#' @details
#' \strong{Methods}
#'   \describe{
#'     \item{\code{make_missing()}}{
#'       make missing data
#'       \itemize{
#'        \item x: a vector of characters, numeric, integers, logicals, etc
#'       }
#'     }
#'   }
#' @format NULL
#' @usage NULL
#' @examples
#' z <- MissingDataProvider$new()
#' z$make_missing(letters)
MissingDataProvider <- R6::R6Class(
  inherit = BaseProvider,
  'MissingDataProvider',
  public = list(

    make_missing = function(x) {
      n <- sample(1:length(x), 1)
      na_value <- switch(
        class(x),
        character = NA_character_,
        numeric = NA_integer_,
        integer = NA_integer_,
        NA
      )
      x[seq_len(n)] <- rep(na_value, times = length(seq_len(n)))
      return(x)
    }
  )
)
