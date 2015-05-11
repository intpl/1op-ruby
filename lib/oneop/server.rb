class Server
  def initialize(quiet = true, port = 31337)
    @quiet = quiet
    @port = port

    start_server
  end

  def greeting
    return "1op:ruby-playground #{VERSION}"
  end

  def log(msg)
    puts msg if DEBUG unless @quiet
  end

  def start_server
    if server = TCPServer.new(@port)
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

    server_thread.join unless @quiet
  end
end
