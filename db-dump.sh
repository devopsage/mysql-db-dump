#===================================================================================
# This script will take the backup of a mysql database and store dumps to the
# /tmp/lab_dumps directory and push to devopsagebucket s3 bucket.
# Owner: DevOpsAGE Technologies
# Contact: devopsage@gmail.com
# Disclaimer: This Script does not comes with any guaranty, please go through it carefully before executing it. DevOpsAGE Will 
# not be responsible for any loss of data or any Issues happened 
#===================================================================================
# !/bin/bash

## Database connection details

db_host="localhost"   ## Replace the Database endpoint here
db_user="wp-user"      ## replace with your database user
db_pass="secure-password" ## Replace with your daabase password
db_name="wordpress"  ## Replace with your database name

## Dump location on server and other variables

server_dump_location="/tmp/mysql-dump/"
log_path="/tmp/script_log/"
log_location="/tmp/script_log/db_dump.log"
s3_bucket="s3://devopsagebucket"
time_stamp="$(date +"%d-%b-%Y-%H_%M_%S")"


# Check If diretory is present or not, If not then create it.
echo "##################################################################" >> $log_location
if [ -d $server_dump_location ]; then
    echo "Directory Alredy Exists" >> $log_location
elif [ -d $log_path ]; then
    echo "Log Directory Alredy Exists" >> $log_location
else
    mkdir $server_dump_location $log_path
    echo "Directory Was not there, hence created $server_dump_location and $log_path" >> $log_location
fi

# Slack Incoming Web hook for db_dump channel
slack_url=https://hooks.slack.com/services/TKKRQR12B/XXXXXXXXXXXXXXXXXXXXXXXXXXXXX  ## Replace you Slack Incoming hook here.

## Server backup initialization
echo "Taking the backup of sample wordpress database, Started at: $time_stamp" >> $log_location
mysqldump -h $db_host -u $db_user -p$db_pass $db_name > $server_dump_location/$db_name-$time_stamp.sql
if [ $? -eq 0 ]; then
    echo "Backup Successfully Done" >> $log_location
else
    echo "Backup Failed, Please check" >> $log_location
    exit 1
fi
echo "Backup Completed at: $time_stamp" >> $log_location

# Push Dump to S3 bucket.
echo "Pushing test wordpress db dump to S3 at $time_stamp" >> $log_location
aws s3 cp $server_dump_location $s3_bucket --recursive
echo "Moved mysql dump to S3 at $time_stamp" >> $log_location
echo "#################################################################" >> $log_location

# Delete the Mysql Dump from the Server
sudo rm -rf $server_dump_location/$db_name-*

# Or, # Clear Dumps from the Server Older than 1 Weeks.

# find $server_dump_location/* -mtime +7 -exec rm {} \;

# Notification to Slack

curl -X POST -H 'Content-type: application/json' --data '{"text":"'"Backup of Sample Wordpress database has completed at $time_stamp"'"}' $slack_url

### complete command
# curl -X POST -H 'Content-type: application/json' --data '{"text":"'"Message $time_stamp"'"}' https://hooks.slack.com/services/xxxxxx/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
