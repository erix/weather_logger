Features Backbone.js, Twitter Bootstrap, Jasmine, Sprockets (CoffeeScript, SASS, and JST support), and more.

### install

    git clone https://github.com/6/sinatra-backbone-boilerplate.git your_app
    cd your_app
    git remote rm origin
    git remote add upstream https://github.com/6/sinatra-backbone-boilerplate.git
    bundle install

### run

    rake start
    rake guard
    rake test

Open [http://localhost:5000](http://localhost:5000) for the web app and [http://localhost:8888](http://localhost:8888) for Jasmine.

### pulling in updates

    git fetch upstream
    git merge upstream/master
