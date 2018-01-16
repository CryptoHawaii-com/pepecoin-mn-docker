#!/bin/bash
set -e

# Add local user
# Either use the LOCAL_USER_ID if passed in at runtime or
# fallback
USER_ID=${LOCAL_USER_ID:-9002}
GRP_ID=${LOCAL_GRP_ID:-9002}

getent group user > /dev/null 2>&1 || groupadd -g $GRP_ID user
id -u user > /dev/null 2>&1 || useradd --shell /bin/bash -u $USER_ID -g $GRP_ID -o -c "" -m user

LOCAL_UID=$(id -u user)
LOCAL_GID=$(getent group user | cut -d ":" -f 3)

if [ ! "$USER_ID" == "$LOCAL_UID" ] || [ ! "$GRP_ID" == "$LOCAL_GID" ]; then
    echo "Warning: User with differing UID "$LOCAL_UID"/GID "$LOCAL_GID" already exists, most likely this container was started before with a different UID/GID. Re-create it to change UID/GID."
fi

echo "Starting with UID/GID : "$(id -u user)"/"$(getent group user | cut -d ":" -f 3)

export HOME=/home/user

# Must have a pepecoin config file
if [ ! -f "/mnt/pepecoin/config/pepecoin.conf" ]; then
  echo "No config found. Exiting."
  exit 1
else
  if [ ! -L $HOME/.pepecoin ]; then
    ln -s /mnt/pepecoin/config $HOME/.pepecoin > /dev/null 2>&1 || true
  fi
fi

# Fix ownership of the created files/folders
chown -R user:user /home/user /mnt/pepecoin


echo "Starting $@ .."
if [[ "$1" == pepecoind ]]; then
    exec /usr/local/bin/gosu user /bin/bash -c "$@ $OPTS"
fi

exec /usr/local/bin/gosu user "$@"
