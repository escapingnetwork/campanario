#!/bin/sh

HACK_INI=/tmp/hack.ini
echo `TZ=JST-9 date +"%Y/%m/%d %H:%M:%S"` ": Reboot & Start watchdog" >> /media/mmc/atomhack.log

router=`ip route | awk '/default/ { print $3 }'`
count=0
wifi_error=0
while sleep 20 ; do
  # wifi
  if ping -c 1 $router > /dev/null ; then
    wifi_error=0
  else
    let wifi_error++
  fi
  if [ $wifi_error -ge 3 ]; then
    echo "WiFi restart" >> /media/mmc/atomhack.log
    ifconfig wlan0 down
    ifconfig wlan0 up
    wifi_error=0
  fi

  let count++

  # process check 1min interval
  if [ `expr $count % 3` -eq 0 ]; then
    /scripts/lighttpd.sh watchdog >> /media/mmc/atomhack.log
    /scripts/rtspserver.sh watchdog >> /media/mmc/atomhack.log
    HEALTHCHECK=$(awk -F "=" '/HEALTHCHECK *=/ {print $2}' $HACK_INI)
    HEALTHCHECK_PING_URL=$(awk -F "=" '/HEALTHCHECK_PING_URL *=/ {print $2}' $HACK_INI)
    [ "$HEALTHCHECK" == "on" ] && [ "$HEALTHCHECK_PING_URL" != "" ] && curl -fsS -m 10 --retry 5 -o /tmp/log/healthcheck.log $HEALTHCHECK_PING_URL
  fi

  # free memory
  if [ $count -ge 180 ]; then # 1H interval
    count=0
    TZ=JST-9 date >> /media/mmc/atomhack.log
    free >> /media/mmc/atomhack.log
  fi
done



