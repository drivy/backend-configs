# Getaround Rubocop

Rubocop Cop base configuration for Ruby projects

## Usage

First add to your `Gemfile`:

```
gem "getaround-rubocop"
```

### Ruby Cops

In your `.rubocop.yml`:

```
inherit_gem:
  getaround-rubocop: .rubocop.yml
```

### With optional Cops

In your `.rubocop.yml`:

```
inherit_gem:
  getaround-rubocop:
    - .rubocop.yml
    - .rubocop-rspec.yml
```