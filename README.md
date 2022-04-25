# bash-timer-zenity
bash countdown countup timer with zenity + cmdline

## shell function
add this to your .bash_aliases

test with
```
. btz.sh
```

run with
```
Ftimer
```

help screen
![help](screenshot.png?raw=true)

For full functionality you have to enable the _OK_ button in the zenity progress dialog! In version 3.42 it is disabled by default.

check
```
d=/usr/share/zenity

cat --number "$d/zenity.ui" | sed -rn '/GtkButton.*zenity_progress_ok_button/, \%/object%p' | grep --color sensitive
```

examples
```
time Ftimer c 5

Ftimer cmdline 0 $((60*60*24-5))

Ftimer s +10min &
```
