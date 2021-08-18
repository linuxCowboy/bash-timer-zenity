# o is a *perl* one-liner to add thousands separator
alias o='perl -pe'\''while(/\d{5,}|[03-9]\d{3}/){$b=$`;$m=$&;$a=$'\'\\\'\'';$m=~s/(?<=\d)(?=(\d{3})+\b)/./;$_="$b$m$a"}'\'

Ftimer ()
{
        #######################################
        ### bash shell function with zenity ###
        #######################################

        # Enable OK/Pause Button in zenity progress dialog
        #
        # Version: 3.32
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
        #     sed -rn /GtkButton.*zenity_progress_ok_button/,/\\/object/p |
        #         grep --colour=always sensitive

        # countup limit in seconds (~ runs forever/till quit)
        local LIMIT=1000000

        # commands
        local CMD='zenity --modal'
        local CAL='ncal -M -w -W5'  # start Monday, number weeks, 1. Week 5 days

        # needs zenity for up + down
        [[ $1 =~ ^(u|d) ]] && ! type ${CMD%% *} >/dev/null && return

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
                local START=0  # for pause/resume
                local PULSE='--pulsate'  # pulse bar if unlimited
                local FILE=$(mktemp)  # get the counter back from subshell

                # a fixed time run with percentage indicator
                [[ $2 =~ ^[0-9]+$ ]] && LIMIT=$2 && PULSE=  && shift

                while (($START < $LIMIT)); do
                        for i in `seq $(($START + 1)) $LIMIT`; do
                                echo $i >$FILE
                                printf -v t "%01d:%02d:%02d" $((i / 3600)) $((i / 60 % 60)) $((i % 60))

                                if [[ $PULSE ]]; then
                                        echo "#Countup: $t"  # unlimited
                                else
                                        echo "$((${i}00 / $LIMIT))\n#Countup: $t"  # fixed
                                fi
                                sleep 1
                        done | WINDOWID=  $CMD --progress $PULSE --cancel-label='Quit' --ok-label='Pause' --title="${2-Timer}"

                        # zenity return value: okay = 0, quit = 1
                        (($?)) && break

                        START=$(< $FILE)
                        (($START == $LIMIT)) && break

                        printf -v t "%01d:%02d:%02d" $((START / 3600)) $((START / 60 % 60)) $((START % 60))

                        # shell handles the pause/restart
                        read -sn1 -p "Last: $t (key to continue | q to quit | r to reset)"
                        echo
                        [[ $REPLY = q ]] && break
                        [[ $REPLY = r ]] && START=0
                done
                # I try not to litter.
                \rm $FILE

        # cmdline only (no zenity)
        elif [[ $1 =~ ^c ]]; then
                for ((i=${3-1}; ; ++i)); do
                        # bonus: value 0 falls through/runs forever
                        [[ $2 =~ ^[1-9][0-9]*$ ]] && ((i > $2)) && return

                        # delay and input in one call :-)
                        read -sn1 -t1
                        [[ $REPLY = q ]] && return
                        [[ $REPLY = r ]] && i=${3-1}

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
                local DATE=`date '+%d. %b\n\n%T'`

                (WINDOWID=  $CMD --info --text "$DATE" --title="${2-Time}" &)

        # info
        elif [[ $1 =~ ^i && $2 ]]; then
                WINDOWID=  $CMD --info --text "$2" --title="${3-Info}"

        # year
        elif [[ $1 =~ ^y ]]; then
                local YEAR=${2-`date +%Y`}

                echo
                $CAL -m11p -A3 $YEAR # winter
                echo
                $CAL -m3   -A1 $YEAR # transition
                echo
                $CAL -m5   -A3 $YEAR # summer
                echo
                $CAL -m9   -A1 $YEAR # transition
                echo

        # fall through to help
        else
                echo "
        $FUNCNAME d seconds [title]    # countdown timer  *uses zenity*

        $FUNCNAME u [seconds] [title]  # countup timer (max: ${LIMIT}s)

        $FUNCNAME c [seconds [start]]  # cmdline timer (q quit, r reset)

        $FUNCNAME t [title]            # current time (background)

        $FUNCNAME i text [title]       # info window

        $FUNCNAME y [year]             # seasonal calendar (console)
        " | o
        fi
}

