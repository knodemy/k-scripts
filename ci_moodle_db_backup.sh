#!/bin/bash -e
# -e means exit if any command fails

#/*  ################################################################################-   */
#
#  Purpose     : This will help take mysql dump of ci moodle mysql db changes and
#              : versions into git repo.
#  Created By  : Kiran Dharmavarapu
#  Created Date: 03/04/2014
#  Dependencies: gets triggered when moodle or moodledata build jobs gets triggered
# 
#/*  ################################################################################-   */

# Declare variables

ST_DB_HOST=ci.scootertutor.com
ST_DB_USER=st_user
ST_DB_PWD=4JgyrVAg
ST_DB_NAME=moodle
ST_DB_REPO=/opt/apps/k-moodledb/
ST_DB_BACKUP_FILENAME=st-moodle-db-schema.sql
ST_DATE=$(date)

echo "\n----------------------------------------------------------------------------------------------------------\n"
echo "START: mysqldump job for "$ST_DB_HOST" DEV DB server initiated\n"
cd $ST_DB_REPO
echo  "Change directory to " $ST_DB_REPO"\n"

echo "START:  Initiated taking mysqldump for database: "$ST_DB_USER"@"$ST_DB_HOST"/"$ST_DB_NAME"\n"
mysqldump -h $ST_DB_HOST -u $ST_DB_USER -p$ST_DB_PWD -C -Q -e --create-options $ST_DB_NAME > $ST_DB_REPO/$ST_DB_BACKUP_FILENAME
echo "END: mysqldump execution completed\n"

#echo "START: Git add - initiated on file "$ST_DB_BACKUP_FILENAME"\n"
#git add st-moodle-db-schema.sql
#echo "END: Git add - completed\n"

echo "INFO: Finding git status"
git status

echo "\nSTART: Git commit initiated with commit details: "$ST_DB_NAME" - st-moodle-db-schema version" $ST_DATE"\n"
git commit -a -m "$ST_DB_NAME - st-moodle-db-schema version $ST_DATE"
echo "END: Git commit completed\n"

echo "START: Git push initiated\n"
git push origin master
echo "END: Git push completed\n"

echo "END: Completed mysqldump job successfully!\n"
echo "----------------------------------------------------------------------------------------------------------\n"