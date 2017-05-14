#!/bin/sh
#####################################################
#
# This Script sends an email with all the PGP Keys expiration details
# Steps to use:
# 1. Copy this script to a directory (where PGP is installed) and change the TOOL_HOME to this directory
# 2. Create a sub-directory with name "config" in TOOL_HOME
# 3. Change ALERT_TO_EMAIL to the email ID to which you want to send the expiration detail
# 3. That's all; You are ready to go and execute the script
#
#####################################################

init()
{
	TOOL_NAME="PGP Keys Expiration Tracker Tool"
	SCRIPT_NAME=PGP_Expiration_Tracker.sh
	TOOL_HOME=/home/mqfteadm/scripts/PGPUtils
	ALERT_TO_EMAIL=syelavarthi@gmail.com
        
	
	ENV_NAME=$1
	EMAIL_HTML_TEXT=""
}

#####################################################
#
# This function logs the informational messages
#
#####################################################

logInfo()
{
	echo "[INFO] `date` $1"
}

#####################################################
#
# This function logs the error messages
#
#####################################################

logError()
{
	echo "[ERROR] `date` $1"
}

#####################################################
#
# This function exits the script abnormally
#
#####################################################

exitAbnormally()
{
	logInfo "${TOOL_NAME} terminated abnormally."
	exit 1
}

#####################################################
#
# This function prints the script usage sytax
#
#####################################################
printUsage()
{
	logInfo "Usage: ${SCRIPT_NAME} <DEV/FTEDEV/PSODEV/INT/FTEINT/PSOINT/QA/FTEQA/PSOQA/STG1/FTESTG1/PSOSTG1/STG2/FTESTG2/PSOSTG2/PRD1/FTEPRD1/PSOPRD1/PRD2/FTEPRD2/PSOPRD2>"
}

contains() 
{ 
	[ -z "${2##*$1*}" ] && [ -z "$1" -o -n "$2" ]; 
}

#####################################################
#
# This function sends email
#
#####################################################
sendEmail()
{   
	#echo $1 | mail -s "Alert: PGP Keys Expiration Status On $ENV_NAME" $ALERT_TO_EMAIL
	(
		echo "To: $ALERT_TO_EMAIL"
		echo "Subject: Alert - PGP Keys Expiration Status On $ENV_NAME"
		echo "Content-Type: text/html"
		echo
		echo "${EMAIL_HTML_TEXT}"
		echo
	) | /usr/sbin/sendmail -t
}

#############################################################################
#
# This is the main function
# 
#############################################################################

main()
{
	init $1
	
	if [ -n "$1" ]
	then
		TEMP_OUT_FILE_PREFIX="${TOOL_HOME}/config/temp."${SCRIPT_NAME}"."${ENV_NAME}
		
		echo $TEMP_OUT_FILE_PREFIX
		hostName=$(hostname)
		EMAIL_HTML_TEXT="<html><body style='font-family:Courier New'><h3>Host Name: $hostName</h3><table border='1' style='font-family:Courier New'><tr><th>Key Id</th><th>User Id</th><th>Expiry Date</th></tr>"
		
		# ---------------------------------------------
		gpg2 --list-keys > $TEMP_OUT_FILE_PREFIX.1.txt
				
		grep -n -E 'expires|expired' $TEMP_OUT_FILE_PREFIX.1.txt  | cut -d':' -f1 |  xargs  -n1 -I % awk 'NR<=%+1 && NR>=%' $TEMP_OUT_FILE_PREFIX.1.txt > $TEMP_OUT_FILE_PREFIX.2.txt
				
		grep -n -E 'pub' $TEMP_OUT_FILE_PREFIX.2.txt  | cut -d':' -f1 |  xargs  -n1 -I % awk 'NR<=%+1 && NR>=%' $TEMP_OUT_FILE_PREFIX.2.txt > $TEMP_OUT_FILE_PREFIX.1.txt
		# ---------------------------------------------
		
		while read first_line; read second_line
		do
			
			keyId=${first_line#*/}
			keyId=$(echo $keyId | cut -d' ' -f1)
	
			expiryDate=${first_line#*:}			
			expiryDate=${expiryDate%]*}			
			
			userId=${second_line#*uid }			
			userId=$(echo "$userId" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g')
			
			EMAIL_HTML_TEXT=$EMAIL_HTML_TEXT"<tr><td>$keyId</td><td>$userId</td><td>$expiryDate</td></tr>"
			
		done < "$TEMP_OUT_FILE_PREFIX.1.txt"		
		
		EMAIL_HTML_TEXT=$EMAIL_HTML_TEXT"</table></body></html>"
		
		#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"$EMAIL_HTML_TEXT
		
		sendEmail $EMAIL_HTML_TEXT
		
		rm "$TEMP_OUT_FILE_PREFIX.*"
		
	else
		printUsage
		exitAbnormally
	fi

	exit 0
}

main $1 

