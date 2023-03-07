# 1 on 1 Chat App
This is a simple one on one chat app that can operate in two modes: server mode and client mode. 
In server mode, the app launches a server and listens for any potential clients that want to connect to it. 
In client mode, the app tries to connect to a server.

## Instalation
After cloning the repository, navigate to the root directory of the project and run the following command to build the project:

`dune build`

## Usage 
The chat starts with default values for the host (127.0.0.1), the port (8000) and the app mode (server).
To start the app with the default settigs, run the following command:

'./_build/default/bin/chat_app.exe'

To change app settings we provide the following flags:

* `-h [<ip address>]` - Set the IP address the application tries to connect to. Default is: 127.0.0.1.
* `-p [<port number>]` - Set the port the aplication tries to connect to. Default is: 8000.
* `-m [<mode of Operation>]` - Set the mode the application starts on. Default is server.

