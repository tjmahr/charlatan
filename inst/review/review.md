## Package Review

*Please check off boxes as applicable, and elaborate in comments below.  Your review is not limited to these topics, as described in the reviewer guide*

- [x] As the reviewer I confirm that there are no conflicts of interest for me to review this work (such as being a major contributor to the software).

#### Documentation

The package includes all the following forms of documentation:

- [x] **A statement of need** clearly stating problems the software is designed to solve and its target audience in README
- [x] **Installation instructions:** for the development version of package and any non-standard dependencies in README
- [x] **Vignette(s)** demonstrating major functionality that runs successfully locally
- [ ] **Function Documentation:** for all exported functions in R help
- [ ] **Examples** for all exported functions in R Help that run successfully locally
- [ ] **Community guidelines** including contribution guidelines in the README or CONTRIBUTING, and `URL`, `Maintainer` and `BugReports` fields in DESCRIPTION

>##### Paper (for packages co-submitting to JOSS)
>
>The package contains a `paper.md` with:
>
>- [ ] **A short summary** describing the high-level functionality of the software
>- [ ] **Authors:**  A list of authors with their affiliations
>- [ ] **A statement of need** clearly stating problems the software is designed to solve and its target audience.
>- [ ] **References:** with DOIs for all those that have one (e.g. papers, datasets, software).

#### Functionality

- [x] **Installation:** Installation succeeds as documented.
- [ ] **Functionality:** Any functional claims of the software been confirmed.
- [ ] **Performance:** Any performance claims of the software been confirmed.
- [ ] **Automated tests:** Unit tests cover essential functions of the package
   and a reasonable range of inputs and conditions. All tests pass on the local machine.
- [ ] **Packaging guidelines**: The package conforms to the rOpenSci packaging guidelines

#### Final approval (post-review)

- [ ] **The author has responded to my review and made changes to my satisfaction. I recommend approving this package.**

Estimated hours spent reviewing:

---

### Review Comments

This package is a tool for generating fake data. Users can create fake data of a
given type by using functions that start with `ch_`. For example,
`ch_credit_card_number()` creates a fake credit card number or 
`ch_name(n = 4, locale = "fr_FR")` creates four fake French-sounding names. 
Applications for the package include education (creating fake datasets for
students), statistical simulation, software testing, and perhaps anonymization.

Charlatan is modeled after Python's Faker library which in turn draws
inspiration from PHP Faker, Ruby Faker and Perl Faker. (Unfortunately, the name
Faker has been taken on CRAN.) 

The purpose of 


## Package design

This package uses the R6 object system to create classes of data-generators. The
base class is the `BaseGenerator` class. It provides methods for generating
random digits, random letters, and populating templates with random strings.



### `BaseProvider`


This package makes extensive use of the `sample()` function. This function has a
flawed default. It expands integers into ranges, so that `sample(10, 1)` is the 
same as `sample(1:10, 1)`. This package's `BaseProvider$random_element()` method
inherits this flaw. Perhaps, `x[sample(seq_along(x), 1)]`, which samples from a
sequence of item positions, would be a better implementation of this method.



The method `random_int()` has the signature

```
random_int = function(min=0, max=9999) {
  floor(runif(1, min, max))
}

range(replicate(n = 1000000, random_int()))
```

...but it can never generate the maximum value.


It's unclear whether some programming decisions are due to faithfulness to Faker. 

For example, wouldn't a simpler form of this method be `random_element(c(1:9, ""))`?

```
random_digit_or_empty = function() {
  if (sample(0:1, size = 1) == 1) {
    sample(0:9, size = 1)
  } else {
    ''
  }
}

random_digit_or_empty()
```




### `NumericsProvider`

This class generates random numbers, and it powers the various random number 
generators. By default, `sample()` does not sample with replacement so
`ch_integer()` will behave in unexpected ways. It is also odd that 

```
ch_integer(n = 10000, min = 1, max = 1000)
#> Error in sample.int(length(x), size, replace, prob) : 
#>   cannot take a sample larger than the population when 'replace = FALSE' 
```







The `random_digit_not_null` method is better named `random_digit_not_zero`

### ch_integer()



ch_integer(n = 10000, min = 1, max = 1000)
 Show Traceback
 
 Rerun with Debug
 Error in sample.int(length(x), size, replace, prob) : 
  cannot take a sample larger than the population when 'replace = FALSE' 






### ch_generate()

The standard error for a bad field name is:

`Error: column name must be selected from allowed options, see docs`

A better error might say, `see ?ch_generate`

`ch_generate("hex_color")` does not work, although the documentations claims to
support it.

The documentation for the `n` argument says "any (integer) number of things to 
get, 1 to inifinity [sic]". I would recommend just saying any non-negative 
integer. The documentation for `...` should say that `name`, `job`, and
`phone_number` columns are created by default if nothing is specified.




### address-provider.R

The package contains exported, in-progress code for generating addresses.





*** 

It is also worth noting that [wakefield](https://github.com/trinker/wakefield) is another R package for fake-data. Wakefield provides *data-frames* of fake data, whereas this package *vectors* of provides fake-data generators.

45 min
