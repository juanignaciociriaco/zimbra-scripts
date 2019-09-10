#!/bin/sh
WHO=`whoami`
if [ $WHO = “zimbra” ] all_account=`zmprov -l gaa`;
for account in ${all_account}
do
mb_size=`zmmailbox -z -m ${account} gms`;
echo “Mailbox size of ${account} = ${mb_size}”;
done
else
echo “Execute this script as user zimbra (\”su – zimbra\”)”
fi
