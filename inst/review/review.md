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
given type by using functions that start with `ch_` --- for example,
`ch_credit_card_number()` will create a fake credit card number or 
`ch_name(n = 4, locale = "fr_FR")` to create four fake French-sounding names. 
Applications for the package include education (creating fake datasets for
students), statistical simulation, software testing, and perhaps anonymization.

Charlatan is modeled after Python's Faker library which in turn draws
inspiration from PHP Faker, Ruby Faker and Perl Faker. (Unfortunately, the name
Faker has been taken on CRAN.) 

The purpose of 


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
