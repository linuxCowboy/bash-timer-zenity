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

        Ftimer c [seconds]          # cmdline timer (q to quit)

```

For full functionality you have to enable the _OK_ button in the zenity progress dialog! In version 3.32 it is disabled by default.
