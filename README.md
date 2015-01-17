# Documentation Portal - Multiple Deliverable Version 

This is a documentation portal written in Ruby, using Sinatra for routing and CouchDB for content storage and searching.  The UI is controlled by Twitter Bootstrap. 

## Using the project 

* [Set up git](https://help.github.com/articles/set-up-git#platform-all)
* Install Ruby 2.1.2 (I suggest using - [RVM](https://rvm.io/rvm/install/))
* Clone this project
* Install the gems in the Gemfile (I suggest using [bundle](http://gembundler.com/bundle_install.html))

## Run it locally
* Set up your database
    * Locally: 
        * [Set up couchdb](http://wiki.apache.org/couchdb/Installation)
        * [Add lucene to couchdb](https://github.com/rnewson/couchdb-lucene)
    * Hosted:
        * [Create a Cloudant Account](https://cloudant.com/sign-up/) 
* Set the CLOUDANT_URL environment variable 
    * For a local database, do something like this: `export CLOUDANT_URL=http://admin:admin@localhost:5984`
    * For a hosted database, do something like this: `export CLOUDANT_URL=http://<username>:<passcode>:<cloudant-host>.cloudant.com`
* Create a file named `.env.development` and add your CLOUDANT_URL export command to it (ie, `export CLOUDANT_URL=http://admin:admin@localhost:5984`)
* Then run
        `rake update_local_db`
* Review the log in log/upload_*.txt
* Then run
        `rake start_local`
* If you want to auto-load local changes, instead of start_local, use
        `rake start_local_debug`
* Open your web browser and look at [http://localhost:5000]
    * If you are prompted to login, the username is redsofa-qa, password doc123456

## Deploy it to heroku
* [Install the Heroku toolbelt](https://toolbelt.heroku.com)
* One time, initialize the project on heroku

  `rake initialize_heroku[`*app_name*, *CLOUDANT_URL* `]`

  where *app_name* is the name you want for your app, and *CLOUDANT_URL* is the URL to your hosted database.

* Set the CLOUDANT_URL environment variable to the same value

* Update the .env file from Heroku
    * `heroku config -s > .env`

* Push the code to heroku
        `git push heroku master`

* Push your content to the remote database
        `rake update_remote_db`

* Review the log in log/upload_*.txt

## Customizing the look and feel
The project depends on Twitter Bootstrap for its look and feel.  To customize, you need to do the following:
* Install [lessc](http://lesscss.org/) and [uglifyjs](https://github.com/mishoo/UglifyJS) installed (the best way is to install them with [npm](https://npmjs.org/), then `npm install -g less uglify-js`)
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

## Updating the content with your own
The content in `content/sample` is there for example purposes.  To serve up your own content, you need to do the following:

* Move the content directory to content-bak (save the files for refernece)
* Add your html files to content/*lang-local/deliverable_name*
* Copy deliverable_metadata.json from the sample files and update it for your needs.
* Copy sample.toc and update it for your needs.  Copy it to *deliverable_name*.toc in content/*lang-local/deliverable_name*
* If you have specific metadata requirements update `lib/db/db_transaction.rb`

© Copyright 2013 salesforce.com, inc.
