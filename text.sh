#!/bin/sh

# Polybar Player
# Copyright (C) 2021 Tim Clifford
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
# License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

batdir="/sys/class/power_supply/BAT1"
pow=$(cat $batdir/power_now)
# keep a log of the power
if ! [ -f $HOME/.config/polybar/power/pow.txt ] \
		|| [ "$(cat $HOME/.config/polybar/power/pow.txt)" = "" ]; then
	echo $pow > $HOME/.config/polybar/power/pow.txt
fi

# running average of the last 20
lpow=$(cat $HOME/.config/polybar/power/pow.txt)
pow=$(echo "$lpow*(19/20) + $pow/20" | bc -l)
echo $pow > $HOME/.config/polybar/power/pow.txt

# calculate time remaining
eng=$(cat $batdir/energy_full)
eng_rem=$(cat $batdir/energy_now)
time=$(echo "scale=3; $eng_rem / $pow" | bc -l)
time=$(printf "%.2g\n" "$time")

# notify if the time is low, only if discharging
if [ "$(cat $batdir/status)" = "Discharging" ]; then
	if [ "$(echo "$time < 0.5" | bc -l)" = "1" ]; then
		dunstify -h string:x-dunst-stack-tag:battery --urgency=critical \
			"Critical battery, $time hr remaining"
	elif [ "$(echo "$time < 1" | bc -l)" = "1" ]; then
		dunstify -h string:x-dunst-stack-tag:battery \
			"Low battery, $time hr remaining"
	fi
fi

echo -n "$time hr"
