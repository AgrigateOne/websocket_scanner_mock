# Websocket for mocking scans

To Run:

    ./run

To send a"scan" via the socket to a listening webpage:

    ./send <value>

(Where `<value>` is the "scanned value".)

Press `CTRL-C` to stop.

Example:

~~~~.ruby
# In one terminal
cd websocket_scanner_mock
./run

# In a second terminal:
cd websocket_scanner_mock
./send LC123
./send SK123
./send AAA
~~~~
