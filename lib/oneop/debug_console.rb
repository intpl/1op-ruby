require 'colorize'

class DebugConsole
  def initialize
    @random_color = String.colors.sample
    puts "zainicjalizowano DebugConsole"
  end

  def receive msg
    puts msg.colorize(@random_color)
  end
    
end
