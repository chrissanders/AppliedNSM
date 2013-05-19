#!/bin/bash
#PSTRsearch.sh

## Variable Configuration. Change as required. ##
PSTRsearchdir="/home/$USER/AppliedNSM/PSTR/PSTRsearch/"
pstrdir="/home/$USER/AppliedNSM/PSTR/PSTRfiles"
#scruffdir="/home/$USER/scruff/"
#################################################

## Checking Variable Sanity ##
#if [ ! -d "$scruffdir" ]; then
#        echo "$scruffdir directory doesn't exist. Exiting."
#        exit
#fi

if [ ! -d "$pstrdir" ]; then
        echo "$pstrdir directory doesn't exist. Exiting."
        exit
fi

#if [ ! -d "$PSTRsearchdir" ]; then
#        echo "$PSTRsearchdir directory doesn't exist. Exiting."
#        exit
#fi
###############################


## Setting up Time Variables ##
timefunction ()
{
#clear
echo ""
echo "<><><><><><><><><><><><><><><><><><><><><><><><><><>" 
echo "The current date is;"
currentdatenow=$(date "+%m-%d-%Y %H:%M")
currentdatetoday=$(date "+%m-%d-%Y 00:00")
echo "$currentdatenow"
echo ""
echo 'Enter start date for your search (ex. mm-dd-yyyy HH:MM "08-18-2009 13:52"):'
read startdate
#echo test $startdate
valiDATE=$(echo $startdate | grep '[0-9]\{2\}-[0-9]\{2\}-[0-9]\{4\} [0-9]\{2\}:[0-9]\{2\}')
#echo test $valiDATE
if [ -z "$valiDATE" ];then
	echo "Invalid Start Date. Defaulting to the beginning of the current date only."
	startdate=$(date "+%m-%d-%Y 00:00")
#	echo "Invalid Start Date - Please enter in mm-dd-yy HH:MM format!"
	#exit
fi

oldminute=$(echo $startdate| awk '{print $2}' | cut -d ":" -f2)
oldhour=$(echo $startdate| awk '{print $2}' | cut -d ":" -f1)
oldday=$(echo $startdate| awk '{print $1}' | cut -d "-" -f2)
oldmonth=$(echo $startdate| awk '{print $1}' | cut -d "-" -f1)
oldyear=$(echo $startdate| awk '{print $1}' | cut -d "-" -f3)
echo ""

echo 'Enter end date for your search (ex. mm-dd-yyyy HH:MM "08-18-2012 08:52"):'
read enddate
valiDATE=$(echo $enddate | grep '[0-9]\{2\}-[0-9]\{2\}-[0-9]\{4\} [0-9]\{2\}:[0-9]\{2\}')
if [ -z "$valiDATE" ];then
	echo "Invalid End Date - Defaulting to the current time and date!"
	enddate=$(date "+%m-%d-%Y %H:%M")
#	exit
fi

newminute=$(echo $enddate| awk '{print $2}' | cut -d ":" -f2)
newhour=$(echo $enddate| awk '{print $2}' | cut -d ":" -f1)
newday=$(echo $enddate| awk '{print $1}' | cut -d "-" -f2)
newmonth=$(echo $enddate| awk '{print $1}' | cut -d "-" -f1)
newyear=$(echo $enddate| awk '{print $1}' | cut -d "-" -f3)


touch -m -t $oldyear$oldmonth$oldday$oldhour$oldminute /tmp/startdate
touch -m -t $newyear$newmonth$newday$newhour$newminute /tmp/enddate
find $pstrdir/*.pstr -newer /tmp/startdate ! -newer /tmp/enddate | sort > $PSTRsearchdir/PSTR.todo
rm -rf /tmp/startdate
rm -rf /tmp/enddate
}
###############################
clear
###############################

echo 'Initializing PSTRsearch, a "choose your own adventure" tool to examine PSTR metadata.'
echo ""
echo "What would you like to do?"
echo "(a). Provide a search term for PSTRsearch to look for and return all records containing that word or words."
echo ""
echo "(b). Perform analysis on PSTRsearch derived statistics for search terms of your choice."
echo ""
echo "(c). Select a PSTR result or file and provide a search term for PSTRsearch to look for and return all records containing that word or words."
echo ""
echo "(d). Select a PSTR result or file and perform analysis on PSTRsearch derived statistics for search terms of your choice."


searchvariablefunction ()
{
## Setting up search variables ##
echo ""
echo "<><><><><><><><><><><><><><><><><><><><><><><><><><>"
echo "Is the search a fixed-string or a regular expression?"
echo "Fixed-String (default) - (a)"
echo "Regular Expression - (b)"
read termqualifier
if [ "$termqualifier" == "b" ]; then
	regexvar=$(echo "-E ")
	else
	regexvar=$(echo "-F")
fi
echo "$regexvar"
sleep 1
echo ""
echo "<><><><><><><><><><><><><><><><><><><><><><><><><><>" 
echo "Is the search case-sensitive?"
echo "(yes)"
echo "(no)"
read casequalifier
if [ "$casequalifier" == "no" -o "$casequalifier" == "n" ]; then
	casevar=$(echo "-i ")
fi
sleep 1

uniqtime=$(date +%s)
echo ""
echo "<><><><><><><><><><><><><><><><><><><><><><><><><><>" 
echo "Provide a filename for the output (defaulting to $PSTRsearchdir/PSTRsearch.$uniqtime if no input):"
read filenamepstr
if [ -z "$filenamepstr" ]; then
	filenamepstr=$(echo "$PSTRsearchdir/PSTRsearch.$uniqtime")
fi
sleep 1
#################################

echo ""
echo "<><><><><><><><><><><><><><><><><><><><><><><><><><>" 
echo "Lastly, please enter the term you would like to search for (eg. Host: google.com):"
read -r searchterm
#echo -e "$searchterm"
sleep 5
if [ -z "$searchterm" ]; then
	echo "You didn't enter a search term. Exiting..."
	exit
fi
}

pstrsearchfunction ()
{
if [ "$1" == "aoption" ]; then
	totalfiles=$(cat $PSTRsearchdir/PSTR.todo | wc -l)
	num=$(echo "0")
	while IFS= read -r file;do
	cat $file | sed ':a;N;$!ba;s/\n/||||/g' | sed 's/-------------------------------/\n-------------------------------/g'| \
	grep $regexvar $casevar "$searchterm"| sed 's/||||/\n/g' >> $filenamepstr
	echo "$searchterm"
	num=$(($num + 1))
	clear
	echo "scale=4; $num / $totalfiles * 100" | bc | sed s/00$//g | sed 's/$/\% complete\./g'
	pstrsize=$(du -h $filenamepstr| awk '{print $1}')
	echo "$pstrsize bytes found."
	done < "$PSTRsearchdir/PSTR.todo"
	echo "Finished. Your file is located at; "
	ls -lh $filenamepstr
	rm -rf $PSTRsearchdir/PSTR.todo
fi
if [ "$1" == "coption" ]; then
	latestfile=$(ls -lh /home/ids.usr/PSTRsearch| tail -1 | awk '{print $9}')
	echo ""
	echo "<><><><><><><><><><><><><><><><><><><><><><><><><><>"
	echo "What PSTR file are you wishing to filter down? "
	echo "(NOTE: Leave blank to examine the latest file, $PSTRsearchdir/$latestfile)"
	read file
	echo ""
	if [ -z "$file" ];then
		file=$(echo "$PSTRsearchdir/$latestfile")
	fi
        cat $file | sed ':a;N;$!ba;s/\n/||||/g' | sed 's/-------------------------------/\n-------------------------------/g'| \
        grep $regexvar $casevar "$searchterm"| sed 's/||||/\n/g' >> $filenamepstr
        echo "Finished. Your file is located at; "
        ls -lh $filenamepstr
fi

read -p "Examine $filenamepstr (y/n)?"
[ "$REPLY" == "n" ] || less $filenamepstr
clear
exit
}

pstrstatfunction ()
{
if [ "$1" == "boption" ]; then
	totalfiles=$(cat $PSTRsearchdir/PSTR.todo | wc -l)
	num=$(echo "0")
	while IFS= read -r file;do
	cat $file | grep $regexvar $casevar "$searchterm" >> $filenamepstr.tempstat
	num=$(($num + 1))
	clear
	echo "scale=4; $num / $totalfiles * 100" | bc | sed s/00$//g | sed 's/$/\% complete\./g'
	done < "$PSTRsearchdir/PSTR.todo"
	cat $filenamepstr.tempstat | sort| uniq -c| sort -n > $filenamepstr.stats
	echo "Finished. Your file is located at; "
	ls -lh $filenamepstr.stats
	rm -rf $filenamepstr.tempstat
	rm -rf $PSTRsearchdir/PSTR.todo
	fi
if [ "$1" == "doption" ]; then
latestfile=$(ls -lh /home/ids.usr/PSTRsearch| tail -1 | awk '{print $9}')
        echo ""
        echo "<><><><><><><><><><><><><><><><><><><><><><><><><><>"
        echo "What PSTR file are you wishing to filter down? "
        echo "(NOTE: Leave blank to examine the latest file, $PSTRsearchdir/$latestfile)"
        read file
	if [ -z "$file" ];then
                file=$(echo "$PSTRsearchdir/$latestfile")
        fi
	cat $file | grep $regexvar $casevar "$searchterm">> $filenamepstr.tempstat
	cat $filenamepstr.tempstat | sort| uniq -c| sort -n > $filenamepstr.stats
	echo "Finished. Your file is located at; "
	ls -lh $filenamepstr.stats
	rm -rf $filenamepstr.tempstat
        echo ""
fi
read -p "Examine $filenamepstr.stats (y/n)?"
[ "$REPLY" == "n" ] || less $filenamepstr.stats
exit
}

read PSTRchoice

#timefunction
searchvariablefunction
if [ "$PSTRchoice" == "a" ]; then
	timefunction
	pstrsearchfunction aoption
	else
	if [ "$PSTRchoice" == "b" ]; then
		timefunction
       		pstrstatfunction boption
		else
		if [ "$PSTRchoice" == "c" ]; then
          	      pstrsearchfunction coption 
			else
			if [ "$PSTRchoice" == "d" ]; then
				pstrstatfunction doption
                		else
	                	echo 'You did not pick a valid choice. Select "a", "b", "c", or "d". '
				sleep 2
	                	exit
	       		fi
		fi
	fi
fi
