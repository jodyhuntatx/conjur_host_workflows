#!/bin/bash 
APP_HOSTNAME=webapp1/tomcat_host

# add subject alt names for Openshift IP address
#echo "$OPENSHIFT_IP	conjur-master conjur-follower" >> /etc/hosts

# delete old identity stuff
rm -f /root/.conjurrc /root/conjur*.pem

# initialize client environment
conjur init -h $OPENSHIFT_IP << EOF
yes
EOF
conjur plugin install policy
conjur authn login -u admin -p Cyberark1
conjur policy load --as-group security_admin webapp1-policy.yml
conjur variable values add webapp1/database_username DatabaseUser
conjur variable values add webapp1/database_password $(openssl rand -hex 12)

# create configuration and identity files (AKA conjurization)
cp ~/conjur-$CONJUR_ACCOUNT.pem /etc

				# generate api key
api_key=$(conjur host rotate_api_key --host $APP_HOSTNAME)

				# copy over identity file
echo "Generating identity file..."
cat <<IDENTITY_EOF | tee /etc/conjur.identity
machine $OPENSHIFT_IP/api/authn
  login host/$APP_HOSTNAME
  password $api_key
IDENTITY_EOF

echo
echo "Generating host configuration file..."
cat <<CONF_EOF | tee /etc/conjur.conf
---
appliance_url: $OPENSHIFT_IP/api
account: $CONJUR_ACCOUNT
netrc_path: "/etc/conjur.identity"
cert_file: "/etc/conjur-$CONJUR_ACCOUNT.pem"
plugins: [ policy ]
CONF_EOF

chmod go-rw /etc/conjur.identity

# delete user identity files to force use of /etc/conjur* host identity files.
rm ~/.conjurrc ~/.netrc
