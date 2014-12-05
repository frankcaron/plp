# Multitenant Storefront

The following codebase provides a simple application which can be used for a multi-tenant, white-label eCommerce storefront.

# Features

* Multi-tenant template loading (based on sub-directory)
	* Modular template structure
	* Inheritance and per-tenant, per-module template overrides
	* CSS override
* Template-agnostic language support
	* CSV with key-value pairs representing all the language found in the templates
	* Inheritance and per-tenant overrides
* Tenant-specific app credential mapping (for interaction with external APIs)

# Installation

`bundle install`

# Run

`ruby myapp.rb`

View at `http://localhost:4567`

# Depedencies

The Gemfile has it all, but in short:

* Ruby (2.1.5)
* Sinatra
* CSV