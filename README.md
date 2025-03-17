## Overview

The jar-launcher.sh is used to start/stop/restart a java application (jar file), or install/uninstall a java applciationas a service.

## Usage

1. Enter your project directory

2. Copy jar-launcher.sh to your deploy folder next to your .jar file, or download it from [https://github.com/augwit/jar-launcher](https://github.com/augwit/jar-launcher):
```shell
curl -O https://raw.githubusercontent.com/augwit/jar-launcher/refs/heads/main/jar-launcher.sh
chmod +x jar-launcher.sh
```
3. Generate a config file:
```shell
./jar-launcher.sh init
```
If there is only one jar file in the current directory, the config will take the jar file, otherwise will list all the jar files for use to choose.
You can supply an argument as the file name if the jar file does not exit yet.
```shell
./jar-launcher.sh init file-not-exist-yet.jar
```
If there is already a config file, you can use -f to overwrite the existing file.
4. Edit the generated jar-launcher.conf if you want
5. Run the jar application with start/stop/restart subcommand and check if it works. You can use jps -l to list your java processes.
```shell
./jar-launcher.sh start
jps -l
```
6. Install/uninstall the service with install/uninstall subcommand
```shell
./jar-launcher.sh install
```
7. Have fun! 


## Project Structure and Development

### Files besides jar-launcher.sh

- jar-launcher.conf: The jar-launcher.conf is a configuration file containing application specific variables. You can generate a sample config file by running jar-launcher.sh init.

- hello-world-0.0.1-SNAPSHOT.jar: The jar file to be deployed, a simple demo java application which will run for 5 minutes then exit.
- abc-3.2.0-beta.2.jar: The second jar file to test init subcommand, it is just a placeholder, cannot be executed.
- def-2.0.0.jar: The third jar file to test init subcommand, it is just a placeholder, cannot be executed.

### Run the example  
To run the example hello-world-0.0.1-SNAPSHOT.jar file:  
```shell
bash jar-launcher.sh start
```
use jps to list your java processes.
```shell
jps -l
```

Note the hello-world jar will run for 5 minutes then exit .  

Check out the hello-world-0.0.1-SNAPSHOT.log file, which contains the error log output of hello-world java application. It will be empty if there is no error.  

Run the stop or restart subcommand to stop or restart the jar app.  

Run the install or uninstall subcommand to install or uninstall the jar app as a service.  

### Development
Please submit pull requests to [https://github.com/augwit/jar-launcher](https://github.com/augwit/jar-launcher)