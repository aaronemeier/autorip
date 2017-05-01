#!/bin/bash
# AutoRip: Automatically ripping of multimedia discs.
# Copyright (C) 2014, Aaron Meier <aaron@bluespeed.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
# File:         autorip.sh
# Description:  Automatically rips audio discs, dvds and blurays
#               via third party tools.
# Author:       Aaron Meier <aaron@bluespeed.org>

# Read configuration
CONFIGFILE="../conf/main.conf"
source $CONFIGFILE

# Global vars
CURRENT_LOG=$MAIN_LOG

# Log filtering expressions
FILTER_ABCDE='(^Selected.*)|(^Grabbing.*)|(^Encoding.*)|(^Tagging.*)|(^Finished.*)'
FILTER_MAKEMKV='(^Current action\:.*)|(^.*Total progress - [0-9]{1,2}%)|(^Copy complete.*)'
FILTER_HANDBRAKE='(^\[[0-9]{1,2}\:[0-9]{2}\:[0-9]{2}\].*)|(^Encoding:.*[1-9]{1}0.{3}.*)'

# Set state
function setState(){
    state=$1
    echo $state > $STATE
}

# Writes logfiles
function writeLog(){
    typ=$1
    string=$2
    TIMESTAMP=$(/bin/date +'[%d.%m.%Y|%H:%M]')
    case "$typ" in
        'info' )
            echo -e $TIMESTAMP '[INFO]' $string >> "$MAIN_LOG"
            echo -e $TIMESTAMP '[INFO]' $string >> "$CURRENT_LOG"
            ;;
        'error' )
            echo $TIMESTAMP '[ERROR]' $string >> "$MAIN_LOG"
            echo $TIMESTAMP '[ERROR]' $string >> "$CURRENT_LOG"
            ;;
        'cmd' )
            echo "$string" | sh 2>&1 | filterLog
            if [ $? != 0 ]; then
                echo -e $TIMESTAMP '[ERROR] There was an error running "'$string'"' >> "$MAIN_LOG"
                echo -e $TIMESTAMP '[ERROR] There was an error running "'$string'"' >> "$CURRENT_LOG"
                setState '0'
                exit 1
            fi
    esac;
}

# Check settings
function checkSettings(){
    CONF=$1
    if [ ! -f $CONF ]; then
        writeLog 'error' 'Settings file not found for '$typ'. Exiting..'
        setState '0'
        exit 1
    else
        return 1
    fi
}


# Returns actual state
function checkState(){
    if [ $(/bin/cat $STATE) === '0' ]; then
        return 0
    else
        writeLog 'error' 'Another Job is running. Exiting..'
        exit 1
    fi
}

# Waitfunction until HandBrake is shutdown
function waitHandbrakeShutdown(){
    HANDBRAKE_PID=$(/bin/ps aux | /bin/grep HandBrakeCLI)
    set -- $HANDBRAKE_PID; HANDBRAKE_PID=$2
    if [ -n "$HANDBRAKE_PID" ]; then
        while [ -e /proc/$HANDBRAKE_PID ]; do
            sleep 1;
        done
    else
        writeLog 'info' 'You are lucky, there are no jobs running right now.'
    fi

}

# Clean function for cleaning current logs
function cleanLog(){
    if [ $(wc -l < $CURRENT_LOG) -gt 100 ]; then
        cat $CURRENT_LOG | head -n 100 > "$CURRENT_LOG"
    fi
}

function filterLog(){
    while read string; do
    echo "$string" &>> $FULL_LOG
        if [[ "$CURRENT_LOG" == "$AUDIO_LOG" ]]; then
            if [[ "$string" =~ $FILTER_ABCDE ]]; then
                echo "$string" >> "$MAIN_LOG"
            fi
        else
            if [[ "$string" =~ $FILTER_MAKEMKV ]] || [[ "$string" =~ $FILTER_HANDBRAKE ]]; then
                echo  "$string" >> "$MAIN_LOG"
            fi
        fi
    done
}

# Rip function for Audio
function ripAudio(){
    checkSettings $AUDIO_CONF
    if [ $? -eq 1 ] && [ !checkState ]; then
        setState '1'
        writeLog 'info' '----------------------------------------------'
        writeLog 'info' 'Starting Audio ripping.'
        writeLog 'cmd' '/usr/bin/abcde -c '$AUDIO_CONF
        writeLog 'info' 'Audio disc has been saved. Ejecting disc.'
        writeLog 'cmd' '/usr/bin/eject '$AUDIO_SRC
        writeLog 'info' 'Correcting permissions.'
        writeLog 'cmd' 'chown -R sysadmin.sysadmin '$AUDIO_OUT
        writeLog 'cmd' 'chmod -R 770 '$AUDIO_OUT
        writeLog 'info' 'Cleaning log.'
        setState '0'
        cleanLog
    fi
}

# Rip function for DVD
function ripDVD(){
    checkSettings $DVD_CONF
    if [ $? -eq 1 ] && [ !checkState ]; then
        test -f $DVD_CONF && . $DVD_CONF
        setState '1'
        writeLog 'info' '----------------------------------------------'
        writeLog 'info' 'Starting DVD ripping.'
        if [[ $DVD_TITLE != "" ]]; then
            writeLog 'cmd' "mkdir -p $DVD_OUT/$DVD_TITLE"
        else
            writeLog 'error' 'Please insert a disc.'
            setState '0'
            exit 1
        fi
        writeLog 'cmd' "/usr/bin/makemkvcon $DVD_OPTPRF $DVD_OPTACT $DVD_OPTMSC $DVD_OPTLOG $DVD_OPTDEV $DVD_OPTCNV $DVD_OPTMSC $DVD_OUT/$DVD_TITLE"
        writeLog 'info' $DVD_TITLE' has been saved.'
        writeLog 'info' 'Waiting until all HandBrake jobs have been processed.'
        waitHandbrakeShutdown
        writeLog 'info' 'Converting '$DVD_TITLE' to a proper format.'
        if [ -d "$DVD_OUT/$DVD_TITLE" ]; then
            HBR_SRCFILE="$DVD_OUT/$DVD_TITLE/*.mkv"
        else
            writeLog 'error' 'No videofile found.'
            setState '0'
            exit 1
        fi
        writeLog 'cmd' "/usr/bin/HandBrakeCLI $HBR_OPTGEN $HBR_OPTSUB $HBR_PRESET --input $HBR_SRCFILE --output $DVD_OUT/$DVD_TITLE.mkv"
        writeLog 'info' $DVD_TITLE' has been converted successfully.'
        writeLog 'info' 'Correcting permissions.'
        writeLog 'cmd' 'chown -R sysadmin.sysadmin '$DVD_OUT
        writeLog 'cmd' 'chmod -R 770 '$DVD_OUT
        writeLog 'info' 'Ejecting disc.'
        writeLog 'cmd' '/usr/bin/eject '$DVD_SRC
        writeLog 'info' 'Cleaning log.'
        setState '0'
        cleanLog
    fi
}

# Rip function for BluRay
function ripBluRay(){
    checkSettings $BLURAY_CONF
    if [ $? -eq 1 ] && [ !checkState ]; then
        test -f $BLURAY_CONF && . $BLURAY_CONF
        echo "$BLURAY_CNFXML" > $BLURAY_CNFSRC &> /dev/null
        setState '1'
        writeLog 'info' '----------------------------------------------'
        writeLog 'info' 'Starting BluRay ripping.'
                if [[ ! $BLURAY_TITLE == "" ]]; then
            writeLog 'cmd' "mkdir -p $BLURAY_OUT/$BLURAY_TITLE"
        else
            writeLog 'error' 'Please insert a disc.'
            setState '0'
            exit 1
        fi
        writeLog 'cmd' "/usr/bin/makemkvcon $BLURAY_OPTPRF $BLURAY_OPTACT $BLURAY_OPTMSC $BLURAY_OPTLOG $BLURAY_OPTDEV $BLURAY_OPTCNV $BLURAY_OPTMSC $BLURAY_OUT/$BLURAY_TITLE"
        writeLog 'info' $BLURAY_TITLE' has been saved. Ejecting disc now.'
        writeLog 'info' 'Waiting until all HandBrake jobs have been processed.'
        waitHandbrakeShutdown
        writeLog 'info' 'Converting '$BLURAY_TITLE' to a proper format.'
        if [ -d "$BLURAY_OUT/$BLURAY_TITLE" ]; then
            HBR_SRCFILE="$BLURAY_OUT/$BLURAY_TITLE/*.mkv"
        else
            writeLog 'error' 'No videofile found.'
            setState '0'
            exit 1
        fi
        writeLog 'cmd' "/usr/bin/HandBrakeCLI $HBR_OPTGEN $HBR_OPTSUB $HBR_PRESET --input $HBR_SRCFILE --output $BLURAY_OUT/$BLURAY_TITLE.mkv"
        writeLog 'info' $BLURAY_TITLE' has been converted successfully.'
        writeLog 'info' 'Correcting permissions.'
        writeLog 'cmd' 'chown -R sysadmin.sysadmin '$BLURAY_OUT
        writeLog 'cmd' 'chmod -R 770 '$BLURAY_OUT
        writeLog 'info' 'Ejecting disc.'
        writeLog 'cmd' '/usr/bin/eject '$BLURAY_SRC
        writeLog 'info' 'Cleaning log.'
        setState '0'
        cleanLog
    fi
}

# Main entry point of this script
if [ $# == 1 ]; then
    case "$1" in
        'audio' )
            CURRENT_LOG=$AUDIO_LOG
            ripAudio
            exit 0
            ;;
        'dvd' )
            CURRENT_LOG=$DVD_LOG
            ripDVD
            exit 0
            ;;
        'bluray' )
            CURRENT_LOG=$BLURAY_LOG
            ripBluRay
            exit 0
            ;;
    esac;
else
    echo -e "\n \
AutoRip Copyright (C) 2014 Aaron Meier <aaron@bluespeed.org> \n \
This program comes with ABSOLUTELY NO WARRANTY; for details see COPYING. \n \
This is free software, and you are welcome to redistribute it \n \
under certain conditions; see COPYING for details."
    echo -e '\n[ERROR] Wrong parameter detected\n'
    echo -e 'Syntax:\t' $0 ' -TYP\n'
    echo -e '\taudio\tRips an audio disc\n'
    echo -e '\tdvd\tRips an DVD\n'
    echo -e '\tbluray\tRips an BluRay disc\n'
    exit 0
fi
