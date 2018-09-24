#!/bin/bash

_START=$(expr $(date +%s%N) / 1000)

function _get_vif_value {
	vif --get $1|grep -o -E "${2}:[0-9]{0,99}"|sed -e "s/${2}://g" &
}

declare -A _VIFLIST
declare -A _VIFNAME
declare -A _CONTRAILCOUNTS
declare -A _LINUXCOUNTS
declare -A _KVMCOUNTS

_WAITSECONDS=300

_DEFAULT=( vhost0 bond1 eno50 ens1f1 )
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]] || [[ "$1" == "?" ]]; then
	echo "By default, pull stats from all interfaces/tap/vif using input source any running VM"
	echo "Usage: $0 [<interface>] [<interface>] [<interface>] [...]"
	exit 1
elif [[ "$@" == "" ]]; then
	_VIFTOPROCESS=("${_DEFAULT[@]}")
	# Pull TAP from KVM using hardcoded tap interface name as per OpenStack way of working
	for _ALLTAP in $(virsh list|awk '/running/ {print $2}'|xargs -n1 virsh domiflist 2>/dev/null|awk '/tap/ {print $1}' || true )
	do
		_VIFTOPROCESS+=("${_ALLTAP}")
	done
else
	_VIFTOPROCESS=("${_DEFAULT[@]}")
	_VIFTOPROCESS+=("$@")
fi

# Pull VIF from Contrail using hardcoded vif0/
_VIFCOUNT=0
for (( i=0 ; i<"${#_VIFTOPROCESS[@]}" ; i++ ))
do
	if [[ "$(vif --list|grep ${_VIFTOPROCESS[$i]}|awk '{print $1}'|sed -e "s|vif0/||g")" != "" ]]; then
		_VIFLIST[${_VIFCOUNT}]=$(vif --list|grep ${_VIFTOPROCESS[$i]}|awk '{print $1}'|sed -e "s|vif0/||g")
		_VIFNAME[${_VIFCOUNT}]="${_VIFTOPROCESS[$i]}"
		_VIFCOUNT=$((_VIFCOUNT+1))
	fi
done
# Pull VIF Parents from Contrail using hardcoded vif0/
for (( i=0 ; i<"${#_VIFLIST[@]}" ; i++ ))
do
	_TAPParent=$(vif --list|grep "Parent:vif0/${_VIFLIST[$i]}"|wc -l)
	if [[ "${_TAPParents}" != "0" ]]; then
		for _PARENT in $(vif --list|grep "Parent:vif0/${_VIFLIST[$i]}"|awk '{print $1}'|sed -e "s|vif0/||g")
		do
			_VIFLIST[${_VIFCOUNT}]=${_PARENT}
			_VIFNAME[${_VIFCOUNT}]=$(echo vif0/${_VIFLIST[$i]}\'s Parent)
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
	_CONTRAILCOUNTS[${_VIFCOUNT},0,3]=$(_get_vif_value ${_VIFID} "RX.*errors")
	_CONTRAILCOUNTS[${_VIFCOUNT},0,4]=$(_get_vif_value ${_VIFID} "TX packets")
	_CONTRAILCOUNTS[${_VIFCOUNT},0,5]=$(_get_vif_value ${_VIFID} "TX.*errors")
	_CONTRAILCOUNTS[${_VIFCOUNT},0,6]=$(_get_vif_value ${_VIFID} "Drops")
	_VIFCOUNT=$((_VIFCOUNT+1))
done

# Take Linux interfaces counters
_INTCOUNT=0
for _INTERFACE in ${_VIFTOPROCESS[@]}
do
	_LINUXCOUNTS[${_INTCOUNT},0,0]=${_INTERFACE}
	_LINUXCOUNTS[${_INTCOUNT},0,1]=$(cat /sys/class/net/${_INTERFACE}/statistics/rx_packets &)
	_LINUXCOUNTS[${_INTCOUNT},0,2]=$(cat /sys/class/net/${_INTERFACE}/statistics/tx_packets &)
	_LINUXCOUNTS[${_INTCOUNT},0,3]=$(cat /sys/class/net/${_INTERFACE}/statistics/rx_dropped &)
	_LINUXCOUNTS[${_INTCOUNT},0,4]=$(cat /sys/class/net/${_INTERFACE}/statistics/tx_dropped &)
	_LINUXCOUNTS[${_INTCOUNT},0,5]=$(cat /sys/class/net/${_INTERFACE}/statistics/rx_errors &)
	_LINUXCOUNTS[${_INTCOUNT},0,6]=$(cat /sys/class/net/${_INTERFACE}/statistics/tx_errors &)
	_INTCOUNT=$((_INTCOUNT+1))
done

# Take KVM TAP counters
_TAPCOUNT=0
for _VM in $( virsh list | awk '/running/ {print $2}')
do
	for _TAP in ${_VIFTOPROCESS[@]}
	do
		virsh domiflist ${_VM} | grep -q ${_TAP}
		if [[ "$?" == "0" ]]; then
			_KVMCOUNTS[${_TAPCOUNT},0,0]=${_VM}
                        _KVMCOUNTS[${_TAPCOUNT},0,1]=${_TAP}
			_KVMCOUNTS[${_TAPCOUNT},0,2]=$(virsh domifstat ${_VM} ${_TAP}|awk '/rx_packets/ {print $3}' &)
			_KVMCOUNTS[${_TAPCOUNT},0,3]=$(virsh domifstat ${_VM} ${_TAP}|awk '/tx_packets/ {print $3}' &)
			_KVMCOUNTS[${_TAPCOUNT},0,4]=$(virsh domifstat ${_VM} ${_TAP}|awk '/rx_drop/ {print $3}' &)
			_KVMCOUNTS[${_TAPCOUNT},0,5]=$(virsh domifstat ${_VM} ${_TAP}|awk '/tx_drop/ {print $3}' &)
			_KVMCOUNTS[${_TAPCOUNT},0,6]=$(virsh domifstat ${_VM} ${_TAP}|awk '/rx_errs/ {print $3}' &)
			_KVMCOUNTS[${_TAPCOUNT},0,7]=$(virsh domifstat ${_VM} ${_TAP}|awk '/tx_errs/ {print $3}' &)
			_TAPCOUNT=$((_TAPCOUNT+1))
		fi
	done
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
        _CONTRAILCOUNTS[${_VIFCOUNT},1,3]=$(_get_vif_value ${_VIFID} "RX.*errors")
        _CONTRAILCOUNTS[${_VIFCOUNT},1,4]=$(_get_vif_value ${_VIFID} "TX packets")
        _CONTRAILCOUNTS[${_VIFCOUNT},1,5]=$(_get_vif_value ${_VIFID} "TX.*errors")
        _CONTRAILCOUNTS[${_VIFCOUNT},1,6]=$(_get_vif_value ${_VIFID} "Drops")
        _VIFCOUNT=$((_VIFCOUNT+1))
done

# Take Linux interfaces counters after Wait Time
_INTCOUNT=0
for _INTERFACE in ${_VIFTOPROCESS[@]}
do
        _LINUXCOUNTS[${_INTCOUNT},1,0]=${_INTERFACE}
        _LINUXCOUNTS[${_INTCOUNT},1,1]=$(cat /sys/class/net/${_INTERFACE}/statistics/rx_packets &)
        _LINUXCOUNTS[${_INTCOUNT},1,2]=$(cat /sys/class/net/${_INTERFACE}/statistics/tx_packets &)
        _LINUXCOUNTS[${_INTCOUNT},1,3]=$(cat /sys/class/net/${_INTERFACE}/statistics/rx_dropped &)
        _LINUXCOUNTS[${_INTCOUNT},1,4]=$(cat /sys/class/net/${_INTERFACE}/statistics/tx_dropped &)
        _LINUXCOUNTS[${_INTCOUNT},1,5]=$(cat /sys/class/net/${_INTERFACE}/statistics/rx_errors &)
        _LINUXCOUNTS[${_INTCOUNT},1,6]=$(cat /sys/class/net/${_INTERFACE}/statistics/tx_errors &)
        _INTCOUNT=$((_INTCOUNT+1))
done

# Take KVM TAP counters after Wait Time
#_TAPCOUNT=0
#for _VM in $( virsh list | awk '/running/ {print $2}')
#do
#        for _TAP in ${_VIFTOPROCESS[@]}
#        do
#                virsh domiflist ${_VM} | grep -q ${_TAP}
#                if [[ "$?" == "0" ]]; then
#                        _KVMCOUNTS[${_TAPCOUNT},1,0]=${_VM}
#                        _KVMCOUNTS[${_TAPCOUNT},1,1]=${_TAP}
#                        _KVMCOUNTS[${_TAPCOUNT},1,2]=$(virsh domifstat ${_VM} ${_TAP}|awk '/rx_packets/ {print $3}' &)
#                        _KVMCOUNTS[${_TAPCOUNT},1,3]=$(virsh domifstat ${_VM} ${_TAP}|awk '/tx_packets/ {print $3}' &)
#                        _KVMCOUNTS[${_TAPCOUNT},1,4]=$(virsh domifstat ${_VM} ${_TAP}|awk '/rx_drop/ {print $3}' &)
#                        _KVMCOUNTS[${_TAPCOUNT},1,5]=$(virsh domifstat ${_VM} ${_TAP}|awk '/tx_drop/ {print $3}' &)
#                        _KVMCOUNTS[${_TAPCOUNT},1,6]=$(virsh domifstat ${_VM} ${_TAP}|awk '/rx_errs/ {print $3}' &)
#                        _KVMCOUNTS[${_TAPCOUNT},1,7]=$(virsh domifstat ${_VM} ${_TAP}|awk '/tx_errs/ {print $3}' &)
#                        _TAPCOUNT=$((_TAPCOUNT+1))
#                fi
#        done
#done

for (( i=0 ; i < ${_TAPCOUNT} ; i++ ))
do
	_KVMCOUNTS[${i},1,2]=$(virsh domifstat ${_KVMCOUNTS[${i},0,0]} ${_KVMCOUNTS[${i},0,1]}|awk '/rx_packets/ {print $3}' &)
	_KVMCOUNTS[${i},1,3]=$(virsh domifstat ${_KVMCOUNTS[${i},0,0]} ${_KVMCOUNTS[${i},0,1]}|awk '/tx_packets/ {print $3}' &)
	_KVMCOUNTS[${i},1,4]=$(virsh domifstat ${_KVMCOUNTS[${i},0,0]} ${_KVMCOUNTS[${i},0,1]}|awk '/rx_drop/ {print $3}' &)
	_KVMCOUNTS[${i},1,5]=$(virsh domifstat ${_KVMCOUNTS[${i},0,0]} ${_KVMCOUNTS[${i},0,1]}|awk '/tx_drop/ {print $3}' &)
	_KVMCOUNTS[${i},1,6]=$(virsh domifstat ${_KVMCOUNTS[${i},0,0]} ${_KVMCOUNTS[${i},0,1]}|awk '/rx_errs/ {print $3}' &)
	_KVMCOUNTS[${i},1,7]=$(virsh domifstat ${_KVMCOUNTS[${i},0,0]} ${_KVMCOUNTS[${i},0,1]}|awk '/tx_errs/ {print $3}' &)
done

# Finish all the threads to process the data
wait 

echo -e "\n########## Linux Interfaces STATS over ${_WAITSECONDS} seconds ##########"
printf "%23s" \
	"" \
        "Interface"
printf "%15s" \
        "TX" \
        "RX" \
        "TX Drops" \
        "RX Drops" \
        "TX Errors" \
        "RX Errors" \
        "TX PPS" \
        "RX PPS" \
        "TX Drops PPS" \
        "RX Drops PPS"
echo 
for (( i=0 ; i<${_INTCOUNT} ; i++ ))
do
	_TX=$(		bc <<< "scale=2; ${_LINUXCOUNTS[$i,1,2]}-${_LINUXCOUNTS[$i,0,2]}")
	_RX=$(		bc <<< "scale=2; ${_LINUXCOUNTS[$i,1,1]}-${_LINUXCOUNTS[$i,0,1]}")
        _TDROP=$(	bc <<< "scale=2; ${_LINUXCOUNTS[$i,1,4]}-${_LINUXCOUNTS[$i,0,4]}")
        _RDROP=$(	bc <<< "scale=2; ${_LINUXCOUNTS[$i,1,3]}-${_LINUXCOUNTS[$i,0,3]}")
	_TXE=$(		bc <<< "scale=2; ${_LINUXCOUNTS[$i,1,6]}-${_LINUXCOUNTS[$i,0,6]}")
	_RXE=$(		bc <<< "scale=2; ${_LINUXCOUNTS[$i,1,5]}-${_LINUXCOUNTS[$i,0,5]}")
	_TXS=$(		bc <<< "scale=2; ${_TX}/${_WAITSECONDS}")
	_RXS=$(		bc <<< "scale=2; ${_RX}/${_WAITSECONDS}")
	_TDROPPS=$(	bc <<< "scale=2; ${_TDROP}/${_WAITSECONDS}")
	_RDROPPS=$(	bc <<< "scale=2; ${_RDROP}/${_WAITSECONDS}")
        printf "%23s" \
		"" \
                "${_LINUXCOUNTS[$i,0,0]}"
        printf "%15s" \
                "${_TX}" \
                "${_RX}" \
                "${_TDROP}" \
                "${_RDROP}" \
                "${_TXE}" \
                "${_RXE}" \
                "${_TXS}" \
                "${_RXS}" \
                "${_TDROPPS}" \
                "${_RDROPPS}"
        echo 
done

echo -e "\n########## Contrail vRouter VIF STATS over ${_WAITSECONDS} seconds ############"
printf "%23s" \
	"VIF" \
	"TAP"
printf "%15s" \
	"TX" \
	"RX" \
	"Drops" \
	"TX Errors" \
	"RX Errors" \
	"TX PPS" \
	"RX PPS" \
	"TX & RX PPS" \
	"Drops PPS"
echo 
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
	printf "%23s" \
		"${_CONTRAILCOUNTS[$i,0,1]}" \
		"${_CONTRAILCOUNTS[$i,0,0]}"
	printf "%15s" \
		"${_TX}" \
		"${_RX}" \
		"${_DROP}" \
		"${_TXE}" \
		"${_RXE}" \
		"${_TXS}" \
		"${_RXS}" \
		"${_TXRXS}" \
		"${_DROPPS}"
	echo 
done

echo -e "\n########## KVM TAP STATS over ${_WAITSECONDS} seconds ##########"
printf "%23s" \
	"VM" \
        "TAP"
printf "%15s" \
        "TX" \
        "RX" \
        "TX Drops" \
        "RX Drops" \
        "TX Errors" \
        "RX Errors" \
        "TX PPS" \
        "RX PPS" \
        "TX Drops PPS" \
        "RX Drops PPS"
echo 
for (( i=0 ; i<${_TAPCOUNT} ; i++ ))
do
	_NAME=$(	virsh dumpxml ${_KVMCOUNTS[$i,0,0]}|grep nova:name|sed -e 's/<[^>]*>//g' -e 's/  //g')
        _TX=$(		bc <<< "scale=2; ${_KVMCOUNTS[$i,1,3]}-${_KVMCOUNTS[$i,0,3]}")
        _RX=$(		bc <<< "scale=2; ${_KVMCOUNTS[$i,1,2]}-${_KVMCOUNTS[$i,0,2]}")
        _TXE=$(		bc <<< "scale=2; ${_KVMCOUNTS[$i,1,6]}-${_KVMCOUNTS[$i,0,6]}")
        _RXE=$(		bc <<< "scale=2; ${_KVMCOUNTS[$i,1,5]}-${_KVMCOUNTS[$i,0,5]}")
        _TDROP=$(	bc <<< "scale=2; ${_KVMCOUNTS[$i,1,5]}-${_KVMCOUNTS[$i,0,5]}")
        _RDROP=$(	bc <<< "scale=2; ${_KVMCOUNTS[$i,1,4]}-${_KVMCOUNTS[$i,0,4]}")
        _TXS=$(		bc <<< "scale=2; ${_TX}/${_WAITSECONDS}")
        _RXS=$(		bc <<< "scale=2; ${_RX}/${_WAITSECONDS}")
        _TDROPPS=$(	bc <<< "scale=2; ${_TDROP}/${_WAITSECONDS}")
        _RDROPPS=$(	bc <<< "scale=2; ${_RDROP}/${_WAITSECONDS}")
        printf "%23s" \
                "${_NAME}" \
                "${_KVMCOUNTS[$i,0,1]}"
        printf "%15s" \
                "${_TX}" \
                "${_RX}" \
                "${_TDROP}" \
                "${_RDROP}" \
                "${_TXE}" \
                "${_RXE}" \
                "${_TXS}" \
                "${_RXS}" \
                "${_TDROPPS}" \
                "${_RDROPPS}"
        echo 
done

echo 
exit 0
