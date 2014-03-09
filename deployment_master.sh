#!/bin/bash -e
# -e means exit if any command fails

#/*  ################################################################################-   */
#
#  Purpose     : Master deployment script that gets triggered by jenkins deploy job 
#              :  
#  Created By  : Kiran Dharmavarapu
#  Created Date: 03/04/2014
#  Dependencies: parameters coming from jenkins job
# 
#/*  ################################################################################-   */

if [[ ${DEPLOYMENT_SOURCE} == "Direct URLs" ]]
	then
	if [[ ${MOODLE_ARTIFACT_URL} == "" ]] || [[ ${MOODLE_DATA_ARTIFACT_URL} == "" ]] || [[ ${MOODLE_DB_ARTIFACT_URL} == "" ]] 
		then
		echo "Please verify artifacts download URLs"
		exit 11
	fi

elif [[ ${DEPLOYMENT_SOURCE} == "Nexus repo" ]]
	then
	MOODLE_ARTIFACT_URL="http://ci.knodemy.com:8081/nexus/service/local/artifact/maven/redirect?r=${NEXUS_ARTIFACTS_REPO}&g=com.knodemy.moodle&a=k-moodle-web&v=${MOODLE_ARTIFACT_VERSION}&e=zip"
	MOODLE_DATA_ARTIFACT_URL="http://ci.knodemy.com:8081/nexus/service/local/artifact/maven/redirect?r=${NEXUS_ARTIFACTS_REPO}&g=com.knodemy.moodledata&a=k-moodle-data&v=${MOODLE_DATA_ARTIFACT_VERSION}&e=zip"
	MOODLE_DB_ARTIFACT_URL="http://ci.knodemy.com:8081/nexus/service/local/artifact/maven/redirect?r=${NEXUS_ARTIFACTS_REPO}&g=com.knodemy.moodledb&a=k-moodle-db&v=${MOODLE_DB_ARTIFACT_VERSION}&e=zip"

elif [[ ${DEPLOYMENT_SOURCE} == "Jenkins Jobs" ]]
	then
	
	if [[ ${MOODLE_ARTIFACT_JOB_BUILD} == "LAST" ]]
		then
		MOODLE_BUILD_ID=`curl -s ${MOODLE_ARTIFACT_JOB}/lastSuccessfulBuild/buildNumber`
	else
		curl -s -I ${MOODLE_ARTIFACT_JOB}/${MOODLE_ARTIFACT_JOB_BUILD}/buildStatus | egrep -q -e "^Location(.*)[blue|green].png"
		if [[ $? == 0 ]]
			then
			MOODLE_BUILD_ID=${MOODLE_ARTIFACT_JOB_BUILD}
		else
			echo "Build is BAD"
			exit 13
		fi
	fi
	MOODLE_BUILD_ID_OUT='mktemp'
	curl -s ${MOODLE_ARTIFACT_JOB}/${MOODLE_BUILD_ID}/consoleText > ${MOODLE_BUILD_ID_OUT}
	MOODLE_ARTIFACT_URL=`egrep -a -e "^Uploading: http://(.*)/k-moodle-web-(.*).zip" ${MOODLE_BUILD_ID_OUT} | awk '{ print $2 };'`

	if [[ ${MOODLE_DATA_ARTIFACT_JOB_BUILD} == "LAST" ]]
		then
		MOODLE_DATA_BUILD_ID=`curl -s ${MOODLE_DATA_ARTIFACT_JOB}/lastSuccessfulBuild/buildNumber`
	else
		curl -s -I ${MOODLE_DATA_ARTIFACT_JOB}/${MOODLE_DATA_ARTIFACT_JOB_BUILD}/buildStatus | egrep -q -e "^Location(.*)[blue|green].png"
		if [[ $? == 0 ]]
			then
			MOODLE_DATA_BUILD_ID=${MOODLE_DATA_ARTIFACT_JOB_BUILD}
		else
			echo "Build is BAD"
			exit 13
		fi
	fi
	
	MOODLE_DATA_BUILD_ID_OUT='mktemp'
	curl -s ${MOODLE_DATA_ARTIFACT_JOB}/${MOODLE_DATA_BUILD_ID}/consoleText > ${MOODLE_DATA_BUILD_ID_OUT}
	MOODLE_DATA_ARTIFACT_URL=`egrep -a -e "^Uploading: http://(.*)/k-moodle-data-(.*).zip" ${MOODLE_DATA_BUILD_ID_OUT} | awk '{ print $2 };'`
	
	if [[ ${MOODLE_DB_JOB_BUILD} == "LAST" ]]
		then
		MOODLE_DB_BUILD_ID=`curl -s ${MOODLE_DB_ARTIFACT_JOB}/lastSuccessfulBuild/buildNumber`
	else
		curl -s -I ${MOODLE_DB_ARTIFACT_JOB}/${MOODLE_DB_JOB_BUILD}/buildStatus | egrep -q -e "^Location(.*)[blue|green].png"
		if [[ $? == 0 ]]
			then
			MOODLE_DB_BUILD_ID=${MOODLE_DB_JOB_BUILD}
		else
			echo "Build is BAD"
			exit 13
		fi
	fi
	MOODLE_DB_BUILD_ID_OUT='mktemp'
	curl -s ${MOODLE_DB_ARTIFACT_JOB}/${MOODLE_DB_BUILD_ID}/consoleText > ${MOODLE_DB_BUILD_ID_OUT}
	MOODLE_DB_ARTIFACT_URL=`egrep -a -e "^Uploading: http://(.*)/k-moodle-db-(.*).zip" ${MOODLE_DB_BUILD_ID_OUT} | awk '{ print $2 };'`
	
else
	echo "Unknown artifacts deployment source specified"
	exit 12

fi	

MOODLE_ARTIFACT_URL_ESC=`echo ${MOODLE_ARTIFACT_URL} | sed -e 's,\/,\\\/,g' -e 's,\&,\\\&,g'`
MOODLE_DATA_ARTIFACT_URL_ESC=`echo ${MOODLE_DATA_ARTIFACT_URL} | sed -e 's,\/,\\\/,g' -e 's,\&,\\\&,g'`
MOODLE_DB_ARTIFACT_URL_ESC=`echo ${MOODLE_DB_ARTIFACT_URL} | sed -e 's,\/,\\\/,g' -e 's,\&,\\\&,g'`

echo "Verifying URLs"

MOODLE_CURL_TMP='mktemp'
curl -s -L -I -u stdeploy:stdeploy123 "${MOODLE_ARTIFACT_URL}" > ${MOODLE_CURL_TMP}
{ grep -q "1.1 200 OK" ${MOODLE_CURL_TMP}; } || { echo "MOODLE_ARTIFACT_URL is invalid"; exit 13; }
curl -s -L -I -u stdeploy:stdeploy123 "${MOODLE_DATA_ARTIFACT_URL}" > ${MOODLE_CURL_TMP}
{ grep -q "1.1 200 OK" ${MOODLE_CURL_TMP}; } || { echo "MOODLE_DATA_ARTIFACT_URL is invalid"; exit 13; }
curl -s -L -I -u stdeploy:stdeploy123 "${MOODLE_DB_ARTIFACT_URL}" > ${MOODLE_CURL_TMP}
{ grep -q "1.1 200 OK" ${MOODLE_CURL_TMP}; } || { echo "MOODLE_DB_ARTIFACT_URL is invalid"; exit 13; }

rm -f ${MOODLE_CURL_TMP} ${MOODLE_DB_BUILD_ID_OUT} ${MOODLE_DATA_BUILD_ID_OUT} ${MOODLE_BUILD_ID_OUT}

cd /opt/apps/
rm -rf deploy
mkdir deploy 
cd /opt/apps/deploy/

wget --content-disposition --http-user=stdeploy --http-passwd=stdeploy123 "${MOODLE_ARTIFACT_URL}"
wget --content-disposition --http-user=stdeploy --http-passwd=stdeploy123 "${MOODLE_DATA_ARTIFACT_URL}"
wget --content-disposition --http-user=stdeploy --http-passwd=stdeploy123 "${MOODLE_DB_ARTIFACT_URL}"

echo ${ENVIRONMENT_HOST}

scp -i /var/lib/jenkins/.ssh/deploy_rsa -r /opt/apps/deploy ubuntu@${ENVIRONMENT_HOST}:/opt/apps


#tar cz . | $SSH_COMMAND $HOST 'tar xz && { pgrep chef-solo > /dev/null && echo "Deployment is already in progress, exiting." && exit 1 ;} || { echo "Starting deployment." && exec sh -xv ./deploy.sh ;}'

	
	