#!/usr/bin/env ruby
require 'socket'
require 'ffi-ncurses'
include FFI::NCurses

DEBUG = true
PORT = 31337

class Screen
  def initialize
    @server = TCPSocket.new("localhost", PORT)
    @response = Thread.new do
      loop do
       msg = @server.gets.chomp
       #send_msg
       receive_msg(msg) 
      end
    end

    @stdscr = initscr
    @rows = getmaxy(stdscr)
    @cols = getmaxx(stdscr)
    @chatnum = 0
    @msgsize = 3
    @msg = []

    @chatwin = newwin(@rows - @msgsize, @cols, 0, 0)
    @msgwin = newwin(@msgsize, @cols, @rows - @msgsize, 0)

    cbreak
    noecho

    loop do
      draw
    end
  end

  def draw
    y, x = getyx(stdscr)
    # Resize our window
    if (y != @cols) || (x != @rows)
      @cols = y
      @rows = x

      wresize(@chatwin, y - @msgsize, x)
      wresize(@msgwin, @msgsize, x)
      mvwin(@msgwin, y - @msgsize, 0)

      wclear(stdscr)
      wclear(@chatwin)
      wclear(@msgwin)

      wmove(@msgwin, 1, 2)
    end

      box(@chatwin, 0, 0)
      box(@msgwin, 0, 0)

    wrefresh(@chatwin)
    wrefresh(@msgwin)

    handle_input(getch)
  end

  def handle_input(key)
    @msg << key.chr
    waddch(@msgwin, key)
    send_msg if key.chr == "\n"
  end

  def send_msg
    werase(@msgwin)
    wmove(@msgwin, 1, 2)
    wrefresh(@stdscr)
    wrefresh(@msgwin)
    
    tmp = @msg.join
    @msg = []

    @server.puts tmp
#    return tmp
  end

  def receive_msg(msg)
    return if msg == nil

    # Not reached message limit in window
    if (@chatnum < @rows - @msgsize - 2)
      @chatnum += 1
      # Get current cursor pos
      cur_y, cur_x = getyx(@stdscr)
      # Move cursor and write new msg
      # FIXME:
      mvprintw(@chatwin, @chatnum + 1, 1, msg)
      # Go back to msg window
      wmove(@msgwin, cur_y, cur_x)
    else
      # Move every goddamn message upwards
      # then print the new one
    end
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
