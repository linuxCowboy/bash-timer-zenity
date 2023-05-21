my_ftimer_edits ()
{
        # Post-it Note
        P1=(  # 16 x 7
                '┌──────────────┐'
                '│              │'
                '│              │'
                '│  Post-it 1   │'
                '│              │'
                '│              │'
                '└──────────────┘')

        P2=(  # 13 x 7
                '┌───────────┐'
                '│           │'
                '│           │'
                '│ Post-it 2 │'
                '│           │'
                '│           │'
                '└───────────┘')

        P3=(
                '┌──────────────┐'
                '│              │'
                '│              │'
                '│  Post-it 3   │'
                '│              │'
                '│              │'
                '└──────────────┘')

        P4=(
                '┌───────────┐'
                '│           │'
                '│           │'
                '│ Post-it 4 │'
                '│           │'
                '│           │'
                '└───────────┘')

        # disable Notes
#        unset P1
#        unset P2
#        unset P3
#        unset P4

        # holiday: full year-month-day  [+x next days]  +=cmdline
        HOLS='2023-4-7+3 2023-5-18 2023-5-28+1'

        # very important day:  [full year/]month/day  +=cmdline
        VID='2/14 4/5  7/31  5/9 9/5  2023/3/26 2023/10/29'

        # sun/moon basis
        CTRY='germany'
        CITY='stuttgart'
}

Ftimer ()  ##:t
{
        #######################################
        ### bash shell function with zenity ###
        #######################################

        # Enable OK/Pause Button in zenity progress dialog
        #
        # Version: 3.44
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

        # define vars for outsourced edit
        local P1 P2 P3 P4  # Post-it
        local HOLS HOLSX   # Holiday
        local VID          # Very Important Day
        local CTRY
        local CITY

        my_ftimer_edits

        # permanent hols:  month/day
        local PERM='1/1 5/1 10/3 12/25 12/26'

        # alarm clock logging if set
        local LOG='/tmp/Ftimer.log'

        # alarm tone if set
        local PLAYER='/usr/bin/mpg321 -q'  # full path
        local MIXER='/usr/bin/amixer -q set Master unmute 60%'
        local FILE='/usr/local/bin/okay.mp3'

        # commands
        local CMD='zenity --modal'
        local CAL='ncal -M -w -W5'  # start Monday, number weeks, 1. Week 5 days

        # scrape sun/moon and debug
        local GET='curl --fail --silent'
        local CHK='curl --fail --verbose'
        local SUN="https://www.timeanddate.com/sun"
        local AUX="https://www.timeanddate.com/worldclock"

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

        # check commands
        [[ $1 =~ ^(d|u|a|A|t|i) ]] && ! type ${CMD%% *} >/dev/null && return

        [[ $1 =~ ^y ]]             && ! type ${CAL%% *} >/dev/null && return

        [[ $1 =~ ^(s|S) ]]         && ! type ${GET%% *} >/dev/null && return
        [[ $1 =~ ^(s|S) ]]         && ! type ${CHK%% *} >/dev/null && return

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
                local FILE=$(mktemp -p ${XDG_RUNTIME_DIR:-/tmp})  # get the counter back from subshell

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
                echo "=== now ==="
                date

        # cmdline only (no zenity)
        elif [[ $1 =~ ^(c|C) ]]; then
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

                        # 7 segment digits
                        if [[ $1 =~ ^C ]]; then
                                t=$(echo -n $t |perl -C -pe 'y/0123456789/\N{U+1FBF0}-\N{U+1FBF9}/')
                                printf "%6s%s%24s\r" "" "$t" ""  # unicode probs
                        else
                                printf "%12s\r" $t
                        fi
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
                YEAR=$y
                FIX=

                while [[ $2 ]]; do
                        if [[ $2 =~ [+-] ]]; then
                                HOLS+=" $2"

                        elif [[ $2 =~ / ]]; then
                                VID+=" $2"
                        else
                                YEAR=$2
                                FIX=1
                        fi
                        shift
                done

                for i in $HOLS; do
                        if [[ $i =~ \+ ]]; then
                                x=${i#*+}
                                h=${i%+*}

                                for ((x++; x; --x)); do
                                        HOLSX+=" $h"
                                        h=`date -d $h+1day +%F`
                                done
                        else
                                HOLSX+=" $i"
                        fi
                done

                for i in $VID $HOLSX $PERM; do
                        date -d $i >/dev/null || return
                done

                YEAR=`date -d $YEAR-1-1 +%Y` || return  # check + 4 digits

                ncal $YEAR >/dev/null || return

                [[ ! $FIX && $m =~ 11|12 ]] && ((++YEAR))  # Winter is Coming

                r="$(tput sgr0)"
                M=(`for i in 11 12 {1..10};do date -d $i/1 +%B;done`)  # full month
                W=(Mon Tue Wed Thu Fri Sat Sun)  # 3 chars

                # core
                for i in 11p 12p {1..10}; do
                        declare -n X=A$i  # nameref
                        X=(`$CAL -m$i $YEAR |sed -n '2,8 s/ /:/gp' |cut -c 4-`)

                        if [[ $YEAR = $y && $i = $m ]] ||
                                [[ $YEAR = $((y + 1)) && $i = ${m}p ]]; then  # today
                                        c="$(tput rev)"  # alternative
                                        c="$(tput rev)$(tput bold)$(tput setaf 3)"

                                        if ((d < 10)); then
                                                X=(`echo "${X[*]}" |sed 's/:'$d'\b/'"$r$c:$d$r-"/`)
                                        else  # - is marker
                                                X=(`echo "${X[*]}" |sed 's/\b'$d'\b/'"$r$c$d$r-"/`)
                                        fi
                        fi

                        for j in $PERM; do
                                [[ `date -d $j +%-m:%-d` =~ ([0-9]+):([0-9]+) ]] &&
                                        pm=${BASH_REMATCH[1]} && pd=${BASH_REMATCH[2]}

                                if [[ $i = $pm || $i = ${pm}p ]]; then  # perm
                                        c="$(tput bold)$(tput setab 5)"

                                        if ((pd < 10)); then
                                                X=(`echo "${X[*]}" |sed 's/:'$pd'\b/'"$c:$pd$r-"/`)
                                        else  # no color reset
                                                X=(`echo "${X[*]}" |sed 's/'$pd'\b/'"$c$pd$r-"/`)
                                        fi
                                fi
                        done

                        for j in $HOLSX; do
                                k=`date -d $j +%Y:%-m:%-d`
                                hy=${k%%:*}
                                hm=${k%:*}
                                hm=${hm#*:}
                                hd=${k##*:}

                                if [[ $YEAR = $hy && $i = $hm ]] ||
                                        [[ $YEAR = $((hy + 1)) && $i = ${hm}p ]]; then  # hols
                                                c="$(tput bold)$(tput setab 5)"

                                                if ((hd < 10)); then
                                                        X=(`echo "${X[*]}" |sed 's/:'$hd'\b/'"$c:$hd$r-"/`)
                                                else  # no color reset
                                                        X=(`echo "${X[*]}" |sed 's/'$hd'\b/'"$c$hd$r-"/`)
                                                fi
                                fi
                        done

                        ### 4/5/2020 and 2020/4/5 are both valid! ###
                        for j in $VID; do
                                k=`date -d $j +%Y:%-m:%-d`

                                vy=${k%%:*}
                                vm=${k%:*}
                                vm=${vm#*:}
                                vd=${k##*:}

                                [[ $j =~ /.+/ && ! (($YEAR = $vy && $i = $vm) ||
                                        ($YEAR = $((vy + 1)) && $i = ${vm}p)) ]] &&
                                                continue  # year optional

                                if [[ $i = $vm || $i = ${vm}p ]]; then  # vid
                                        c="$(tput bold)$(tput setab 1)"

                                        if ((vd < 10)); then
                                                X=(`echo "${X[*]}" |sed 's/:'$vd'\b/'"$c:$vd$r-"/`)
                                        else  # no color reset
                                                X=(`echo "${X[*]}" |sed 's/'$vd'\b/'"$c$vd$r-"/`)
                                        fi
                                fi
                        done
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
                        l=`echo "${A11p[$i]} ${A12p[$i]} ${A1[$i]} ${A2[$i]}" |sed s/-/"$w"/g`
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
                        l=`echo "${A3[$i]} ${A4[$i]}" |sed s/-/"$w"/g`
                        l=`echo "$r$h${W[$i]}$r $w$l$r" |sed 's/:*$//; s/:/ /g'`
                        printf "$p%16s  $l  %13s\n" "${P1[$i]}" "${P2[$i]}"
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
                        l=`echo "${A5[$i]} ${A6[$i]} ${A7[$i]} ${A8[$i]}" |sed s/-/"$w"/g`
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
                        l=`echo "${A9[$i]} ${A10[$i]}" |sed s/-/"$w"/g`
                        l=`echo "$r$h${W[$i]}$r $w$l$r" |sed 's/:*$//; s/:/ /g'`
                        printf "$p%16s  $l  %13s\n" "${P3[$i]}" "${P4[$i]}"
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
                [[ $YEAR =~ ^[0-9][0-9]$ ]] && YEAR="`date -d $YEAR-1-1 +%Y`"

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

        # diff
        elif [[ $1 =~ ^h && $2 ]]; then
                date -d "$2" >/dev/null || return
                local ASK=`date -d "$2" +%s`

                local NOW=`date +%s`
                if [[ $3 ]]; then
                        date -d "$3" >/dev/null || return
                        NOW=`date -d "$3" +%s`
                fi

                local DIFF=$((ASK - NOW < 0 ? NOW - ASK : ASK - NOW))

                local SEC=$((DIFF % 60))
                local MIN=$((DIFF / 60))
                local HOU=$((DIFF / 60 / 60))
                local DAY=$((DIFF / 60 / 60 / 24))

                local YEAR
                ((DAY > 364)) && YEAR=`perl -e 'printf "%.1f", eval '$DAY/365`

                date -d "@$NOW" +%c
                date -d "@$ASK" +%c
                        echo "---"
                printf "%d day %d hour %d min %d sec\n" $DAY $((HOU % 24)) $((MIN % 60)) $SEC
                printf "%d Hours  or  %d Minutes  or  %d Seconds\n" $HOU $MIN $DIFF |eval "$sep"
                [[ ! $YEAR ]] || echo "~$YEAR years"
                return

        # sun
        elif [[ $1 =~ ^(s|S) ]]; then
                local DEBUG=0
                [[ $1 == 'S' ]] && DEBUG=1

                local NOW=now
                if [[ $2 =~ ^[0-9/-]+$ ]]; then
                        date -d $2 >/dev/null || return
                        NOW=$2
                        shift
                fi

                CITY=${2-$CITY}
                CTRY=${3-$CTRY}

                # header
                u="$AUX/$CTRY/$CITY";
                h=`$GET "$u"`

                if (($?)); then
                        echo "$u"
                                perl -E 'say "=" x '$COLUMNS
                        h=`$CHK "$u"`
                        r=$?
                                perl -E 'say "=" x '$COLUMNS
                        echo "$h"
                        return $r
                fi

                (($DEBUG)) && echo "$u"

                printf "\nSunlight:  %s / %s  " ${CITY^} ${CTRY^}

                echo "$h" | perl -nE '
                        if (/<tr><th[^>]*Latitude and Longitude.*?<\/tr>/) {
                                say "\n|$&|" if '$DEBUG';

                                if ($& =~ /<td.*?>\s*(\d+)°.*?([NESW]).*?(\d+)°.*([NESW])/) {
                                        printf("%d %s / %d %s  ", $1, $2, $3, $4);
                                }
                        }

                        if (/<tr><th[^>]*Altitude.*?<\/tr>/) {
                                say "\n|$&|" if '$DEBUG';

                                if ($& =~ /<td.*>\s*(.*)<\/td>/) {
                                        printf("%s\n", $1);
                                }
                        }
                '

                # yesterday
                read d m y <<<`date -d $NOW-1day +"%-d %-m %Y"`

                u="$SUN/$CTRY/$CITY?month=$m&year=$y"
                h=`$GET "$u"`

                if (($?)); then
                        echo "$u"
                                perl -E 'say "=" x '$COLUMNS
                        h=`$CHK "$u"`
                        r=$?
                                perl -E 'say "=" x '$COLUMNS
                        echo "$h"
                        return $r
                fi

                (($DEBUG)) && echo "\n$u"

                H=`echo "$h" |sed 's/id=as-monthsun/&'$d/`

                # today
                l=$m
                read d m y <<<`date -d $NOW +"%-d %-m %Y"`

                if ((l != m)) {
                        u="$SUN/$CTRY/$CITY?month=$m&year=$y"
                        h=`$GET "$u"`

                        if (($?)); then
                                echo "$u"
                                        perl -E 'say "=" x '$COLUMNS
                                h=`$CHK "$u"`
                                r=$?
                                        perl -E 'say "=" x '$COLUMNS
                                echo "$h"
                                return $r
                        fi

                        (($DEBUG)) && echo "\n$u"
                }

                H+=`echo "$h" |sed 's/id=as-monthsun/&'$d/`

                # tomorrow
                l=$m
                read d m y <<<`date -d $NOW+1day +"%-d %-m %Y"`

                if ((l != m)) {
                        u="$SUN/$CTRY/$CITY?month=$m&year=$y"
                        h=`$GET "$u"`

                        if (($?)); then
                                echo "$u"
                                        perl -E 'say "=" x '$COLUMNS
                                h=`$CHK "$u"`
                                r=$?
                                        perl -E 'say "=" x '$COLUMNS
                                echo "$h"
                                return $r
                        fi

                        (($DEBUG)) && echo "\n$u"
                }

                H+=`echo "$h" |sed 's/id=as-monthsun/&'$d/`

                echo "$H" | perl -nE '
                        BEGIN {
                                $yes = '`date -d $NOW-1day +%d`';
                                $now = '`date -d $NOW      +%d`';
                                $tom = '`date -d $NOW+1day +%d`';
                                ($x, $x, $x, $yes) = localtime(time - 86400);
                                ($x, $x, $x, $now) = localtime;
                                ($x, $x, $x, $tom) = localtime(time + 86400);

                                $AT = "Astro  Twilight:";
                                $NT = "Nautic Twilight:";
                                $CT = "Civil  Twilight:";
                                $DT = "       Daylight:";
                                $ct = "Civil  Twilight:";
                                $nt = "Nautic Twilight:";
                                $at = "Astro  Twilight:";
                                $dt = "          Night:";
                        }
                        for $i ($yes, $now, $tom) {
                                $A = "A$i";
                                $a = "a$i";
                                $d = "d$i";
                                if (/<table[^>]*id=as-monthsun$i/) {
                                        if(/<tr[^>]*data-day=$i\b.*?<\/tr>/) {
                                                $s = $&;
                                                while ($s =~ /<td[^>]*>(.*?)<\/td>/g) {
                                                        $T = $&;
                                                        $t = $1;

                                                        $t =~ s|\s*<span.*span>||;
                                                        $t =~ s/\s*<br>/ /g;
                                                        $t =~ s/([^<]*).*/$1/;

                                                        $c = ($T =~ /colspan=(\d+)/) ? $1 : 1;

                                                        while ($c--) {
                                                                push @$A, $T;
                                                                push @$a, $t;
                                                                push @$d, ($t =~ /(\d+):(\d+)/) ? $1 * 60 + $2 : "";
                                                        }
                                                }

                                                                say "";
                                                say "|@$A[4]|" if '$DEBUG';
                                                $d1 = "(+" . (@$d[6] - @$d[4]) . ")" if (@$d[4] && @$d[6]);
                                                $AT .= "  @$a[4] $d1";

                                                say "\n|@$A[6]|" if '$DEBUG';
                                                $d2 = "(+" . (@$d[8] - @$d[6]) . ")" if (@$d[6] && @$d[8]);
                                                $NT .= "  @$a[6] $d2";

                                                say "\n|@$A[8]|" if '$DEBUG';
                                                $d3 = "(+" . (@$d[0] - @$d[8]) . ")" if (@$d[8] && @$d[0]);
                                                $CT .= "  @$a[8] $d3";

                                                say "\n|@$A[0]|" if '$DEBUG';
                                                $DT .= "  @$a[0]";
                                                        say "";
                                                say "\n|@$A[1]|" if '$DEBUG';
                                                $d4 = "(+" . (@$d[9] - @$d[1]) . ")" if (@$d[1] && @$d[9] && @$d[9] > @$d[1]);
                                                $ct .= "  @$a[1] $d4";

                                                say "\n|@$A[9]|" if '$DEBUG';
                                                $d5 = "(+" . (@$d[7] - @$d[9]) . ")" if (@$d[9] && @$d[7] && @$d[7] > @$d[9]);
                                                $nt .= "  @$a[9] $d5";

                                                say "\n|@$A[7]|" if '$DEBUG';
                                                $d6 = "(+" . (@$d[5] - @$d[7]) . ")" if (@$d[7] && @$d[5] && @$d[5] > @$d[7]);
                                                $at .= "  @$a[7] $d6";

                                                say "\n|@$A[5]|" if '$DEBUG';
                                                $dt .= "  @$a[5]";
                                                        say "";
                                                say "\nRemaining Slots:" if '$DEBUG';
                                                say "\n|@$A[2]| " if '$DEBUG';
                                                say "\n|@$A[3]| " if '$DEBUG';
                                                say "\n|@$A[10]|" if '$DEBUG';
                                                say "\n|@$A[11]|" if '$DEBUG';
                                                say "=" x '$COLUMNS';
                                        }
                                }
                        }
                        END {
                                say "$AT";
                                say "$NT";
                                say "$CT";
                                say "$DT";
                                say "$ct";
                                say "$nt";
                                say "$at";
                                say "$dt";
                        }
                '

        # fall through to help
        else
                (( ${#LOG} > 21 )) && LOG="${LOG:0:7}...${LOG: -11}"

                printf -v LOG "%-23s" "(${LOG:-no log})"

                echo "
        $FUNCNAME d seconds [title]          # countdown timer (*uses zenity*)

        $FUNCNAME u [start] [title]          # countup timer  (with hot start)

        $FUNCNAME a time(GNU date) [title]   # alarm clock            (zenity)

        $FUNCNAME A time(GNU date) [title]   # Alarm Clock silent     (zenity)

        $FUNCNAME l $LOG  # alarm clock log       (console)

        $FUNCNAME c [seconds [start]]        # cmdline timer  (Quit Rst Pause)

        $FUNCNAME C [seconds [start]]        # Cmdline Timer       (\U1FBF7 segment)

        $FUNCNAME t [title]                  # current time       (background)

        $FUNCNAME i text [title]             # info window            (zenity)

        $FUNCNAME y [year] [hols] [VID]      # seasonal calendar     (console)

        $FUNCNAME w [day [month [year]]]     # weekday               (console)

        $FUNCNAME f [year [[+-]range{1}]]    # Friday the 13th       (console)

        $FUNCNAME h date1 [date2{now}]       # hour/day difference   (console)

        $FUNCNAME s [date] [city [country]]  # sunrise / sunset      (console)

        $FUNCNAME S [date] [city [country]]  # sun* debug            (console)
        "
        fi
} # Ftimer
