
# Sysm

Conky-like Linux (kernel dependant) system monitoring program

Requirements:

	Basics:
        bash, cat, grep, head, awk, sleep, echo, sed, tr, tail
	Date:
        date, time, uptime
	Networking:
        ss, iproute2, wireless_tools
	Hardware monitoring:
        sensors, free, ps
	[Optional] Nvidia GPU monitoring:
        nvidia-smi
	[Optional] GUI:
        yad

Usage:

	./sysm [arguments]

Arguments include:

		--stealth: Hides sensitive info from output, including wifi name, channel, local IP, and MAC address
		--gui: Enables a Zenity-based graphical interface
		--amd: Toggles displaying AMD video card info. Warning, might break if one isn't installed.
		--nvidia: Toggles displaying Nvidia video card info. Warning, might break if one isn't installed.

Example output:

```
Time: 21:48:55 UTC, 16:48:55 here
Date: 06.25.2023 - Sunday
Uptime: 1 day, 10 hours, 38 minutes

No battery detected
AC Adapter: Connected

Not connected to wifi
Connected to wired network
Assigned as 192.168.0.2 on wlan0
MAC Address: 00:00:00:00:00:00
Speed: 0B/s down, 70B/s up
Available entropy: 256

Core temperature: 44.2°C
First core frequency: 2968.909MHz
CPU usage: 2.49066%
RAM usage: 3461 / 23980 -  14.4329%
Swap usage: 226 / 12287 -  1.83934%

GPU stats:
 Power: 23.56 W; Usage: 13%;
 FanSpd: 35%; Temperature: 40°C;

Processes: 430 up, 1 running
Most intensive processes:
MEM%  CPU%  PID NAME
 2.7  2.2    5838 firefox

Processes accessing the network:
mpd
ncmpcpp
```
