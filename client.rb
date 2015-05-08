#!/usr/bin/env ruby
require 'socket'
require 'ffi-ncurses'
include FFI::NCurses

DEBUG = true
PORT = 31337
INPUT_DELAY_MS = 100

class Screen
  def initialize
    @stdscr = initscr
    @rows = getmaxy(@stdscr)
    @cols = getmaxx(@stdscr)
    @chatnum = 0
    @msgsize = 3
    @msg = []

    @chatwin = newwin(@rows - @msgsize, @cols, 0, 0)
    @msgwin = newwin(@msgsize, @cols, @rows - @msgsize, 0)

    cbreak
    qiflush
    noecho
    # We're using wtimeout to stop getch from blocking refreshes, so if 
    # no input occurs in INPUT_DELAY_MS then run the loop again
    wtimeout(@stdscr, INPUT_DELAY_MS)
    # Oh really, fuck this one. We want getch to be blocking so it doesn't
    # use 99% CPU in nodelay mode, but it stops the receive function from
    # refreshing the chatwin until we hit the key.
    #nodelay(@stdscr, true)

    draw
  end

  def draw
#    FIXME: Resize our window
#    y, x = getyx(@stdscr)
#    if (y != @cols) || (x != @rows)
#      @cols = y
#      @rows = x

#      wresize(@chatwin, y - @msgsize, x)
#      wresize(@msgwin, @msgsize, x)
#      mvwin(@msgwin, y - @msgsize, 0)

#      wclear(@stdscr)
#      wclear(@chatwin)
#      wclear(@msgwin)
#    end

    box(@chatwin, 0, 0)
    box(@msgwin, 0, 0)

    # TODO: Move cursor where it should be (prompt or end of a current msg)
    wmove(@msgwin, 1, 2)

    #clearok(@msgwin, true)
   refresh
#    wrefresh(@chatwin)
#    wrefresh(@msgwin)
  end

  def get_msg
    return @msg.join
  end

  def append(key)
    # DEBUG
    if key.chr == "T"
      receive "testdsa"
    end

    @msg << key.chr
    waddch(@msgwin, key)
    wrefresh(@msgwin)
  end

  def flush_msg
    @msg = []
    # Clear contents and draw a box again
    werase(@msgwin)
    box(@msgwin, 0, 0)
    # Move the cursor inside the box
    wmove(@msgwin, 1, 2)
    # Enforce refresh of the message window
    wrefresh(@msgwin)
  end

  def receive(msg)
    return if msg == nil
   # wrefresh(@msgwin)

    # Not reached message limit in window
    if (@chatnum < @rows - @msgsize - 2)
      @chatnum += 1
      # Get current cursor pos
      cur_y, cur_x = getyx(@msgwin)
      # Move cursor and write new msg
      # FIXME: Implement using scrollable NCurses pads
      mvwaddstr(@chatwin, @chatnum, 2, msg + "\n")
      # Go back to msg window
      wmove(@msgwin, cur_y, cur_x)
    else
      # Move every goddamn message upwards
      # then print the new one
      # FIXME: use pads to do it
    end

    # Add a box to ensure we we didn't fuck up anything in the process
    box(@chatwin, 0, 0)
    # Apply changes
    wrefresh(@chatwin)
    wrefresh(@msgwin)
  end
end

begin
  server = TCPSocket.new("localhost", PORT)
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
    c = getch
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
  endwin
end
