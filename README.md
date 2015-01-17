# Documentation Portal - Multiple Deliverable Version 

This is a documentation portal written in Ruby, using Sinatra for routing and CouchDB for content storage and searching.  The UI is controlled by Twitter Bootstrap. 

## Quick hosting using Heroku
1. [Create a Heroku Account](https://signup.heroku.com)

1. [Create a Cloudant Account](https://cloudant.com/sign-up/) 

1. [![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

1. Answer questions on that web page.  Use your own CLOUDANT database
   URL, please.  It should be something like this:  Ensure that you enter your the URL to your Cloudant database in the CLOUDANT_URL
   field; for example, it should be something like
   `http://<username>:<password>@sanderson.cloudant.com"}

1. When the app is deploy, click View It.  Sign in with username
   `redsofa-qa` password `doc123456`


## Setting up the project to configure and customize

1. [Set up git](https://help.github.com/articles/set-up-git#platform-all)

1. Install Ruby 2.1.2 (I suggest using - [RVM](https://rvm.io/rvm/install/))

1. Clone this project

1. Install the gems in the Gemfile (I suggest using [bundle](http://gembundler.com/bundle_install.html))


## Run it locally

1. Set up your database
    1. [Set up couchdb](http://wiki.apache.org/couchdb/Installation)
    1. [Add lucene to couchdb](https://github.com/rnewson/couchdb-lucene)

1. Set the CLOUDANT_URL environment variable 
    * For a local database, do something like this: `export CLOUDANT_URL=http://admin:admin@localhost:5984`
    * For a hosted database, do something like this: `export CLOUDANT_URL=http://<username>:<passcode>:<cloudant-host>.cloudant.com`

1. Create a file named `.env.development` and add your CLOUDANT_URL export command to it (ie, `export CLOUDANT_URL=http://admin:admin@localhost:5984`)

1. Then run
        `rake update_local_db`

1. Review the log in log/upload_*.txt

1. Then run
        `rake start_local`

1. If you want to auto-load local changes, instead of start_local, use
        `rake start_local_debug`

1. Open your web browser and look at [http://localhost:5000]
    * If you are prompted to login, the username is redsofa-qa, password doc123456



## Deploy it to heroku - manual

1. [Create a Heroku Account](https://signup.heroku.com)

1. [Install the Heroku toolbelt](https://toolbelt.heroku.com)

1. [Create a Cloudant Account](https://cloudant.com/sign-up/) 

1. One time, initialize the project on heroku

  `rake initialize_heroku[`*app_name*,*CLOUDANT_URL* `]`

    where *app_name* is the name you want for your app, and *CLOUDANT_URL* is the URL to your hosted database.  *Note*: Don't put spaces around the comma between *app_name* and *CLOUDANT_URL*.  If you do, you'll get an error.
    
1. Push your content to the remote database
        `rake update_remote_db`

1. Review the log in log/upload_*.txt

1. Validate it's working

    `heroku open`

    Username: redsofa-qa

    Password: doc123456

## Customizing the look and feel
The project depends on Twitter Bootstrap for its look and feel.  To customize, you need to do the following:

1. Install [lessc](http://lesscss.org/) and [uglifyjs](https://github.com/mishoo/UglifyJS) installed (the best way is to install them with [npm](https://npmjs.org/), then `npm install -g less uglify-js`)

1. Customize the files in `less/`.  See [http://lesscss.org/](http://lesscss.org/) for details on less.

1. Due to an issue with less v2
   (see http://stackoverflow.com/questions/26628309/less-v2-does-not-compile-twitters-bootstrap-2-x),
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

1. Run `rake bootstrap:make`

## Updating the content with your own
The content in `content/sample` is there for example purposes.  To serve up your own content, you need to do the following:

1. Move the content directory to content-bak (save the files for refernece)

1. Add your html files to content/*lang-local/deliverable_name*

1. Copy deliverable_metadata.json from the sample files and update it for your needs.

1. Copy sample.toc and update it for your needs.  Copy it to *deliverable_name*.toc in content/*lang-local/deliverable_name*

1. If you have specific metadata requirements update `lib/db/db_transaction.rb`

## Customizing the username and password

The username and password are stored in `config/app_config.yaml`.  Update that file to change the username or password.

To turn off the required login, uncomment (remove the # character) the line that begins with `LOGIN_REQUIRED`.

© Copyright 2013 salesforce.com, inc.
