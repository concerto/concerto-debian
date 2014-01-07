#!/usr/bin/env ruby
#This script is used on the Concerto Server VM image to make sure users change the default passwords

file = File.open("/etc/passwords_changed")
changed = file.read.chomp
if changed == "true"
  exit 0
else
  #Change concerto user password
  if system("passwd")
    #Mark passwords as properly changed
    system("echo true > /etc/passwords_changed")
    #change mysql root password
    system("sudo dpkg-reconfigure mysql-server-5.5")
  end
end
