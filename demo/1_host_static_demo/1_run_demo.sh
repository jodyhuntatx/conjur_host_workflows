#!/bin/bash
echo
echo "This runs summon which uses the /etc/conjur.conf and /etc/conjur.identity files to authenticate the host identity and retrieve the secrets specified in secrets.yml and calls echo_secrets which echos their values."
summon ./echo_secrets.sh 
