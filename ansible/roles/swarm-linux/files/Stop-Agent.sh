#!/bin/bash
# Stop the Jenkins Swarm Agent by killing the process running the swarm-client.jar
pkill -f "swarm-client.jar"
echo "Agent stopped. Press any key to exit..."
read -n1 -s
