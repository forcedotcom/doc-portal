# Documentation Portal - Multiple Deliverable Version 

This is a documentation portal written in Ruby, using Sinatra for routing and CouchDB for content storage and searching.  The UI is controlled by Twitter Bootstrap. 

## Using the project 

* [Set up git](https://help.github.com/articles/set-up-git#platform-all)
* [Install RVM](https://rvm.io/rvm/install/)
* [Install bundle](http://gembundler.com/bundle_install.html)
* Clone this project
* In that directory, run 
        bundle install
* Install [lessc](http://lesscss.org/) and [uglifyjs](https://github.com/mishoo/UglifyJS) installed (the best way is to install them with [npm](https://npmjs.org/), then `npm install -g less uglify-js`)
* Add Bootstrap,  version 2.3.2, and Font Awesome, as submodules with the following rake command `rake bootstrap:init`
* Customize the files in `less/`.  See [http://lesscss.org/](http://lesscss.org/) for details on less.
* Run `rake bootstrap:make`
* If you have specific metadata requirements update `lib/db/db_transaction.rb`
* Add you html files to content/*lang-local/deliverable_name*
* Create a deliverable_metadata.json file in content/*lang-local/deliverable_name*
* Create a *deliverable_name*.toc in content/*lang-local/deliverable_name*

## Run it locally
* [Set up couchdb](http://wiki.apache.org/couchdb/Installation)
* [Add lucene to couchdb](https://github.com/rnewson/couchdb-lucene)
* Then run
        `rake update_local_db`
* Review the log in log/upload_*.txt
* Then run
        `rake start_local`
* If you want to auto-load local changes, instead of start_local, use
        `rake start_local_debug`

## Deploy it to heroku
* One time, initialize the project on heroku
        `rake initialize_heroku`
* Push it to heroku
        `git push heroku master`
* Push your content to the remote database
        `rake update_remote_db`
* Review the log in log/upload_*.txt

© Copyright 2013 salesforce.com, inc.