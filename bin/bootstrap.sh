#!/bin/bash
#
# Bootstrap to either install, or start server.
#



if [ ! -w /data ]; then
  echo "/data is not writable.  Volume not set correctly."
  sleep 36000
fi



# SSL cert doesn't exist?  Create it.
if [ ! -e /data/cert.pem -o ! -e /data/pkey.pem ]; then

  cd /data
  echo Creating default SSL cert/key
  openssl req -newkey rsa:4096 -nodes -sha512 -x509 -days 3650 -nodes -out ./cert.pem -keyout ./pkey.pem -subj "/C=US/ST=NC/L=Some Town/O=Red Hat/CN=localhost"

  # Show fingerprint
  openssl x509 -noout -fingerprint -sha512 -inform pem -in ./cert.pem

fi



# ZNC config directory doesn't exist?  Create it and symlink in the cert
if [ ! -d /data/znc ]; then
  mkdir -p /data/znc/configs
fi


# No ZNC ssl cert?  Concatenate what we created above to create it
if [ ! -e /data/znc/znc.pem ]; then
  cat /data/pkey.pem /data/cert.pem > /data/znc/znc.pem
fi


# No ZNC config?  ZNC docs say to use --makeconf, but we'll hack it together
# to get going.
if [ ! -e /data/znc/configs/znc.conf ]; then

  if [ -z "$ZNC_ADMIN_PASSWORD" ]; then
    echo "No ZNC_ADMIN_PASSWORD vars set for initial user."
    sleep 36000
  fi

  # Run makepass once, then parse it for key/value pairs
  pwhash=$( echo -e "$ZNC_ADMIN_PASSWORD\n$ZNC_ADMIN_PASSWORD\n" | /opt/znc/bin/znc --makepass | sed -n '/^<Pass/,/^<\/Pass/p' )

  # TODO - make sure pw components could be read

  # ZNC docs say to not create initial conf automatically, but we don't want a
  # manual process here so will try out best.

  echo Writing initial znc configuration to disk

  cat <<EOF > /data/znc/configs/znc.conf

# Unsupported initial ZNC file
Version = 1.7.1
<Listener l>
	Port = 7776
	IPv4 = true
	IPv6 = false
	SSL = true
</Listener>

# Disable IP protection to avoid a hard requirement on
# session affinity in the svc config
ProtectWebSessions = false

LoadModule = webadmin

<User admin>
	Admin      = true
	Nick       = admin
	AltNick    = admin_
	Ident      = admin
	LoadModule = chansaver
	LoadModule = controlpanel

$pwhash

</User>


EOF



fi

  



# TODO: look for env variable for clean start


# TODO - launch http server with error


# TODO: look for an env variable to "git pull" an update






# Run ZNC - defaults to background

# TODO: an unclean shutdown, or rolling deployment strategy falls foul of RWO pvc, leaving the znc.conf file locked.
# We try to start clean, but if that doesn't work we break the file lock to get started.
# 
if [ -e /data/znc/configs/znc.conf ]; then

  echo Launching ZNC
  r="R$RANDOM"   # cannot use $$ as it's always "1"
  ( /opt/znc/bin/znc -d /data/znc -r ) || ( echo Breaking file lock and trying again; sleep 5; cp -f /data/znc/configs/znc.conf /tmp/znc.$r; rm -f /data/znc/configs/znc.conf; cp -f /tmp/znc.$r /data/znc/configs/znc.conf; /opt/znc/bin/znc -d /data/znc -r )
fi



# Run irslackd - defaults to foreground

if [ -e /opt/irslackd/irslackd ]; then
  echo Launching irslackd
  # Disable SSL to run irslackd on loopback only
  # /opt/irslackd/irslackd -k /data/pkey.pem -c /data/cert.pem
  /opt/irslackd/irslackd -i -a 127.0.0.1 &
fi



echo "$( date ) - Finished bootstrap ... container running."


# Loop and copy out the znc config every 10 minutes to avoid locked files
# during container restarts

while :; do
  sleep 1h
  cp -f /data/znc/configs/znc.conf /data/znc/configs/znc.conf.bak
done


