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
# Run Performance Tests for Ballerina - Aggregator with two services with DB
# ----------------------------------------------------------------------------

########################################
#------------Test-Variables--------------#
########################################

concurrent_users=(1 2 50 100 300 500 700 1000) #to be changed 1 2 50 100 300 500 700 1000 
test_duration=900#to be changed to 900
split_time=5 #to be changed to 5

########################################
#------------Host Machine--------------#
########################################

target_script=/home/fct/Project/Builds/Ballerina/aggregator-with-db-two/start.sh
target_uptime_script=/home/fct/Project/Builds/Ballerina/aggregator-with-db-two/uptime.sh
target_uptime_path=/home/fct/Project/Builds/Ballerina/aggregator-with-db-two/uptime_dir

###Machine A
host1_ip=#########
host1_port=8080
host1_username_ip=#########
host1_pwd=#########
host1_machine_num=1

###Machine B
host2_ip=#########
host2_port=8081
host2_username_ip=#########
host2_pwd=#########
host2_machine_num=2

###Machine C
host3_ip=#########
host3_port=8082
host3_username_ip=#########
host3_pwd=#########
host3_machine_num=3

########################################
#------------Client Machine------------#
########################################

jmeter_path=/home/fct/Downloads/Software/JMeter/apache-jmeter-4.0/bin
jtl_splitter_path=/home/fct/Projects/ballerina-0-981-1/common

jtl_location=/home/fct/Projects/ballerina-0-981-1/Results/aggregator-with-db-two/jtls
jmx_file=/home/fct/Projects/ballerina-0-981-1/Tests/aggregator-with-db-two/Aggregator_Two_DB_Test.jmx
dashboards_path=/home/fct/Projects/ballerina-0-981-1/Results/aggregator-with-db-two/dashboards
uptime_path=/home/fct/Projects/ballerina-0-981-1/Results/aggregator-with-db-two

performance_report_python_file=/home/fct/Projects/ballerina-0-981-1/common/python/NoMsg/with_three_machines/performance-report.py
performance_report_output_file=/home/fct/Projects/ballerina-0-981-1/Results/aggregator-with-db-two/summary_aggregator_db_two

########################################
#------------Test Begins---------------#
########################################

# Generating JTL files

		for u in ${concurrent_users[@]}
		do

			total_users=$(($u))

			report_location=$jtl_location/${total_users}_users
			echo "Report location is ${report_location}"
			mkdir -p $report_location
			
			#MachineA
			#SSH
			echo "begin SSH"
			nohup sshpass -p ${host1_pwd} ssh -n ${host1_username_ip} -f "/bin/bash $target_script" &

			#Check Service
			while true 
			do
				echo "Checking service"
				response_code=$(curl -s -o /dev/null -w "%{http_code}" -X GET http://${host1_ip}:${host1_port}/serviceAggregator/test)
				if [ $response_code -eq 200 ]; then
					echo "First Ballerina service has started"
					break
				else
					sleep 10
					echo "Retrying..."
					nohup sshpass -p ${host1_pwd} ssh -n ${host1_username_ip} -f "/bin/bash $target_script" &
				fi
			done
			
			#MachineB
			#SSH
			echo "begin SSH"
			nohup sshpass -p ${host2_pwd} ssh -n ${host2_username_ip} -f "/bin/bash $target_script" &

			#Check Service
			while true 
			do
				echo "Checking service"
				response_code=$(curl -s -o /dev/null -w "%{http_code}" -X GET http://${host2_ip}:${host2_port}/serviceFamousPolitical/test)
				if [ $response_code -eq 200 ]; then
					echo "Second Ballerina service has started"
					break
				else
					sleep 10
					echo "Retrying..."
					nohup sshpass -p ${host2_pwd} ssh -n ${host2_username_ip} -f "/bin/bash $target_script" &
				fi
			done
			
			#MachineC
			#SSH
			echo "begin SSH"
			nohup sshpass -p ${host3_pwd} ssh -n ${host3_username_ip} -f "/bin/bash $target_script" &

			#Check Service
			while true 
			do
				echo "Checking service"
				response_code=$(curl -s -o /dev/null -w "%{http_code}" -X GET http://${host3_ip}:${host3_port}/serviceSports/test)
				if [ $response_code -eq 200 ]; then
					echo "Third Ballerina service has started"
					break
				else
					sleep 10
					echo "Retrying..."
					nohup sshpass -p ${host3_pwd} ssh -n ${host3_username_ip} -f "/bin/bash $target_script" &
				fi
			done
			
			echo "Begin test for ${u} users"

			# Start JMeter server
			
			${jmeter_path}/jmeter -Jgroup1.host=${host1_ip} -Jgroup1.port=${host1_port} -Jgroup1.threads=$u -Jgroup1.seconds=${test_duration} -n -t ${jmx_file} -l ${report_location}/results.jtl

			# uptime
			
			echo "Running Uptime command in first"	
			nohup sshpass -p ${host1_pwd} ssh -n -f ${host1_username_ip} "/bin/bash $target_uptime_script ${total_users} ${target_uptime_path} ${host1_machine_num}" &
			
			echo "Running Uptime command in second"	
			nohup sshpass -p ${host2_pwd} ssh -n -f ${host2_username_ip} "/bin/bash $target_uptime_script ${total_users} ${target_uptime_path} ${host2_machine_num}" &
			
			echo "Running Uptime command in Third"	
			nohup sshpass -p ${host3_pwd} ssh -n -f ${host3_username_ip} "/bin/bash $target_uptime_script ${total_users} ${target_uptime_path} ${host3_machine_num}" &

			echo "Completed Generating JTL files for ${u} users"

	done

	echo "Completed Generating JTL files"

# Copying uptime logs

	echo "Copying uptime logs of first machine to Jmeter client machine"

	mkdir -p ${uptime_path}
	sshpass -p ${host1_pwd} scp -r ${host1_username_ip}:${target_uptime_path} ${uptime_path}
	
	echo "Copying uptime logs of second machine to Jmeter client machine"

	mkdir -p ${uptime_path}
	sshpass -p ${host2_pwd} scp -r ${host2_username_ip}:${target_uptime_path} ${uptime_path}
	
	echo "Copying uptime logs of third machine to Jmeter client machine"

	mkdir -p ${uptime_path}
	sshpass -p ${host3_pwd} scp -r ${host3_username_ip}:${target_uptime_path} ${uptime_path}
	
	echo "Finished Copying uptime logs to client machine"

# Split JTLs

echo "Splitting JTL files started"


	for u in ${concurrent_users[@]}
	do
		total_users=$(($u))
		jtl_file=${jtl_location}/${total_users}_users/results.jtl
		
		java -jar ${jtl_splitter_path}/jtl-splitter-0.1.1-SNAPSHOT.jar -f $jtl_file -t ${split_time} -d	
		
		echo "Splitting jtl file for ${u} users test completed"
	done


echo "Splitting JTL files Completed"

# Generating dashboards

echo "Generating Dashboards"

	for u in ${concurrent_users[@]}
	do	
		total_users=$(($u))
		report_location=${dashboards_path}/${total_users}_users
		echo "Report location is ${report_location}"
		mkdir -p $report_location
		
		${jmeter_path}/jmeter -g  ${jtl_location}/${total_users}_users/results-measurement.jtl -o $report_location	

		echo "Generating dashboard for ${u} users test completed"
	done


echo "Generating Dashboards Completed"

#Generate CSV

echo "Generating the CSV file"

python3 $performance_report_python_file $dashboards_path $uptime_path $performance_report_output_file

echo "Finished generating CSV file"

