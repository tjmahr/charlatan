# modified from the python library faker:
# https://github.com/joke2k/faker/blob/master/faker/providers/__init__.py

#' BaseProvider
#'
#' @export
#' @keywords internal
#' @details
#' \strong{Methods}
#'   \describe{
#'    \item{\code{random_element}}{
#'      wrapper around \code{\link{sample}}
#'    }
#'    \item{\code{random_int}}{
#'      random integer
#'    }
#'    \item{\code{random_digit}}{
#'      random integer between 0 and 9
#'    }
#'    \item{\code{random_digit_not_null}}{
#'      random integer between 1 and 9
#'    }
#'    \item{\code{random_digit_or_empty}}{
#'      random integer between 0 and 9 or empty character string
#'    }
#'    \item{\code{random_digit_not_null_or_empty}}{
#'      random integer between 1 and 9 or empty character string
#'    }
#'    \item{\code{random_letter}}{
#'      random letter
#'    }
#'    \item{\code{numerify}}{
#'      replace a template with numbers
#'    }
#'    \item{\code{lexify}}{
#'      replace a template with letters
#'    }
#'    \item{\code{bothify}}{
#'      both numerify and lexify together
#'    }
#'    \item{\code{check_locale}}{
#'      check a locale to see if it exists, if not, stop with error message
#'    }
#'  }
#' @format NULL
#' @usage NULL
#' @examples
#' (x <- BaseProvider$new())
#'
#' x$numerify("#%%asdf221?")
#' x$lexify("#%%asdf221?")
#' x$bothify("#%%asdf221?")
#'
#' z <- PhoneNumberProvider$new()
#' x$numerify(z$render())
#'
#' x$random_element(letters)
#' x$random_int()
#' x$random_digit()
#' x$random_digit_not_null()
#' x$random_digit_or_empty()
#' x$random_digit_not_null_or_empty()
#' x$random_letter()
#' x$check_locale("es_ES")
#' ## fails
#' # x$check_locale("es_EQ")
BaseProvider <- R6::R6Class(
  'BaseProvider',
  public = list(
    random_element = function(x) {
      sample(x, size = 1)
    },

    random_int = function(min=0, max=9999) {
      floor(runif(1, min, max))
    },

    random_digit = function() {
      sample(0:9, size = 1)
    },

    random_digit_not_null = function() {
      sample(1:9, size = 1)
    },

    random_digit_or_empty = function() {
      if (sample(0:1, size = 1) == 1) {
        sample(0:9, size = 1)
      } else {
        ''
      }
    },

    random_digit_not_null_or_empty = function() {
      if (sample(0:1, size = 1) == 1) {
        sample(1:9, size = 1)
      } else {
        ''
      }
    },

    random_letter = function() {
      # Returns a random letter (between a-z and A-Z)
      self$random_element(c(letters, LETTERS))
    },

    numerify = function(text = '###') {
      text <- do_match(text, "#", self$random_digit)
      text <- do_match(text, "%", self$random_digit_not_null)
      text <- do_match(text, "!", self$random_digit_or_empty)
      text <- do_match(text, "@", self$random_digit_not_null_or_empty)
      return(text)
    },

    lexify = function(text = '????') {
      # Replaces all question mark ('?') occurrences with a random letter
      do_match(text, "?", self$random_letter)
    },

    bothify = function(text = '## ??') {
      # Replaces all placeholders with random numbers and letters.
      self$lexify(self$numerify(text))
    },

    check_locale = function(x) check_locale_(x)
  )
)

check_locale_ <- function(x) {
  if (!x %in% available_locales) {
    stop(x, ' not in set of avaiable locales', call. = FALSE)
  }
}

n_matches <- function(text, pattern) {
  tmp <- gregexpr(paste0("\\", pattern), text)[[1]]
  if (length(tmp) == 1) {
    if (tmp == -1) 0 else tmp
  } else {
    length(tmp)
  }
}

replace_loop <- function(x, pattern, repl) {
  for (i in seq_along(repl)) {
    x <- sub(paste0("\\", pattern), repl[i], x)
  }
  return(x)
}

do_match <- function(text, pattern, fun) {
  nm <- n_matches(text, pattern)
  if (nm > 0) {
    pat <- replicate(nm, eval(fun)())
    replace_loop(text, pattern, pat)
  } else {
    return(text)
  }
}
