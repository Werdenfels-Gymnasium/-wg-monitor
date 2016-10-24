#!/bin/bash

function log() {
  echo "$(LC_ALL=en_US.utf8 date  +'%b %e %T') $(cat /etc/hostname) [$1] $2" >> /var/log/syslog
}

function connect() {
  opposite=$([ "$1" == "HDMI" ] && echo "VGA" || echo "HDMI" );
  if ( [ $1 == "HDMI" -a $vgaStatus == "connected" ] ) || ( [ $1 == "VGA" -a $hdmiStatus == "connected" ] ) ; then
    notify-send -i "/usr/share/icons/gnome/256x256/status/dialog-warning.png" "Es ist bereits eine Verbindung zu einem Monitor aufgebaut. Bitte trennen Sie diese Verbindung!";
    exit;
  fi
  xrandr --output ${opposite}1 --off;
  xrandr --output LVDS1 --mode 1024x768;
  xrandr --output ${1}1 --mode 1024x768;
  log "Monitor Daemon" "Successfully connected to ${1} and disconnected from ${opposite}";
  notify-send -i "/opt/monitor/${1}.png" "Verbindung zum Monitor über $1 aufgebaut";
}

function disconnect() {
  xrandr --output LVDS1 --mode 1366x768;
  log "Monitor Daemon" "Successfully disconnected from all external monitors";
  notify-send -i "/usr/share/icons/gnome/256x256/status/dialog-warning.png" "Verbindung zum externen Monitor getrennt";
}

export DISPLAY=:0;
user=$(echo "$(users)" | awk 'END {print $1}');
home=$(getent passwd $user | cut -d: -f6);
export XAUTHORITY=$home/.Xauthority;
log "Monitor Daemon" "Executing script";

vgaStatus=$(cat /sys/class/drm/card0-VGA-1/status);
hdmiStatus=$(cat /sys/class/drm/card0-HDMI-A-1/status);
lvdsStatus=$(cat /sys/class/drm/card0-LVDS-1/status);
log "Monitor Daemon" "VGA1 $vgaStatus. HDMI1 $hdmiStatus. LVDS1 $lvdsStatus";

if [ $hdmiStatus == "connected" ] ; then
  connect "HDMI";
  exit;
fi

if [ $vgaStatus == "connected" ] ; then
  connect "VGA";
  exit;
fi;

disconnect;


#echo 'KERNEL=="card0", SUBSYSTEM=="drm", RUN+="/opt/monitor/monitor.sh"' > /etc/udev/rules.d/95-monitor-hotplug.rules
