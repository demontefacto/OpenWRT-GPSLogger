#!/bin/bash
PATH=$PATH:/usr/local/sbin:/usr/local/bin:/sbin:/bin

#definice promennych
TMPDIR="/tmp/GPS"
GPSDIR="/mnt/GPS"
INTERFACE="/dev/ttyS1"

TMPLOG="$TMPDIR"
GPSLOG="$GPSDIR"

#nejaka adresarova struktura
mkdir -p $TMPLOG
mkdir -p $GPSLOG

#pokud se logger zapne, predpoklada se, ze se chce zapisovat
touch $GPSLOG/Data.nmea
#aby mohl mazat i samba guest
chown -R nobody.nogroup $GPSLOG
chmod -R 777 $GPSLOG

#neverending story
while true ; do

	if ! pgrep -x gpspipe >> /dev/null ; then #pokud nebezi gpspipe, vyprselo 5min
		RANDOM_APENDIX=$(echo $RANDOM) #novy nazev docasneho souboru
		[[ -z "$debug" ]] && logger "Novy appendix: $RANDOM_APENDIX"
		touch $TMPLOG/$RANDOM_APENDIX #docasny soubor aby se nelogovalo v sekundovych intervelech na SDkartu
		chmod +w $TMPLOG/$RANDOM_APENDIX

		[[ -f "$TMPDIR/gpslastapendix.pid" ]] && LAST_APENDIX=$(cat $TMPDIR/gpslastapendix.pid)
		[[ -z "$debug" ]] && logger "Stary appendix: $LAST_APENDIX"

		[[ -z "$debug" ]] && logger "Spoustim gpsmon"
		timeout 360 gpspipe -r -o $TMPLOG/$RANDOM_APENDIX &

		echo $RANDOM_APENDIX > $TMPDIR/gpslastapendix.pid
		[[ -z "$debug" ]] && logger "Ukladam predchozich 5min"
		if [[ -f $GPSLOG/Data.nmea && "x$LAST_APENDIX" != "x" ]] ; then
			grep -i GPRMC $TMPLOG/$LAST_APENDIX >> $GPSLOG/Data.nmea #pet minut odsypeme na SDKARTU
			sync & #kdyby vypli proud, tak o vsecko prijdeme, ale netreba cekat nez to zkonci, 5min by melo do dalsiho zapisu stacit
		fi
		if ! ping 10.0.0.138 -c 1 -w 1 ; then
			nmtui-connect Doma &
		fi

		[[ ! "x$LAST_APENDIX" = "x" ]] && rm $TMPLOG/$LAST_APENDIX #a smazeme posledni apendix, at to nezere ramku
	else
		sleep 5 # furt dokola pgrep docela zere procesor
	fi

done
