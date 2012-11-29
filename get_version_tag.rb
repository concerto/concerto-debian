#!/usr/bin/env ruby
#https://api.github.com/repos/concerto/concerto/git/refs/tags

require 'net/https'
require 'uri'
require 'json'

uri = URI.parse('https://api.github.com/repos/concerto/concerto/git/refs/tags')
http = Net::HTTP.new(uri.host, uri.port)
if uri.scheme == "https" # enable SSL/TLS
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  http.ca_file = File.join("cacert.pem")
end
http.start {
  http.request_get(uri.path) {|res|
    @versions = Array.new
    JSON.parse(res.body).each do |tag|
      @versions << tag['ref'].gsub(/refs\/tags\//,'')
    end
    @versions.sort! {|x,y| y <=> x }
    File.open("VERSION", 'w') {|f| f.write(@versions[0]) }
  }
}
