# Points Loyalty Program (Front-End)

The following codebase provides a simple, Heroku-deployable front-end web application which connects to the Points Loyalty Commerce Platform and our own homebrewed loyalty program so that our employees can live in the shoes of our customers.

# Features

* Log in with Google ID (Points employees only)
  * An account is automatically created upon first log in 
* View your balance and leaderboard position
* View a stream of activity for all members of the program to highlight big wins and recognitions
* Earn points for doing specific activities within the company
* Gift points to hard-working fellow employees as a means of recognition

# Installation

`bundle install`

# Run

`rackup config.ru`

View at `http://localhost:9292`

# Demo

Alternatively, check it out on Heroku @ 'https://plp.herokuapp.com'.

# Depedencies

The Gemfile has it all, but in short:

* Ruby (2.1.5)
* Sinatra
* RbLCP
* RestClient

This front-end app also relies on a back-end, called the PLP-API, also deployed to Heroku and built on Mulesoft.
