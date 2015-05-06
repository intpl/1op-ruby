#!/usr/bin/env ruby
require 'socket'

VERBOSE = true
VERSION = "0.0 DEVELOPMENT"

# I use this command to easily restart the server:
# while true; do ./server.rb; done
# and then server restarts just by hitting Enter
waiter = Thread.new do
  puts "To quit, press Enter."
  gets
  exit
end
def log(msg, client = "")
  msg = msg
  msg += "[#{client}]" unless client.empty?
  puts msg if VERBOSE
end

def greeting
    return "1op:ruby-playground #{VERSION}"
end

# this will be changed
server = TCPServer.new(31337)

log "server started." if server

while (session = server.accept)
  Thread.new(session) do |my_session|
    my_session.puts greeting
    loop do
      msg = my_session.gets.chomp
      next if msg.empty?
      log "received: #{msg}"
      my_session.puts msg
      log "sent: #{msg}"
    end
    log "closing session #{my_session}"
    my_session.close
  end
end
