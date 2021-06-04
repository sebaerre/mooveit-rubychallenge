== THIS IS THE MEMCACHED RUBY SERVER MOOVE IT CHALLENGE == @@Sebastian Herrera@@

1) Introduction

The server is implemented following the TCP protocol, and listens for connections on port 28561.
Its multi-threaded, so it can listen to many simultaneous connections from different clients and uses mutex as a semaphore, to control the lock over the shared resources.
It also follows the same syntax and delivers the same responses as memcached.

To run the server simply set the IP where the server should be hosted in the file server.rb and run it.
The project also includes a client.rb file that you can use to send commands to the server, provided that you also set the same IP on the client.rb file.

The server supports the following commands:

==================Storage Commands==================

1) set \<key> \<flags> \<exptime> \<bytesize>

This command is used to save data under the key \<key>, which can then be retrieved using get / gets.

-\<flags> Is extra info which gets stored right next to the data. Since the official documentation says its 16-bit unsigned int, the server expects to get between 1 and 2 digit integer.

-\<exptime> Is the expiration time of the data expressed in seconds. If the server gets a value higher than 30 days in seconds (2592000), it will interpret the time as UNIX time.
If a value of 0 is used, the data will never expire.
If a value \<0 is used, the data will immediatly expire (will never get stored)
The server expects to get between 1 and 12 digits for this.

-\<bytesize> Is the amount of bytes that are going to be stored under that key. Since each character is 1 byte, the amount of bytes set here has to be the same number of characters that
are gonna be stored.

After this command is delivered to the server, we can then type the data to be stored under \<key>, and we should get a "STORED" message from the server.

2) add \<key> \<flags> \<exptime> \<bytesize>

This command behaves like the previous set command, the only difference being that it will only store the data if no data is already being stored under the key \<key>.
In that case, it will return "NOT_STORED"

After this command is delivered to the server, we can then type the data to be stored under \<key>, and we should get a "STORED" message from the server if the key did not hold data already.

3) replace \<key> \<flags> \<exptime> \<bytesize>

This command behaves like the opposite of the previous add command. It will only store the data if there is already data being stored under the key \<key>.
In the case that the key \<key> holds no data, the server will return "NOT_STORED"

After this command is delivered to the server, we can then type the data to be stored under \<key>, and we should get a "STORED" message from the server if the key did hold data already.


4) append \<key> \<flags> \<exptime> \<bytesize>

This command completly ignores \<flags> and \<exptime>.
It appends the data to the data already existing under the key \<key>.

After this command is delivered to the server, we can then type the data to be stored under \<key>, and we should get a "STORED" message from the server if the key did hold data already.
In the case that the key \<key> holds no data, the server will return "NOT_STORED"


5) prepend \<key> \<flags> \<exptime> \<bytesize>

This command completly ignores \<flags> and \<exptime>.
It prepends the data to the data already existing under the key \<key>.

After this command is delivered to the server, we can then type the data to be stored under \<key>, and we should get a "STORED" message from the server if the key did hold data already.
In the case that the key \<key> holds no data, the server will return "NOT_STORED"


5) cas \<key> \<flags> \<exptime> \<bytesize> \<casuniquekey>

This 'cas' command  (comes from check-and-set) requires an extra parameter \<casuniquekey>.
Every storage command, asigns a new and unique id to the data being stored under the specified key.
We can get this unique cas id or key, by running the command 'gets \<key>'. The last number received by this command is the key we are looking for.

Only if the key we provide to this command, is equal to the unique cas key stored in memory with the data, the data is set to the new data we pass after.
So this command only works if no one has altered the value of the key, since we last fetched it with gets (because every data-altering command sets a new unique cas key)


After this command is delivered to the server, we can then type the data to be stored under \<key>, and we should get a "STORED" message from the server if the cas unique key is equal to \<casuniquekey> and if the key already held any data.
If the keys do not match, we will get an "EXISTS" message back from the server.
If the key did not hold data, we will get a "NOT_FOUND" message back from the server

==THE SERVER WILL RETURN AN ERROR "CLIENT_ERROR bad data chunk" FOR EVERY STORAGE COMMAND IF THE BYTE SIZE SPECIFIED DOES NOT MATCH WITH THE BYTESYZE OF THE DATA WE ARE TRYING TO STORE.==

==================Retrieval Commands==================

1) get \<key>*

The command key receives 1 or more keys, and then returns the data stored for all of them.
If only one key is provided and there is no data saved in that key, the server returns an empty string, if many keys are provided and some of them do not store any data, the server ignores them and returns the data of the keys that do.
The data returned contains the value, the flags and the amount of bytes.

1) gets \<key>*

It works exactly as the get command, but with the difference that it also returns the cas unique key needed to call the cas command.

==================Special Commands==================

1) PURGE

Used only with testing purposes, it deletes all data for the current session.

==================Sample Commands==================

==================SET==================

set testvar 0 900 4

test
STORED
get testvar

VALUE testvar 0 4
test
END

set neverexpire 1 0 4

neve
STORED
get neverexpire

VALUE neverexpire 1 4
neve
END

set errorchunk 0 900 16

test

CLIENT_ERROR bad data chunk

==================ADD==================

set testadd 0 900 4

test
STORED
get testadd

VALUE testadd 0 4
test
END
add testadd 0 900 10

addedvalue

NOT_STORED
get testadd

VALUE testadd 0 4
test
END
add newValue 0 900 4

test
STORED
get newValue

VALUE newValue 0 4
test
END

add errorchunk 0 900 16

test

CLIENT_ERROR bad data chunk

==================REPLACE==================

set testreplace 0 900 4

test
STORED
get testreplace

VALUE testreplace 0 4
test
END
replace testreplace 1 900 13

replacedvalue
STORED
get testreplace

VALUE testreplace 1 13
replacedvalue
END
replace newValue 0 900 4

test

NOT_STORED
get newValue
END
replace errorchunk 0 900 16

test

CLIENT_ERROR bad data chunk

==================APPEND==================

set testappend 0 900 4

test
STORED
append testappend 1 900 11

appendvalue

STORED
get testappend

VALUE testappend 1 15
testappendvalue
END
append newValue 0 900 4

test

NOT_STORED
get newValue
END

append errorchunk 0 900 16

test

CLIENT_ERROR bad data chunk

==================PREPEND==================

set testprepend 0 900 4

test
STORED
prepend testprepend 1 900 11

prependvalue
STORED
get testprepend

VALUE testprepend 1 15
prependvaluetest
END

prepend newValue 0 900 4

test
NOT_STORED
get newValue

END

prepend errorchunk 0 900 16

test

CLIENT_ERROR bad data chunk

==================CAS==================

cas tottallynewvalue 0 900 4 5

none

NOT_FOUND

cas chunkerror 0 900 5 5

nonesnones

CLIENT_ERROR bad data chunk

set testvar 0 900 4

test
STORED
gets testvar

VALUE testvar 0 4 9
test
END

cas testvar 0 900 4 10 #\<--wrong cas key

test

EXISTS

replace testvar 0 900 4

yeah

STORED
cas testvar 0 900 4 9 #\<--The key changed since a storage command (replace) was called on the key before calling cas

test

EXISTS
gets testvar

VALUE testvar 0 4 10 #\<--The key has changed
test
END

cas testvar 0 900 4 10

cass

STORED
get testvar

VALUE testvar 0 4
cass
END

==================GET==================

get newvar
END
set newvar 0 900 4

test

STORED
set othervar 1 900 5

words

STORED
get newvar

VALUE newvar 0 4
test
END
get foo othervar newvar anothervar

VALUE othervar 1 5
words
VALUE newvar 0 4
test
END

==================GETS==================

get newvar
END
set newvar 0 900 4

test

STORED
set othervar 1 900 5

words

STORED
gets newvar

VALUE newvar 0 4 8
test
END
gets foo othervar newvar anothervar

VALUE othervar 1 5 9
words
VALUE newvar 0 4 8
test
END

==================TEST==================

To run the tests, simply run "gem install rspec" on the project root folder, and after instalation is done run the "rspec -fd" command on the project root folder.
