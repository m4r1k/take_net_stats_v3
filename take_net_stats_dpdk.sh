#!/bin/bash

_START=$(expr $(date +%s%N) / 1000)

function _get_vif_value {
	vif --get $1|grep -o -E "${2}:[0-9]{0,99}"|sed -e "s/${2}://g" &
}

function _get_vif_core_value {
	vif --get $1 --core $2|grep -o -E "${3}:[0-9]{0,99}"|sed -e "s/${3}://g" &
}

declare -A _VIFLIST
declare -A _VIFNAME
declare -A _CONTRAILCOUNTS
declare -A _CONTRAILCOUNTSCORE

_WAITSECONDS=300

# Define log file
if [[ "$1" == "-l" ]]; then
	_LOG=$2'/'$3
else
	_LOG="/tmp/_net_stats"
fi
rm -f ${_LOG}

# Pull vRouter Cores in BIN format
_MASK=$(cat /etc/contrail/supervisord_vrouter_files/contrail-vrouter-dpdk.ini | grep -v "^#"| awk -F "x| " '/taskset/{print $3}')

# Convert BIN to DEC vRouter cores
_NB_CORES=$(echo $(echo "obase=2; ibase=16; ${_MASK}" | bc ) | sed 's/./&\n/g' | awk '{s+=$1} END {printf "%.0f\n", s}')

# Pull TAP from KVM using hardcoded tap interface name as per OpenStack way of working
for _ALLTAP in $(sudo virsh list|awk '/running/ {print $2}'|xargs -n1 sudo virsh dumpxml 2>/dev/null|awk -F"[_|']" '/tap/ {print $6}' || true )
do
	_VIFTOPROCESS+=("${_ALLTAP}")
done

# Pull VIF0/0 that is the vRouter Bond VIF
_VIFLIST[0]=0
_VIFNAME[0]=vrouter_bond

# Pull VIF from Contrail using hardcoded vif0/ prefix
_VIFCOUNT=1
for (( i=0 ; i<"${#_VIFTOPROCESS[@]}" ; i++ ))
do
	if [[ "$(vif --list|grep ${_VIFTOPROCESS[$i]}|awk '{print $1}'|sed -e "s|vif0/||g")" != "" ]]; then
		_VIFLIST[${_VIFCOUNT}]=$(vif --list|grep ${_VIFTOPROCESS[$i]}|awk '{print $1}'|sed -e "s|vif0/||g")
		_VIFNAME[${_VIFCOUNT}]="${_VIFTOPROCESS[$i]}"
		_VIFCOUNT=$((_VIFCOUNT+1))
	fi
done

# Pull VIF Parents from Contrail using hardcoded vif0/ prefix
_NB_VIF="${#_VIFLIST[@]}"
for (( i=0 ; i<${_NB_VIF} ; i++ ))
do
	_TAPParents=$(vif --list|grep -E "Parent:vif0/${_VIFLIST[$i]}$"|wc -l)
	if [[ "${_TAPParents}" != "0" ]]; then
		for _PARENT in $(vif --list|grep "Parent:vif0/${_VIFLIST[$i]}"|awk '{print $1}'|sed -e "s|vif0/||g")
		do
			_VIFLIST[${_VIFCOUNT}]=${_PARENT}
			_VIFNAME[${_VIFCOUNT}]=$(echo vif0/${_VIFLIST[$i]})
			_VIFCOUNT=$((_VIFCOUNT+1))
		done
	fi
done

# Take VIF and VIF Parents counters
_VIFCOUNT=0
for (( i=0 ; i<"${#_VIFLIST[@]}" ; i++ ))
do
	_VIFID=${_VIFLIST[$i]}
	_CONTRAILCOUNTS[${_VIFCOUNT},0,0]=$(echo ${_VIFNAME[${_VIFCOUNT}]})
	_CONTRAILCOUNTS[${_VIFCOUNT},0,1]=$(echo vif0/${_VIFID})
	_CONTRAILCOUNTS[${_VIFCOUNT},0,2]=$(_get_vif_value ${_VIFID} "RX packets")
	_CONTRAILCOUNTS[${_VIFCOUNT},0,3]=$(_get_vif_value ${_VIFID} "RX packets.*errors")
	_CONTRAILCOUNTS[${_VIFCOUNT},0,4]=$(_get_vif_value ${_VIFID} "TX packets")
	_CONTRAILCOUNTS[${_VIFCOUNT},0,5]=$(_get_vif_value ${_VIFID} "TX packets.*errors")
	_CONTRAILCOUNTS[${_VIFCOUNT},0,6]=$(_get_vif_value ${_VIFID} "Drops")
	_CONTRAILCOUNTS[${_VIFCOUNT},0,7]=$(_get_vif_value ${_VIFID} "RX port.*syscalls")
	_CONTRAILCOUNTS[${_VIFCOUNT},0,8]=$(_get_vif_value ${_VIFID} "TX port.*syscalls")
	_CONTRAILCOUNTS[${_VIFCOUNT},0,9]=$(_get_vif_value ${_VIFID} "RX queue.*errors")
	_CONTRAILCOUNTS[${_VIFCOUNT},0,10]=$(_get_vif_value ${_VIFID} "RX port.*errors")
	_CONTRAILCOUNTS[${_VIFCOUNT},0,11]=$(_get_vif_value ${_VIFID} "TX port.*errors")
	_VIFCOUNT=$((_VIFCOUNT+1))
done

# Take VIF and VIF Parents counters per CORE
_VIFCOUNT=0
for (( i=0 ; i<"${#_VIFLIST[@]}" ; i++ ))
do
	for (( j=0 ; j<"${_NB_CORES}" ; j++ ))
	do
		_VIFID=${_VIFLIST[$i]}
		_CONTRAILCOUNTSCORE[${_VIFCOUNT},0,$j,0]=$(echo ${_VIFNAME[${_VIFCOUNT}]})
		_CONTRAILCOUNTSCORE[${_VIFCOUNT},0,$j,1]=$(echo vif0/${_VIFID})
		_CONTRAILCOUNTSCORE[${_VIFCOUNT},0,$j,2]=$(_get_vif_core_value ${_VIFID} $(($j+10)) "RX packets")
		_CONTRAILCOUNTSCORE[${_VIFCOUNT},0,$j,3]=$(_get_vif_core_value ${_VIFID} $(($j+10)) "RX packets.*errors")
		_CONTRAILCOUNTSCORE[${_VIFCOUNT},0,$j,4]=$(_get_vif_core_value ${_VIFID} $(($j+10)) "TX packets")
		_CONTRAILCOUNTSCORE[${_VIFCOUNT},0,$j,5]=$(_get_vif_core_value ${_VIFID} $(($j+10)) "TX packets.*errors")
		_CONTRAILCOUNTSCORE[${_VIFCOUNT},0,$j,6]=$(_get_vif_core_value ${_VIFID} $(($j+10)) "Drops")
		_CONTRAILCOUNTSCORE[${_VIFCOUNT},0,$j,7]=$(_get_vif_core_value ${_VIFID} $(($j+10)) "RX port.*syscalls")
		_CONTRAILCOUNTSCORE[${_VIFCOUNT},0,$j,8]=$(_get_vif_core_value ${_VIFID} $(($j+10)) "TX port.*syscalls")
		_CONTRAILCOUNTSCORE[${_VIFCOUNT},0,$j,9]=$(_get_vif_core_value ${_VIFID} $(($j+10)) "RX queue.*errors")
		_CONTRAILCOUNTSCORE[${_VIFCOUNT},0,$j,10]=$(_get_vif_core_value ${_VIFID} $(($j+10)) "RX port.*errors")
		_CONTRAILCOUNTSCORE[${_VIFCOUNT},0,$j,11]=$(_get_vif_core_value ${_VIFID} $(($j+10)) "TX port.*errors")
	done
	_VIFCOUNT=$((_VIFCOUNT+1))
done

_END=$(expr $(date +%s%N) / 1000)
usleep $(bc <<< "(${_WAITSECONDS} * 1000 * 1000) - (${_END} - ${_START})")

if [[ "${_WAITSECONDS}" == "0" ]]; then
	_WAITSECONDS=1
fi

# Take VIF and VIF Parents counters after Wait Time
_VIFCOUNT=0
for (( i=0 ; i<"${#_VIFLIST[@]}" ; i++ ))
do
	_VIFID=${_VIFLIST[$i]}
	_CONTRAILCOUNTS[${_VIFCOUNT},1,0]=$(echo ${_VIFNAME[${_VIFCOUNT}]})
	_CONTRAILCOUNTS[${_VIFCOUNT},1,1]=$(echo vif0/${_VIFID})
	_CONTRAILCOUNTS[${_VIFCOUNT},1,2]=$(_get_vif_value ${_VIFID} "RX packets")
	_CONTRAILCOUNTS[${_VIFCOUNT},1,3]=$(_get_vif_value ${_VIFID} "RX packets.*errors")
	_CONTRAILCOUNTS[${_VIFCOUNT},1,4]=$(_get_vif_value ${_VIFID} "TX packets")
	_CONTRAILCOUNTS[${_VIFCOUNT},1,5]=$(_get_vif_value ${_VIFID} "TX packets.*errors")
	_CONTRAILCOUNTS[${_VIFCOUNT},1,6]=$(_get_vif_value ${_VIFID} "Drops")
	_CONTRAILCOUNTS[${_VIFCOUNT},1,7]=$(_get_vif_value ${_VIFID} "RX port.*syscalls")
	_CONTRAILCOUNTS[${_VIFCOUNT},1,8]=$(_get_vif_value ${_VIFID} "TX port.*syscalls")
	_CONTRAILCOUNTS[${_VIFCOUNT},1,9]=$(_get_vif_value ${_VIFID} "RX queue.*errors")
	_CONTRAILCOUNTS[${_VIFCOUNT},1,10]=$(_get_vif_value ${_VIFID} "RX port.*errors")
	_CONTRAILCOUNTS[${_VIFCOUNT},1,11]=$(_get_vif_value ${_VIFID} "TX port.*errors")

	_VIFCOUNT=$((_VIFCOUNT+1))
done

# Take VIF and VIF Parents counters per CORE after Wait Time
_VIFCOUNT=0
for (( i=0 ; i<"${#_VIFLIST[@]}" ; i++ ))
do
	for (( j=0 ; j<"${_NB_CORES}" ; j++ ))
	do
		_VIFID=${_VIFLIST[$i]}
		_CONTRAILCOUNTSCORE[${_VIFCOUNT},1,$j,0]=$(echo ${_VIFNAME[${_VIFCOUNT}]})
		_CONTRAILCOUNTSCORE[${_VIFCOUNT},1,$j,1]=$(echo vif0/${_VIFID})
		_CONTRAILCOUNTSCORE[${_VIFCOUNT},1,$j,2]=$(_get_vif_core_value ${_VIFID} $(($j+10)) "RX packets")
		_CONTRAILCOUNTSCORE[${_VIFCOUNT},1,$j,3]=$(_get_vif_core_value ${_VIFID} $(($j+10)) "RX packets.*errors")
		_CONTRAILCOUNTSCORE[${_VIFCOUNT},1,$j,4]=$(_get_vif_core_value ${_VIFID} $(($j+10)) "TX packets")
		_CONTRAILCOUNTSCORE[${_VIFCOUNT},1,$j,5]=$(_get_vif_core_value ${_VIFID} $(($j+10)) "TX packets.*errors")
		_CONTRAILCOUNTSCORE[${_VIFCOUNT},1,$j,6]=$(_get_vif_core_value ${_VIFID} $(($j+10)) "Drops")
		_CONTRAILCOUNTSCORE[${_VIFCOUNT},1,$j,7]=$(_get_vif_core_value ${_VIFID} $(($j+10)) "RX port.*syscalls")
		_CONTRAILCOUNTSCORE[${_VIFCOUNT},1,$j,8]=$(_get_vif_core_value ${_VIFID} $(($j+10)) "TX port.*syscalls")
		_CONTRAILCOUNTSCORE[${_VIFCOUNT},1,$j,9]=$(_get_vif_core_value ${_VIFID} $(($j+10)) "RX queue.*errors")
		_CONTRAILCOUNTSCORE[${_VIFCOUNT},1,$j,10]=$(_get_vif_core_value ${_VIFID} $(($j+10)) "RX port.*errors")
		_CONTRAILCOUNTSCORE[${_VIFCOUNT},1,$j,11]=$(_get_vif_core_value ${_VIFID} $(($j+10)) "TX port.*errors")
	done
	_VIFCOUNT=$((_VIFCOUNT+1))
done

# Finish all threads before processing the data
wait

echo -e "########## Contrail vRouter VIF STATS over ${_WAITSECONDS} seconds ############" >> ${_LOG} 2>&1
printf "%18s" \
	"VIF" \
	"TAP" >> ${_LOG} 2>&1
printf "%14s" \
	"TX" \
	"RX" \
	"Drops" \
	"TX Errors" \
	"RX Errors" \
	"TX PPS" \
	"RX PPS" \
	"TX & RX PPS" \
	"Drops PPS" \
	"TX port sys" \
	"RX port sys" \
	"TX port err" \
	"RX port err" \
	"RX queue Err" >> ${_LOG} 2>&1
echo >> ${_LOG} 2>&1
for (( i=0 ; i<${_VIFCOUNT} ; i++ ))
do
	_TX=$(		bc <<< "scale=2; ${_CONTRAILCOUNTS[$i,1,4]}-${_CONTRAILCOUNTS[$i,0,4]}")
	_RX=$(		bc <<< "scale=2; ${_CONTRAILCOUNTS[$i,1,2]}-${_CONTRAILCOUNTS[$i,0,2]}")
	_DROP=$(	bc <<< "scale=2; ${_CONTRAILCOUNTS[$i,1,6]}-${_CONTRAILCOUNTS[$i,0,6]}")
	_TXE=$(		bc <<< "scale=2; ${_CONTRAILCOUNTS[$i,1,5]}-${_CONTRAILCOUNTS[$i,0,5]}")
	_RXE=$(		bc <<< "scale=2; ${_CONTRAILCOUNTS[$i,1,3]}-${_CONTRAILCOUNTS[$i,0,3]}")
	_TXS=$(		bc <<< "scale=2; ${_TX}/${_WAITSECONDS}")
	_RXS=$(		bc <<< "scale=2; ${_RX}/${_WAITSECONDS}")
	_TXRXS=$(	bc <<< "scale=2; ${_TXS}+${_RXS}")
	_DROPPS=$(	bc <<< "scale=2; ${_DROP}/${_WAITSECONDS}")
	if [[ ${_CONTRAILCOUNTS[$i,1,7]} == "" ]] && [[ ${_CONTRAILCOUNTS[$i,0,7]} == "" ]]
	then
		_RXSYS=0
	else
		_RXSYS=$(       bc <<< "scale=2; ${_CONTRAILCOUNTS[$i,1,7]}-${_CONTRAILCOUNTS[$i,0,7]}")
	fi
	if [[ ${_CONTRAILCOUNTS[$i,1,8]} == "" ]] &&  [[ ${_CONTRAILCOUNTS[$i,0,8]} == "" ]]
	then
		_TXSYS=0
	else
		_TXSYS=$(       bc <<< "scale=2; ${_CONTRAILCOUNTS[$i,1,8]}-${_CONTRAILCOUNTS[$i,0,8]}")
	fi
	
	if [[ ${_CONTRAILCOUNTS[$i,1,10]} == "" ]] && [[ ${_CONTRAILCOUNTS[$i,0,10]} == "" ]]
	then
		_RXPERR=0
	else
		_RXPERR=$(       bc <<< "scale=2; ${_CONTRAILCOUNTS[$i,1,10]}-${_CONTRAILCOUNTS[$i,0,10]}")
	fi
	if [[ ${_CONTRAILCOUNTS[$i,1,11]} == "" ]] &&  [[ ${_CONTRAILCOUNTS[$i,0,11]} == "" ]]
	then
		_TXPERR=0
	else
		_TXPERR=$(       bc <<< "scale=2; ${_CONTRAILCOUNTS[$i,1,11]}-${_CONTRAILCOUNTS[$i,0,11]}")
	fi

	if [[ ${_CONTRAILCOUNTS[$i,1,9]} == "" ]] && [[ ${_CONTRAILCOUNTS[$i,0,9]} == "" ]]
	then
		_RXQE=0
	else
		_RXQE=$(       bc <<< "scale=2; ${_CONTRAILCOUNTS[$i,1,9]}-${_CONTRAILCOUNTS[$i,0,9]}")
	fi

	printf "%18s" \
		"${_CONTRAILCOUNTS[$i,0,1]}" \
		"${_CONTRAILCOUNTS[$i,0,0]}" >> ${_LOG} 2>&1
	printf "%14s" \
		"${_TX}" \
		"${_RX}" \
		"${_DROP}" \
		"${_TXE}" \
		"${_RXE}" \
		"${_TXS}" \
		"${_RXS}" \
		"${_TXRXS}" \
		"${_DROPPS}" \
		"${_TXSYS}" \
		"${_RXSYS}" \
		"${_TXPERR}" \
		"${_RXPERR}" \
		"${_RXQE}" >> ${_LOG} 2>&1
	echo >> ${_LOG} 2>&1
done

echo >> ${_LOG} 2>&1

echo -e "\n########## Contrail vRouter VIF STATS per CORE over ${_WAITSECONDS} seconds ############"  >> ${_LOG} 2>&1
echo  >> ${_LOG} 2>&1
echo -e "\n########## RX packets ############" >> ${_LOG} 2>&1
printf "%18s" \
	"VIF" \
	"TAP" >> ${_LOG} 2>&1
for (( j=0 ; j<"${_NB_CORES}" ; j++ ))
do
printf "%14s" \
	"CORE$(($j+10))"  >> ${_LOG} 2>&1
done
echo  >> ${_LOG} 2>&1
for (( i=0 ; i<${_VIFCOUNT} ; i++ ))
do
	printf "%18s" \
		"${_CONTRAILCOUNTSCORE[$i,0,0,1]}" \
		"${_CONTRAILCOUNTSCORE[$i,0,0,0]}"  >> ${_LOG} 2>&1
	for (( j=0 ; j<${_NB_CORES} ; j++ ))
	do
		if [[ ${_CONTRAILCOUNTSCORE[$i,1,$j,2]} == "" ]] && [[ ${_CONTRAILCOUNTSCORE[$i,0,$j,2]} == "" ]]
		then
			_RX=0
		else
			_RX=$(	 bc <<< "scale=2; ${_CONTRAILCOUNTSCORE[$i,1,$j,2]}-${_CONTRAILCOUNTSCORE[$i,0,$j,2]}")
		fi
		printf "%14s" "${_RX}"  >> ${_LOG} 2>&1
	done
	echo >> ${_LOG} 2>&1
done

echo  >> ${_LOG} 2>&1
echo -e "\n########## RX packets errors ############"  >> ${_LOG} 2>&1
printf "%18s" \
	"VIF" \
	"TAP"  >> ${_LOG} 2>&1
for (( j=0 ; j<"${_NB_CORES}" ; j++ ))
do
printf "%14s" \
	"CORE$(($j+10))"  >> ${_LOG} 2>&1
done
echo  >> ${_LOG} 2>&1
for (( i=0 ; i<${_VIFCOUNT} ; i++ ))
do
	printf "%18s" \
		"${_CONTRAILCOUNTSCORE[$i,0,0,1]}" \
		"${_CONTRAILCOUNTSCORE[$i,0,0,0]}" >> ${_LOG} 2>&1
	for (( j=0 ; j<${_NB_CORES} ; j++ ))
	do
		if [[ ${_CONTRAILCOUNTSCORE[$i,1,$j,3]} == "" ]] && [[ ${_CONTRAILCOUNTSCORE[$i,0,$j,3]} == "" ]]
		then
			_RXE=0
		else
			_RXE=$(	 bc <<< "scale=2; ${_CONTRAILCOUNTSCORE[$i,1,$j,3]}-${_CONTRAILCOUNTSCORE[$i,0,$j,3]}")
		fi
		printf "%14s" "${_RXE}"  >> ${_LOG} 2>&1
	done
	echo >> ${_LOG} 2>&1
done

echo >> ${_LOG} 2>&1
echo -e "\n########## TX packets ############" >> ${_LOG} 2>&1
printf "%18s" \
	"VIF" \
	"TAP" >> ${_LOG} 2>&1
for (( j=0 ; j<"${_NB_CORES}" ; j++ ))
do
printf "%14s" \
	"CORE$(($j+10))"  >> ${_LOG} 2>&1
done
echo  >> ${_LOG} 2>&1

for (( i=0 ; i<${_VIFCOUNT} ; i++ ))
do
	printf "%18s" \
		"${_CONTRAILCOUNTSCORE[$i,0,0,1]}" \
		"${_CONTRAILCOUNTSCORE[$i,0,0,0]}" >> ${_LOG} 2>&1
	for (( j=0 ; j<${_NB_CORES} ; j++ ))
	do
		if [[ ${_CONTRAILCOUNTSCORE[$i,1,$j,4]} == "" ]] && [[ ${_CONTRAILCOUNTSCORE[$i,0,$j,4]} == "" ]]
		then
			_TX=0
		else
			_TX=$(	 bc <<< "scale=2; ${_CONTRAILCOUNTSCORE[$i,1,$j,4]}-${_CONTRAILCOUNTSCORE[$i,0,$j,4]}")
		fi
		printf "%14s" "${_TX}" >> ${_LOG} 2>&1
	done
	echo  >> ${_LOG} 2>&1
done

echo  >> ${_LOG} 2>&1
echo -e "\n########## TX packets errors ############" >> ${_LOG} 2>&1
printf "%18s" \
	"VIF" \
	"TAP" >> ${_LOG} 2>&1
for (( j=0 ; j<"${_NB_CORES}" ; j++ ))
do
printf "%14s" \
	"CORE$(($j+10))"  >> ${_LOG} 2>&1
done
echo  >> ${_LOG} 2>&1
for (( i=0 ; i<${_VIFCOUNT} ; i++ ))
do
	printf "%18s" \
		"${_CONTRAILCOUNTSCORE[$i,0,0,1]}" \
		"${_CONTRAILCOUNTSCORE[$i,0,0,0]}" >> ${_LOG} 2>&1
	for (( j=0 ; j<${_NB_CORES} ; j++ ))
	do
		if [[ ${_CONTRAILCOUNTSCORE[$i,1,$j,5]} == "" ]] && [[ ${_CONTRAILCOUNTSCORE[$i,0,$j,5]} == "" ]]
		then
			_TXE=0
		else
			_TXE=$(	 bc <<< "scale=2; ${_CONTRAILCOUNTSCORE[$i,1,$j,5]}-${_CONTRAILCOUNTSCORE[$i,0,$j,5]}")
		fi
		printf "%14s" "${_TXE}" >> ${_LOG} 2>&1
	done
	echo >> ${_LOG} 2>&1
done

echo >> ${_LOG} 2>&1
echo -e "\n########## RX syscalls ############" >> ${_LOG} 2>&1
printf "%18s" \
	"VIF" \
	"TAP" >> ${_LOG} 2>&1
for (( j=0 ; j<"${_NB_CORES}" ; j++ ))
do
printf "%14s" \
	"CORE$(($j+10))"  >> ${_LOG} 2>&1
done
echo  >> ${_LOG} 2>&1
for (( i=0 ; i<${_VIFCOUNT} ; i++ ))
do
	printf "%18s" \
		"${_CONTRAILCOUNTSCORE[$i,0,0,1]}" \
		"${_CONTRAILCOUNTSCORE[$i,0,0,0]}" >> ${_LOG} 2>&1
	for (( j=0 ; j<${_NB_CORES} ; j++ ))
	do
		if [[ ${_CONTRAILCOUNTSCORE[$i,1,$j,7]} == "" ]] && [[ ${_CONTRAILCOUNTSCORE[$i,0,$j,7]} == "" ]]
		then
			_RXSYS=0
		else
			_RXSYS=$(	 bc <<< "scale=2; ${_CONTRAILCOUNTSCORE[$i,1,$j,7]}-${_CONTRAILCOUNTSCORE[$i,0,$j,7]}")
		fi
		printf "%14s" "${_RXSYS}"  >> ${_LOG} 2>&1
	done
	echo >> ${_LOG} 2>&1
done

echo >> ${_LOG} 2>&1
echo -e "\n########## TX syscalls ############"  >> ${_LOG} 2>&1
printf "%18s" \
	"VIF" \
	"TAP" >> ${_LOG} 2>&1
for (( j=0 ; j<"${_NB_CORES}" ; j++ ))
do
printf "%14s" \
	"CORE$(($j+10))"  >> ${_LOG} 2>&1
done
echo  >> ${_LOG} 2>&1
for (( i=0 ; i<${_VIFCOUNT} ; i++ ))
do
	printf "%18s" \
		"${_CONTRAILCOUNTSCORE[$i,0,0,1]}" \
		"${_CONTRAILCOUNTSCORE[$i,0,0,0]}" >> ${_LOG} 2>&1
	for (( j=0 ; j<${_NB_CORES} ; j++ ))
	do
		if [[ ${_CONTRAILCOUNTSCORE[$i,1,$j,8]} == "" ]] && [[ ${_CONTRAILCOUNTSCORE[$i,0,$j,8]} == "" ]]
		then
			_TXSYS=0
		else
			_TXSYS=$(	 bc <<< "scale=2; ${_CONTRAILCOUNTSCORE[$i,1,$j,8]}-${_CONTRAILCOUNTSCORE[$i,0,$j,8]}")
		fi
		printf "%14s" "${_TXSYS}"  >> ${_LOG} 2>&1 
	done
	echo >> ${_LOG} 2>&1
done

echo >> ${_LOG} 2>&1
echo -e "\n########## RX port errors ############" >> ${_LOG} 2>&1
printf "%18s" \
	"VIF" \
	"TAP" >> ${_LOG} 2>&1
for (( j=0 ; j<"${_NB_CORES}" ; j++ ))
do
printf "%14s" \
	"CORE$(($j+10))"  >> ${_LOG} 2>&1
done
echo  >> ${_LOG} 2>&1
for (( i=0 ; i<${_VIFCOUNT} ; i++ ))
do
	printf "%18s" \
		"${_CONTRAILCOUNTSCORE[$i,0,0,1]}" \
		"${_CONTRAILCOUNTSCORE[$i,0,0,0]}" >> ${_LOG} 2>&1
	for (( j=0 ; j<${_NB_CORES} ; j++ ))
	do
		if [[ ${_CONTRAILCOUNTSCORE[$i,1,$j,10]} == "" ]] && [[ ${_CONTRAILCOUNTSCORE[$i,0,$j,10]} == "" ]]
		then
			_RXPERR=0
		else
			_RXPERR=$(	 bc <<< "scale=2; ${_CONTRAILCOUNTSCORE[$i,1,$j,10]}-${_CONTRAILCOUNTSCORE[$i,0,$j,10]}")
		fi
		printf "%14s" "${_RXPERR}"  >> ${_LOG} 2>&1
	done
	echo >> ${_LOG} 2>&1
done

echo >> ${_LOG} 2>&1
echo -e "\n########## TX port errors ############"  >> ${_LOG} 2>&1
printf "%18s" \
	"VIF" \
	"TAP" >> ${_LOG} 2>&1
for (( j=0 ; j<"${_NB_CORES}" ; j++ ))
do
printf "%14s" \
	"CORE$(($j+10))"  >> ${_LOG} 2>&1
done
echo  >> ${_LOG} 2>&1
for (( i=0 ; i<${_VIFCOUNT} ; i++ ))
do
	printf "%18s" \
		"${_CONTRAILCOUNTSCORE[$i,0,0,1]}" \
		"${_CONTRAILCOUNTSCORE[$i,0,0,0]}" >> ${_LOG} 2>&1
	for (( j=0 ; j<${_NB_CORES} ; j++ ))
	do
		if [[ ${_CONTRAILCOUNTSCORE[$i,1,$j,11]} == "" ]] && [[ ${_CONTRAILCOUNTSCORE[$i,0,$j,11]} == "" ]]
		then
			_TXPERR=0
		else
			_TXPERR=$(	 bc <<< "scale=2; ${_CONTRAILCOUNTSCORE[$i,1,$j,11]}-${_CONTRAILCOUNTSCORE[$i,0,$j,11]}")
		fi
		printf "%14s" "${_TXPERR}"  >> ${_LOG} 2>&1
	done
	echo >> ${_LOG} 2>&1
done

echo >> ${_LOG} 2>&1
echo -e "\n########## RX queue errors ############" >> ${_LOG} 2>&1
printf "%18s" \
	"VIF" \
	"TAP" >> ${_LOG} 2>&1
for (( j=0 ; j<"${_NB_CORES}" ; j++ ))
do
printf "%14s" \
	"CORE$(($j+10))"  >> ${_LOG} 2>&1
done
echo  >> ${_LOG} 2>&1
for (( i=0 ; i<${_VIFCOUNT} ; i++ ))
do
	printf "%18s" \
		"${_CONTRAILCOUNTSCORE[$i,0,0,1]}" \
		"${_CONTRAILCOUNTSCORE[$i,0,0,0]}" >> ${_LOG} 2>&1
	for (( j=0 ; j<${_NB_CORES} ; j++ ))
	do
		if [[ ${_CONTRAILCOUNTSCORE[$i,1,$j,9]} == "" ]] && [[ ${_CONTRAILCOUNTSCORE[$i,0,$j,9]} == "" ]]
		then
			_RXQE=0
		else
			_RXQE=$(	 bc <<< "scale=2; ${_CONTRAILCOUNTSCORE[$i,1,$j,9]}-${_CONTRAILCOUNTSCORE[$i,0,$j,9]}")
		fi
		printf "%14s" "${_RXQE}" >> ${_LOG} 2>&1
	done
	echo >> ${_LOG} 2>&1
done

cat ${_LOG}

exit 0
