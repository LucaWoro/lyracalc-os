#!/bin/sh
# Boot finished: no more kernel and journal messages on the console
sysctl -q -w "kernel.printk=3 4 1 7"
mkdir -p /run/systemd/journald.conf.d
printf '[Journal]\nForwardToConsole=no\n' > /run/systemd/journald.conf.d/99-quiet.conf
systemctl restart systemd-journald
