#Introduction
The two files are used for testing the network with client and server binaries
using [getaddrinfo](http://linux.die.net/man/3/getaddrinfo). The server can be
set to listen on `ipv4` or `ipv6` addresses.

#Usage
~~~
# ./getaddrinfo-server <port number>
# ./getaddrinfo-client <hostname or IP address> <port number> <some text message>
~~~

#Compile
~~~
# gcc -o getaddrinfo-server getaddrinfo-server.c
# gcc -o getaddrinfo-client getaddrinfo-client.c
~~~

#How to Run
Start the server on a host.
~~~
# ./getaddrinfo-server 4242
~~~

Send a message from the client to the server and way for a reply.
~~~
# ./getaddrinfo-client server.example.com 4242 hello
~~~
