#!/bin/sh
#==============================================================================
# company  :Augwit
# author   :Benjamin Qin
# email    :benjamin.qin@augwit.com
# usage    :bash install-service.sh [command]
# remark   :This script will install your java application as a service on a
#           centos server, assuming jar-launcher.sh and jar-launcher.conf are in place.
#    .
#==============================================================================

#In most cases, you don't need to change below lines, unless you know what you are doing.
CONFIG_FILE_NAME="jar-launcher.conf"
LAUNCHER_FILE_NAME="jar-launcher.sh"

echox() {
  if [ "$(uname)" == "Darwin" ]; then
    echo $1
  else
    echo -e $1
  fi
}

if command -v realpath &> /dev/null
then
  BASE_DIR=$(dirname $(realpath "$0"))
else
  echox "\033[1;31mError: The realpath command was not found, please install it.\033[0m"
  echox "\033[1;32mIf you are under macOS, please try to install coreutils with homebrew.\033[0m"
  exit 1
fi

if [ -z "$BASE_DIR" ]; then
  echox "\033[1;31mError: Cannot locate the directory where I (the bash script file) live.\033[0m"
  exit 2
fi

if [ ! -f $BASE_DIR/$CONFIG_FILE_NAME ]; then
  echox "\033[1;31mError: Cannot locate configuration file:"
  echox "$BASE_DIR/$CONFIG_FILE_NAME\033[0m"
  exit 3
fi

source $BASE_DIR/$CONFIG_FILE_NAME

if [ ! -f $BASE_DIR/$LAUNCHER_FILE_NAME ]; then
  echox "\033[1;31mError: Cannot locate jar-launcher:"
  echox "$BASE_DIR/$LAUNCHER_FILE_NAME\033[0m"
  exit 4
fi

echo "[Unit]
Description=$APPLICATION_DISPLAY_NAME
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
ExecStart=/usr/bin/bash $BASE_DIR/$LAUNCHER_FILE_NAME start
ExecStop=/usr/bin/bash $BASE_DIR/$LAUNCHER_FILE_NAME stop
PrivateTmp=true
 
[Install]
WantedBy=multi-user.target
" >> /usr/lib/systemd/system/$SERVICE_NAME.service

echo "Service installed. Now enable service and start it."
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME