#!/bin/bash
if [ -z "$1" ]
then
    echo "Usage: chmod 777 ./timer.sh; ./timer.sh secs-offset"
    echo -e "       e.g."
    echo -e "       ./timer.sh 0"
else
    # date
    t1=`date +%s`
    flag=`date +%H`
    if [ $flag -gt 12 ]
    then
        t2=`date -d "\`date +%Y-%m-%d\` 18:00" +%s`
    else
        t2=`date -d "\`date +%Y-%m-%d\` 11:30" +%s`
    fi
    let "d1=$t2-$t1+$1"
    let "d1=$d1*2"
    a=1
    while [ $a -eq 1 ]
    do
        clear
        # let "d1=$d1*2"
        # let "h1=$d1/(60*60)"
        # let "m1=$d1/60-$h1*60"
        # let "s1=$d1%60"
        # if [ $h1 -lt 10 ]
        # then
        #     h1="0"$h1
        # fi
        # if [ $m1 -lt 10 ]
        # then
        #     m1="0"$m1
        # fi
        # if [ $s1 -lt 10 ]
        # then
        #     s1="0"$s1
        # fi
        # echo -e "\n\t$d1\t$h1:$m1:$s1"
        echo -e "\n\t$d1"
        sleep 0.5
        let "d1=$d1-1"
    done
fi
