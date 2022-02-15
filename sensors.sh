#! /bin/sh

# Copyright (c) 2022 Slawomir Wojciech Wojtczak (vermaden)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that following conditions are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS 'AS IS' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# ------------------------------
# SIMPLE SENSORS INFORMATION
# ------------------------------
# vermaden [AT] interia [DOT] pl
# https://vermaden.wordpress.com

__usage() {
  local NAME=${0##*/}
  echo "USAGE:"
  echo "  ${NAME} (without any arguments)"
  echo
  echo "NOTES:"
  echo "  load these modules to get all the temperature data:"
  echo "    - amdtemp.ko"
  echo "    - coretemp.ko"
  echo
  echo "  install 'smartmontools' package for disks temperatures:"
  echo "    # pkg install smartmontools"
  echo
  echo "  you need to execute as 'root' to get disks temperatures"
  echo "    # ${NAME}"
  echo "    % doas ${NAME}"
  echo "    $ sudo ${NAME}"
  echo
  exit 1
}

if [ "${1}" = "-h"    -o \
     "${1}" = "help"  -o \
     "${1}" = "-help" -o \
     "${1}" = "--help" ]
then
  __usage
fi

SYSCTL_A=$( sysctl -a )

echo
printf "%38s\n" 'BATTERY/AC/TIME/FAN/SPEED '
printf "%38s\n" '------------------------------------ '
echo "${SYSCTL_A}" \
  | grep -e hw.acpi.cpu.cx_lowest \
         -e hw.acpi.acline \
         -e hw.acpi.battery.life \
         -e hw.acpi.battery.time \
         -e \.fan \
  | while read MIB VALUE
    do
      printf "%38s %s\n" ${MIB} ${VALUE}
    done
echo

printf "%38s\n" 'SYSTEM/TERMEPATURES '
printf "%38s\n" '------------------------------------ '
echo "${SYSCTL_A}" \
  | grep -e temperature \
  | while read MIB VALUE
   do
     printf "%38s %s\n" ${MIB} ${VALUE}
   done
echo

if [ $( whoami ) != "root" ]
then
  exit 0
fi

if ! which smartctl 1> /dev/null 2> /dev/null
then
  exit 0
fi

printf "%38s\n" 'DISKS/TERMEPATURES '
printf "%38s\n" '------------------------------------ '
for I in $( sysctl -n kern.disks )
do
  smartctl -a /dev/${I} \
    | sed -E 's|\(.*\)||g' \
    | grep -e Temperature_ \
    | awk -v DISK=${I} \
        '{MIB="smart." DISK "." tolower($2) ":"; printf("%38s %s.0C\n", MIB, $NF)}'
done
echo