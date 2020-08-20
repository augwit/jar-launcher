# Augwit Example Deployment

This project demonstrates how to deploy a java application on a linux server.

## Scripts in this project

### 1. jar-launcher.sh & jar-launcher.conf

The jar-launcher.sh is an example bash script demonstrating:  
How to start/stop/restart a Java app (in jar or war) in background process on a linux server.  

The jar-launcher.conf is a configuration file containing application specific variables.

## Usage

### Run the example  
To run the example, you need to generate a jar file from the hello-world-java-application project and put the hello-world-0.0.1-SNAPSHOT.jar file into the same folder next to jar-launcher.sh.  

Then run this command to start:  

    bash jar-launcher.sh start

Check out the hello-world.log file, which contains the log output of hello-world java application.

Run with stop or restart argument to stop or restart the jar app.

Note the hello-world jar app is a demo service, it will run for 5 minutes then exit unless you stop it manually.

### Use in your project

1. Copy jar-launcher.sh & jar-launcher.conf to your deploy folder next to your .jar file.  
2. Edit jar-launcher.conf, change the variables accordingly:  
     - APPLICATION_DISPLAY_NAME: your application name
     - JAR_FILE_NAME: your .jar file name 
     - JAVA_COMMAND_ARGS: command line arguments following java -jar hello-world.jar
     - LOG_OUTPUT_FILE_NAME: your log output file name 
3. Run the script with start/stop/restart argument and check if it works. You can use jps -l to list your java processes.  
4. Have fun! 


