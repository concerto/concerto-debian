#!/usr/bin/env ruby1.9.1
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
  end
end
