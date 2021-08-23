#!/bin/sh
#==============================================================================
# company  :Augwit Information Technology
# author   :Benjamin Qin
# email    :benjamin.qin@augwit.com
# desc     :start, stop or restart a jar/war application, or install as a service
# usage    :bash jar-launcher.sh (start | stop | restart | install)
#
# Required ENV vars:
# ------------------
#   JAVA_HOME - location of a JDK home dir
#
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

if [[ $# -lt 1 ]] ; then
  echo "USAGE: $0 (start | stop | restart)"
  exit 1
fi

if command -v realpath &> /dev/null
then
  BASE_DIR=$(dirname $(realpath "$0"))
else
  echox "\033[1;31mError: The realpath command was not found, please install it.\033[0m"  >&2
  echox "\033[1;32mIf you are under macOS, please try to install coreutils with homebrew.\033[0m"  >&2
  exit 2
fi

if [ -z "$BASE_DIR" ]; then
  echox "\033[1;31mError: Cannot locate the directory where I (the bash script file) live.\033[0m"  >&2
  exit 3
fi

if [ ! -f $BASE_DIR/$CONFIG_FILE_NAME ]; then
  echox "\033[1;31mError: Cannot locate such configuration file:"  >&2
  echox "$BASE_DIR/$CONFIG_FILE_NAME\033[0m"  >&2
  echox "\n\033[1;32m#You need to define variables in $CONFIG_FILE_NAME
  \n#Here is an example:\033[0m"
  echo "APPLICATION_DISPLAY_NAME=\"Augwit Example Java Application\"
JAR_FILE_NAME=\"hello-world-0.0.1-SNAPSHOT.jar\"
JAVA_COMMAND_ARGS=\"example-arg1 example-arg2\"
LOG_OUTPUT_FILE_NAME=\"hello-world.log\"
  "
  exit 4
fi

source $BASE_DIR/$CONFIG_FILE_NAME

PATH_TO_JAR=$BASE_DIR/$JAR_FILE_NAME

if [ ! -f $PATH_TO_JAR ]; then
  echox "\033[1;31mError: Cannot locate java application:" >&2
  echox "$PATH_TO_JAR\033[0m" >&2
  exit 5
else
  echox "Jar file: $PATH_TO_JAR\033[0m"
fi

start_jar()
{
  PID=$(ps -ef | grep $PATH_TO_JAR | grep -v 'grep' | awk '{print $2}')
  if [ ! -z "$PID" ]; then
    echo "$APPLICATION_DISPLAY_NAME is already running in process $PID."
    exit
  fi

  # OS specific support.  $var _must_ be set to either true or false.
  cygwin=false;
  darwin=false;
  mingw=false
  case "`uname`" in
    CYGWIN*) cygwin=true ;;
    MINGW*) mingw=true;;
    Darwin*) darwin=true
      # Use /usr/libexec/java_home if available, otherwise fall back to /Library/Java/Home
      # See https://developer.apple.com/library/mac/qa/qa1170/_index.html
      if [ -z "$JAVA_HOME" ]; then
        if [ -x "/usr/libexec/java_home" ]; then
          export JAVA_HOME="`/usr/libexec/java_home`"
        else
          export JAVA_HOME="/Library/Java/Home"
        fi
      fi
      ;;
  esac

  if [ -z "$JAVA_HOME" ] ; then
    if [ -r /etc/gentoo-release ] ; then
      JAVA_HOME=`java-config --jre-home`
    fi
  fi

  # For Cygwin, ensure paths are in UNIX format before anything is touched
  if $cygwin ; then
    [ -n "$JAVA_HOME" ] &&
      JAVA_HOME=`cygpath --unix "$JAVA_HOME"`
  fi

  # For Migwn, ensure paths are in UNIX format before anything is touched
  if $mingw ; then
    [ -n "$JAVA_HOME" ] &&
      JAVA_HOME="`(cd "$JAVA_HOME"; pwd)`"
  fi

  if [ -z "$JAVA_HOME" ]; then
    javaExecutable="`which javac`"
    if [ -n "$javaExecutable" ] && ! [ "`expr \"$javaExecutable\" : '\([^ ]*\)'`" = "no" ]; then
      # readlink(1) is not available as standard on Solaris 10.
      readLink=`which readlink`
      if [ ! `expr "$readLink" : '\([^ ]*\)'` = "no" ]; then
        if $darwin ; then
          javaHome="`dirname \"$javaExecutable\"`"
          javaExecutable="`cd \"$javaHome\" && pwd -P`/javac"
        else
          javaExecutable="`readlink -f \"$javaExecutable\"`"
        fi
        javaHome="`dirname \"$javaExecutable\"`"
        javaHome=`expr "$javaHome" : '\(.*\)/bin'`
        JAVA_HOME="$javaHome"
        export JAVA_HOME
      fi
    fi
  fi

  if [ -z "$JAVACMD" ] ; then
    if [ -n "$JAVA_HOME"  ] ; then
      if [ -x "$JAVA_HOME/jre/sh/java" ] ; then
        # IBM's JDK on AIX uses strange locations for the executables
        JAVACMD="$JAVA_HOME/jre/sh/java"
      else
        JAVACMD="$JAVA_HOME/bin/java"
      fi
    else
      JAVACMD="`which java`"
    fi
  fi

  if [ ! -x "$JAVACMD" ] ; then
    echo "Error: JAVA_HOME is not defined correctly." >&2
    echo "  We cannot execute $JAVACMD" >&2
    exit 6
  fi

  if [ -z "$JAVA_HOME" ] ; then
    echo "Warning JAVA_HOME environment variable is not found."
  fi
  
  # For Cygwin, switch paths to Windows format before running java
  if $cygwin; then
    [ -n "$JAVA_HOME" ] &&
      JAVA_HOME=`cygpath --path --windows "$JAVA_HOME"`
  fi

  echo "-----------------------------------------------"
  echo "Starting $APPLICATION_DISPLAY_NAME ..."
  echo "-----------------------------------------------"
  $JAVACMD -version
  echo "JDK path: $JAVACMD"
  echo "-----------------------------------------------"
  nohup $JAVACMD $JAVA_COMMAND_OPTIONS -jar $PATH_TO_JAR $JAVA_COMMAND_ARGS > $BASE_DIR/$LOG_OUTPUT_FILE_NAME &
    PID=$(echo $!)
  sleep 1
  PID=$(ps -ef | grep $PATH_TO_JAR | grep -v 'grep' | awk '{print $2}')
  if [ ! -z $PID ]; then
    echo "$APPLICATION_DISPLAY_NAME started in process $PID."
  else
    echox "\033[1;31mSomething wrong when trying to start $APPLICATION_DISPLAY_NAME !\033[0m"
    exit 6
  fi
}

stop_jar()
{
  PID=$(ps -ef | grep $PATH_TO_JAR | grep -v 'grep' | awk '{print $2}')
  if [ ! -z $PID ]; then
    echo "$APPLICATION_DISPLAY_NAME in process $PID stopping ..."
    kill $PID
    PID=NULL
    sleep 2
    if [ $? -ne 0 ]; then
      echox "Failed to stop $APPLICATION_DISPLAY_NAME."
    else
      echo "$APPLICATION_DISPLAY_NAME stopped."
    fi
  else
    echo "$APPLICATION_DISPLAY_NAME is not running."
  fi
}

install_service()
{
  if [ -z "$SERVICE_NAME" ] ; then
    echox "Cannot install as service. SERVICE_NAME not defined."
    exit 7
  fi

  if [ -f "/usr/lib/systemd/system/$SERVICE_NAME.service" ] ; then
    echox "Service $SERVICE_NAME already exists. Installation aborted."
    exit 8
  fi

  LAUNCHER_FILE_NAME=$(basename "$0")

  echo "[Unit]
Description=$APPLICATION_DISPLAY_NAME
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
WorkingDirectory=$BASE_DIR
Type=forking
Environment=\"JAVA_HOME=$JAVA_HOME\"
ExecStart=/usr/bin/bash $BASE_DIR/$LAUNCHER_FILE_NAME start
ExecStop=/usr/bin/bash $BASE_DIR/$LAUNCHER_FILE_NAME stop
PrivateTmp=true
 
[Install]
WantedBy=multi-user.target
" >> /usr/lib/systemd/system/$SERVICE_NAME.service

  echo "Service installed. Now enable service and start it."
  systemctl enable $SERVICE_NAME
  systemctl start $SERVICE_NAME
}

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
  install)
    install_service
  ;;
 esac
