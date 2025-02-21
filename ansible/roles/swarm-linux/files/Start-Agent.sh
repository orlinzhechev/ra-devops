#!/bin/bash
# Start the Jenkins Swarm Agent by executing the generated script
bash "{{ swarm_working_dir }}/start-swarm-agent.sh"
echo "Agent started. Press any key to exit..."
read -n1 -s
