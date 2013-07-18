#!/usr/bin/env ruby1.9.1
#This script is used on the Concerto Server VM image to make sure users change the default passwords
#It also invokes a script to switch Concerto to MySQL and set database credentials and database.rb accordingly
def main 
  require 'rubygems'
  require 'highline/import'

  file = File.open("/etc/passwords_changed")
  changed = file.read.chomp
  if changed == "true"
    exit 0
  else
    puts "The MySQL root and the concerto user passwords are still set to the defaults and should be changed for security. The current password is the password that came with this system image"
    #Use Debian utility to reset MySQL password
    puts "Resetting MySQL root password..."
    #system("sudo dpkg-reconfigure mysql-server-5.5")
    old_password = ask("Enter current MySQL root password: ") { |q| q.echo = false }
    new_password = ask("Enter new MySQL root password: ") { |q| q.echo = false }
    
    puts "A random password is now being generated for use in Concerto's database configuration"
    random_password = generate_password(12)
    query = "use mysql;update user set password=PASSWORD(\'#{random_password}\') where User=\'concerto\';update user set password=PASSWORD(\'#{new_password}\') where User=\'root\';flush privileges;"
    
    system("mysql -u root -p#{old_password} -e \"#{query}\"")
    
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
    
    #Change concerto user password
    system("passwd")   
    
    #Mark passwords as properly changed
    system("echo true > /etc/passwords_changed")
  end

end

def generate_password(len)
  chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
  newpass = ""
  1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
  return newpass
end

main()
