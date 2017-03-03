
Package Review
--------------

*Please check off boxes as applicable, and elaborate in comments below. Your review is not limited to these topics, as described in the reviewer guide*

-   \[x\] As the reviewer I confirm that there are no conflicts of interest for me to review this work (such as being a major contributor to the software).

#### Documentation

The package includes all the following forms of documentation:

-   \[x\] **A statement of need** clearly stating problems the software is designed to solve and its target audience in README
-   \[x\] **Installation instructions:** for the development version of package and any non-standard dependencies in README
-   \[x\] **Vignette(s)** demonstrating major functionality that runs successfully locally
-   \[x\] **Function Documentation:** for all exported functions in R help
-   \[x\] **Examples** for all exported functions in R Help that run successfully locally
-   \[x\] **Community guidelines** including contribution guidelines in the README or CONTRIBUTING, and `URL`, `Maintainer` and `BugReports` fields in DESCRIPTION

#### Functionality

-   \[x\] **Installation:** Installation succeeds as documented.
-   \[x\] **Functionality:** Any functional claims of the software been confirmed.
-   \[x\] **Performance:** Any performance claims of the software been confirmed.
-   \[x\] **Automated tests:** Unit tests cover essential functions of the package and a reasonable range of inputs and conditions. All tests pass on the local machine.
-   \[x\] **Packaging guidelines**: The package conforms to the rOpenSci packaging guidelines

#### Final approval (post-review)

-   \[ \] **The author has responded to my review and made changes to my satisfaction. I recommend approving this package.**

Estimated hours spent reviewing: 8

------------------------------------------------------------------------

### Review Comments

This package is a tool for generating fake data. Users can create fake data of a given type by using functions that start with `ch_`. For example, `ch_credit_card_number()` creates a fake credit card number or `ch_name(n = 4, locale = "fr_FR")` creates four fake French-sounding names. Applications for the package include education (creating fake datasets for students), statistical simulation, software testing, and perhaps anonymization.

Charlatan is modeled after Python's Faker library which in turn draws inspiration from PHP Faker, Ruby Faker and Perl Faker. Unfortunately, the name Faker has been taken on CRAN. (It is also worth noting that [wakefield](https://github.com/trinker/wakefield) is another R package for fake-data. Wakefield provides *data-frames* of fake data, whereas this package mainly provides *vectors* of fake data.)

Overall, this package is well designed and well structured. The code is cleanly written and formatted, and it takes advantage of R idioms. This clear, expressive style made reading the code a breeze. That said, I found few bugs and inconsistencies while reviewing it.

This package uses the R6 object system to create classes of data-generators. (Presumably, using objects and methods made porting the code from Python rather straightforward.) The base class is the `BaseGenerator` class. All other generators inherit from this class. Therefore, I'll review the code by visiting each of the generators in turn.

#### BaseProvider

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
#> [1] 0
bp$numerify("I have ## friends")
#> [1] "I have 75 friends"
```

This package makes extensive use of the `sample()` function. This function has a flawed default behavior: It expands integers into ranges. Thus, `sample(10, 1)` is the same as `sample(1:10, 1)`. This package's `BaseProvider$random_element()` method inherits this flaw.

``` r
set.seed(22)
bp$random_element(10)
#> [1] 4
```

Perhaps, `x[sample(seq_along(x), 1)]`, which samples from a sequence of item positions, would be a better implementation for this method.

The method `random_int()` has the signature:

``` r
str(args(bp$random_int))
#> function (min = 0, max = 9999)
```

It can never generate the maximum value, and this fact isn't noted anywhere.

``` r
set.seed(22)
range(replicate(bp$random_int(min = 0, max = 99), n = 100000))
#> [1]  0 98
```

~~It's not clear whether this behavior is intentional or an oversight, but it's the kind of weird detail that should be noted.~~ On further consideration, this behavior is probably a bug because the DOI-generators uses the function with `min = 0` and `max = 9999`.

I'm curious why the digit-or-blank generators don't just sample from a larger set. The code for `random_digit_not_null_or_empty()` means that half of the generated items should be `""`.

``` r
bp$random_digit_not_null_or_empty
#> function() {
#>       if (sample(0:1, size = 1) == 1) {
#>         sample(1:9, size = 1)
#>       } else {
#>         ''
#>       }
#>     }
#> <environment: 0x0000000008c7dd58>

# Why not sample with this instead?
bp$random_element(c(1:9, ""))
#> [1] "9"
```

#### NumericsProvider

This class generates random numbers. It demonstrates nice features of the R6-based design:

1.  grouping similar functionality into a cohesive object
2.  providing a logical extension point for other kinds of number generators

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

This class powers the various random number generators in the package. The functions `ch_integer()`, `ch_double()`, `ch_unif()`, etc. actually just generate one-off `NumericsProvider` objects and call a method for the object.

``` r
ch_norm
#> function(n = 1, mean = 0, sd = 1) {
#>   assert(n, c('integer', 'numeric'))
#>   NumericsProvider$new()$norm(n, mean, sd)
#> }
#> <environment: namespace:charlatan>
```

The package rightly calls upon R's built-in number generators (`rnorm`, `runif`, `rbeta`, etc.) for almost all of the number generators. It uses different defaults for the uniform distribution than R, but does use the same defaults as R for the others.

``` r
args(runif)
#> function (n, min = 0, max = 1) 
#> NULL
args(NumericsProvider$new()$unif)
#> function (n = 1, min = 0, max = 9999) 
#> NULL
```

Here I think the package should follow R's defaults and take advantage of what the user may already know about the `r*` functions.

The `integer()` method doesn't defer to R, but it instead uses `sample()`. By default `sample()` does not sample with replacement, so `NumericsProvider$new()$integer()` and `ch_integer()` can behave in unexpected ways.

``` r
ch_integer(n = 10000, min = 1, max = 1000)
#> Error in sample.int(length(x), size, replace, prob): cannot take a sample larger than the population when 'replace = FALSE'
```

It is also odd that the `random_int()` and `integer()` use different techniques for generating random integers.

#### PersonProvider

This class implements the package's impressive (and fun) random name generator. It can generator locale-specific names. It has one method: `render()`. This class powers the `ch_name()` function.

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

As the example above shows, the names can vary in format. (Sometimes there is a blank first name --- this might be a bug.)

This function works by randomly selecting a name format and populating the format with random names/affixes.

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

The package's locale-specificity is just a matter of selecting the appropriate formats and slot fillers for a locale. This implementation is a clean design win.

The locale-specific names are stored as variables in the package's namespace, and they are stored in R scripts. Thus, there are .R files that contain vectors with thousands of names.

``` r
r_dir <- rprojroot::find_rstudio_root_file("R/")
list.files(r_dir, "person-provider-")
#>  [1] "person-provider-bg_BG.R" "person-provider-cs_CZ.R"
#>  [3] "person-provider-de_AT.R" "person-provider-de_DE.R"
#>  [5] "person-provider-dk_DK.R" "person-provider-en_US.R"
#>  [7] "person-provider-es_ES.R" "person-provider-fa_IR.R"
#>  [9] "person-provider-fi_FI.R" "person-provider-fr_CH.R"
#> [11] "person-provider-fr_FR.R" "person-provider-hr_HR.R"
#> [13] "person-provider-it_IT.R"
```

I wonder if using a `data/` folder would be a cleaner way to separate code and package data.

The documentation for `ch_name()` under-reports the supported locales. For example, Spanish is supported but this Spanish support is not documented.

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

This behavior is a problem with `whisker::render()`. The following code tweaks the package internals for debugging. It generates four different last names but whisker recycles the first.

``` r
pluck_names <- charlatan:::pluck_names

fmt <- "{{last_name}} {{last_name}} {{last_name}} {{last_name}}"
dat <- lapply(
  spanish$person[pluck_names(fmt, spanish$person)], 
  sample, 
  size = 1)

str(dat)
#> List of 4
#>  $ last_name: chr "Alegre"
#>  $ last_name: chr "Delgado"
#>  $ last_name: chr "Heras"
#>  $ last_name: chr "Cordero"
whisker::whisker.render(fmt, data = dat)
#> [1] "Alegre Alegre Alegre Alegre"
```

#### ColorProvider

This class generates colors.

Its hex-color generator users the `random_int()` method to choose a number between 1 and 16777215. The above noted behavior means it will never generate \#ffffff, and the lower bound of 1 prevents \#000000 from being generated too.

``` r
cp <- ColorProvider$new()
cp$color_name()
#> [1] "PowderBlue"
cp$safe_color_name()
#> [1] "fuchsia"

# Some locale sensitivity for color names, but not safe ones
cp2 <- ColorProvider$new(locale = "uk_UA")
cp2$color_name()
#> [1] "<U+0424><U+0456><U+043E><U+043B><U+0435><U+0442><U+043E><U+0432><U+0438><U+0439>"
cp2$safe_color_name()
#> [1] "maroon"

set.seed(26)
cp$hex_color()
#> [1] "#43f66"
```

It pads zeros onto strings less than 6 characters to create the familiar six- digit format. But padding is done on the right side, so it will never generate "\#0000ff". It also counts character length after appending the the pound sign, so the above example shows an incorrect hex color.

~~I think using `sprintf("#%06x", ...)` would fix these problems.~~ Actually, I discovered `grDevices::rgb()` while reading about the `colors()` for a later comment. That function should power the implementation.

``` r
rgb(0, 0, 0, maxColorValue = 255)
#> [1] "#000000"
rgb(255, 255, 255, maxColorValue = 255)
#> [1] "#FFFFFF"

sample_col <- function() sample(0:255, 1)
rgb(sample_col(), sample_col(), sample_col(), maxColorValue = 255)
#> [1] "#4ADFCC"
```

A similar strategy underlies `safe_hex_color()`, so the method has the same flaws. Plus, something mysterious happens sometimes:

``` r
set.seed(26)
cp$safe_hex_color()
#> [1] "#4400#4400"
```

For this method I think generating three separate hex digits and duplicating them and concatenating them would be a cleaner implementation. I also find [conflicting information](http://websafecolors.info/color-chart) about which colors are "safe" --- is this method's definition of safe colors standard?

`rbg_color()` calls the `hex_color()` method, so it will inherit that function's bugs. Plus, sometimes I get an error.

``` r
set.seed(133)
colors <- replicate(n = 1000, cp$rgb_color())
#> Error: precBits >= 2 are not all TRUE
```

R has its own family of accepted color names, so those might a natural extension point.

``` r
sample(colors(), 3)
#> [1] "springgreen" "gray40"      "gray32"
```

#### CoordinateProvider

CoordinateProvider does what it says. It powers `ch_lat()`, `ch_lon()`, `ch_position()`. Notably, it does not inherit from the BaseProvider class.

``` r
cp <- CoordinateProvider$new()
CoordinateProvider
#> <CoordinateProvider> object generator
#>   Public:
#>     lon: function () 
#>     lat: function () 
#>     position: function (bbox = NULL) 
#>     clone: function (deep = FALSE) 
#>   Private:
#>     rnd: function () 
#>     coord_in_bbbox: function (bbox) 
#>   Parent env: <environment: namespace:charlatan>
#>   Locked objects: TRUE
#>   Locked class: FALSE
#>   Portable: TRUE

cp$lat()
#> [1] -21.11343
cp$lon()
#> [1] 123.7104
cp$position()
#> [1] 72.99215 12.02990
```

It can generate coordinates within a boundary box. The box is not checked, so users can get invalid coordinates as a result.

``` r
# Specify a bad box
cp$position(c(-12000, 0, 0, 30000))
#> [1] -9588.538 16289.230
```

#### CreditCardProvider

This class looks good but there is some commented out Python/R code in place. It looks like the class produces legitimate credit card numbers (i.e., they pass an appropriate checksum that real credit card numbers have). This detail highlights an important use case for this package: Generating fake data for testing code, as one could test some credit-card-validating function with this package.

#### DateTimeProvider

This class powers `ch_timezone()`, `ch_unix_time()`, and `ch_date_time()`. It is not documented that the date-times are integers converted to POSIX times, so they are all after 1970. The file also features some commented out Python code.

``` r
DateTimeProvider$new()$unix_time()
#> [1] 530920243
DateTimeProvider$new()$date_time()
#> [1] "2016-07-26 14:40:45 CDT"
```

There is a typo in `century()` method, so it always errors.

``` r
body(DateTimeProvider$new()$century)
#> {
#>     super$random_element(self$cenuries)
#> }
```

#### TaxonomyProvider

This class randomly samples from prepackaged genus/species names. The basis for the random genus/species names is well detailed in the hidden `?TaxonomyProvider` page but not included in the user-facing `?taxonomy` page. Now that Roxygen2 supports the new `@inherit` and `@inheritSection fun title` directives, I suggest that the user-facing page include this documentation.

``` r
set.seed(22)
TaxonomyProvider$new()$genus()
#> [1] "Dialium"
TaxonomyProvider$new()$epithet()
#> [1] "kovacevii"

# A species just genus() + epithet()
set.seed(22)
TaxonomyProvider$new()$species()
#> [1] "Dialium kovacevii"
```

#### Do-one-thing generators

##### CurrencyProvider

This class randomly samples a vector of currency abbreviations.

##### DOIProvider

This class's main job is to randomly select a DOI format and populate the format with characters/integers. This class does not use its inherited `random_int()` method to generate the integers, but it should.

##### JobProvider

The class produces occupation titles using the same locale-specificity covered earlier. It just randomly samples occupations from a vector with each locale's occupation names.

``` r
set.seed(36)
JobProvider$new(locale = "fr_FR")$render()
#> [1] "Intégrateur web"
ch_job(n = 3)
#> [1] "Pharmacist, community"         "Restaurant manager, fast food"
#> [3] "Designer, textile"
```

##### PhoneNumberProvider

This class randomly selects a format and then populates that format with digits.

``` r
head(PhoneNumberProvider$new()$formats, 3)
#> [1] "+##(#)##########" "+##(#)##########" "0##########"
PhoneNumberProvider$new()$render()
#> [1] "1-094-032-6500x4515"
ch_phone_number(4)
#> [1] "333-862-9754"         "(681)356-2399x715"    "1-612-259-7099x07938"
#> [4] "720.912.3811"
```

##### SequenceProvider

This class generates gene sequences by sampling letters and concatenating them. I feel the user-facing function should be named `ch_gene_sequence()`, not `ch_sequence()`

#### FraudsterClient

This class wraps all the `ch_` functions into a single object for general-purpose fake data generation in a given locale. Because locales are not uniformly supported, this can lead to errors. Also, the `name()` method ignores the locale even though it can support different locales.

``` r
y <- fraudster(locale = "fr_FR")
y
#> <fraudster>
#>   locale: fr_FR

y$job()
#> [1] "Aquaculteur"
y$color_name()
#> Error in sample.int(length(x), size, replace, prob): invalid first argument
y$name()
#> [1] "Teddie McCullough III"
```

#### Unfinished providers

I didn't closely review the code for these classes, as they appear to be unfinished and are not user-facing like the other ones. I am documenting them here for completeness.

The package contains exported, in-progress code for generating addresses with `AddressProvider`. There is no `ch_address()`.

It also contains the `company_provider` class which is exported but not documented and not linked to any `ch_` functions. It has a different R6 design and naming scheme than other classes. This one looks like a lot of fun.

``` r
# I think the same whisker::render() bug is happening here
set.seed(27)
company_provider()$company()
#> [1] "Boehm, Boehm and Boehm"
company_provider()$company()
#> [1] "Hansen, Hansen and Hansen"
company_provider()$company()
#> [1] "Jacobi Inc,and Sons,LLC,Group,PLC,Ltd"

company_provider()$bs()
#> [1] "optimize clicks-and-mortar platforms"
company_provider()$bs()
#> [1] "reinvent extensible applications"

company_provider()$catch_phrase()
#> [1] "Object-based optimal structure"
company_provider()$catch_phrase()
#> [1] "Seamless zero-defect archive"
```

`MissingProvider` provides a method to inject NA values into a vector. There is no user-facing function (something like `ch_missing()`) for this class). Nevertheless, it's odd that the *n* missing values it generates for a vector overwrite the first *n* values.

``` r
set.seed(10)
MissingDataProvider$new()$make_missing(letters)
#>  [1] NA  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA  "o" "p" "q"
#> [18] "r" "s" "t" "u" "v" "w" "x" "y" "z"
```

I feel like it should randomly determine *n*, `sample()` *n* position indices, and make the elements in those positions NA so that the NAs are scattered throughout the vector.

#### `ch_generate()`

This function creates a data-frame of (en\_US) fake data.

``` r
ch_generate("name", "job", n = 4)
#> # A tibble: 4 × 2
#>             name                               job
#>            <chr>                             <chr>
#> 1 Jaelynn Pouros                     Meteorologist
#> 2  Dalia Goldner Environmental health practitioner
#> 3  Loyce Keebler               Geologist, wellsite
#> 4   Kellen Bruen            Amenity horticulturist
```

The standard error for a bad field name is:

``` r
ch_generate("badname", n = 2)
#> Error: column name must be selected from allowed options, see docs
```

A better error might say, `see ?ch_generate` or print out the `all_choices` vector.

`ch_generate("hex_color")` does not work, although the documentations claims to support it.

The documentation for the `n` argument says "any (integer) number of things to get, 1 to inifinity". I would recommend just saying any non-negative integer. This applies to every documentation page as well.

The documentation for `...` should also say that `name`, `job`, and `phone_number` columns are created by default if nothing is specified.

#### Other comments

`parse_eval()` should move to zzz.R, where the rest of the utility functions live. Personally, I would avoid using this function by structuring all the data into nested lists so that items can be retrieved with `data[[locale_name]]` instead of using `parse_eval()` to create-then-evaluate a variable name.

Some functions have `return()`; some do not.

The `random_digit_not_null()` method in the BaseGenerator is better named `random_digit_not_zero()`.

The unit test for colors and safe colors should check that the generated colors meets the color and safe-color formats.

There are only unit tests for the colors, coordinates, credit cards, currency and jobs. I would suggest adding tests for the functions I've described bugs in.
