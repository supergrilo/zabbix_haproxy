require 'socket'
require 'json'
require 'optparse'

options = {}

parser = OptionParser.new do|opts|
  opts.banner = "Usage: years.rb [options]"
  options[:type] = "FRONTEND"
  opts.on('-t', '--type type', 'Backend Type(FRONTEND|BACKEND) Default: FRONTEND') do |type|
    options[:type] = type;
  end

  opts.on('-d', '--discovery', 'Discovery HAProxy backend or frontend') do |discovery|
    options[:discovery] = true;
  end

  opts.on('-h', '--help', 'Displays Help') do
    puts opts
    exit
  end
end

parser.parse!

class Connect
  attr_accessor :hp_command, :hp_socket_file

  def initialize
    @hp_command = "stat"
    @hp_socket_file = "/var/run/haproxy.stat"
  end

  def hp_get_itens(hp_command = @hp_command)
    socket = UNIXSocket.open hp_socket_file 
    socket.puts "show #{hp_command}"

    lines = ""

    while line = socket.gets
      lines << line
    end
    socket.close
    lines
  end

  def discovery(hp_type, hp_command = @hp_command)
    hap_status = hp_get_itens(hp_command)
    status = []

    hap_status.each_line { |line|
      if line.include? hp_type
        status << line.match('^[-a-zA-Z_]+')
      end
    }

    my_json = []

    for i in status
      my_json << {"{##{hp_type}}" => i}
    end

    "{ \"data\": #{JSON.generate(my_json)} }"
  end
end

if options[:discovery]
  a = Connect.new
  puts a.discovery(options[:type], "stat")
end

if options[:discovery].nil?
  STDERR.puts "Missing parameters"
  puts parser
  exit(1)
end
 
