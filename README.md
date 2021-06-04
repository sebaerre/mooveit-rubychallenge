== THIS IS THE MEMCACHED RUBY SERVER MOOVE IT CHALLENGE == @@Sebastian Herrera@@

1) Introduction

The server is implemented following the TCP protocol, and listens for connections on port 28561.
Its multi-threaded, so it can listen to many simultaneous connections from different clients and uses mutex as a semaphore, to control the lock over the shared resources.
It also follows the same syntax and delivers the same responses as memcached.


The server supports the following commands:

==================Storage Commands==================

1) set <key> <flags> <exptime> <bytesize>

This command is used to save data under the key <key>, which can then be retrieved using get / gets.

-<flags> Is extra info which gets stored right next to the data. Since the official documentation says its 16-bit unsigned int, the server expects to get between 1 and 2 digit integer.
-<exptime> Is the expiration time of the data expressed in seconds. If the server gets a value higher than 30 days in seconds (2592000), it will interpret the time as UNIX time.
The server expects to get between 1 and 12 digits for this.
-<bytesize> Is the amount of bytes that are going to be stored under that key. Since each character is 1 byte, the amount of bytes set here has to be the same number of characters that
are gonna be stored.

After this command is delivered to the server, we can then type the data to be stored under <key>, and we should get a "STORED" message from the server.

2) add <key> <flags> <exptime> <bytesize>

This command behaves like the previous set command, the only difference being that it will only store the data if no data is already being stored under the key <key>.
In that case, it will return "NOT_STORED"

After this command is delivered to the server, we can then type the data to be stored under <key>, and we should get a "STORED" message from the server if the key did not hold data already.

3) replace <key> <flags> <exptime> <bytesize>

This command behaves like the opposite of the previous add command. It will only store the data if there is already data being stored under the key <key>.
In the case that the key <key> holds no data, the server will return "NOT_STORED"

After this command is delivered to the server, we can then type the data to be stored under <key>, and we should get a "STORED" message from the server if the key did hold data already.


4) append <key> <flags> <exptime> <bytesize>

This command completly ignores <flags> and <exptime>.
It appends the data to the data already existing under the key <key>.

After this command is delivered to the server, we can then type the data to be stored under <key>, and we should get a "STORED" message from the server if the key did hold data already.
In the case that the key <key> holds no data, the server will return "NOT_STORED"


5) prepend <key> <flags> <exptime> <bytesize>

This command completly ignores <flags> and <exptime>.
It prepends the data to the data already existing under the key <key>.

After this command is delivered to the server, we can then type the data to be stored under <key>, and we should get a "STORED" message from the server if the key did hold data already.
In the case that the key <key> holds no data, the server will return "NOT_STORED"


5) cas <key> <flags> <exptime> <bytesize> <casuniquekey>

This 'cas' command  (comes from check-and-set) requires an extra parameter <casuniquekey>.
Every storage command, asigns a new and unique id to the data being stored under the specified key.
We can get this unique cas id or key, by running the command 'gets <key>'. The last number received by this command is the key we are looking for.

Only if the key we provide to this command, is equal to the unique cas key stored in memory with the data, the data is set to the new data we pass after.
So this command only works if no one has altered the value of the key, since we last fetched it with gets (because every data-altering command sets a new unique cas key)


After this command is delivered to the server, we can then type the data to be stored under <key>, and we should get a "STORED" message from the server if the cas unique key is equal to <casuniquekey> and if the key already held any data.
If the keys do not match, we will get an "EXISTS" message back from the server.
If the key did not hold data, we will get a "NOT_FOUND" message back from the server

==THE SERVER WILL RETURN AN ERROR "CLIENT_ERROR bad data chunk" FOR EVERY STORAGE COMMAND IF THE BYTE SIZE SPECIFIED DOES NOT MATCH WITH THE BYTESYZE OF THE DATA WE ARE TRYING TO STORE.==

==================Retrieval Commands==================

1) get <key>*

The command key receives 1 or more keys, and then returns the data stored for all of them.
If only one key is provided and there is no data saved in that key, the server returns an empty string, if many keys are provided and some of them do not store any data, the server ignores them and returns the data of the keys that do.
The data returned contains the value, the flags and the amount of bytes.

1) gets <key>*
It works exactly as the get command, but with the difference that it also returns the cas unique key needed to call the cas command.

==================Special Commands==================

1) PURGE
Used only with testing purposes, it deletes all data for the current session.
