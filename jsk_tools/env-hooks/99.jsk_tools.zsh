#!/bin/zsh
# -*- mode: shell-script -*-

function rossetmaster() {
    if [ "${ZSH_REMATCH}" = "" ]; then
        export ZSH_REMATCH="${PS1}"
    fi
    local hostname=${1-"pr1040"}
    local ros_port=${2-"11311"}
    export ROS_MASTER_URI=http://$hostname:$ros_port
    if [ "$NO_ROS_PROMPT" = "" ]; then
        if [[ "${PS1}" =~ .{4}\[http://.*:.*\].*$ ]] ; then
            export PS1="${ZSH_REMATCH}"
        fi
        export PS1="%{$fg[yellow]%}[$ROS_MASTER_URI][$ROS_IP]%{$reset_color%} ${PS1}"
    fi
    echo -e "\e[1;31mset ROS_MASTER_URI to $ROS_MASTER_URI\e[m"
}
function rossetrobot() {
    echo -e "\e[1;31m *** rossetrobot is obsoleted, use rossetmaster ***\e[m"
    rossetmaster $@
}

function rossetlocal() {
    rossetmaster localhost
    if [ "$NO_ROS_PROMPT" = "" ]; then
        if [[ "${PS1}" =~ .{4}\[http://.*:.*\].*$ ]] ; then
            export PS1="${ZSH_REMATCH}"
        fi
    fi
}

function rossetip_dev() {
  local device=${1-"(eth0|eth1|eth2|eth3|eth4|wlan0|wlan1|wlan2|wlan3|wlan4)"}
  export ROS_IP=`PATH=$PATH:/sbin LANGUAGE=en LANG=C ifconfig | egrep -A1 "${device}"| grep inet\  | grep -v 127.0.0.1 | sed 's/.*inet addr:\([0-9\.]*\).*/\1/' | head -1`
  export ROS_HOSTNAME=$ROS_IP
}

function rossetip_addr() {
  local target_host=${1-"133.11.216.211"}
  ##target_hostip=$(host ${target_host} | sed -n -e 's/.*address \(.*\)/\1/gp')
  target_hostip=$(getent hosts ${target_host} | cut -f 1 -d ' ')
  if [ "$target_hostip" = "" ]; then target_hostip=$target_host; fi
  local mask_target_ip=$(echo ${target_hostip} | cut -d. -f1-3)
  export ROS_IP=$(PATH=$PATH:/sbin LANGUAGE=en LANG=C ifconfig | grep inet\ | sed 's/.*inet addr:\([0-9\.]*\).*/\1/' | tr ' ' '\n' | grep $mask_target_ip | head -1)
  export ROS_HOSTNAME=$ROS_IP
}

function rossetip() {
  local device=${1-"(eth0|eth1|eth2|eth3|eth4|wlan0|wlan1|wlan2|wlan3|wlan4)"}
  if [[ $device =~ [0-9]+.[0-9]+.[0-9]+.[0-9]+ ]]; then
      export ROS_IP="$device"
  else
      export ROS_IP=""
      local master_host=$(echo $ROS_MASTER_URI | cut -d\/ -f3 | cut -d\: -f1);
      if [ "${master_host}" != "localhost" ]; then rossetip_addr ${master_host} ; fi
      if [ "${ROS_IP}" = "" ]; then rossetip_addr ${device}; fi
      if [ "${ROS_IP}" = "" ]; then rossetip_dev ${device}; fi
  fi
  export ROS_HOSTNAME=$ROS_IP
  if [ "${ROS_IP}" = "" ];
  then
      export ROS_IP
      export ROS_HOSTNAME
      echo -e "\e[1;31munable to set ROS_IP and ROS_HOSTNAME\e[m"
  else
      echo -e "\e[1;31mset ROS_IP and ROS_HOSTNAME to $ROS_IP\e[m";
  fi
}

function rosn() {
    if [ "$1" = "" ]; then
        topic=$(rosnode list | percol | xargs -n 1 rosnode info | percol | sed -e 's%.* \* \(/[/a-zA-Z0-9_]*\) .*%\1%')
    else
        topic=$(rosnode info $1 | percol | sed -e 's%.* \* \(/[/a-zA-Z0-9_]*\) .*%\1%')
    fi
    if [ "$topic" != "" ] ; then
        rost $topic
    fi
}
function rost() {
    if [ "$1" = "" ]; then
        node=$(rostopic list | percol | xargs -n 1 rostopic info | percol | sed -e 's%.* \* \(/[/a-zA-Z0-9_]*\) .*%\1%')
    else
        node=$(rostopic info $1 | percol | sed -e 's%.* \* \(/[/a-zA-Z0-9_]*\) .*%\1%')
    fi
    if [ "$node" != "" ] ; then
        rosn $node
    fi
}
