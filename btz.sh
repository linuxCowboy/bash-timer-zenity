Ftimer ()
{
        #######################################
        ### bash shell function with zenity ###
        #######################################

        # Enable OK/Pause Button in zenity progress dialog
        #
        # Version: 3.42
        # File:    /usr/share/zenity/zenity.ui
        # Object:  zenity_progress_ok_button
        # Name:    sensitive
        #
        # comment out:
        #<!-- <property name="sensitive">False</property> -->
        #
        # or set to true:
        #<property name="sensitive">True</property>
        #
        # check:
        # cat -n /usr/share/zenity/zenity.ui |
        #     sed -rn '/GtkButton.*zenity_progress_ok_button/, \%/object%p' |
        #         grep --colour=always sensitive

        # alarm clock logging if set
        local LOG='/tmp/Ftimer.log'

        # alarm tone if set
        local PLAYER='/usr/bin/mpg321 -q'  # full path
        local MIXER='/usr/bin/amixer -q set Master unmute 70%'
        local FILE='/usr/local/bin/okay.mp3'

        # commands
        local CMD='zenity --modal'
        local CAL='ncal -M -w -W5'  # start Monday, number weeks, 1. Week 5 days

        ##### thousands separator #####
        #
        # #!/usr/bin/perl
        #
        # ### outside:
        # while (<>) {
        #         while (/\d{5,}/) {
        #                 $b=$`; $m=$&; $a=$'; $m =~ s/(?<=\d)(?=(\d{3})+\b)/./; $_="$b$m$a";
        #         }
        #         print
        # }
        #
        # ### inside:
        # $_ = sprintf "1000000 my string with long numbers 1234567890";
        #
        # while (/\d{5,}/p) {
        #         $b = ${^PREMATCH};
        #         $m = ${^MATCH};
        #         $a = ${^POSTMATCH};
        #
        #         $m =~ s/(?<=\d)(?=(\d{3})+\b)/./;
        #
        #         $_ = "$b$m$a";
        # }
        # CORE::say;
        #
        ############

        local CHR="."
        local sep='perl -pe'\''while(/\d{5,}/){$b=$`;$m=$&;$a=$'\'"\'"\'';$m=~s/(?<=\d)(?=(\d{3})+\b)/'$CHR'/;$_="$b$m$a"}'\'

        # needs zenity
        [[ $1 =~ ^(d|u|a|A|t|i) ]] && ! type ${CMD%% *} >/dev/null && return

        # needs ncal for year
        [[ $1 =~ ^y ]] && ! type ${CAL%% *} >/dev/null && return

        # countdown
        if [[ $1 =~ ^d && $2 =~ ^[0-9]+$ ]]; then
                for i in `seq $2 -1 1`; do
                        echo "$((100 - ${i}00 / $2))\n#Countdown: $i"
                        sleep 1
                done | WINDOWID=  $CMD --progress --auto-close --title="${3-Timer}"

        # countup
        elif [[ $1 =~ ^u ]]; then
                local HOT=0
                [[ $2 =~ ^((([0-9]*):)?([0-9]*):)?([0-9]*)$ ]] &&
                        HOT=$(( 10#${BASH_REMATCH[3]:-0} * 3600 +
                                10#${BASH_REMATCH[4]:-0} * 60 +
                                10#${BASH_REMATCH[5]:-0})) &&
                        shift

                local START=$HOT
                local FILE=$(mktemp)  # get the counter back from subshell

                while :; do
                        for ((; ; ++START)); do
                                echo $START >$FILE
                                printf -v t "%01d:%02d:%02d" $((START / 3600)) $((START / 60 % 60)) $((START % 60))

                                echo "#Countup: $t"
                                sleep 1
                        done | WINDOWID=  $CMD --progress --pulsate \
                                                --cancel-label='Quit' --ok-label='Pause' --title="${2-Timer}"

                        # zenity return value: okay = 0, quit = 1
                        (($?)) && break

                        START=$(< $FILE)
                        printf -v t "%01d:%02d:%02d" $((START / 3600)) $((START / 60 % 60)) $((START % 60))

                        # shell handles the pause/restart
                        read -sn1 -p "Last: $t (key to continue / q to quit / r|R to reset)"
                        echo
                        [[ $REPLY = q ]] && break
                        [[ $REPLY = r ]] && START=$HOT
                        [[ $REPLY = R ]] && START=0
                done
                \rm $FILE

        # alarm timer
        elif [[ $1 =~ ^(a|A) && $2 ]]; then
                local ICON='appointment'
                local FULL='/usr/share/icons/mate/48x48/actions/appointment.png'
                local TONE=0
                local MAST=0
                local INTERVAL=6  # precision

                date --date "$2" >/dev/null || return

                [[ -f "$FILE" && -x ${PLAYER%% *} ]] && ((++TONE))
                [[ $1 = 'A' ]] && TONE=0
                ((TONE)) && [[ -x ${MIXER%% *} ]] && ((++MAST))

                if [[ $LOG ]]; then
                        [[ $3 ]] && echo "$3"    >> "$LOG"
                        date         | tee --append "$LOG"
                        date -d "$2" | tee --append "$LOG"
                                echo             >> "$LOG"
                else
                        date
                        date --date "$2"
                fi

                ((MAST)) && $MIXER
                ((TONE)) && $PLAYER "$FILE"  # test

                local TARGET=`date -d "$2" +%s`

                while :; do
                        local CURRENT=`date +%s`

                        if ((CURRENT >= TARGET)); then
                                TARGET=`date -d@$TARGET '+%d. %b\n\n%T'`

                                ((MAST)) && $MIXER
                                ((TONE)) && $PLAYER "$FILE"

                                WINDOWID=  $CMD --warning ${ICON:+--icon-name "$ICON"} ${FULL:+--window-icon "$FULL"} \
                                        --text "$TARGET" --title "${3-Alarm Clock}"
                                return
                        fi
                        sleep $INTERVAL
                done

        # alarm log
        elif [[ $1 =~ ^l ]]; then
                [[ -f $LOG ]] && cat $LOG || echo "No Log."
                echo ===
                date

        # cmdline only (no zenity)
        elif [[ $1 =~ ^c ]]; then
                [[ $2 && ! $2 =~ ^[0-9]+$ ]] ||
                [[ $3 && ! $3 =~ ^[0-9]+$ ]] &&
                        return 1

                local START=${3-1}
                local PAUSE=0

                for ((i=$START; ; $PAUSE || ++i)); do
                        # bonus: value 0 falls through/runs forever
                        (( $2 )) && ((i > $2)) && return

                        # delay and input in one call :-)
                        read -sn1 -t1

                        # bonus: Enter for pause
                        (( ! $? )) && [[ ! $REPLY ]] && ((PAUSE ^= 1))
                        [[ $REPLY = p ]]             && ((PAUSE ^= 1))

                        # bonus: Esc for quit
                        [[ $REPLY = $'\x1b' ]] && return
                        [[ $REPLY = q ]]       && return

                        # bonus: Space for restart
                        [[ $REPLY = ' ' ]] && i=$START
                        [[ $REPLY = r ]]   && i=$START

                        # sparse print
                        t=$((i % 60))
                        ((i >= 60 && t < 10)) && t="0$t"
                        ((i >= 60)) && t="$((i / 60 % 60)):$t"
                        ((i >= 3600)) && ((i / 60 % 60 < 10)) && t="0$t"
                        ((i >= 3600)) && t="$((i / 3600)):$t"

                        # no need for tput ;-)
                        printf "% 12s\r" $t
                done

        # time
        elif [[ $1 =~ ^t ]]; then
                local ICON='preferences-system-time'
                local FULL='/usr/share/icons/mate/48x48/apps/preferences-system-time.png'
                local DATE=`date '+%d. %b\n\n%T'`

                (WINDOWID=  $CMD --info ${ICON:+--icon-name "$ICON"} ${FULL:+--window-icon "$FULL"} \
                        --text "$DATE" --title "${2-Time}" &)

        # info
        elif [[ $1 =~ ^i && $2 ]]; then
                local ICON='edit-paste'
                local FULL='/usr/share/icons/mate/48x48/actions/edit-paste.png'

                WINDOWID=  $CMD --info ${ICON:+--icon-name "$ICON"} ${FULL:+--window-icon "$FULL"} \
                        --text "$2" --title "${3-Info}"

        # year
        elif [[ $1 =~ ^y ]]; then
            # 0-black 1-red 2-green 3-brown [yellow] 4-blue 5-purple [magenta] 6-cyan 7-white
            echo "$(
                y=`date +%Y`
                m=`date +%-m`  # hyphen
                d=`date +%-d`
                local YEAR=${2-$y}  # if no subshell

                YEAR=`date -d $YEAR-1-1 +%Y` || return  # check + 4 digits

                ncal $YEAR >/dev/null || return

                [[ ! $2 && $m =~ 11|12 ]] && ((++YEAR))  # Winter is Coming

                r="$(tput sgr0)"
                M=(`for i in 11 12 {1..10};do date -d $i/1 +%B;done`)  # full month
                W=(Mon Tue Wed Thu Fri Sat Sun)  # 3 char

                # core
                for i in 11p 12p {1..10}; do
                        declare -n X=A$i  # nameref
                        X=(`$CAL -m$i $YEAR |sed -n '2,8 s/ /:/gp' |cut -c 4-`)

                        if [[ $YEAR = $y && $i = $m ]] ||
                                [[ $YEAR = $((y + 1)) && $i = ${m}p ]]; then  # today
                                        f="$(tput rev)"  # alternative
                                        f="$(tput rev)$(tput bold)$(tput setaf 3)"

                                        if ((d < 10)); then
                                                X=(`echo "${X[*]}" |sed 's/:'$d'\b/'"$r$f:$d$r-"/`)
                                        else  # - is marker
                                                X=(`echo "${X[*]}" |sed 's/\b'$d'\b/'"$r$f$d$r-"/`)
                                        fi
                        fi
                done

                # winter
                N=`$CAL -m11p -A3 $YEAR |tail -n 1`  # week number
                p='  '  # padding left margin
                g="$(tput setaf 3)"
                        echo
                printf "$p$r$g        %-17s %-17s %-17s %-17s$r\n" ${M[0]} ${M[1]} ${M[2]} ${M[3]}
                for i in {0..6}; do
                        if ((i < 5)); then
                                w=
                                h="$(tput setaf 4)"
                        else  # weekend
                                w="$(tput bold)$(tput setaf 2)"  # day number
                                h="$(tput bold)$(tput setaf 4)"  # day name
                        fi
                        l=`echo "${A11p[$i]} ${A12p[$i]} ${A1[$i]} ${A2[$i]}" |sed s/-/"$w"/`
                        echo "$p$r$h${W[$i]}$r $w$l$r" |sed 's/:*$//; s/:/ /g'  # highlight today
                done
                f="$(tput setaf 6)"
                echo "$p $r$f$N$r"

                # transition
                N=`$CAL -m3 -A1 $YEAR |tail -n 1`
                q='                  '  # indent
                        echo
                printf "$p$q$r$g        %-17s %-17s$r\n" ${M[4]} ${M[5]}
                for i in {0..6}; do
                        if ((i < 5)); then
                                w=
                                h="$(tput setaf 4)"
                        else
                                w="$(tput bold)$(tput setaf 2)"
                                h="$(tput bold)$(tput setaf 4)"
                        fi
                        l=`echo "${A3[$i]} ${A4[$i]}" |sed s/-/"$w"/`
                        echo "$p$q$r$h${W[$i]}$r $w$l$r" |sed 's/:*$//; s/:/ /g'
                done
                echo "$p$q $r$f$N$r"

                # year
                c="$(tput bold)$(tput setab 4)$(tput setaf 3)"
                        echo
                echo "$p$q     $r$c           -=[ $YEAR ]=-           $r"

                # summer
                N=`$CAL -m5 -A3 $YEAR |tail -n 1`
                        echo
                printf "$p$r$g        %-17s %-17s %-17s %-17s$r\n" ${M[6]} ${M[7]} ${M[8]} ${M[9]}
                for i in {0..6}; do
                        if ((i < 5)); then
                                w=
                                h="$(tput setaf 4)"
                        else
                                w="$(tput bold)$(tput setaf 2)"
                                h="$(tput bold)$(tput setaf 4)"
                        fi
                        l=`echo "${A5[$i]} ${A6[$i]} ${A7[$i]} ${A8[$i]}" |sed s/-/"$w"/`
                        echo "$p$r$h${W[$i]}$r $w$l$r" |sed 's/:*$//; s/:/ /g'
                done
                echo "$p $r$f$N$r"

                # transition
                N=`$CAL -m9 -A1 $YEAR |tail -n 1`
                        echo
                printf "$p$q$r$g        %-17s %-17s$r\n" ${M[10]} ${M[11]}
                for i in {0..6}; do
                        if ((i < 5)); then
                                w=
                                h="$(tput setaf 4)"
                        else
                                w="$(tput bold)$(tput setaf 2)"
                                h="$(tput bold)$(tput setaf 4)"
                        fi
                        l=`echo "${A9[$i]} ${A10[$i]}" |sed s/-/"$w"/`
                        echo "$p$q$r$h${W[$i]}$r $w$l$r" |sed 's/:*$//; s/:/ /g'
                done
                echo "$p$q $r$f$N$r"
            )\n"

        # weekday
        elif [[ $1 =~ ^w ]]; then
                # set format
                local FORMAT='%02d.%02d.%d'
                # set format params (year is 4 digits)
                local F1=d
                local S2=m
                local T3=y

                # cmd line
                local DAY=${2-`date +%d`}
                local MON=${3-`date +%m`}
                local YEA=${4-`date +%Y`}

                [[ $YEA =~ ^[0-9]$ ]] && YEA=0$YEA

                # check date
                date -d $YEA-$MON-$DAY >/dev/null || return

                # full year
                [[ $YEA =~ ^[0-9][0-9]$ ]] && YEA=`date -d $YEA-1-1 +%Y`

                # not octal
                DAY=${DAY#0}
                MON=${MON#0}

                # mapping
                [ $F1 = d ] && F1=$DAY && { [ $S2 = m ] && { S2=$MON; T3=$YEA;} || { S2=$YEA; T3=$MON;};}
                [ $F1 = m ] && F1=$MON && { [ $S2 = y ] && { S2=$YEA; T3=$DAY;} || { S2=$DAY; T3=$YEA;};}
                [ $F1 = y ] && F1=$YEA && { [ $S2 = d ] && { S2=$DAY; T3=$MON;} || { S2=$MON; T3=$DAY;};}

                echo
                printf "$FORMAT -=[ %s ]=-\n" $F1 $S2 $T3 "`date -d $YEA-$MON-$DAY +%A`"
                echo

        # luck or bad luck
        elif [[ $1 =~ ^f ]]; then
                local YEAR=`date +%Y`
                local RANGE=1
                local SIGN

                # year
                [[ $2 && $2 =~ ^[0-9]+$ ]] && YEAR=$2
                [[ $YEAR =~ ^[0-9]$ ]] && YEAR=0$YEAR
                [[ $YEAR =~ ^[0-9][0-9]$ ]] && YEAR=`date -d $YEAR-1-1 +%Y`

                # range + sign
                [[ $3 && $3 =~ ^([+-]?)([0-9]+)$ ]] && SIGN=${BASH_REMATCH[1]} && RANGE=${BASH_REMATCH[2]}

                # local Friday
                local NAME=`date -d 2021-08-13 +%A`
                # local short months
                local MONTH=(0 `for i in {1..12}; do date -d $i/1 +%b; done`)

                local BEG=$((YEAR - RANGE))
                local END=$((YEAR + RANGE))

                [[ $SIGN = + ]] && BEG=$YEAR
                [[ $SIGN = - ]] && END=$YEAR

                echo
                echo "\t\t -=[ Friday the 13th ]=-"
                echo

                for ((y = $BEG; y <= $END; ++y)); do
                        local OUT="$y:"

                        for ((m=1; m <= 12; ++m)); do
                                t='- '
                                [[ `date -d $y-$m-13 +%A` = $NAME ]] && t=${MONTH[$m]}
                                t=`printf "% 5s" "$t"`
                                OUT+="$t"
                        done
                        echo "$OUT"

                        ((END - BEG < 5 || y % 5)) || echo
                done

        # fall through to help
        else
                (( ${#LOG} > 21 )) && LOG="${LOG:0:7}...${LOG: -11}"

                printf -v LOG "%-23.23s" "(${LOG:-no log})"

                echo "
        $FUNCNAME d seconds [title]         # countdown timer (*uses zenity*)

        $FUNCNAME u [start] [title]         # countup timer  (with hot start)

        $FUNCNAME a time(GNU date) [title]  # alarm clock            (zenity)

        $FUNCNAME A time(GNU date) [title]  # Alarm Clock silent     (zenity)

        $FUNCNAME l $LOG # alarm clock log       (console)

        $FUNCNAME c [seconds [start]]       # cmdline timer  (quit rst pause)

        $FUNCNAME t [title]                 # current time       (background)

        $FUNCNAME i text [title]            # info window            (zenity)

        $FUNCNAME y [year]                  # seasonal calendar     (console)

        $FUNCNAME w [day [month [year]]]    # weekday               (console)

        $FUNCNAME f [year [[+-]range{1}]]   # Friday the 13th       (console)
        " | eval "$sep"
        fi
}
