#!/bin/bash
#
# -------------------------------------- Description ---------------------------------------------------
#
# Monitoring Docker CPU / MEM / Network / Status
# Usage example :
# ./check_docker.sh -n <container name> -c <PERC_WARNING_CPU>,<PERC_CRITCAL_CPU> \
# -m <PERC_WARNING_MEM>,<PERC_CRITICAL_MEM> \
# -N <WARNING_NET_RX,WARNING_NET_TX,CRITCAL_NET_RX,CRITCAL_NET_TX>
#
# ------------------------------------- Requierements --------------------------------------------------
#
# Please add nagios user in group Docker -> usermod -aG docker ${USER}
# If nagios have shell "/bin/false" -> chsh -s /bin/bash ${USER}
# Minimum Docker version -> 1.10.0
#
# ---------------------------------------- License -----------------------------------------------------
# 
# This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>. 
#
#----------------------------------------------------------------------------------------------------------

VERSION="Version 1.1"
AUTHOR="2017 by sysC0D"
STATE_OK=0
STATE_WARN=1
STATE_CRIT=2
STATE_UNKN=3

#
## HELP ##
#

function print_help {
        echo "Usage: ./check_docker_stats.sh [-v] [-h] [-n [-s -c -m -N]]
        -h, --help
        print this help message
        -v, --version
	print version program
	-n, --name
        name docker to check
        -c, --cpulimitperc PERC_WARNING_CPU,PERC_CRITCAL_CPU
        number in percent alert for CPU
        -m, --memlimitperc PERC_WARNING_MEM,PERC_CRITICAL_MEM
        number in percent alert for MEM usage
        -N, --ntwlimit WARNING_NET_RX,WARNING_NET_TX,CRITCAL_NET_RX,CRITCAL_NET_TX
        bandwidth (RX -> DL,TX -> UL) in kBps for docker selected
	-s, --status
	check if docker is alive"
	##SOON
	#-M, --memlimit=WARNING_MEM,CRITCAL_MEM
        #number in Byte for MEM Usage
}

#
## PRINT VERSION #
#

function print_version {
	echo "$VERSION $AUTHOR"
}

#
## Exist Docker ##
#

function ifexist () {
        local namedocker="$1"
        checkdocker=`docker ps --filter "name=$namedocker" | grep $namedocker`

        if [ ! -z "$checkdocker" ]
        then
                echo "true"
	fi
}

#
## GET SHORT ID ## 
#

function getshortiddocker () {
        local namedocker=$1

       	shortid=`docker ps | grep $namedocker | awk '{print $1}'`
        echo "$shortid"
}

#
## GET BANDWIDTH ##
#

function getrxtxdocker () {
        local instanceid=$1

        #Get Container ID
       	CID=`docker inspect --format='{{.Id}}' $instanceid`

        #Get RX-TX Virtual interface
        TASKS=/sys/fs/cgroup/devices/docker/$CID*/tasks
        PID=$(head -n 1 $TASKS)
        mkdir -p /var/run/netns
        ln -sf /proc/$PID/ns/net /var/run/netns/$CID
        VETH=`ip netns exec $CID netstat -i | grep "eth0" | awk '{print $4":"$8}'`

        echo "$VETH"
}

function getbandwidthdocker () {
	local instanceid=$1

	#Get RXTX
	rxtx1=$(getrxtxdocker $instanceid)
	sleep 1
	rxtx2=$(getrxtxdocker $instanceid)	
	
	#GET RBPS-TBPS
	R1=`echo "$rxtx1" | awk '{split($0,a,":"); print a[1]}'`
	T1=`echo "$rxtx1" | awk '{split($0,a,":"); print a[2]}'`
        R2=`echo "$rxtx2" | awk '{split($0,a,":"); print a[1]}'`
        T2=`echo "$rxtx2" | awk '{split($0,a,":"); print a[2]}'`
	RBPS=`expr $R2 - $R1`
	TBPS=`expr $T2 - $T1`

	#GET  RBPS-TBPS
        RKBPS=`expr $RBPS / 1024`
	TKBPS=`expr $TBPS / 1024`
	echo "${RKBPS},${TKBPS}"
}

#
## STATS Docker ## 
#

function getstats () {
        #CPUPerc - MemUsage - MemPerc - NetIO - BlockIO
        local typestats="$1"
	local cid="$2"
	if [[ "$valid_version" == "1" ]]
        then
                [ "$currentstats" == "" ] && currentstats=($(docker stats --no-stream \
                  $cid --format="{{.Container}} {{.CPUPerc}} {{.MemPerc}}"))
                case $1 in
                  CPUPerc) echo ${currentstats[1]} ;;
                  MemPerc) echo ${currentstats[2]} ;;
                esac
	else
		case "$typestats" in
  		      CPUPerc)
			currentstats=`docker stats --no-stream | grep $cid | awk '{print $2}'`
			;;
        	      MemPerc)
			currentstats=`docker stats --no-stream | grep $cid | awk '{print $8}'`
			;;
		      *)
            		echo "Unknown argument: $typestats"
            		exit $STATE_UNKN
            		;;
     		esac
		echo "${currentstats::-1}"
	fi	
}

#
## Function monitoring perc ##
#

function monitorperc () {
        local typestats="$1"
        local arg_limit="$2"
        local shortid="$3"
        formatreg='^[0-9.]{1,5},[0-9.]{1,5}$'

        if  [[ $arg_limit =~ $formatreg ]]
        then
                valcurrentp=$(getstats $typestats $shortid)
                vallimitwarn=`echo "$arg_limit" | awk '{split($0,a,","); print a[1]}'`
                vallimitcrit=`echo "$arg_limit" | awk '{split($0,a,","); print a[2]}'`
                valcurrent=${valcurrentp::-1}
                if (( $(echo "$valcurrent > $vallimitcrit" |bc -l) ))
                then
                        echo ", CRITICAL $typestats: $valcurrent"
                elif (( $(echo "$valcurrent > $vallimitwarn" |bc -l) ))
                then
                        echo ", WARNING $typestats: $valcurrent"
		else
			echo ", $typestats $valcurrentp"
		fi 
       else
                echo "Value $arg_limit malformed, please show --help"
       fi
}

#
## Function monitoring Network ##
#

function monitorbandwith () {
        #WARNING_NET_RX,WARNING_NET_TX,CRITCAL_NET_RX,CRITCAL_NET_TX
	local arg_limit="$1"
        local shortid="$2"
        formatregbd='^[0-9]+,[0-9]+,[0-9]+,[0-9]+$'

        if  [[ $arg_limit =~ $formatregbd ]]
        then
                valcurrentrxtx=$(getbandwidthdocker $shortid)
		valcurrentrx=`echo "$valcurrentrxtx" | awk '{split($0,a,","); print a[1]}'`
		valcurrenttx=`echo "$valcurrentrxtx" | awk '{split($0,a,","); print a[1]}'`

                vallimitwarnrx=`echo "$arg_limit" | awk '{split($0,a,","); print a[1]}'`
                vallimitwarntx=`echo "$arg_limit" | awk '{split($0,a,","); print a[2]}'`
		vallimitcritrx=`echo "$arg_limit" | awk '{split($0,a,","); print a[3]}'`
                vallimitcrittx=`echo "$arg_limit" | awk '{split($0,a,","); print a[4]}'`

		if [ "$valcurrentrx" -gt "$vallimitcritrx" ]
		then
			echo ", CRITICAL Network DL : ${valcurrentrx}kbps"
		elif [ "$valcurrentrx" -gt "$vallimitwarnrx" ]
		then
			echo ", WARNING Network DL : ${valcurrentrx}kbps"
		else
			echo ", DL ${valcurrentrx}kbps"
		fi

		if [ "$valcurrenttx" -gt "$vallimitcrittx" ]
                then
			echo ", CRITICAL $valcurrenttx"
                elif [ "$valcurrenttx" -gt "$vallimitwarntx" ]
		then
			echo ", WARNING $valcurrenttx"
                else
			echo ", UL ${valcurrentrx}kbps"
		fi
        else
                echo "Value $arg_limit malformed, please show --help"
        fi
}

#
## MAIN
#

arg_namedocker=""
arg_cpulimitperc=""
arg_memlimitperc=""
arg_memlimit=""
arg_ntwlimit=""
arg_checkstatus=""

while test -n "$1"; do
    case "$1" in
	-h|--help)
	    print_help
	    exit "$STATE_OK"
            ;;
	-v|--version)
            print_version
	    exit "$STATE_OK"
	    ;;
	-n|--name)
	    arg_namedocker=$2
	    shift
	    ;;
	-c|--cpulimitperc)
	    arg_cpulimitperc=$2
	    shift
	    ;;
	-m|--memlimitperc)
	    arg_memlimitperc=$2
	    shift
	    ;;
	-M|--memlimit)
	    arg_memlimit=$2
	    shift
	    ;;
	-N|--ntwlimit)
	    arg_ntwlimit=$2
	    shift
	    ;;
	-s|--status)
	    arg_checkstatus="true"
	    ;;
	*)
	    echo "Unknown argument: $1"
	    print_help
	    exit $STATE_UNKN
	    ;;
     esac
     shift
done

#Check version docker
valid_version=0
version_docker=`docker --version | awk '{split($0,a,","); print a[1]}' | sed "s/Docker version //g"`
major_param=`echo "$version_docker" | awk '{split($0,a,"."); print a[1]}'`
minor_param=`echo "$version_docker" | awk '{split($0,a,"."); print a[2]}'`
if [ "$major_param" -ge "17" ]; then
	valid_version=1
elif [ "$major_param" -ge "1" ] && [ "$minor_param" -ge "13" ]; then
	valid_version=1
elif [ "$major_param" -ge "1" ] && [ "$minor_param" -ge "10" ]
then
	valid_version=0
elif [ "$major_param" -ge "1" ]
then
        valid_version=1
else
	echo "Docker version must be higher 1.10.0 for use this plugin"
	exit $STATE_UNKN
fi

if [ ! -z $arg_namedocker ]
then
	existdocker=$(ifexist $arg_namedocker)
	if [[ $existdocker == "true" ]]
	then 
		shortid=$(getshortiddocker $arg_namedocker)
	
		statscpu="CPUPerc"
		statsmemu="MemUsage"
		statsmem="MemPerc"
	
		valstatus=""
		valcpup=""
		valmemp=""
		valnet=""		

		if [[ $arg_checkstatus == "true" ]]
                then
                        statusdocker=`docker ps --filter status=running | grep $shortid`
			if [[ $statusdocker == *"$arg_namedocker" ]]
                        then
                            	valstatus=", running"    
			else
				echo "$arg_namedocker not running"
                                exit $STATE_CRIT
                        fi
                fi
		
		if [ ! -z $arg_cpulimitperc ] 
		then	
			valcpup=`echo "$(monitorperc $statscpu $arg_cpulimitperc $shortid)"`
		fi

		if [ ! -z $arg_memlimitperc ]
                then
                	valmemp=`echo "$(monitorperc $statsmem $arg_memlimitperc $shortid)"`
		fi
		
		if [ ! -z $arg_ntwlimit ]
                then
                	valnet=`echo "$(monitorbandwith $arg_ntwlimit $shortid)"`
		fi
	else
		echo "Docker $arg_namedocker not running or not exist"
		exit $STATE_UNKN
	fi
	
	valcheck=${valcpup}${valmemp}${valnet}
        if [[ $valcheck == *"CRITICAL"* ]]
	then 
        	echo "${arg_namedocker}${valcheck}"
                exit $STATE_CRIT
        elif [[ $valcheck == *"WARNING"* ]]
	then
		echo "${arg_namedocker}${valcheck}"
		exit $STATE_WARN
	elif [[ $valcheck == *"--help"* ]]
	then	
		echo "$arg_namedocke UNKNOW - Please show --help"
    		exit $STATE_UNKN
	else
		echo "$arg_namedocker OK ${valstatus}${valcheck}"
		exit $STATE_OK
	fi
else
	echo "Docker Name required, please show --help"
	exit $STATE_UNKN
fi
