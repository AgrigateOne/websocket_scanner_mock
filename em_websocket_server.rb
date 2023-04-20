# rubocop:disable Style/FrozenStringLiteralComment
# rubocop:disable Layout/LineLength

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

port = ARGV[0] || 2115
mode = ARGV[1] || 'apk'

QC_RESPONSES = [
  ['Type=RFM_Start', %(<MessageWS Status="true" Msg="RFM Peripheral='RFM-01'  Device='/dev/ttyS1' selected and started..." />)],
  ['Type=RFM_Zero', %(<MessageWS Status="true" Msg="RFM Peripheral='RFM-01'  Device='/dev/ttyS1' ZERO'ing..." />)],
  ['Type=RFM_Finish', %(<MessageWS Status="true" Msg="RFM Peripheral='RFM-01'  Device='/dev/ttyS1' connection closed..." />)],
  ['Type=MAF_Start', %(<MessageWS Status="true" Msg="MAF Peripheral='MAF'  Device='/dev/ttyS0' selected and started..." />)],
  ['Type=FTA_Start', %(<MessageWS Status="true" Msg="FTA Peripheral='FTA-01'  Device='/dev/ttyS0' selected and started..." />)],
  ['Type=FTA_Firmness', %(<MessageWS Status="true" Msg="FTA Peripheral='FTA-01' Firmness mode selected..." />)],
  ['Type=FTA_RetractProbe', %(<MessageWS Status="true" Msg="FTA Peripheral='FTA-01' Retract probe mode selected..." />)],
  ['Type=FTA_Firmness_Diameter', %(<MessageWS Status="true" Msg="FTA Peripheral='FTA-01' Firmness & Diameter mode selected..." />)],
  ['Type=FTA_Firmness_Weight', %(<MessageWS Status="true" Msg="FTA Peripheral='FTA-01' Firmness & Weight mode selected..." />)],
  ['Type=FTA_Diameter', %(<MessageWS Status="true" Msg="FTA Peripheral='FTA-01' Diameter mode selected..." />)],
  ['Type=FTA_Weight', %(<MessageWS Status="true" Msg="FTA Peripheral='FTA-01' Weight mode selected..." />)],
  ['Type=FTA_Finish', %(<MessageWS Status="true" Msg="FTA Peripheral='FTA-01'  Device='/dev/ttyS0' connection closed..." />)],
  ['Type=Sysinfo', %(<Data Type="SysInfo" Status="true" Company="NoSoft" IP="localhost" Server="192.168.50.54" ServerPort="2080" Revision="4.95"/>)]
].freeze

EM.run do # rubocop:disable Metrics/BlockLength
  @current_type = 'NOT DEFINED'
  @scans = File.readlines('.scans.txt')
  EM::WebSocket.run(host: '0.0.0.0', port: port) do |ws| # rubocop:disable Metrics/BlockLength
    ws.onopen do |handshake|
      puts 'WebSocket connection open'

      # Access properties on the EM::WebSocket::Handshake object, e.g.
      # path, query_string, origin, headers

      # Publish message to the client
      # ws.send "Hello Client, you connected to #{handshake.path}"
      if mode == 'apk'
        ws.send "WS: Connected to #{handshake.path} - awaiting type declaration."
      else
        ws.send '<DisplayMessage PID="601" Msg="WebSocket Connected..." />'
      end
    end

    ws.onclose { puts 'WS: Connection closed' }

    ws.onmessage do |msg|
      if mode == 'apk'
        if msg.start_with?('Type')
          @current_type = msg.delete_prefix('Type=')
          puts "WS: Type set to: #{@current_type}"
          ws.send "WS: Type set to: #{@current_type}"
        else
          puts "WS: Invalid message: #{msg}"
          ws.send "WS: Invalid message: #{msg}"
        end
      else
        puts "WS: received: #{msg}"
        # inner = 'selected and started [THIS MSG WILL VARY]...'
        # ws.send %(<DisplayMessage PID="601" Msg="FTA Peripheral='FTA-01'  Device='/dev/ttyS0' #{inner}" />)
        ws.send QC_RESPONSES.select { |k, _| msg.start_with?(k) }.flatten.last || 'Do not have correct response...'
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
            if scan.start_with?('[LOGIN]')
              ws.send "#{scan.chomp},#{@current_type},#{Time.now}"
            elsif scan.start_with?('[SCALE]')
              ws.send "#{scan.chomp},#{@current_type},#{Time.now}"
            elsif scan.start_with?('[SCAN]')
              # ws.send "[SCAN]#{scan.chomp},#{@current_type},#{Time.now}"
              # puts "||>>> #{scan.chomp},#{@current_type},#{Time.now}"
              ws.send "#{scan.chomp},#{@current_type},#{Time.now}"
            else
              ws.send scan.chomp
            end
            @scans << scan
          end
        end
        sleep 3
      end
    end
  end
end
# rubocop:enable Layout/LineLength
# rubocop:enable Style/FrozenStringLiteralComment
