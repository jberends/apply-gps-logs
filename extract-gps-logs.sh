#!/bin/bash

# extract GPS logs from images into a gpx track filw
# See: http://www.sno.phy.queensu.ca/~phil/exiftool/geotag.html#Reverse

if [[ $# -eq 0 ]] ; then
    echo "usage:"
    echo "    extract-gps-logs <directory> [<gpslog>.gpx]"
    echo " "
    echo "Prerequisite: exiftool in path available"
    echo " "
    echo "<directory> : a directory with images to extract recursively gps logs from"
    echo "<gpslog>    : [optional] a gpslog filename (without gpx, extension is added)"
    echo "              if not provided, the <directory-name>.gpx is used"
    echo " The extracted track is immediately applied to the other photos in the <directory> structure"
    echo " "
    exit 1
fi

DIRNAME=$1
GPXFILENAME=$2

EXIFTOOL_CONFDIR=~/.exiftool
GPXFORMAT_FILENAME=gpx.fmt

# setting to determine the maximum interpolation between GPS track points and the maximum extra polation
# until first/last point in the extracted tracklist
GEOTAG_MAX_INTERPOLATION_SECS=21600
GEOTAG_MAX_EXTRAPOLATION_SECS=21600


if [ -z $2 ]; then
    GPXFILENAME=`basename ${DIRNAME}`
    echo "Using gpslog filename '${GPXFILENAME}.gpx' in current directory";
fi

if [ ! -d ${EXIFTOOL_CONFDIR} ] ; then
	mkdir -p ${EXIFTOOL_CONFDIR}
fi

if [ ! -f ${EXIFTOOL_CONFDIR}/${GPXFORMAT_FILENAME} ]; then
	cat > ${EXIFTOOL_CONFDIR}/${GPXFORMAT_FILENAME} << 'EOF'
#------------------------------------------------------------------------------
# File:         gpx.fmt
#
# Description:  Example ExifTool print format file for generating GPX track log
#
# Usage:        exiftool -p gpx.fmt -d %Y-%m-%dT%H:%M:%SZ FILE [...] > out.gpx
#
# Requires:     ExifTool version 8.10 or later
#
# Revisions:    2010/02/05 - P. Harvey created
#
# Notes:     1) All input files must contain GPSLatitude and GPSLongitude.
#            2) The -fileOrder option may be used to control the order of the
#               generated track points.
#------------------------------------------------------------------------------
#[HEAD]<?xml version="1.0" encoding="utf-8"?>
#[HEAD]<gpx version="1.0"
#[HEAD] creator="ExifTool $ExifToolVersion"
#[HEAD] xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
#[HEAD] xmlns="http://www.topografix.com/GPX/1/0"
#[HEAD] xsi:schemaLocation="http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd">
#[HEAD]<trk>
#[HEAD]<number>1</number>
#[HEAD]<trkseg>
#[BODY]<trkpt lat="$gpslatitude#" lon="$gpslongitude#">
#[BODY]  <ele>$gpsaltitude#</ele>
#[BODY]  <time>$gpsdatetime</time>
#[BODY]</trkpt>
#[TAIL]</trkseg>
#[TAIL]</trk>
#[TAIL]</gpx>
EOF
fi

echo "Performing a recursive search of GPS tagged photos in directory:"
for PHOTODIR in `find ${DIRNAME} -type d`; do
	echo " - ${PHOTODIR}"
done


# from http://www.sno.phy.queensu.ca/~phil/exiftool/geotag.html#Reverse
exiftool -if '$gpsdatetime' \
	-fileOrder gpsdatetime \
	-p ${EXIFTOOL_CONFDIR}/${GPXFORMAT_FILENAME} \
	-d %Y-%m-%dT%H:%M:%SZ -r ${DIRNAME} > ${GPXFILENAME}.gpx

echo "exported GPS data in photos to '${GPXFILENAME}.gpx'" 
echo "Done."

echo "-----------------------------"
echo "updating the other files"

exiftool -if 'not $gpsdatetime' \
	-geotag ${GPXFILENAME}.gpx "-geotime<DateTimeUTC" \
	-api GeoMacIntSecs=${GEOTAG_MAX_INTERPOLATION_SECS} -api GeoMaxExtSecs=${GEOTAG_MAX_EXTRAPOLATION_SECS} \
	-overwrite_original_in_place \
	-v0 \
	-r ${DIRNAME}
