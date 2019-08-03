# Websocket for mocking scans

To Run:

    bin/run

To send a"scan" via the socket to a listening webpage:

    bin/send <value>

(Where `<value>` is the "scanned value".)

Press `CTRL-C` to stop.

Example:

~~~~.ruby
# In one terminal
cd websocket_scanner_mock
bin/run

# In a second terminal:
cd websocket_scanner_mock
bin/send LC123
bin/send SK123
bin/send AAA
~~~~
