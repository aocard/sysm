########################################################################################################
#                                                                                                      #
# Conky-like Linux (kernel dependant) system monitoring program,                                       #
# By Aria O. Cardoso                                                                                   #
# Please see README and LICENSE for more details.                                                      #
#                                                                                                      #
# Arguments:                                                                                           #
# --stealth: Hides sensitive info from output, including wifi name, channel, local IP, and MAC address #
# --gui: Enables a Zenity-based graphical interface                                                    #
# --amd: Toggles displaying AMD video card info. Warning, might break if one isn't installed.          #
# --nvidia: Toggles displaying Nvidia video card info. Warning, might break if one isn't installed.    #
#                                                                                                      #
########################################################################################################

# TODO:
# Add Intel gcard support


#!/bin/bash

# Sets program name [dev]
progname="sysm"

# Sets network monitoring command
watchy='ss -tp | grep -v FIN-WAIT | grep -v Recv-Q | grep -v LAST-ACK | sed -e '\''s/.*users:'\(\(\"'//'\'' -e '\''s/'\"'.*$//'\'' | sort | uniq'

# Network speed testing routine
spdtst(){
  interface=$(ip route|grep -v lxdbr0|grep -v gateway|head -n 1|awk '/default/ {print $5}') # Removes 'gateway' and 'br0' entries for lxd users
  sys_dir="/sys/class/net/${interface}/statistics"

  rxb=$(<${sys_dir}/rx_bytes)
  txb=$(<${sys_dir}/tx_bytes)
  sleep 1
  rxbn=$(<${sys_dir}/rx_bytes)
  txbn=$(<${sys_dir}/tx_bytes)

  rxdif=$(echo $(((rxbn - rxb) / 2)) )
  txdif=$(echo $(((txbn - txb) / 2)) )

  echo -e "Speed: $((rxdif / 2))B/s down, $((txdif / 2))B/s up"
}

export -f spdtst

# Main program
4ll(){

  # Variable setting
  if [[ -v gui_out ]]; then # If settings set via GUI, override cli params
    if [[ $gui_out == *"nvidia"* ]]; then
      nvidia=1
      else nvidia=0
    fi
    if [[ $gui_out == *"amd"* ]]; then
      amd=1
      else amd=0
    fi
    if [[ $gui_out == *"stealth"* ]]; then
      stealth=1
      else stealth=0
    fi
  else # If nothing set via gui, use cli parameters
    if [[ "$*" == *"--stealth"* ]]; then
      stealth=1
    fi
    if [[ "$*" == *"--amd"* ]]; then
      amd=1
    fi
    if [[ "$*" == *"--nvidia"* ]]; then
      nvidia=1
    fi
  fi

  echo &&\

	# Time, date, uptime
  echo "Time: $(date -u +%H:%M:%S) UTC, $(date +%H:%M:%S) here" &&\
  echo "Date: $(date +%m.%d.%Y" - "%A)" &&\
  echo "Uptime: $(uptime -p|awk '{for(i=2; i<=NF; i++) printf "%s",$i (i==NF?ORS:OFS)}')" &&\
  echo &&\

	# Battery level and status
  if [ -a /sys/class/power_supply/BAT0 ]; then
  nwbatstat=$(cat /sys/class/power_supply/BAT0/status); if [ "$nwbatstat" == "Unknown" ]; then nwbatstat=Stopped; fi; echo "Battery: $(cat /sys/class/power_supply/BAT0/capacity)%, $nwbatstat"
  else echo "No battery detected"
  fi &&\
  echo "AC Adapter: Connected" &&\
  #if [ $(cat /sys/class/power_supply/$(ls /sys/class/power_supply|grep -v BAT)/online) -eq 1 ]; then echo "AC Adapter: Connected"; else echo "AC Adapter: Disconnected"; fi &&\
  echo &&\

	##############
	# Networking #
	##############

  # Are we on wifi
  EsSiD=$(iwgetid -r); if [[ ! -z $EsSiD ]]; then
    if [[ $stealth -eq 1 ]]; then
			echo "Connected to ESSID=[REDACTED]"
		else
			echo "Connected to ESSID=$EsSiD"
		fi
  else 
    echo "Not connected to wifi"
  fi &&\

  # Are we on wired or wireless
  EsSiD=$(iwgetid -r); NWINT=$(ip route|grep -v lxdbr0|grep -v gateway-tor|awk '/default/ {print $5}')
  if [[ -z "$NWINT" && -z "$EsSiD" ]]; then
    echo "Not connected to network"
  elif [[ -z $EsSiD ]]; then
    echo "Connected to wired network"
  elif [[ $stealth -eq 1 ]]; then
		echo "on channel [REDACTED]"
	else
    echo "on channel $(iwgetid --channel --raw) ($(iwgetid --freq|sed -n 's/Frequency://p'|awk '{print $2, $3}'))"
  fi &&\

  # LAN ip address
  if [[ -z $(ip route|grep -v lxdbr0|grep -v gateway-tor) ]]; then
    echo "No IP address assigned"
	elif [[ $stealth -eq 1 ]]; then
		echo "Assigned as [REDACTED] on [REDACTED]"
  elif [[ $(ip route|grep -v lxdbr0|grep -v gateway-tor|awk '/default/ {print $5}'|wc -l) -eq 2 ]]; then
    echo "Assigned as $(ip route get 1|head -n 1|awk '{print $7;exit}') on $(ip route|grep -v lxdbr0|grep -v gateway-tor|head -n 1|awk '/default/ {print $5}')"
    echo "Assigned as $(ip route|grep -v lxdbr0|grep -v gateway-tor|tail -n 1|awk '{print $9;exit}') on $(ip route|grep -v lxdbr0|grep -v gateway-tor|tail -n 1|awk '{print $3}')"
  else
    echo "Assigned as $(ip route get 1|head -n 1|awk '{print $7;exit}') on $(ip route|grep -v lxdbr0|grep -v gateway-tor|awk '/default/ {print $5}')"
  fi &&\

  # MAC Address
  if [[ -z $(ip route|grep -v lxdbr0|grep -v gateway-tor) ]]; then
    echo "No network card in use"
	elif [[ $stealth -eq 1 ]]; then
		echo "MAC Address: [REDACTED]"
  elif [[ $(ip route|grep -v lxdbr0|grep -v gateway-tor|awk '/default/ {print $5}'|wc -l) -eq 2 ]]; then
    echo "MAC Address: $(cat /sys/class/net/$(ip route|grep -v lxdbr0|grep -v gateway-tor|head -n 1|awk '/default/ {print $5}')/address) ($(ip route|grep -v lxdbr0|grep -v gateway-tor|head -n 1|awk '/default/ {print $5}'))"
    echo "MAC Address: $(cat /sys/class/net/$(ip route|grep -v lxdbr0|grep -v gateway-tor|tail -n 1|awk '{print $3}')/address) ($(ip route|grep -v lxdbr0|grep -v gateway-tor|tail -n 1|awk '{print $3}'))"
  else
    echo "MAC Address: $(cat /sys/class/net/$(ip route|grep -v lxdbr0|grep -v gateway-tor|awk '/default/ {print $5}')/address)"
  fi &&\

	# Network speed
  if [[ -z $(ip route|grep -v lxdbr0|grep -v gateway-tor) ]]; then echo "Speed: 0B/s down, 0B/s up"; else spdtst=$(spdtst) && echo $spdtst; fi &&\
	# Entropy
  echo "Available entropy: $(cat /proc/sys/kernel/random/entropy_avail)"
  echo &&\

	##############
	# Core stats #
	##############

  echo -n "Core temperature: "  && sensors|grep Tdie|awk '{print substr($2,2,length($2)-3);}'|tr -d '\n' && echo "°C"
  #echo Temperature: $[$(cat /sys/class/thermal/thermal_zone0/temp)/1000]°C, $[$(cat /sys/class/thermal/thermal_zone0/temp)/1000+273]K &&\
  echo "First core frequency: $(grep "cpu MHz" /proc/cpuinfo|head -n 1|awk ' {print $4}')MHz" &&\
  echo "CPU usage: $(for i in {1..2}; do sleep .5; grep -w cpu /proc/stat ; done|awk '{print (o2+o4-$2-$4)*100/(o2+o4+o5-$2-$4-$5) "%"; o2=$2;o4=$4;o5=$5}'|tail -n 1)" &&\
  echo "RAM usage: $(free -m|grep Mem|awk {'print $3,"/",$2,"- ",$3/$2 * 100.0'})%" &&\
  if [ "$(free -m|grep Swap|awk $'{print $2}')" == "0" ]; then echo "No swap partition or file in use"; else echo "Swap usage: $(free -m|grep Swap|awk {'print $3,"/",$2,"- ",$3/$2 * 100.0'})%"; fi &&\
	echo &&\

	###################
	# AMD GPU Section #
	###################

  if [[ $amd -eq 1 ]]; then
	  echo "GPU usage: $(cat /sys/class/drm/card0/device/gpu_busy_percent)%"

	  VRAM_USED=$(( $(cat /sys/class/drm/card0/device/mem_info_vram_used) / 1000000 ))
	  VRAM_TOTAL=$(( $(cat /sys/class/drm/card0/device/mem_info_vram_total) / 1000000 ))
	  echo "VRAM usage: $VRAM_USED / $VRAM_TOTAL MB, $(( $VRAM_USED * 100 / $VRAM_TOTAL ))%"
    echo -n "GPU temperature: " && sensors|grep edge|awk '{print substr($2,2,length($2)-3);}'|tr -d '\n' && echo "°C"
	  echo
  fi

	######################
	# Nvidia GPU Section #
	######################

  if [[ $nvidia -eq 1 ]]; then
	  nvd=$(nvidia-smi --format=csv --query-gpu=power.draw,utilization.gpu,fan.speed,temperature.gpu | grep -v power.draw)
	  nvd1=$(echo $nvd | awk '{print $1}')
	  nvd2=$(echo $nvd | awk '{print $3}')
	  nvd3=$(echo $nvd | awk '{print $5}')
	  nvd4=$(echo $nvd | awk '{print $7}')
	  echo "GPU stats:"
	  echo " Power: $nvd1 W; Usage: $nvd2%;"
    echo " FanSpd: $nvd3%; Temperature: $nvd4°C;"
	  echo
  fi

	#####################
	# Processes section #
	#####################

  echo "Processes: $(ps -A --no-headers | wc -l) up, $(top -bn 1|awk '/Tasks/ {print $4}') running" &&\
  echo "Most intensive processes:" &&\
  echo 'MEM%  CPU%  PID NAME' && ps c -eo pmem,pcpu,pid,command --no-headers| sort -t. -nk1,2 -k4,4 -r |head -n 3 &&\
  echo &&\
  echo "Processes accessing the network:"
}

# Execution

export -f 4ll

if [[ "$*" == *"--gui"* ]]; then # For GUI
  ret=100 # For loop start
  while [[ $ret -eq 100 ]]; do # Yad will return 100 when Options is pressed
    yad --button "Options":100 --width 100 --height 800 \
    --text-info --title "$progname" < <(
    echo "Loading system info..." # So Yad isn't empty on the first run
    while true; do # Auto-update until Yad closes
      var=$(4ll $@ && eval $watchy) &&
      echo -e '\f' &&
      echo "$var" &&
      sleep 5
    done)
    ret=$? # Get the return code from Yad
    if [[ $ret -eq 100 ]]; then # Open Options dialog if Options pressed
      gui_tmp=`yad --list --checklist --title="[$progname] Options" --column="Toggle" \
      --column="Option" TRUE nvidia FALSE amd FALSE stealth \
      --button yad-cancel --button yad-ok --always-print-result`
      if [ $? -eq 1 ]; then # If "Ok" was pressed, propagate options
        gui_out=$gui_tmp
      fi
    fi
  done
else # For CLI (cli ftw)
	watch -tn 1 "4ll $@ && $watchy"
fi
