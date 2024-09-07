# CommerceCore Product Management Microservice

## System dependencies

* Ruby version: 3.3.4

To install the dependencies for the project, run `bundle install` and every
dependency used in this project will be installed.

## Database initialization

To initialize the database, simply perform the migrations with the following
commands.

```shell
rails db:create  # if the databases are not yet created

rails db:migrate
```

Be sure that the configuration in the `config/database.yml` mimics your setup.

## How to run the test suite

### Running all test cases

Tests are written using RSpec, so while on the on command line you execute the
command

```shell
bundle exec rspec
```

This will run all the tests available.

### Running tests for a specific file

If you need to run specific tests, you can specify the file. For example

```shell
bundle exec rspec spec/models/category_spec.rb
```

### Running specific lines from the file

Just running the tests for a file, specify the name of the file followed by the
line number where the test you want to run is defined

```shell
bundle exec rspec spec/models/category.rb:38
```
