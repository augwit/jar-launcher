#!/bin/bash
#==============================================================================
# company  :Augwit Information Technology
# author   :Benjamin Qin
# email    :benjamin.qin@augwit.com
# desc     :start, stop or restart a jar application, or install/uninstall as a service
# usage    :bash jar-launcher.sh (init [-f] | start | stop [-f] | restart [-f] | install | uninstall)
#           -f: force commnd, only apply to init, stop and restart
#
# Required ENV varibles:
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
  echo "USAGE:"
  echo "$0 (init [-f] | start | stop [-f] | restart [-f] | install | uninstall)"
  exit 1
fi

#Find the directory where I (the bash script file) live
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

init_config() {
  local overwrite=false
  if [[ $# -ge 1 ]] && [ $1 = "-f" ] ; then
    overwrite=true
  fi

  if [ -f $BASE_DIR/$CONFIG_FILE_NAME ] && ! $overwrite; then
    echox "\033[1;31mConfig file already exists:\033[0m"  >&2
    echox "\033[1;31m$BASE_DIR/$CONFIG_FILE_NAME\033[0m"  >&2
    echox "\033[1;31mUse -f to overwrite it if you want.\033[0m"  >&2
    exit 1
  else
    if $overwrite; then
      echox "Overwriting existing config file:"  >&2
      echox "$BASE_DIR/$CONFIG_FILE_NAME"  >&2
      rm -f $BASE_DIR/$CONFIG_FILE_NAME
    else
      echox "Creating config file:"  >&2
      echox "$BASE_DIR/$CONFIG_FILE_NAME"  >&2
    fi

    JAR_FILE_NAME=$(ls *.jar 2>/dev/null | head -1)
    if [ -z "$JAR_FILE_NAME" ]; then
      echox "No jar file found in current directory."  >&2
      echox "I will generate a default config file for you."  >&2
      JAR_FILE_NAME="hello-world.jar"
    else
      JAR_FILES_FOUND=$(ls *.jar 2>/dev/null | wc -l)
      if [ $JAR_FILES_FOUND -gt 1 ]; then
        echox "Found $JAR_FILES_FOUND jar files in current directory:"  >&2
        ls *.jar 2>/dev/null | awk '{print NR, $0}' | while read i jar; do
          echox "  $i. $jar"
        done
        read -p "Please enter the number of the jar file, press enter to confirm: " choice
        JAR_FILE_NAME=$(ls *.jar 2>/dev/null | head -n $choice | tail -1)
      fi
    fi

    APPLICATION_DISPLAY_NAME=$(echo $JAR_FILE_NAME | sed 's/\.[^.]*$//')
    SERVICE_NAME=$(echo $APPLICATION_DISPLAY_NAME | sed -E 's/(-[0-9.]+(-[a-zA-Z]+)*(\.[0-9]+)*)?(\.jar)?$//')

    echo "# Please Change below variables according to your project situation:" >> $BASE_DIR/$CONFIG_FILE_NAME
    echo "# You can change this to a more user friendly name" >> $BASE_DIR/$CONFIG_FILE_NAME
    echo "APPLICATION_DISPLAY_NAME=\"$APPLICATION_DISPLAY_NAME\"" >> $BASE_DIR/$CONFIG_FILE_NAME
    echo "# Options for JVM" >> $BASE_DIR/$CONFIG_FILE_NAME
    echo "JAVA_COMMAND_OPTIONS=\"-Xms128m -Xmx128m\"" >> $BASE_DIR/$CONFIG_FILE_NAME
    echo "# Name of the jar application file, without path" >> $BASE_DIR/$CONFIG_FILE_NAME
    echo "JAR_FILE_NAME=\"$JAR_FILE_NAME\"" >> $BASE_DIR/$CONFIG_FILE_NAME
    echo "# Arguments for the jar application" >> $BASE_DIR/$CONFIG_FILE_NAME
    echo "JAVA_COMMAND_ARGS=\"\"" >> $BASE_DIR/$CONFIG_FILE_NAME
    echo "# Log file only contains error messages by default" >> $BASE_DIR/$CONFIG_FILE_NAME
    echo "LOG_OUTPUT_FILE_NAME=\"$APPLICATION_DISPLAY_NAME.log\"" >> $BASE_DIR/$CONFIG_FILE_NAME
    echo "# Used to install service" >> $BASE_DIR/$CONFIG_FILE_NAME
    echo "SERVICE_NAME=\"$SERVICE_NAME\"" >> $BASE_DIR/$CONFIG_FILE_NAME
  fi
}

if [[ $# -ge 1 ]] && [ $1 = "init" ] ; then
  init_config $2
  exit 0
fi

if [ ! -f $BASE_DIR/$CONFIG_FILE_NAME ]; then
  echox "\033[1;31mError: Cannot locate configuration file:"  >&2
  echox "$BASE_DIR/$CONFIG_FILE_NAME\033[0m"  >&2
  echox "\033[1;32mPlease run below command to create one:\033[0m"
  echo "$0 init"
  exit 4
fi

source $BASE_DIR/$CONFIG_FILE_NAME

PATH_TO_JAR=$BASE_DIR/$JAR_FILE_NAME

if [ ! -f $PATH_TO_JAR ]; then
  echox "\033[1;31mError: Cannot locate java application:" >&2
  echox "$PATH_TO_JAR\033[0m" >&2
  exit 5
fi

start_jar()
{
  PID=$(ps -ef | grep $PATH_TO_JAR | grep -v 'grep' | awk '{print $2}')
  if [ ! -z "$PID" ]; then
    echo "$APPLICATION_DISPLAY_NAME is already running in process $PID."
    echox "Jar file: $PATH_TO_JAR\033[0m"
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

  echo "-----------------------------------------------------------"
  echo "Starting $APPLICATION_DISPLAY_NAME ..."
  echo "-----------------------------------------------"
  $JAVACMD -version
  echo "JDK path: $JAVACMD"
  echo "Jar file: $PATH_TO_JAR"
  echo "-----------------------------------------------"
  cd $BASE_DIR
  nohup $JAVACMD $JAVA_COMMAND_OPTIONS -jar $PATH_TO_JAR $JAVA_COMMAND_ARGS > /dev/null 2>> $BASE_DIR/$LOG_OUTPUT_FILE_NAME &
    PID=$(echo $!)
  sleep 1
  PID=$(ps -ef | grep $PATH_TO_JAR | grep -v 'grep' | awk '{print $2}')
  if [ ! -z $PID ]; then
    echo "$APPLICATION_DISPLAY_NAME started in process $PID."
  else
    echox "\033[1;31mSomething wrong when trying to start $APPLICATION_DISPLAY_NAME !\033[0m"
    exit 6
  fi
  echo "-----------------------------------------------------------"
}

stop_jar()
{
  PID=$(ps -ef | grep $PATH_TO_JAR | grep -v 'grep' | awk '{print $2}')
  if [ ! -z $PID ]; then
    echo "-----------------------------------------------------------"
    if [[ $# -ge 1 ]] && [ $1 = "-f" ] ; then
      echo "$APPLICATION_DISPLAY_NAME in process $PID force stopping ..."
      kill -9 $PID
      echox "Jar file: $PATH_TO_JAR\033[0m"
    else
      echo "$APPLICATION_DISPLAY_NAME in process $PID stopping ..."
      kill $PID
      echox "Jar file: $PATH_TO_JAR\033[0m"

      # Wait for up to 30 seconds for the process to stop gracefully
      for i in {1..30}; do
        sleep 1
        if ! ps -p $PID > /dev/null; then
          break
        fi
        # If still running after 30 seconds, force kill
        if [ $i -eq 30 ]; then
          echo "$APPLICATION_DISPLAY_NAME in process $PID did not stop gracefully. Force stopping ..."
          kill -9 $PID
        fi
      done
    fi

    # Check if process is still running
    if ps -p $PID > /dev/null; then
      echox "Failed to stop $APPLICATION_DISPLAY_NAME."
    else
      echo "$APPLICATION_DISPLAY_NAME stopped."
    fi

    # PID=NULL
    echo "-----------------------------------------------------------"
  else
    echo "$APPLICATION_DISPLAY_NAME is not running."
  fi
}

uninstall_service()
{
  if [ ! -f "/usr/lib/systemd/system/$SERVICE_NAME.service" ] ; then
    echox "Service $SERVICE_NAME does not exist. Uninstallation aborted."
    exit 8
  fi

  systemctl status $SERVICE_NAME
  systemctl disable $SERVICE_NAME
  rm -f /usr/lib/systemd/system/$SERVICE_NAME.service
  systemctl daemon-reload
  systemctl reset-failed
  jps -l | grep $JAR_FILE_NAME
  echo "Service $SERVICE_NAME is uninstalled. The application might be still running, you can manually stop it if you want."
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
After=syslog.target network.target remote-fs.target nss-lookup.target docker.service

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
}

case $1 in
  start)
    start_jar
  ;;
  stop)
    stop_jar $2
  ;;
  restart)
    stop_jar $2
    echo "."
    echo ".."
    echo "..."
    start_jar
  ;;
  install)
    install_service
    systemctl enable $SERVICE_NAME
    echo "Service was installed and enabled. Now you can run below command to start it:"
    echo "systemctl start $SERVICE_NAME"
  ;;
  uninstall)
    uninstall_service
  ;;
 esac
