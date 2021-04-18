# A tool for testing mod_perl with multiple perls and httpds on unix like systems

testing mod_perl RC's or patches can be laborious. This repository is an attempt
to bring some automation to that task. The goal is to be able to download some
distribution archives for perl, and httpd, along with a mod_perl source directory
then be able to run something and walk away, and come back to some kind of
of how the tests went for each version of perl with each version of httpd. It's
not there yet though

## How to use this naively

1. checkout the repository
2. put tar.gz's of the perls you want to test with into perl_src
3. put tar.gz's of httpds you wan to test ingo httpd_src
4. put tar.gz's of mod_perl source you want to test into mod_perl_src
5. ./run.pl all

## Note

this is a work in progress and is currently only installing perl(s)
