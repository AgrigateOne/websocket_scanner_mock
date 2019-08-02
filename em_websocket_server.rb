# rubocop:disable Style/FrozenStringLiteralComment

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'em-websocket'
end

require 'em-websocket'

Signal.trap('INT') do
  puts "\nStopping..."
  EM.stop
end

File.open('.scans.txt', 'w') {}

EM.run do # rubocop:disable Metrics/BlockLength
  @current_type = 'NOT DEFINED'
  @scans = File.readlines('.scans.txt')
  EM::WebSocket.run(host: '0.0.0.0', port: 2115) do |ws| # rubocop:disable Metrics/BlockLength
    ws.onopen do |handshake|
      puts 'WebSocket connection open'

      # Access properties on the EM::WebSocket::Handshake object, e.g.
      # path, query_string, origin, headers

      # Publish message to the client
      # ws.send "Hello Client, you connected to #{handshake.path}"
      ws.send "WS: Connected to #{handshake.path} - awaiting type declaration."
    end

    ws.onclose { puts 'WS: Connection closed' }

    ws.onmessage do |msg|
      if msg.start_with?('Type')
        @current_type = msg.delete_prefix('Type=')
        puts "WS: Type set to: #{@current_type}"
        ws.send "WS: Type set to: #{@current_type}"
      else
        puts "WS: Invalid message: #{msg}"
        ws.send "WS: Invalid message: #{msg}"
      end
    end

    # Every 15 seconds, check the .scans.txt file to see if
    # any new lines have been written.
    # Send any new lines via the websocket.
    Thread.new do
      loop do
        if ws.state == :connected
          latest_scans = File.readlines('.scans.txt')
          # new_scans = latest_scans - @scans
          new_scans = latest_scans.drop(@scans.length)
          new_scans.each do |scan|
            puts ">> Sending #{scan}"
            ws.send "[SCAN]#{scan.chomp},#{@current_type},#{Time.now}"
            @scans << scan
          end
        end
        sleep 5
      end
    end
  end
end
# rubocop:enable Style/FrozenStringLiteralComment
