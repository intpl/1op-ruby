#!/usr/bin/env ruby
require 'socket'
require 'ffi-ncurses'
include FFI::NCurses

DEBUG = true
PORT = 31337

class Screen
  def initialize
    @stdscr = initscr
    @rows = getmaxx(
    @cols

    @msgwin = newwin(3, 30, 15, 0)
#    wborder(@msgwin, 0, 0, 0, 0, 0, 0, 0, 0)
#    box(@msgwin, 0, 0)
    @chatwin = newwin(7, 30, 0, 0)
#    box(@chatwin, 0, 0)
    cbreak
    noecho

#    write "\n\n"
#    wrefresh(@stdscr)
#    clear
  end

  def draw
    
  end

  def write(msg)
#    waddstr(@stdscr, msg + "\n")
    waddstr(@chatwin, msg + "\n");
    wrefresh(@stdscr)
    wrefresh(@msgwin)
  end

  def read
    msg = []
    loop do
#      write "test" if DEBUG
      wrefresh(@stdscr)
      wrefresh(@msgwin)
#      refresh
      key = getch.chr  # read and convert to a String
#      refresh
      msg << key
      waddstr(@msgwin, key)
      if key == "\n"
        wclear(@msgwin)
        refresh
        return msg.join
      end
#      return msg.join if key == "\n"
    end
  end
  #def refresh
  #  wrefresh(@stdscr)
  #  wrefresh(@msgwin)
  #end
end

class Client
  def initialize(server, screen)
    @server = server
    @request = nil
    @response = nil
    @screen = screen

    listen
    speak

    @request.join
    @response.join
  end

  def listen
    @response = Thread.new do
      loop do
        @screen.write "awaiting server messages..." if DEBUG
        msg = @server.gets.chomp
        @screen.write msg
      end

      @screen.write "stopped awaiting server messages..." if DEBUG
    end
  end

  def speak
    @request = Thread.new do
      loop do
        @screen.write "awaiting local messages..." if DEBUG
        msg = @screen.read
        @server.puts msg
      end

      @screen.write "stopped awaiting local messages..." if DEBUG
    end
  end
end

begin
  screen = Screen.new
  server = TCPSocket.new("localhost", PORT)
  screen.write "connected to: " + server.addr[2] + ":" + server.addr[1].to_s if server
  client = Client.new(server, screen)
ensure
  client.refresh
  endwin
end
