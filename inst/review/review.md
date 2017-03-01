
Package Review \[in progress\]
------------------------------

*Please check off boxes as applicable, and elaborate in comments below. Your review is not limited to these topics, as described in the reviewer guide*

-   \[x\] As the reviewer I confirm that there are no conflicts of interest for me to review this work (such as being a major contributor to the software).

#### Documentation

The package includes all the following forms of documentation:

-   \[x\] **A statement of need** clearly stating problems the software is designed to solve and its target audience in README
-   \[x\] **Installation instructions:** for the development version of package and any non-standard dependencies in README
-   \[x\] **Vignette(s)** demonstrating major functionality that runs successfully locally
-   \[ \] **Function Documentation:** for all exported functions in R help
-   \[ \] **Examples** for all exported functions in R Help that run successfully locally
-   \[x\] **Community guidelines** including contribution guidelines in the README or CONTRIBUTING, and `URL`, `Maintainer` and `BugReports` fields in DESCRIPTION

#### Functionality

-   \[x\] **Installation:** Installation succeeds as documented.
-   \[ \] **Functionality:** Any functional claims of the software been confirmed.
-   \[x\] **Performance:** Any performance claims of the software been confirmed.
-   \[x\] **Automated tests:** Unit tests cover essential functions of the package and a reasonable range of inputs and conditions. All tests pass on the local machine.
-   \[ \] **Packaging guidelines**: The package conforms to the rOpenSci packaging guidelines

#### Final approval (post-review)

-   \[ \] **The author has responded to my review and made changes to my satisfaction. I recommend approving this package.**

Estimated hours spent reviewing:

------------------------------------------------------------------------

### Review Comments

This package is a tool for generating fake data. Users can create fake data of a given type by using functions that start with `ch_`. For example, `ch_credit_card_number()` creates a fake credit card number or `ch_name(n = 4, locale = "fr_FR")` creates four fake French-sounding names. Applications for the package include education (creating fake datasets for students), statistical simulation, software testing, and perhaps anonymization.

Charlatan is modeled after Python's Faker library which in turn draws inspiration from PHP Faker, Ruby Faker and Perl Faker. (Unfortunately, the name Faker has been taken on CRAN.)

Package design
--------------

This package uses the R6 object system to create classes of data-generators. (Presumably, using objects and methods made porting the code from Python rather straightforward.) The base class is the `BaseGenerator` class. All other generators inherit from this class. Therefore, I'll review the code by visiting each of the generators in turn.

### BaseProvider

`BaseProvider` contains methods for generating random digits, random letters, and populating templates with random strings.

``` r
library(charlatan)
bp <- BaseProvider$new()
bp
#> <BaseProvider>
#>   Public:
#>     bothify: function (text = "## ??") 
#>     check_locale: function (x) 
#>     clone: function (deep = FALSE) 
#>     lexify: function (text = "????") 
#>     numerify: function (text = "###") 
#>     random_digit: function () 
#>     random_digit_not_null: function () 
#>     random_digit_not_null_or_empty: function () 
#>     random_digit_or_empty: function () 
#>     random_element: function (x) 
#>     random_int: function (min = 0, max = 9999) 
#>     random_letter: function ()

bp$random_digit()
#> [1] 5
bp$numerify("I have ## friends")
#> [1] "I have 87 friends"
```

This package makes extensive use of the `sample()` function. This function has a flawed default. It expands integers into ranges, so that `sample(10, 1)` is the same as `sample(1:10, 1)`. This package's `BaseProvider$random_element()` method inherits this flaw.

``` r
set.seed(22)
bp$random_element(10)
#> [1] 4
```

Perhaps, `x[sample(seq_along(x), 1)]`, which would sample from a sequence of item positions, would be a better implementation for this method.

The method `random_int()` has the signature:

``` r
str(args(bp$random_int))
#> function (min = 0, max = 9999)
```

It can never generate the maximum value, and this fact is isn't noted anywhere.

``` r
set.seed(22)
range(replicate(bp$random_int(), n = 100000))
#> [1]    0 9998
```

It's not clear whether this is intentional or an oversight, but it's the kind of weird detail that should be noted.

I'm curious why the digit-or-blank generators don't just sample from a larger set. The code for `random_digit_not_null_or_empty()` means that half of the generated items should be`""`.

``` r
bp$random_digit_not_null_or_empty
#> function() {
#>       if (sample(0:1, size = 1) == 1) {
#>         sample(1:9, size = 1)
#>       } else {
#>         ''
#>       }
#>     }
#> <environment: 0x00000000086aee70>

# Why not sample with this instead?
bp$random_element(c(1:9, ""))
#> [1] "9"
```

### NumericsProvider

This class generates random numbers. This class demonstrates nice features of the R6-based design: 1) grouping similar functionality into a cohesive object and 2) provide a logical extension point for other kinds of number generators.

``` r
np <- NumericsProvider$new()
np
#> <NumericsProvider>
#>   Inherits from: <BaseProvider>
#>   Public:
#>     beta: function (n = 1, shape1, shape2, ncp = 0) 
#>     bothify: function (text = "## ??") 
#>     check_locale: function (x) 
#>     clone: function (deep = FALSE) 
#>     double: function (n = 1, mean = 0, sd = 1) 
#>     integer: function (n = 1, min = 1, max = 1000) 
#>     lexify: function (text = "????") 
#>     lnorm: function (n = 1, mean = 0, sd = 1) 
#>     norm: function (n = 1, mean = 0, sd = 1) 
#>     numerify: function (text = "###") 
#>     random_digit: function () 
#>     random_digit_not_null: function () 
#>     random_digit_not_null_or_empty: function () 
#>     random_digit_or_empty: function () 
#>     random_element: function (x) 
#>     random_int: function (min = 0, max = 9999) 
#>     random_letter: function () 
#>     unif: function (n = 1, min = 0, max = 9999)
```

This class powers the various random number generators in the package. The functions `ch_integer()`, `ch_double()`, `ch_unif()`, etc. actually just generate one-off `NumericsProvider` objects and call a method.

``` r
ch_norm
#> function(n = 1, mean = 0, sd = 1) {
#>   assert(n, c('integer', 'numeric'))
#>   NumericsProvider$new()$norm(n, mean, sd)
#> }
#> <environment: namespace:charlatan>
```

The package rightly calls upon R's built-in number generators (`rnorm`, `runif`, `rbeta`, etc.) for almost all of the number generators. It uses different defaults for the uniform distribution than R, but uses the same defaults as R for the others.

``` r
args(runif)
#> function (n, min = 0, max = 1) 
#> NULL
args(NumericsProvider$new()$unif)
#> function (n = 1, min = 0, max = 9999) 
#> NULL
```

Here I think the package should follow R's defaults and take advantage of what the user may already know about the `r*` functions.

The `integer()` method doesn't defer to R, but instead uses `sample()`. By default, `sample()` does not sample with replacement so `NumericsProvider$new()$integer()` and `ch_integer()` can behave in unexpected ways.

``` r
ch_integer(n = 10000, min = 1, max = 1000)
#> Error in sample.int(length(x), size, replace, prob): cannot take a sample larger than the population when 'replace = FALSE'
```

It is also odd that the `random_int()` and `integer()` use different techniques for generating random integers.

`PersonProvider`
----------------

This class implements the package's fun random name generator feature. It can generator locale-specific names using a locale. It has one method: `render()`. This powers the `ch_name()` function.

``` r
set.seed(100)
person <- PersonProvider$new()
person$render()
#> [1] "Devan Lubowitz"
person$render()
#> [1] " Konopelski"
person$render()
#> [1] "Dr. Gladis Little MD"

ch_name(4)
#> [1] "Stanley Gottlieb"  "Ollie Ortiz MD"    "Ms. Meaghan Lesch"
#> [4] "Jordy Rohan"
```

As the example above shows, the names can vary in format, and sometimes there is a blank first name.

This function works by randomly selecting a name format, and populating the format with random appropriate names/affixes.

``` r
# Formats
person$formats
#>  [1] "{{first_name_female}} {{last_names}}"                                         
#>  [2] "{{first_names_female}} {{last_names}}"                                        
#>  [3] "{{first_names_female}} {{last_names}}"                                        
#>  [4] "{{first_names_female}} {{last_names}}"                                        
#>  [5] "{{first_names_female}} {{last_names}}"                                        
#>  [6] "{{prefixes_female}} {{first_names_female}} {{last_names}}"                    
#>  [7] "{{first_names_female}} {{last_names}} {{suffixes_female}}"                    
#>  [8] "{{prefixes_female}} {{first_names_female}} {{last_names}} {{suffixes_female}}"
#>  [9] "{{first_names_male}} {{last_names}}"                                          
#> [10] "{{first_names_male}} {{last_names}}"                                          
#> [11] "{{first_names_male}} {{last_names}}"                                          
#> [12] "{{first_names_male}} {{last_names}}"                                          
#> [13] "{{first_names_male}} {{last_names}}"                                          
#> [14] "{{prefixes_male}} {{first_names_male}} {{last_names}}"                        
#> [15] "{{first_names_male}} {{last_names}} {{suffixes_male}}"                        
#> [16] "{{prefixes_male}} {{first_names_male}} {{last_names}} {{suffixes_male}}"

# Possible slot fillers
str(person$person)
#> List of 8
#>  $ first_names       : chr [1:7203] "Aaden" "Aarav" "Aaron" "Ab" ...
#>  $ first_names_male  : chr [1:3271] "Aaden" "Aarav" "Aaron" "Ab" ...
#>  $ first_names_female: chr [1:3932] "Aaliyah" "Abagail" "Abbey" "Abbie" ...
#>  $ last_names        : chr [1:473] "Abbott" "Abernathy" "Abshire" "Adams" ...
#>  $ prefixes_female   : chr [1:4] "Mrs." "Ms." "Miss" "Dr."
#>  $ prefixes_male     : chr [1:2] "Mr." "Dr."
#>  $ suffixes_female   : chr [1:4] "MD" "DDS" "PhD" "DVM"
#>  $ suffixes_male     : chr [1:11] "Jr." "Sr." "I" "II" ...
```

The package's locale-specifity is just a matter of selecting the appropriate formats and slot fillers for a locale. This is a clean design win.

The locale-specific names are stored as variables in the package's namespace, and they are stored in R scripts. Thus, there are .R files that contain vectors with thousands of names. I wonder if using a `data/` folder would be a cleaner way to separate code and package data.

The documentation for `ch_name` under reports the supported locales. For example, Spanish is supported but Spanish support is not documented.

There is a bug in how double last names (as in Spanish) are generated.

``` r
set.seed(103)
spanish <- PersonProvider$new(locale = "es_ES")

# Double last names are common in Spanish
spanish$formats
#>  [1] "{{first_name_male}} {{last_name}} {{last_name}}"                        
#>  [2] "{{first_name_male}} {{last_name}} {{last_name}}"                        
#>  [3] "{{first_name_male}} {{last_name}} {{last_name}}"                        
#>  [4] "{{first_name_male}} {{last_name}} {{last_name}}"                        
#>  [5] "{{first_name_male}} {{last_name}} {{last_name}}"                        
#>  [6] "{{first_name_male}} {{last_name}} {{last_name}}"                        
#>  [7] "{{first_name_male}} {{last_name}}"                                      
#>  [8] "{{first_name_male}} {{prefix}} {{last_name}}"                           
#>  [9] "{{first_name_male}} {{last_name}}-{{last_name}}"                        
#> [10] "{{first_name_male}} {{first_name_male}} {{last_name}} {{last_name}}"    
#> [11] "{{first_name_female}} {{last_name}} {{last_name}}"                      
#> [12] "{{first_name_female}} {{last_name}} {{last_name}}"                      
#> [13] "{{first_name_female}} {{last_name}} {{last_name}}"                      
#> [14] "{{first_name_female}} {{last_name}} {{last_name}}"                      
#> [15] "{{first_name_female}} {{last_name}} {{last_name}}"                      
#> [16] "{{first_name_female}} {{last_name}} {{last_name}}"                      
#> [17] "{{first_name_female}} {{last_name}}"                                    
#> [18] "{{first_name_female}} {{prefix}} {{last_name}}"                         
#> [19] "{{first_name_female}} {{last_name}}-{{last_name}}"                      
#> [20] "{{first_name_female}} {{first_name_female}} {{last_name}} {{last_name}}"

# The two last names should be different
spanish$render()
#> [1] "Jose Antonio Lloret Lloret"
spanish$render()
#> [1] "Javier Gras Gras"
```

This is a problem with `whisker::render()`. The following code tweaks the package internals for debugging. It generates four different last names but whisker recycles the first.

``` r
pluck_names <- charlatan:::pluck_names

fmt <- "{{last_name}} {{last_name}} {{last_name}} {{last_name}}"
dat <- lapply(spanish$person[pluck_names(fmt, spanish$person)], sample, size = 1)

str(dat)
#> List of 4
#>  $ last_name: chr "Alegre"
#>  $ last_name: chr "Delgado"
#>  $ last_name: chr "Heras"
#>  $ last_name: chr "Cordero"
whisker::whisker.render(fmt, data = dat)
#> [1] "Alegre Alegre Alegre Alegre"
```

Sctatch pad
-----------

<!-- The number-generator `ch_*` functions are not well documented on the `?numerics` -->
<!-- page which is included in the package documentation. The underlying methods, -->
<!-- however, are well documented on the `?NumericsProvider` page but this page is -->
<!-- excluded from the main package documentation. -->
The `random_digit_not_null` method is better named `random_digit_not_zero`

### ch\_integer()

ch\_integer(n = 10000, min = 1, max = 1000) Show Traceback

Rerun with Debug Error in sample.int(length(x), size, replace, prob) : cannot take a sample larger than the population when 'replace = FALSE'

### ch\_generate()

The standard error for a bad field name is:

`Error: column name must be selected from allowed options, see docs`

A better error might say, `see ?ch_generate`

`ch_generate("hex_color")` does not work, although the documentations claims to support it.

The documentation for the `n` argument says "any (integer) number of things to get, 1 to inifinity \[sic\]". I would recommend just saying any non-negative integer. The documentation for `...` should say that `name`, `job`, and `phone_number` columns are created by default if nothing is specified.

### address-provider.R

The package contains exported, in-progress code for generating addresses.

------------------------------------------------------------------------

It is also worth noting that [wakefield](https://github.com/trinker/wakefield) is another R package for fake-data. Wakefield provides *data-frames* of fake data, whereas this package *vectors* of provides fake-data generators.

4 hours
