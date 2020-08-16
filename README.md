# Augwit Example Deployment

## example.sh

The example.sh is an example bash script demonstrating:  
How to start/stop/restart a Java app (in jar or war) in background process on a linux server.  

### Run the example  
If you want to run the example, you need to generate a jar file from the hello-world-java-service project and put the hello-world-0.0.1-SNAPSHOT.jar file into the same folder with example.sh.  

Then run this command to start:  

    ./example.sh start

Run with stop and restart argument to stop and restart the jar app.

Note the hello-world jar app is a demo service, it will run for 5 minutes then exit unless you stop it manually.

### Usage

1. Copy example.sh to your deploy folder together with your jar file.  
2. Rename it properly (meaning don't use example.sh as its name, use your own meaningful name please!).  
3. Edit the script, change the service name and jar file name accordingly.  
4. Run the script with start/stop/restart argument and check if it works. You can use jps -l to list your java processes.  
5. Have fun! 
