class Client
  def initialize(klass)
    @server = TCPSocket.new(HOST, PORT)
    @viewer = klass
    threads = []

    Thread.new do
      loop do
        message = @server.gets.chomp
        @viewer.receive message 
      end.join
    end

    Thread.new do
      loop do
        message = $stdin.gets.chomp
        @server.puts message
      end
    end.join
  end

#  def method_missing(method_name, *args, &block)
#    @viewer.send(method_name, *args, &block)
#  end
end
