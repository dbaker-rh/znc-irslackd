#!/bin/sh

# Liveness checks

# ZNC - https request, look for "ZNC" in web page output
curl -s -k https://localhost:7776 | grep ZNC 
Zrc=$?


# irslackd - the readiness check dumps output to log, so for liveness we
# just ensure the socket is still listening
netstat -an | grep ^tcp | grep 6697 | grep LISTEN
Irc=$?


# Return binary or of both rcs.  Both are zero = result is zero.

exit $(( Zrc | Irc ))

