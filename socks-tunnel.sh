#!/bin/bash
#
# SSH TUNNEL (SOCKS)

PRIVKEY=/your/rsa_key
USER=user
SERVER=123.456.789.123

echo "SOCKS port 8080"
ssh -i $PRIVKEY -D 8080 -C -N $USER@$SERVER
