#!/usr/bin/env ruby
require 'socket'
require 'rsa'

Dir["./oneop/*.rb"].each {|file| require file }

# initial const.
DEBUG = true
PORT = 31337
HOST = "localhost"
INPUT_DELAY_MS = 100
VERSION = "0.0 DEVELOPMENT"
if ARGV.include? '-sc' or ARGV.include? '-cs'
  SERVER = true
  CLIENT = true
else
  SERVER = ARGV.include? '-s'
  CLIENT = ARGV.include? '-c'
end

Server.new(CLIENT == true, PORT) if SERVER
Client.new(DebugConsole.new) if CLIENT
