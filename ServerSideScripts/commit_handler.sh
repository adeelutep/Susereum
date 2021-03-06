#!/bin/bash
SENDERID=$1
REPOID=$2
NAME=$3
COMMIT_URL=$4
TIME=$5
echo 'about to run'
#COMMIT_URL check if url has spaces?



#check if cron is set up, if not add
cron_cmd_g="\*/10 \* \* \* \* /home/practicum2018/Suserium/Susereum/ServerSideScripts/commit_handler.sh $1 $2 $3 $4 $5"
cron_cmd="*/10 * * * * /home/practicum2018/Suserium/Susereum/ServerSideScripts/commit_handler.sh $1 $2 $3 $4 $5"
crontab -l > mycron
echo "adding.. cron command: $cron_cmd"
if grep -Fxq "$cron_cmd" mycron
then
	echo -n ""
else
	#add task
	echo "$cron_cmd" >> mycron
	crontab mycron
fi
rm mycron
echo "$cron_cmd $(date)" > /commit_handler_cron.txt
#send a new comit
#get chain ports

Dir=$(
cd $(dirname "$0")
pwd
)
readarray ports < $Dir/map/$REPOID
export SAWTOOTH_HOME="/home/practicum2018/.sawtooth_projects/.$(echo $NAME)_$(echo $REPOID)"
cd $SAWTOOTH_HOME
#push to chain the commit
api=$(echo ${ports[2]} | tr -d '\n')
#if the client did the health
health_done=`sawtooth transaction list --url http://127.0.0.1:$api | grep "health" | grep $COMMIT_URL`
if [ -z "$health_done" ] ;then
	echo 'sending new commit'
	#get random client public key 
	sawtooth peer list --url http://127.0.0.1:$api > ips
	size=`wc ips  | awk '{printf $3}'`
	if (( size <4 ));
	then
		rm ips
	fi
	echo -n "tcp://" >> ips
	ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n 1 | tr -d '\n' >> ips
	echo -n ":1001" >> ips
	echo "IIIIIIIIIIIIIIIIIPPPPPPPPPPPPPSSSSSSSSSSSS:"
	cat ips
	peer_ip=`cat ips | shuf -n 1 | awk '{print $1;}'`
	python3 bin/health.py commit --url http://127.0.0.1:$api --giturl $COMMIT_URL --gituser $SENDERID --date $TIME --client_key "$peer_ip" &
	#url is for chain api
	echo "python3 bin/health.py commit --url http://127.0.0.1:$api --giturl $COMMIT_URL --gituser $SENDERID --date $TIME --client_key $peer_ip" > /commitran
	echo " $SENDERID $REPOID $NAME $COMMIT_URL $TIME ----- $transaction_id @ $key " >> /commitran
else
	#delete self from cron
	cron_cmd="\*/10 \* \* \* \* /home/practicum2018/Suserium/Susereum/ServerSideScripts/commit_handler.sh $1 $2 $3 $4 $5"
	echo "deleting self $cron_cmd"
	crontab -l | grep -v "$cron_cmd" > mycron
	crontab mycron
	cat mycron
	rm mycron
fi



	


