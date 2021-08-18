# bash-timer-zenity
bash countdown countup timer with zenity + cmdline

## shell function
source with
```
. btz.sh
```

run with
```
Ftimer
```

help screen
```

        Ftimer d seconds [title]    # countdown timer  *uses zenity*

        Ftimer u [seconds] [title]  # countup timer (max: 1.000.000s)

        Ftimer c [seconds [start]]  # cmdline timer (q quit, r reset)

        Ftimer t [title]            # current time (background)

        Ftimer i text [title]       # info window

        Ftimer y [year]             # seasonal calendar (console)

```

For full functionality you have to enable the _OK_ button in the zenity progress dialog! In version 3.32 it is disabled by default.

check
```
d=/usr/share/zenity

cat --number "$d/zenity.ui" | sed -rn /GtkButton.*zenity_progress_ok_button/,/\\/object/p | grep --colour sensitive
```

examples
```
time Ftimer c 5

Ftimer cmdline 0 $((60*60*24-5))
```
