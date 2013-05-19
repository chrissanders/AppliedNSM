#!/bin/bash

#Written by Jason Smith

## pstr.sh is a utility designed to pull out human readable metadata from raw PCAP files. ##

## Example Usage ##
# - The following will daemonize a pstr process that is collecting metadata from tcp port 80 or udp port 53 based on pcap located at /data/pcap/.
# - The files will be written to /data/pstr/
# [idsusr@localhost ~]# sudo ./pstr.sh -r /data/pcap/ -w /data/pstr/ -d 10 -f 'tcp port 80 or udp port 53' -D

# - The following will daemonize a pstr process that is collecting metadata from port 25 communications containing 192.168.2.54 based on pcap located at /home/user/pcap/.
# - The files will be written to /var/log/pstr/
# [idsusr@localhost ~]# sudo ./pstr.sh -r /home/user/pcap/ -w /var/log/pstr/ -f 'host 192.168.2.54 and tcp port 25'

sleep 1
echo ""
echo "<><><><><><><><><><><>"
echo "Initializing pstr generation..."
## Setting up options ##
NO_ARGS=0
E_OPTERROR=85
snaplength=500
pstrshDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ $# -eq "$NO_ARGS" ]    # Script invoked with no command-line args?
	then
	echo "Usage: `basename $0` options (-hDrwfd). Use -h for help and examples."
	
	echo ""
  	exit $E_OPTERROR          # Exit and explain usage.
                            # Usage: scriptname -options
                            # Note: dash (-) necessary
fi

while getopts ":hDr:w:f:d:" Option
do
  case $Option in
    h     ) helpoption=$(echo "-HELP-");;
    D     ) daemonoption=$(echo "Daemonizing...");;
    r     ) pcapdir=$(echo "$OPTARG");;
    w     ) pstrdir=$(echo "$OPTARG");;
    f     ) BPF=$(echo "$OPTARG");;
    d     ) rollover=$(echo "$OPTARG");;
    *     ) echo "Unimplemented option chosen.";;   # Default.
  esac
done

## Identify PCAP creation process if currently logging ##
echo ""
#pcapagenttest=$(lsof $pcapdir/*|awk '{print $1}' | tail -1)
## Display Help ##
if [ ! -z "$helpoption" ];then
	clear
	echo "############"
	echo "# pstr.sh #"
	echo "############"
	echo "Written by Jason Smith"
	echo ""
	echo "pstr.sh is a utility designed to pull out human readable metadata from raw PCAP files." 
	echo ""
	echo "   -D (--Daemonize)"
	echo "          When running pstr.sh, send the process to the background as a daemon."
	echo ""
	echo "   -r (--read)"
        echo "          Select a directory containing PCAP files for pstr.sh to use when creating PSTR from PCAP."
       	echo ""
	echo "   -w (--write)"
        echo "          Select a directory for pstr.sh to write PSTR files to."
       	echo ""
	echo "   -f (--filter)"
        echo "          Provide a tcpdump filter for pstr.sh to use when reading PCAP files. Default is 'tcp port 80 or tcp port 25'."
       	echo ""
	echo "   -d (--delete)"
        echo "          Provide the number of days you would like to keep PSTR files before rolling over. Default is forever."
       	echo ""
	echo "## Example Usage ##"
		echo " "
		echo ' - The following will daemonize a pstr process that is collecting metadata from tcp port 80 or udp port 53 based on pcap located at /data/pcap/ '
		echo ' - The files will be written to /data/pstr/'
		echo " <><>[idsusr@localhost ~]# sudo ./pstr.sh -r /data/pcap/ -w /data/pstr/ -d 10 -f 'tcp port 80 or udp port 53' -D "
		echo " "
		echo ' - The following will start a pstr process that is collecting metadata from port 25 communications containing 192.168.2.54 based on pcap located at /home/user/pcap/'
		echo ' - The files will be written to /var/log/pstr/'
		echo " <><>[idsusr@localhost ~]# sudo ./pstr.sh -r /home/user/pcap/ -w /var/log/pstr/ -f 'host 192.168.2.54 and tcp port 25'"
		echo " "
	exit
fi

##Verify PCAP source
if [ -z "$pcapdir" ];then
        echo "You didn't specify a PCAP directory. Please use -r to read from your directory containing PCAPs"
        exit
	else
	if [ ! -d "$pcapdir" ]; then
		echo ""
        echo "FATAL ERROR: The directory you've chosen does not exist or cannot be read. Please select a pcap directory other than \"$pcapdir\""
		echo "<><><><><><><><><><><>"
		echo ""
        exit
	fi
fi

##Verify PSTR destination
if [ -z "$pstrdir" ];then
	echo "You didn't specify a PSTR directory. Please use -w to select a destination directory for PSTR files"
	exit
	else
	if [ ! -d "$pstrdir" ]; then
		echo ""
		echo "FATAL ERROR: The directory you've chosen does not exist or cannot be read. Please select a PSTR directory other than \"$pstrdir\""
		echo "<><><><><><><><><><><>"
		echo ""
		exit
	fi
fi

if [ -z "$BPF" ];then
        echo "INFO: You didn't choose a custom TCPdump filter. If you would like to, use the -f option. Defaulting to 'tcp port 80 or tcp port 25'"
        sleep 1
	BPF=$(echo 'tcp port 80 or tcp port 25')
	else
	BPFcheck=$(tcpdump -dd "$BPF")
        if [ -z "$BPFcheck" ];then
		echo ""
                echo "ERROR: Your TCPdump filter is not valid. Either specify a proper TCPdump filter or exclude the option to accept the default filter."
                echo ""
		exit
        fi
fi

if [ -z "$rollover" ];then
	echo " "
	sleep 1
        echo "INFO: You have selected to not rollover PSTR files. If you would like to delete PSTR files older than [num] days, use the -d [num] option."
        sleep 1
	else
	if ! [[ "$rollover" =~ ^[0-9]+$ ]] ; then
   		echo ""
		echo "FATAL ERROR: The rollover duration you've selected is not a number. Please select a number (in days) for your rollover."
		echo "<><><><><><><><><><><>"
		echo ""
		exit
	fi
fi
		echo ""
                echo "Reading PCAP files from $pcapdir"
                echo "Reading PSTR files from $pstrdir"
                echo "Applying the following filter; $BPF"
		if [ ! -z "$pcapagenttest" ];then
#                        echo "Ongoing PCAP logging detected. Will continuously process until ctrl+c."
                fi
		if [ ! -z "$rollover" ];then
        		echo "PSTR files will rollover every $rollover day(s)."
		fi
		echo " "
		sleep 1

if [ -z "$daemonoption" ];then
	echo "Running in continuous mode. To daemonize, please use the -D option."
        else
	echo "All options are valid."
	echo  ""
	echo "<><><><><><><><><><><>"
	echo "$daemonoption"
	sleep 2
        nohup $pstrshDIR/./pstr.sh -r $pcapdir -w $pstrdir -f "$BPF" -d $rollover > /dev/null  2>&1 &
        nohupid=$(echo $!)
	echo "Daemon created with pid $nohupid..."
	echo "<><><><><><><><><><><>"
	exit
fi
shift $(($OPTIND - 1))
echo "All options are valid."
echo "<><><><><><><><><><><>"
echo " "
sleep 2


## Begin loop process ##
while [ true ]
	do

## auto-identify pcaps for analysis ##
#	pcapagent=$(lsof | grep $pcapdir | awk '{print $1}')
if [ ! -z "$pcapdir" ];then
		if [ ! -z "$pcapagent" ];then
#		currentpcap=$(lsof -c $pcapagent | grep $pcapdir |awk '{print $9}')
		file $pcapdir* | grep tcpdump | cut -d ':' -f1 | awk -F "/" '{ print $NF; }' |grep -v $currentpcap > $pstrshDIR/pcapindex.txt
		else
	file $pcapdir* | grep tcpdump | cut -d ':' -f1 | awk -F "/" '{ print $NF; }' > $pstrshDIR/pcapindex.txt
		fi
	fi

## Index files which have already been analyzed ##
	ls -lh $pstrdir/ | awk '{print $9}'|cut -d '.' -f1,2 > $pstrshDIR/pstrindex.txt
	        while IFS= read -r file
	        do

                unprocessedpcap=$(grep $file $pstrshDIR/pstrindex.txt)
		if [ -z "$unprocessedpcap" ];then
## Bare Parsing of PCAP ##
	echo "Processing $file..."
	/usr/sbin/tcpdump -qnns $snaplength -A -r $pcapdir/$file "$BPF" | \
			strings | \
			sed '/^$/d'| \
			sed '/[0-9][0-9]\:[0-9][0-9]\:[0-9][0-9].[0-9]\{6\} IP [0-9]\{1,3\}\.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}/{x;p;x;}'| \
			sed 's/^$/\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-/g'| \
			egrep ''^[a-zA-Z]\{2,20\}:'|'^[0-9][0-9]\:'|'^[a-zA-Z]\{1,15\}-[a-zA-Z]\{1,15\}:'|'GET'|'POST'|'HEAD'|'PUT'|'CONNECT'' | \
			sed '/[0-9][0-9]\:[0-9][0-9]\:[0-9][0-9].[0-9]\{6\} IP [0-9]\{1,3\}\.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}/{x;p;x;}'| \
			sed 's/^$/\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-/g'| \
			awk 'BEGIN { RS="-------------------------------\n" ;ORS="-------------------------------\n" ;  FS="\n" } ; {       if(NF>2) print; }'  | \
			awk 'BEGIN{print "-------------------------------"}{print}' > $pstrdir/$file.pstr
			echo "$pstrdir/$file.pstr created successfully."
			ls -lh $pstrdir/$file.pstr
			echo ""
fi
		done < "$pstrshDIR/pcapindex.txt"
## Rollover old files and reduce load of loop ##

	if [ ! -z "$rollover" ];then
find $pstrdir/* -mmin +$rollover -exec rm {} \;
	fi
	if [ -z "$file" ];then
		if [ -z "$pcapagenttest" ];then
#                        echo "No on-going PCAP agent process detected for the selected PCAP directory. If this is true, press ctrl+c to quit. Continuing until quit."
               	fi
		sleep 5
	fi
done
