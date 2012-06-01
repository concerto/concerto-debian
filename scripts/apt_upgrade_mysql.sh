#!/bin/bash

#Replaces the default Concerto sqlite junk with MySQL
#For use after a package update to Concerto that may still be using sqlite on an image using MySQL
  #Changes Gemfile
  #Runs bundle install
  #Runs migration and seeding rake tasks

sed -i 's/sqlite3/mysql2/g' /usr/share/concerto/Gemfile
cd /usr/share/concerto/
bundle install --path vendor/bundle
rake db:migrate
rake db:seed

