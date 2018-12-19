#!/bin/sh

# Readiness checks

# ZNC - https request, look for "ZNC" in web page output
curl -s -k https://localhost:7776 | grep ZNC 
Zrc=$?


# irslackd - different checks depending on SSL

# For reference, a check for if irslackd is also using TLS
# echo | openssl s_client -connect localhost:6697 | openssl x509 -noout -dates

netstat -an | grep ^tcp | grep 6697 | grep LISTEN
Irc=$?


# Return binary or of both rcs.  Both are zero = result is zero.

exit $(( Zrc | Irc ))

