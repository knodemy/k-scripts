#!/bin/bash -e
# -e means exit if any command fails

#/*  ################################################################################-   */
#
#  Purpose     :  Deployment script that gets triggered by deploy master 
#              :  
#  Created By  : Kiran Dharmavarapu
#  Created Date: 03/04/2014
#  Dependencies: deployable artifacts should be present in ARTIFACTS_DIR
# 
#/*  ################################################################################-   */


# Declare variables

HOST=$1
DEPLOYMENT_TYPE=$2
ST_MOODLE_LOC=/var/www/moodle
ST_MOODLE_LOC_BAK=/var/www/moodle_bak
ST_NEW_MOODLE_LOC=/var/www
ST_MOODLE_DATA_LOC=/var/moodledata
ST_MOODLE_DATA_LOC_BAK=/var/moodledata_bak
ST_NEW_MOODLE_DATA_LOC=/var

ARTIFACTS_DIR=/opt/apps/deploy/



echo "*****************************************************************************************"
echo "                           Deploying Knodemy Moodle ...                                 "
echo "*****************************************************************************************"

echo "******************* Deployment type:  $DEPLOYMENT_TYPE ********************************"

deployMoodle
deployMoodledata

echo "*****************************************************************************************"
echo "                 Knodemy deployment Completed successfully                              "
echo "*****************************************************************************************"



# function for granting privileges to moodle code directory
function grantAccessToMoodle {
	echo "INFO: Granting privileges to moodle"
	sudo chown -R root:root ${ST_MOODLE_LOC}
	sudo chmod -R 0755 ${ST_MOODLE_LOC}
	echo "INFO: All required privileges granted to moodle"
}

# function for granting privileges to moodle data directory
function grantAccessToMoodleData {
	echo "INFO: Granting privileges to moodledata"
	sudo chmod -R 0777 ${ST_MOODLE_DATA_LOC}
	sudo chown -R www-data:root ${ST_MOODLE_DATA_LOC}
	echo "INFO: All required privileges granted to moodledata"
}

function deployMoodle {
	echo "-----------------------------------------------------------------------------------------"
	echo "                         Initiated moodle code deployment...                             "
	echo "-----------------------------------------------------------------------------------------"
	
	# Try creating the directories if they do not exist
	mkdir -p $ST_MOODLE_LOC
	mkdir -p $ST_MOODLE_LOC_BAK
	
	rm -rf $ST_MOODLE_LOC_BAK/*
	echo "INFO: Removed existing moodle code backup"
	
	# Back up the existing installation 
	echo "INFO: Backing up moodle code for new deployment"
	cp -rf $ST_MOODLE_LOC/* $ST_MOODLE_LOC_BAK
	chmod -Rf 777 $ST_MOODLE_LOC_BAK/*
	echo "INFO: Backed up moodle code, ready for deployment"
	
	rm -rf $ST_MOODLE_LOC/*
	echo "INFO: Removed existing moodle code"
	
	# creating directory for new install
	mkdir -p $ST_MOODLE_LOC
	echo "INFO: Re created moodle dir for new deployment"
	
	
	cd ${ARTIFACTS_DIR}
	echo "INFO: Deployable artifacts directory: $ARTIFACTS_DIR"
	
	echo "INFO: verifying if new deployable moodle artifact exists"
	ST_MOODLE_WEB_ARTIFACT_FILE=`ls -tr | grep k-moodle-web*zip`
	
	if [[ ! -f ${ST_MOODLE_WEB_ARTIFACT_FILE} ]]; then
	    echo "ERROR: The deployable moodle artifact file does not exist for deployment, did jenkins deploy this file?"
	    # Restore the previous code
		echo "INFO: Restoring previous release code..."
	    cp -rf $ST_MOODLE_LOC_BAK/* $ST_MOODLE_LOC
		# grant access to moodle directory
		grantAccessToMoodle
		echo "INFO: Restored previous release code successfully"
	        exit 1
	fi
	
	cp ${ST_MOODLE_WEB_ARTIFACT_FILE} ${ST_NEW_MOODLE_LOC}
	cd ${ST_NEW_MOODLE_LOC}
	echo "INFO: Deploying new code - in progress..."
	unzip -q -o ${ST_MOODLE_WEB_ARTIFACT_FILE} -d ${ST_MOODLE_LOC}
	cd $ST_MOODLE_LOC
	mv config_${HOST}.php config.php
	echo "INFO: config.php loaded."
	echo "INFO: Deployed new moodle artifact: $ST_MOODLE_WEB_ARTIFACT_FILE to location ${ST_MOODLE_LOC}"
	
	# grant access to moodle directory
	grantAccessToMoodle
	
	rm $ARTIFACTS_DIR$ST_MOODLE_WEB_ARTIFACT_FILE
	echo "INFO: Removed $ST_MOODLE_WEB_ARTIFACT_FILE installer file from deployment location $ARTIFACTS_DIR."
	
	echo "-----------------------------------------------------------------------------------------"
	echo "                          moodle code deployment completed!                              "
	echo "-----------------------------------------------------------------------------------------"
}

function deployMoodledata {
	echo "-----------------------------------------------------------------------------------------"
	echo "                       Initiated moodledata deployment...                                "
	echo "-----------------------------------------------------------------------------------------"
	
	# Try creating the directories if they do not exist
	mkdir -p $ST_MOODLE_DATA_LOC
	mkdir -p $ST_MOODLE_DATA_LOC_BAK
	
	rm -rf $ST_MOODLE_DATA_LOC_BAK/*
	echo "INFO: Removed existing moodledata backup"
	
	# Back up the existing installation 
	echo "INFO: Backing up moodledata for new deployment"
	cp -rf $ST_MOODLE_DATA_LOC/* $ST_MOODLE_DATA_LOC_BAK
	chmod -Rf 777 $ST_MOODLE_DATA_LOC_BAK/*
	echo "INFO: Backed up moodledata, ready for deployment"
	
	rm -rf $ST_MOODLE_DATA_LOC/*
	echo "INFO: Removed existing moodledata"
	
	# creating directory for new install
	mkdir -p $ST_MOODLE_DATA_LOC
	echo "INFO: Re created moodledata dir for new deployemnt"
	
	cd ${ARTIFACTS_DIR}
	echo "INFO: Deployable artifacts directory: $ARTIFACTS_DIR"
	
	echo "INFO: verifying if new deployable moodledata artifact exists"
	ST_MOODLE_DATA_WEB_ARTIFACT_FILE=`ls -tr | grep k-moodle-data*zip`
	
	if [[ ! -f ${ST_MOODLE_DATA_WEB_ARTIFACT_FILE} ]]; then
	    echo "ERROR: The deployable moodledata artifact file does not exist for deployment, did jenkins deploy this file?"
	    # Restore the previous code
		echo "INFO: Restoring previous release code..."
	    cp -rf $ST_MOODLE_DATA_LOC_BAK/* $ST_MOODLE_DATA_LOC
	    cd $ST_MOODLE_DATA_LOC
	    rm -rf cache
	    rm -rf sessions
	    echo "INFO: Removed cache and sessions directory came from backup"
		# grant access to moodledata directory
		grantAccessToMoodleData
		echo "INFO: Restored previous release code successfully"
	    exit 1
	fi
	
	cp ${ST_MOODLE_DATA_WEB_ARTIFACT_FILE} ${ST_NEW_MOODLE_DATA_LOC}
	cd ${ST_NEW_MOODLE_DATA_LOC}
	echo "INFO: Deploying new code - in progress..."
	unzip -q -o ${ST_MOODLE_DATA_WEB_ARTIFACT_FILE} -d ${ST_MOODLE_DATA_LOC}
	echo "INFO: Deployed new moodledata artifact: $ST_MOODLE_DATA_WEB_ARTIFACT_FILE to location ${ST_MOODLE_DATA_LOC}"
	
	# grant access to moodledata directory
	grantAccessToMoodleData
	
	rm $ARTIFACTS_DIR$ST_MOODLE_DATA_WEB_ARTIFACT_FILE
	echo "INFO: Removed $ST_MOODLE_DATA_WEB_ARTIFACT_FILE installer file from deployment location $ARTIFACTS_DIR."
	
	echo "-----------------------------------------------------------------------------------------"
	echo "                       moodledata deployment completed!                                  "
	echo "-----------------------------------------------------------------------------------------"
}

function deployMoodledb {
	echo "-----------------------------------------------------------------------------------------"
	echo "                         Initiated moodle database deployment...                         "
	echo "-----------------------------------------------------------------------------------------"
	
	echo "INFO: Deployable artifacts directory: $ARTIFACTS_DIR"
	cd ${ARTIFACTS_DIR}
	
	echo "INFO: verifying if new deployable moodle database artifact exists"
	ST_MOODLE_DB_ARTIFACT_FILE=`ls -tr | grep k-moodle-db*zip`
	
	if [[ ! -f ${ST_MOODLE_DB_ARTIFACT_FILE} ]]; then
	    echo "ERROR: The deployable moodle database artifact file does not exist for deployment, did jenkins deploy this file?"
	    exit 1
	fi
	
	unzip ST_MOODLE_DB_ARTIFACT_FILE
	echo "INFO: Uploading new database - in progress..."
	mysql -v -u root -proot moodle < st-moodle-db-schema.sql
	echo "INFO: Uploaded new database artifact: $ST_MOODLE_DATA_WEB_ARTIFACT_FILE"
	
	rm $ARTIFACTS_DIR$ST_MOODLE_DB_ARTIFACT_FILE
	echo "INFO: Removed $ST_MOODLE_DB_ARTIFACT_FILE installer file from deployment location $ARTIFACTS_DIR."
		
	echo "-----------------------------------------------------------------------------------------"
	echo "                          moodle database deployment completed!                          "
	echo "-----------------------------------------------------------------------------------------"	
}