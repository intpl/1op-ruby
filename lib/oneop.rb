#!/usr/bin/env ruby
require 'socket'
require 'ffi-ncurses'

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

if SERVER
  def log(msg, client = "")
    msg = msg
    msg += "[#{client}]" unless client.empty?
    puts msg if DEBUG unless CLIENT
  end

  def greeting
    return "1op:ruby-playground #{VERSION}"
  end

  if server = TCPServer.new(PORT)
    log "server started." if server
  end

  server_thread = Thread.new do
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
  end

  server_thread.join unless CLIENT
end

if CLIENT
  begin
    server = TCPSocket.new(HOST, PORT)
    return unless server

    screen = Screen.new
    screen.receive "connected to: " + server.addr[2] + ":" + server.addr[1].to_s

    server_listener = Thread.new do
      loop do
        msg = server.gets.chomp
        screen.receive msg
      end
    end

    # Main loop
    # Outside Screen class so we can use initialize Screen correctly and block on getch
    loop do
      c = screen.getch
      exit if c == 3 #FIXME: interrupt, silly ncurses swalloing every control char

      if c.between?(0, 255)
        if (c.chr != "\n")
          screen.append(c)
        else
          server.puts screen.get_msg
          screen.flush_msg
        end

        #    screen.draw
      end
    end

  ensure
    screen.endwin if screen
  end
end
