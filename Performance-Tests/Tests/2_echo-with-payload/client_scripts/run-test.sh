#!/bin/bash
# Copyright 2018 WSO2 Inc. (http://wso2.org)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ----------------------------------------------------------------------------
# Run Full Performance Tests for Ballerina - Echo with Payload
# ----------------------------------------------------------------------------

########################################
#------------Test-Variables--------------#
########################################

concurrent_users=(1) #to be changed 1 2 50 100 300 500 700 1000 
message_sizes=(50 1024) # 400 1600
test_duration=120 #to be changed to 900
split_time=1 #to be changed to 5

########################################
#------------Host Machine--------------#
########################################

host1_ip=###########
host1_port=8080
host1_username_ip=###########
host1_pwd=###########

target_script=/home/uok/Project/Builds/Ballerina/echo-with-payload/start.sh
target_uptime_script=/home/uok/Project/Builds/Ballerina/echo-with-payload/uptime.sh
target_uptime_path=/home/uok/Project/Builds/Ballerina/echo-with-payload/uptime_dir

########################################
#------------Client Machine------------#
########################################

jmeter_path=/home/uok/Downloads/Software/JMeter/apache-jmeter-4.0/bin

jmx_file=/home/uok/Projects/ballerina-0-981-1/Tests/echo-with-payload/Echo_Payload_Test.jmx
jtl_location=/home/uok/Projects/ballerina-0-981-1/Results/echo-with-payload/jtls
uptime_path=/home/uok/Projects/ballerina-0-981-1/Results/echo-with-payload

payload_generator_file=/home/uok/Projects/ballerina-0-981-1/common/payload-generator-0.1.1-SNAPSHOT.jar
payloads_output_file_root=/home/uok/Projects/ballerina-0-981-1/Tests/echo-with-payload/client_scripts
payload_files_postfix=B
payload_files_extension=json

########################################
#------------Test Begins-------------#
########################################

#Generate payloads

echo "Generating Payloads"

for size in ${message_sizes[@]}
do
	echo "Generating ${size}B file"
	java -jar ${payload_generator_file} --size $size
done

echo "Finished generating payloads"

# Generating JTL files

	for size in ${message_sizes[@]}
	do
		echo "Tests for ${size} size message"

		for u in ${concurrent_users[@]}
		do

			total_users=$(($u))

			report_location=$jtl_location/${size}_message/${total_users}_users
			echo "Report location is ${report_location}"
			mkdir -p $report_location

			#SSH
			echo "begin SSH"
			nohup sshpass -p ${host1_pwd} ssh -n ${host1_username_ip} -f "/bin/bash $target_script" &

			#Check Service
			while true 
			do
				echo "Checking service"
				response_code=$(curl -s -o /dev/null -w "%{http_code}" -X GET -d "hello" http://${host1_ip}:${host1_port}/hello/payloadCheck)
				if [ $response_code -eq 200 ]; then
					echo "Ballerina service has started"
					break
				else
					sleep 10
					echo "Retrying..."
					nohup sshpass -p ${host1_pwd} ssh -n ${host1_username_ip} -f "/bin/bash $target_script" &
				fi
			done

			echo "Begin test for ${u} users and ${size} size message"

			# Start JMeter server
			message=$(<${payloads_output_file_root}/${size}${payload_files_postfix}.${payload_files_extension})
			
			${jmeter_path}/jmeter -Jgroup1.host=${host1_ip} -Jgroup1.port=${host1_port} -Jgroup1.threads=$u -Jgroup1.seconds=${test_duration} -Jgroup1.data=${message} -n -t ${jmx_file} -l ${report_location}/results.jtl

			# uptime
			echo "Running Uptime command"	
			nohup sshpass -p ${host1_pwd} ssh -n -f ${host1_username_ip} "/bin/bash $target_uptime_script ${total_users} ${size} ${target_uptime_path}" &

			echo "Completed Generating JTL files for ${u} users and ${size} size message"
		done

		echo "Completed tests for ${size} size message"

	done

	echo "Completed Generating JTL files"

# Copying uptime logs
	sleep 5
	
	echo "Copying uptime logs of server machine"

	mkdir -p ${uptime_path}
	sshpass -p ${host1_pwd} scp -r ${host1_username_ip}:${target_uptime_path} ${uptime_path}

	echo "Finished Copying uptime logs server machine"