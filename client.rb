#!/usr/bin/env ruby
require 'socket'
require 'ffi-ncurses'
include FFI::NCurses

DEBUG = false
PORT = 31337

class Screen
  def initialize
      @stdscr = initscr
      cbreak
      noecho

      self.write "1op client"
      wrefresh(@stdscr)
  end

  def write(msg)
    waddstr(@stdscr, "[chat window] " + msg + "\n")
    wrefresh(@stdscr)
  end

  def read
    msg = []
    loop do
      key = FFI::NCurses.getch.chr  # read and convert to a String
      FFI::NCurses.waddstr(@stdscr, "#{key}")
      FFI::NCurses.wrefresh(@stdscr)
      msg << key
      return msg.join if key == "\n"
    end
  end

  wrefresh(@stdscr)
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

screen = Screen.new
server = TCPSocket.new("localhost", 31337)
screen.write "connected to: " + server.addr[2] + ":" + server.addr[1].to_s if server
Client.new(server, screen)
