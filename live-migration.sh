#!/bin/bash
#
# This script should be executed on destination server (new Zimbra installation = TO_IP value)
# Customize as required. You need to select the proper mode to run this script
# Option "1 and 2":
#		Backup Mode imports one/all the accounts from origin server (FROM_IP) and stores them in a local directory
# Option "3 and 4":
#		Restore Mode exports one/all the accounts in .tgz stored locally (in $BACKUPFOLDER) to remote server (new Zimbra)
# Option "5": 
#		Backup/Restore Mode imports and exports all the accounts from origin ($FROM_IP) server to destination ($TO_IP).
# NOTE: Option 3 requires all domains and accounts to be created in destination ($TO_IP) server.
# 
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
CLEAR=$(which clear)
FROM_IP=127.0.0.1
FROM_ADMIN_ACCOUNT="admin@server-origin.com"
FROM_ADMIN_PASSWORD="PASSWORD"
TO_IP=127.0.0.1
TO_ADMIN_ACCOUNT="admin@server-destination.com"
TO_ADMIN_PASSWORD="PASSWORD"
CURL=$(which curl)
RM=$(which rm)
LS=$(which ls)
MKDIR=$(which mkdir)
BACKUPFOLDER="/tmp/files"
# MailBoxes=$(zmprov -l gaa)
#######################################################
# Functions
_DeleteBackupFile() {
	$RM -rf $BACKUPFOLDER/$1
}

_DeleteBackupFolder() {
	$RM -rf $BACKUPFOLDER/*
	$MKDIR -p $BACKUPFOLDER 2>/dev/null
}
_BackupMode() {
        for Account in $1
                do
                $CURL  -S -v -k -u $FROM_ADMIN_ACCOUNT:$FROM_ADMIN_PASSWORD "https://$FROM_IP:7071/service/home/$Account?fmt=tgz" > "$BACKUPFOLDER/$Account.tgz" 
		echo ""
		echo ""
		echo "Backup of $Account is available in $BACKUPFOLDER/$Account.tgz"
	done
}
_RestoreMode() {
        for Account in $1
		do
 		$CURL -v -k -u $TO_ADMIN_ACCOUNT:$TO_ADMIN_PASSWORD -T "$BACKUPFOLDER/$Account.tgz"  "https://$TO_IP:7071/service/home/$Account/?fmt=tgz&resolve=skip"
	done
}
_BackupRestoreMode() {
	MAILBOXES=$(su - zimbra -c "zmprov -l gaa")
	for Account in $MAILBOXES
		do
		$CURL -v -k -u $FROM_ADMIN_ACCOUNT:$FROM_ADMIN_PASSWORD "https://$FROM_IP:7071/service/home/$Account?fmt=tgz" > "$BACKUPFOLDER/$Account.tgz"
 		$CURL -v -k -u $TO_ADMIN_ACCOUNT:$TO_ADMIN_PASSWORD -T "$BACKUPFOLDER/$Account.tgz"  "https://$TO_IP:7071/service/home/$Account/?fmt=tgz&resolve=skip"
	done
}
_Menu() {
$CLEAR
echo " ------------------------------------------------------------------------------------------------------------------------- "
echo " Zimbra | Backup - Restore - Backup/Restore | by Juan Ignacio Ciriaco (https://github.com/juanignaciociriaco)		 "
echo " ------------------------------------------------------------------------------------------------------------------------- "
echo " Choose a number 1-6 to start. Press 0 to exit"
echo " 1) Backup All Accounts "
echo " 2) Backup ONE Account"
echo " 3) Restore All Accounts"
echo " 4) Restore ONE Account"
echo " 5) Backup/Restore All Accounts"
echo " 0) Exit"
echo " ------------------------------------------------------------------------------------------------------------------------- "
echo ""
echo -n "Enter a number: "
}
# End Functions
_Menu
read NUMBER
case $NUMBER in
	1) 
		echo " ------------------------------------------------------------------------------------------------------------------------- "
		echo "Lets perform a FULL BACKUP"
		echo "It is recommended to clean the Backup Directory (located in $BACKUPFOLDER)."
		echo "Current content of Backup Directory"
		echo "Do you want to delete backup files?"
		echo " 1. Yes | 2. No"
		read _DeleteOption
		if [ $_DeleteOption == 1 ]; then
			 _DeleteBackupFolder
		fi
		echo " ------------------------------------------------------------------------------------------------------------------------- "
		MAILBOXES=$(su - zimbra -c "zmprov -l gaa")
		_BackupMode $MAILBOXES

		;;

	2)	
          	echo " ------------------------------------------------------------------------------------------------------------------------- "
                echo "Lets perform a ONE ACCOUNT backup"
                echo "It is recommended to clean the Backup Directory (located in $BACKUPFOLDER) before starting."
                echo -e -n "Type exactly the name of the account to backup: "
                read _Filename
                echo "Do you want to delete backup files?"
                echo " 1. Yes | 2. No"
                read _DeleteOption
                if [ $_DeleteOption == 1 ]; then
                       _DeleteBackupFile $_Filename.tgz
                fi
                echo " ------------------------------------------------------------------------------------------------------------------------- "
                echo -e -n "Type exactly THE ACCOUNT to backup (e.g. username@domain.com): "
                read _Account
               	MAILBOXES=$_Account
		_BackupMode $MAILBOXES
		;;
	3)
          	echo " ------------------------------------------------------------------------------------------------------------------------- "
               	echo "Restore all account backups existing in $BACKUPFOLDER"
               	echo "Current content of Backup Directory"
                 $LS $BACKUPFOLDER | sed 's/^/   -->    /'
               	echo "Do you want to proceed??"
               	echo " 1. Yes | 2. No"
               	read _Option
               	echo " ------------------------------------------------------------------------------------------------------------------------- "
               	if [ $_Option == 1 ]; then
		MAILBOXES=$(su - zimbra -c "zmprov -l gaa")
                         _RestoreMode $MAILBOXES
               	fi
		;;
	4)
          	echo " ------------------------------------------------------------------------------------------------------------------------- "
               	echo "Restore ONE account backups existing in $BACKUPFOLDER"
               	echo "Current content of Backup Directory"
		 $LS $BACKUPFOLDER | sed 's/^/	 -->	/' 
               	echo -e -n "Type exactly as shown above (e.g. username@domain.com.tgz): "
               	read _Filename
               	echo " ------------------------------------------------------------------------------------------------------------------------- "
		FILE=$BACKUPFOLDER/$_Filename
		if [ -f "$FILE" ]; then
			ACCOUNT_NO_EXTENSION=$(echo ${_Filename%.tgz})
			MAILBOXES=$(su - zimbra -c "zmprov -l gaa | grep $ACCOUNT_NO_EXTENSION")
        	       	 _RestoreMode $MAILBOXES
		else
			echo "FILE NOT EXISTS. ABORTING PROCESS"
			sleep 2
		fi
		;;

	5)
              echo " ------------------------------------------------------------------------------------------------------------------------- "
              echo "Lets perform a FULL BACKUP/RESTORE"
              echo "It is recommended to clean the Backup Directory (located in $BACKUPFOLDER)."
              echo "Current content of Backup Directory"
              echo "Do you want to delete backup files?"
              echo " 1. Yes | 2. No"
              read _DeleteOption
              if [ $_DeleteOption == 1 ]; then
                       _DeleteBackupFolder
              fi
	      echo ""
              echo " ------------------------------------------------------------------------------------------------------------------------- "
              MAILBOXES=$(su - zimbra -c "zmprov -l gaa")
              _BackupMode $MAILBOXES
              echo ""
              echo ""
              echo ""
              echo "FULL BACKUP FINISHED"
              echo "Do you want to perform the FULL RESTORE??"
              echo " 1. Yes | 2. No"
              read _Option
              echo " ------------------------------------------------------------------------------------------------------------------------- "
              MAILBOXES=$(su - zimbra -c "zmprov -l gaa")
              if [ $_Option == 1 ]; then
                       _RestoreMode $MAILBOXES
              fi
	      ;;
esac
