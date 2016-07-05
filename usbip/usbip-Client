#!/bin/bash

### BEGIN INIT INFO
# Provides:          usbip-Client
# Required-Start:    $local_fs $network $named $time $syslog
# Required-Stop:     $local_fs $network $named $time $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Description:       P5Software USB IP Client
### END INIT INFO

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------
P5SoftwareHome=/etc/P5Software/Linux-Tools
scripthome=$P5SoftwareHome/usbip

# Must be a valid filename
NAME=usbip-Client
PIDFILE=/var/run/$NAME.pid
LOGFILE=/var/log/$NAME.log

# Read the configuration file
source $scripthome/$NAME.conf

#This is the command to be run, give the full pathname
PATH=/usr/bin
EXECUTABLE=usbip
DAEMON=$PATH/$EXECUTABLE
DAEMON_OPTS="attach -r $serverFQDN -b $busID"
DETACH_OPTS="detach -p 0"

export PATH="${PATH:+$PATH:}/usr/sbin:/sbin:/usr/bin"

case "$1" in


# ------------------------------------------------------------
# Start
# ------------------------------------------------------------
start)
if [ -f /var/run/$PIDNAME ] && kill -0 $(cat /var/run/$PIDNAME); then
echo $(date +%Y-%m-%d\ %H:%M:%S) 'Service already running' >> $LOGFILE 2>&1
return 1
fi

#Set the environment appropriately
modprobe vhci-hcd

echo -n "Starting service: "$NAME
echo $(date +%Y-%m-%d\ %H:%M:%S) 'Starting service…' >> $LOGFILE 2>&1
start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON -- $DAEMON_OPTS
echo $(date +%Y-%m-%d\ %H:%M:%S) 'Service started' >> $LOGFILE 2>&1
echo "."
;;


# ------------------------------------------------------------
# Stop
# ------------------------------------------------------------
stop)
if [ ! -f $PIDFILE ] || ! kill -0 $(cat $PIDFILE); then
echo $(date +%Y-%m-%d\ %H:%M:%S) 'Service not running' >> $LOGFILE 2>&1
return 1
fi

#Detach the device
echo -n "Detaching device..."
echo $(date +%Y-%m-%d\ %H:%M:%S) 'Detaching device…' >> $LOGFILE 2>&1

$DAEMON $DETACH_OPTS >> $LOGFILE 2>&1

echo -n "Device detached."
echo $(date +%Y-%m-%d\ %H:%M:%S) 'Device detached.' >> $LOGFILE 2>&1

#Stop the service
echo -n "Stopping service: "$NAME
echo $(date +%Y-%m-%d\ %H:%M:%S) 'Stopping service…' >> $LOGFILE 2>&1

start-stop-daemon --stop --quiet --oknodo --pidfile $PIDFILE
echo "Service stopped."

echo $(date +%Y-%m-%d\ %H:%M:%S) 'Service stopped.' >> $LOGFILE 2>&1
;;


# ------------------------------------------------------------
# Status
# ------------------------------------------------------------
status)
status_of_proc -p $PIDFILE $PATH $EXECUTABLE && exit 0 || exit $?
;;


# ------------------------------------------------------------
# Uninstall
# ------------------------------------------------------------
uninstall() {
echo -n "Are you really sure you want to uninstall this service? That cannot be undone. [yes|No] "
local SURE
read SURE
if [ "$SURE" = "yes" ]; then
stop
rm -f "$PIDFILE"
echo "Notice: log file is not be removed: '$LOGFILE'" >&2
update-rc.d -f usbip-Client remove
rm -fv "$0"
fi
}


# ------------------------------------------------------------
# Undefined
# ------------------------------------------------------------
*)
echo "Usage: "$1" {start|stop|status|uninstall}"
exit 1
esac

exit 0