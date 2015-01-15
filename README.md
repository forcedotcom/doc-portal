# Documentation Portal - Multiple Deliverable Version 

This is a documentation portal written in Ruby, using Sinatra for routing and CouchDB for content storage and searching.  The UI is controlled by Twitter Bootstrap. 

## Using the project 

* [Set up git](https://help.github.com/articles/set-up-git#platform-all)
* Install Ruby 2.1.2 (I suggest using - [RVM](https://rvm.io/rvm/install/))
* Clone this project
* Install the gems in the Gemfile (I suggest using [bundle](http://gembundler.com/bundle_install.html)
* Install [lessc](http://lesscss.org/) and [uglifyjs](https://github.com/mishoo/UglifyJS) installed (the best way is to install them with [npm](https://npmjs.org/), then `npm install -g less uglify-js`)
* Add Bootstrap,  version 2.3.2, and Font Awesome, as submodules with the following rake command `rake bootstrap:init`
* Customize the files in `less/`.  See [http://lesscss.org/](http://lesscss.org/) for details on less.
* Due to an issue with less v2
  ([see http://stackoverflow.com/questions/26628309/less-v2-does-not-compile-twitters-bootstrap-2-x]),
  modify vendor/twitter-bootstrap/less/navbar.less by changing
  ```
  .navbar-static-top .container,
  .navbar-fixed-top .container,
  .navbar-fixed-bottom .container {
    #grid > .core > .span(@gridColumns);
    }
  ```
  to
  ```
  .navbar-fixed-top .container,
  .navbar-fixed-bottom .container {
    width: (@gridColumnWidth * @gridColumns) + (@gridGutterWidth * (@gridColumns - 1));
  }
  ```

* Run `rake bootstrap:make`
* Add the bootstrap files source control - `git add public/bootstrap`,
  then `git commit -m "Adding styling"`
* If you have specific metadata requirements update `lib/db/db_transaction.rb`
* Add you html files to content/*lang-local/deliverable_name*
* Create a deliverable_metadata.json file in content/*lang-local/deliverable_name*
* Create a *deliverable_name*.toc in content/*lang-local/deliverable_name*
* Set the CLOUDANT_URL environment variable (for a local install, do something like this: `export CLOUDANT_URL=http://admin:admin@localhost:5984`)


## Run it locally
* [Set up couchdb](http://wiki.apache.org/couchdb/Installation)
* [Add lucene to couchdb](https://github.com/rnewson/couchdb-lucene)
* Create a file named `.env.development` and add your CLOUDANT_URL export command to it (ie, `export CLOUDANT_URL=http://admin:admin@localhost:5984`)
* Then run
        `rake update_local_db`
* Review the log in log/upload_*.txt
* Then run
        `rake start_local`
* If you want to auto-load local changes, instead of start_local, use
        `rake start_local_debug`
* Open your web browser and look at http://localhost:5000
    * If you are prompted to login, the username is redsofa-qa, password doc123456

## Deploy it to heroku
* One time, initialize the project on heroku
        `rake initialize_heroku`
* Push it to heroku
        `git push heroku master`
* Push your content to the remote database
        `rake update_remote_db`
* Review the log in log/upload_*.txt

© Copyright 2013 salesforce.com, inc.
