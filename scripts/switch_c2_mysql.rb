#!/usr/bin/env ruby1.9.1

def main
  require 'highline/import'
  #Install mySQL packages from apt
  system("sudo apt-get install mysql-server mysql-client libmysql-ruby1.9.1")
  #replace sqliite junk with mysql
  system("sed -i 's/sqlite3/mysql2/g' /usr/share/concerto/Gemfile")

  password = ask("Enter MySQL root password: ") { |q| q.echo = false }

  puts "A random password is now being generated for use in Concerto's database configuration"
  random_password = generate_password(12)
  query = "use mysql;update user set password=PASSWORD(\'#{random_password}\') where User=\'concerto\';flush privileges;"

  system("mysql -u root -p#{password} -e \"#{query}\"")

  #Create database.yml entry
  database_yml = %{development:
  adapter: mysql2
  database: concerto_development
  username: concerto
  password: #{random_password}
  host: localhost

production:
    adapter: mysql2
    database: concerto_production
    username: concerto
    password: #{random_password}
    host: localhost}

  File.open('/usr/share/concerto/config/database.yml', 'w') {|f| f.write(database_yml) }

  Dir.chdir("/usr/share/concerto/") do
    #Install gems
    puts "Installing Gems..."
    system("bundle install --path vendor/bundle;")

    #Migrate database and install seed data
    puts "Migrating Database and Installing Seed Data..."
    system("rake db:migrate; rake db:seed")
  end
end

def generate_password(len)
  chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
  newpass = ""
  1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
  return newpass
end

main()

