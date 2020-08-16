#!/bin/sh
#=============================================================
#company  :Augwit
#author   :Benjamin Qin
#email    :benjamin.qin@augwit.com
#usage    :bash example.sh start/stop/restart
#note     :Bash script to start, stop or restart a java app.
#=============================================================

SERVICE_NAME="Augwit Example application"
JAR_NAME=hello-world-0.0.1-SNAPSHOT.jar

if command -v realpath &> /dev/null
then
  BASE_DIR=$(dirname $(realpath "$0"))
else
  echo "The realpath command was not found, please install it."
  echo "If you are under macOS, please try to install coreutils with homebrew."
  exit
fi

if [ -z "$BASE_DIR" ]; then
  echo "Cannot locate file $JAR_NAME under the same directory where I (the bash script file) live."
  echo "Please make sure the file exists or the file name is correct."
  exit
fi

PATH_TO_JAR=$BASE_DIR/$JAR_NAME

start_jar()
{
  PID=$(ps -ef | grep $PATH_TO_JAR | grep -v 'grep' | awk '{print $2}')
  if [ -z "$PID" ]; then
       echo "Starting $SERVICE_NAME ..."
       nohup java -jar $PATH_TO_JAR /tmp 2>> /dev/null >>/dev/null &
                   PID=$(echo $!)
       sleep 1
       echo "$SERVICE_NAME started in process $PID ..."
  else
       echo "$SERVICE_NAME is already running in process $PID ..."
  fi
}

stop_jar()
{
  PID=$(ps -ef | grep $PATH_TO_JAR | grep -v 'grep' | awk '{print $2}')
  if [ ! -z $PID ]; then
         echo "$SERVICE_NAME in process $PID stopping ..."
         kill $PID
         PID=NULL
         sleep 1
         echo "$SERVICE_NAME stopped ..."
  else
         echo "$SERVICE_NAME is not running ..."
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
