#!/bin/sh
#==============================================================================
# company  :Augwit
# author   :Benjamin Qin
# email    :benjamin.qin@augwit.com
# usage    :
#   bash jar-launcher.sh [command]
#   command: start/stop/restart to start, stop or restart the java application.
#==============================================================================

#You can change the config file name if you want.
#But in most cases, you don't need to do that.
CONFIG_FILE_NAME="jar-launcher.conf"

#Normally you don't need to change below lines.
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
  exit
fi

if [ -z "$BASE_DIR" ]; then
  echox "\033[1;31mError: Cannot locate the directory where I (the bash script file) live.\033[0m"
  exit
fi

if [ ! -f $BASE_DIR/$CONFIG_FILE_NAME ]; then
  echox "\033[1;31mError: Cannot locate such configuration file:"
  echox "$BASE_DIR/$CONFIG_FILE_NAME\033[0m"
  echox "\n\033[1;32m#You need to define variables in $CONFIG_FILE_NAME
  \n#Here is an example:\033[0m"
  echo "APPLICATION_DISPLAY_NAME=\"Augwit Example Java Application\"
JAR_FILE_NAME=\"hello-world-0.0.1-SNAPSHOT.jar\"
JAVA_COMMAND_ARGS=\"example-arg1 example-arg2\"
LOG_OUTPUT_FILE_NAME=\"hello-world.log\"
  "
  exit
fi

source $BASE_DIR/$CONFIG_FILE_NAME

PATH_TO_JAR=$BASE_DIR/$JAR_FILE_NAME

if [ ! -f $PATH_TO_JAR ]; then
  echox "\033[1;31mError: Cannot locate java application:"
  echox "$PATH_TO_JAR\033[0m"
  exit
fi

start_jar()
{
  PID=$(ps -ef | grep $PATH_TO_JAR | grep -v 'grep' | awk '{print $2}')
  if [ -z "$PID" ]; then
       echo "Starting $APPLICATION_DISPLAY_NAME ..."
       nohup java -jar $PATH_TO_JAR $JAVA_COMMAND_ARGS > $BASE_DIR/$LOG_OUTPUT_FILE_NAME &
                   PID=$(echo $!)
       sleep 1
       echo "$APPLICATION_DISPLAY_NAME started in process $PID ..."
  else
       echo "$APPLICATION_DISPLAY_NAME is already running in process $PID ..."
  fi
}

stop_jar()
{
  PID=$(ps -ef | grep $PATH_TO_JAR | grep -v 'grep' | awk '{print $2}')
  if [ ! -z $PID ]; then
         echo "$APPLICATION_DISPLAY_NAME in process $PID stopping ..."
         kill $PID
         PID=NULL
         sleep 1
         echo "$APPLICATION_DISPLAY_NAME stopped ..."
  else
         echo "$APPLICATION_DISPLAY_NAME is not running ..."
  fi
}

if [[ $# -eq 0 ]] ; then
    echo 'Please run this script with an argument: start, stop or restart'
    exit 0
fi

case $1 in
  start)
    start_jar
  ;;
  stop)
    stop_jar
  ;;
  restart)
    stop_jar
    sleep 1
    start_jar
  ;;
 esac
