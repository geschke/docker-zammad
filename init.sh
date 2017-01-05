#!/bin/bash

cd /opt/zammad
export RAILS_ENV=production
export PATH=/opt/zammad/bin:$PATH
export GEM_PATH=/opt/zammad/vendor/bundle/ruby/2.3.0/


if [ ! -f /opt/zammad/initdata/initialized ]; then
        rake db:create
        rake db:migrate
        rake db:seed
        rake assets:precompile

        rails r "Setting.set('es_url', 'http://localhost:9200')"
        sleep 15
        rake searchindex:rebuild

        echo true > /opt/zammad/initdata/initialized
fi
