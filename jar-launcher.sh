#!/bin/sh
#===================================================================
#company  :Augwit
#author   :Benjamin Qin
#email    :benjamin.qin@augwit.com
#usage    :bash example.sh start/stop/restart
#note     :Bash script to start, stop or restart a java application.
#===================================================================

CONFIG_FILE_NAME="jar-launcher.conf"
#You can change the config file name if you want.
#But in most cases, you don't need to do that.

#Please don't change this file.

if command -v realpath &> /dev/null
then
  BASE_DIR=$(dirname $(realpath "$0"))
else
  echo "\033[1;31mError:\nThe realpath command was not found, please install it.\033[0m"
  echo "If you are under macOS, please try to install coreutils with homebrew."
  exit
fi

if [ -z "$BASE_DIR" ]; then
  echo "\033[1;31mError:\nCannot locate the directory where I (the bash script file) live.\033[0m"
  echo "Something wrong, please contact your system administrator."
  exit
fi

if [ ! -f $BASE_DIR/$CONFIG_FILE_NAME ]; then
  echo "\033[1;31mError:\nCannot locate configuration file!\033[0m"
  echo "Please make sure such file exists:"
  echo "$BASE_DIR/$CONFIG_FILE_NAME"
  echo "\n\033[1;34mHINT:\033[0m
  #You need to define variables in $CONFIG_FILE_NAME
  #Here is an example:

  APPLICATION_DISPLAY_NAME=\"Augwit Example Java Application\"
  JAR_FILE_NAME=\"hello-world-0.0.1-SNAPSHOT.jar\"
  JAVA_COMMAND_ARGS=\"example-arg1 example-arg2\"
  LOG_OUTPUT_FILE_NAME=\"hello-world.log\"
  "
  exit
fi

source $BASE_DIR/$CONFIG_FILE_NAME

PATH_TO_JAR=$BASE_DIR/$JAR_FILE_NAME

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
