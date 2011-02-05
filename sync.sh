#!/bin/bash

# Simple sync between two(or more) hosts by rsync & ssh

USAGE='Usage like: . sync.rc && ./sync.sh [in|out]\n\n
This script need some vars:\n
SYNC_USER="username"\n
SYNC_SERVER="hostname_or_ip"\n
DIR_LOCAL="/local/dir"\n
DIR_REMOTE="/remote/dir/on/server"\n
RSYNC_FLAGS="-e ssh --delete --owner --group --links --perms --times --progress --recursive --exclude -*"'

# check variables
VARS="SYNC_USER SYNC_SERVER DIR_LOCAL DIR_REMOTE RSYNC_FLAGS"
for VAR in $VARS; do
    if [[ $DEBUG == 1 ]]; then
        echo "VAR: $VAR = ${!VAR}"
    fi
    if [[ -z ${!VAR} ]]; then
        echo "Need to set $VAR !"
        echo -e $USAGE
        exit 1
    fi
done
SYNC_MAKE_LS_R=1
if [[ $SYNC_MAKE_LS_R ]]; then
    TIMESTAMP_FILE="ls-R"
else
    TIMESTAMP_FILE=".timestamp"
fi

# detect if 'already run'
# TODO : detect 'already run' more? propertly
RUN=`ps ax | grep sync.sh | grep -v grep | wc -l`
if [[ "$RUN" -gt 2 ]]; then
    echo "already running $RUN"
    echo `ps jawx | grep sync.sh`
    exit 1
fi

# choose direction
DIRECTION=$1
if [[ ! $DIRECTION ]]; then
    TIMESTAMP_LOCAL=`stat --format=%Y $DIR_LOCAL/$TIMESTAMP_FILE`
    TIMESTAMP_REMOTE=`ssh $SYNC_USER@$SYNC_SERVER stat --format=%Y $DIR_REMOTE/$TIMESTAMP_FILE`
    if [[ $TIMESTAMP_LOCAL -eq $TIMESTAMP_REMOTE ]]; then
        echo 'TIMESTAMP is equal, so there is nothing to do !'
        exit
    elif [[ $TIMESTAMP_LOCAL -gt $TIMESTAMP_REMOTE ]]; then
        DIRECTION='out'
    elif [[ $TIMESTAMP_LOCAL -lt $TIMESTAMP_REMOTE ]]; then
        DIRECTION='in'
    fi
fi

# sync here
if [[ "$DIRECTION" == 'out' ]]; then
    echo ".OUT.";
    if [[ $SYNC_MAKE_LS_R ]]; then
        if [[ $DEBUG == 1 ]]; then
            echo "MAKE ls -R"
        fi
        # TODO : make ls-R work propertly
        cd $DIR_LOCAL
        ls -R -1 --group-directories-first . > ls-R;
    else
        touch "$DIR_LOCAL/$TIMESTAMP_FILE"
    fi
    rsync $RSYNC_FLAGS "$DIR_LOCAL/" "$SYNC_USER@$SYNC_SERVER:$DIR_REMOTE";
elif [[ "$DIRECTION" == 'in' ]]; then
    echo ".IN.";
    rsync $RSYNC_FLAGS "$SYNC_USER@$SYNC_SERVER:$DIR_REMOTE/" $DIR_LOCAL;
else
    echo 'ERROR: Cant detect direction (in/out) !'
fi

# clean variables
#for VAR in $VARS; do
    # TODO
    #export ${VAR}=
#done

exit 0
