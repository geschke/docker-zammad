#!/bin/bash

cd /opt/zammad
export RAILS_ENV=production
export PATH=/opt/zammad/bin:$PATH
export GEM_PATH=/opt/zammad/vendor/bundle/ruby/2.3.0/


script/websocket-server.rb start &
script/scheduler.rb start &
rails s --binding=0.0.0.0 -p 3000
