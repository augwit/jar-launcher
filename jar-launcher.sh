#!/bin/bash
# filepath: /Users/benjamin/Code/augwit/dev-hero/jar-launcher/jar-launcher.sh
#==============================================================================
# company  :Augwit Information Technology
# author   :Benjamin Qin
# email    :benjamin.qin@augwit.com
# desc     :start, stop or restart a jar application, show application status, install/uninstall as a service, or upgrade the script itself.
# usage    :bash jar-launcher.sh (init [-f] | start | status | stop [-f] | restart [-f] | install | uninstall | self-upgrade)
#           -f: force execute the subcommnd, only apply to init, stop and restart
#
# Required ENV varibles:
# ------------------
#   JAVA_HOME - location of a JRE/JDK home directory
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

show_usage() {
  echo "USAGE:"
  echo "$0 (init [-f] | start | status | stop [-f] | restart [-f] | install | uninstall | self-upgrade)"
}

if [[ $# -lt 1 ]] ; then
  show_usage
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

self_upgrade() {
  echo "Performing self-upgrade..."
    # Get the absolute path of the script
  SCRIPT_PATH=$(realpath "$0")

  # Download the latest version and replace the current script
  curl -o "$SCRIPT_PATH" "https://raw.githubusercontent.com/augwit/jar-launcher/refs/heads/main/jar-launcher.sh"
  if [ $? -eq 0 ]; then
    chmod +x "$SCRIPT_PATH"
    echo "Self-upgrade complete."
  else
    echo "Self-upgrade failed."
  fi
}

if [[ $# -ge 1 ]] && [ $1 = "self-upgrade" ] ; then
  self_upgrade
  exit 0
fi

init_config() {
  local overwrite=false
  if [[ $# -ge 1 ]] && [ $1 = "-f" ] ; then
    overwrite=true
  elif [[ $# -ge 2 ]] && [ $2 = "-f" ] ; then
    overwrite=true
  fi

  if [ -f $BASE_DIR/$CONFIG_FILE_NAME ] && ! $overwrite; then
    echox "Config file already exists:"  >&2
    echox "$BASE_DIR/$CONFIG_FILE_NAME"  >&2
    echox "Use -f to overwrite it if you want."  >&2
    exit 1
  else
    if $overwrite; then
      rm -f $BASE_DIR/$CONFIG_FILE_NAME
    fi

    # If an argument is supplied, take it as the jar file name
    if [[ $# -ge 1 ]]  && [ $1 != "-f" ] ; then
      JAR_FILE_NAME=$1
    elif [[ $# -ge 2 ]]  && [ $1 = "-f" ] ; then
      JAR_FILE_NAME=$2
    else
      JAR_FILE_NAME=$(ls $BASE_DIR/*.jar 2>/dev/null | head -1)
      JAR_FILE_NAME=$(basename $JAR_FILE_NAME)
      if [ -z "$JAR_FILE_NAME" ]; then
        echox "No jar file found in current directory."  >&2
        echox "I will generate an example config for you, please feel free to edit it."  >&2
        JAR_FILE_NAME="hello-world.jar"
      else
        JAR_FILES_FOUND=$(ls $BASE_DIR/*.jar 2>/dev/null | wc -l)
        if [ $JAR_FILES_FOUND -gt 1 ]; then
          echox "Found $JAR_FILES_FOUND jar files in current directory:"  >&2
          ls $BASE_DIR/*.jar 2>/dev/null | awk '{print NR, $0}' | while read i jar; do
            jar=$(basename $jar)
            echox "  $i. $jar"
          done
          read -p "Please enter the number of the file, enter c to cancel, preess enter to confirm: " choice
          if [ $choice = "c" ] ; then
            echo "Operation canceled"
            exit
          else
            JAR_FILE_NAME=$(ls $BASE_DIR/*.jar 2>/dev/null | head -n $choice | tail -1)
            JAR_FILE_NAME=$(basename $JAR_FILE_NAME)
          fi
        fi
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

    if $overwrite; then
      echox "Config overwritten: $BASE_DIR/$CONFIG_FILE_NAME"  >&2
    else
      echox "Config created: $BASE_DIR/$CONFIG_FILE_NAME"  >&2
    fi
    if [ ! -f "$BASE_DIR/$JAR_FILE_NAME" ]; then
      echo ""
      echo "However, file \"$JAR_FILE_NAME\" does not exist yet, please make sure to deploy it later"
    fi
  fi
}

if [[ $# -ge 1 ]] && [ $1 = "init" ] ; then
  init_config $2 $3
  exit 0
fi

if [ ! -f $BASE_DIR/$CONFIG_FILE_NAME ]; then
  echox "\033[1;31mError: Cannot locate configuration file:\033[0m"  >&2
  echox "\033[1;31m$BASE_DIR/$CONFIG_FILE_NAME\033[0m"  >&2
  echox "\Please run below command to create one:"
  echox "$0 init"
  exit 4
fi

source $BASE_DIR/$CONFIG_FILE_NAME

PATH_TO_JAR=$BASE_DIR/$JAR_FILE_NAME

if [ ! -f $PATH_TO_JAR ]; then
  echox "\033[1;31mError: Cannot locate java application:\033[0m" >&2
  echox "\033[1;31m$PATH_TO_JAR\033[0m" >&2
  exit 5
fi

prepare_jre()
{
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
}

start_jar()
{
  PID=$(ps -ef | grep $PATH_TO_JAR | grep -v 'grep' | awk '{print $2}')
  if [ ! -z "$PID" ]; then
    echo "$APPLICATION_DISPLAY_NAME is already running in process $PID."
    echox "Jar file: $PATH_TO_JAR\033[0m"
    exit
  fi

  prepare_jre


  echo "Starting $APPLICATION_DISPLAY_NAME ..."
  echo "-----------------------------------------------------------"
  echo "Jar File: $PATH_TO_JAR"
  echo "Java Path: $JAVACMD"
  $JAVACMD -version
  echo "-----------------------------------------------------------"
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
}

show_jar_status()
{
  PID=$(ps -ef | grep $PATH_TO_JAR | grep -v 'grep' | awk '{print $2}')

  if [ ! -z $PID ]; then
    echo "$APPLICATION_DISPLAY_NAME is running in process $PID."
  else
    echo "$APPLICATION_DISPLAY_NAME is not running."
  fi
  echo "-----------------------------------------------------------"
  echo "Jar File: $PATH_TO_JAR"
  prepare_jre
  echo "Java Path: $JAVACMD"
  $JAVACMD -version
  echo "-----------------------------------------------------------"
}

stop_jar()
{
  PID=$(ps -ef | grep $PATH_TO_JAR | grep -v 'grep' | awk '{print $2}')
  if [ ! -z $PID ]; then
    if [[ $# -ge 1 ]] && [ $1 = "-f" ] ; then
      echo "$APPLICATION_DISPLAY_NAME in process $PID force stopping ..."
      kill -9 $PID
      echo "-----------------------------------------------------------"
      echox "Jar File: $PATH_TO_JAR"
      echo "-----------------------------------------------------------"
    else
      echo "$APPLICATION_DISPLAY_NAME in process $PID stopping ..."
      kill $PID
      echo "-----------------------------------------------------------"
      echox "Jar File: $PATH_TO_JAR"
      echo "-----------------------------------------------------------"

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

  systemctl disable $SERVICE_NAME
  rm -f /usr/lib/systemd/system/$SERVICE_NAME.service
  systemctl daemon-reload
  systemctl reset-failed
  echo "Service $SERVICE_NAME is uninstalled."
  PID=$(ps -ef | grep $PATH_TO_JAR | grep -v 'grep' | awk '{print $2}')
  if [ ! -z "$PID" ]; then
    echo "The application is still running, you can manually stop it if you want."
    jps -l | grep $JAR_FILE_NAME
    exit
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
After=syslog.target network.target remote-fs.target nss-lookup.target docker.service

[Service]
WorkingDirectory=$BASE_DIR
Type=forking
Environment=\"JAVA_HOME=$JAVA_HOME\"
ExecStartPre=/bin/sleep 30
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
  status)
    show_jar_status
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
  self-upgrade)
    self_upgrade
  ;;
  *)
    echo "Unsupported subcommand: $1"
    echo ""
    show_usage
  ;;
esac
