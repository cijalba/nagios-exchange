#!/bin/bash
#
  Copyright="(C) 2018 - Carlos Ijalba GPLv3" # <perkolator @ gmail.com>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
########################################################################################################################
#
#  Program: check_klms.sh
#
#  Parameters:
#              $1   -  status --MANDATORY-- (otherwise usage shown)
#
#  Output:
#              3    -  Error:    KLMS couldn't be contacted, or not installed.
#              2    -  CRITICAL: Database Obsolete: [ AntiVirus | AntiSPAM | AntiPhishing ].
#              1    -  WARNING:  Database Outdated: [ AntiVirus | AntiSPAM | AntiPhishing ], KLMS not running, LDAP not connected.
#              0    -  OK:       All KLMS Databases are Up to Date, KLMS running, LDAP connected.
#
#  Description:
#
#    Shell Script for Nagios, checks if the Databases for AV & AntiSPAM of a Kaspersky for Linux Mail Security (KLMS)
#    server are Up to Date, Outdated or Obsolete.
#
#    Verified compatible with the following OS:
#                                      Ubuntu v16.04.1-5 LTS
#                                      CentOS v6.10 (Final)
#                                      Busybox v1.20.0-v1.22.1
#
# Versions       Date        Programmer, Modification
# ------------   ----------  ----------------------------------------------------
# Version=1.01   25/04/2018  Carlos Ijalba, Original GPLv3 open source release.
# Version=1.02   08/08/2018  Carlos Ijalba, Added version control output & improved error handling.
# Version=1.03   09/08/2018  Carlos Ijalba, Added checks: LDAP & KLMS
  Version=1.04 # 10/08/2018  Carlos Ijalba, Fixed regression bug, modified documentation.
#
########################################################################################################################
#set -x

# Constants ###

PROGRAM=$(basename $0)                                  # Name of this script
KLMS_BIN=/opt/kaspersky/klms/bin/klms-control           # PATH of the klms-control KLMS binary
NAGIOS_ERROR=3
NAGIOS_CRIT=2
NAGIOS_WARN=1
NAGIOS_OK=0
RC=0

# Usage ###

if [ $# -lt 1 ]
  then
    cat << EOF

$PROGRAM v$Version - $Copyright

  ERROR - no parameter passed in \$1

     USE:
            $PROGRAM [ status ]

     Reports:
            OK:       All KLMS Databases are Up to Date, KLMS running, LDAP connected.
            WARNING:  Database Outdated: [ AntiVirus | AntiSPAM | AntiPhishing ].
            CRITICAL: Database Obsolete: [ AntiVirus | AntiSPAM | AntiPhishing ], KLMS not running, LDAP not connected.
            Error:    KLMS couldn't be contacted, or not installed.

     Examples:
            $PROGRAM status

EOF
    RC=$NAGIOS_ERROR
    exit $RC
fi
FS=$1


# Main ###


# Check the status of the KLMS program.

sudo $KLMS_BIN --is-program-started 2>/dev/null
if [ $? -eq 0 ]
then
  MSG="OK - KLMS Running."
  RC=$NAGIOS_OK
else
  MSG="CRITICAL - KLMS NOT Running."
  RC=$NAGIOS_CRIT
fi


# Check the status of the Anti-Virus DB.

#OUTPUT="Outdated"              # debug

OUTPUT=`sudo $KLMS_BIN --get-avs-bases-info 2>/dev/null | grep status | cut -f2 -d">" | cut -f1 -d"<"`
case $OUTPUT in

  "Obsolete" ) MSG=$MSG"\nCRITICAL - KLMS AV-DB Obsolete."
               RC=$NAGIOS_CRIT;;

  "UpToDate" ) MSG=$MSG"\nOK - KLMS AV-DB up to date."
               RC=$NAGIOS_OK;;

  "Outdated" ) MSG=$MSG"\nWARNING - KLMS AV-DB Outdated."
               RC=$NAGIOS_WARN;;

  * )          MSG=$MSG"\nERROR - KLMS binaries not found in this machine (review PATH)."
               RC=$NAGIOS_ERROR
               echo -e $MSG
               echo $PROGRAM v$Version
               exit $RC;;
esac


# Check the status of the Anti-SPAM DB.

#OUTPUT="Obsolete"              # debug

OUTPUT=`sudo $KLMS_BIN --get-asp-bases-info 2>/dev/null | grep status | cut -f2 -d">" | cut -f1 -d"<"`
case $OUTPUT in

  "Obsolete" ) MSG=$MSG"\nCRITICAL - KLMS SPAM-DB Obsolete."
               RC=$NAGIOS_CRIT;;

  "UpToDate" ) MSG=$MSG"\nOK - KLMS SPAM-DB up to date."
               RC=`expr $RC + $NAGIOS_OK`;;

  "Outdated" ) MSG=$MSG"\nWARNING - KLMS SPAM-DB Outdated."
               RC=$NAGIOS_WARN;;

  * )          MSG=$MSG"\nERROR - KLMS binaries not found in this machine (review PATH)."
               RC=$NAGIOS_ERROR
               echo -e $MSG
               echo $PROGRAM v$Version
               exit $RC;;
esac


# Check the status of the Anti-Phishing DB.

#OUTPUT="Obsolete"              # debug

OUTPUT=`sudo $KLMS_BIN --get-aph-bases-info 2>/dev/null | grep status | cut -f2 -d">" | cut -f1 -d"<"`
case $OUTPUT in

  "Obsolete" ) MSG=$MSG"\nCRITICAL - KLMS Anti-Phishing-DB Obsolete."
               RC=$NAGIOS_CRIT;;

  "UpToDate" ) MSG=$MSG"\nOK - KLMS Anti-Phishing-DB up to date."
               RC=`expr $RC + $NAGIOS_OK`;;

  "Outdated" ) MSG=$MSG"\nWARNING - KLMS Anti-Phishing-DB Outdated."
               RC=$NAGIOS_WARN;;

  * )          MSG=$MSG"\nERROR - KLMS binaries not found in this machine (review PATH)."
               RC=$NAGIOS_ERROR
               echo -e $MSG
               echo $PROGRAM v$Version
               exit $RC;;
esac


# Check the status of the LDAP connection.

sudo $KLMS_BIN --test-ldap-settings-connection 1>/dev/null 2>&1
if [ $? -eq 0 ]
then
  MSG=$MSG"\nOK - KLMS LDAP Connection is OK."
  RC=`expr $RC + $NAGIOS_OK`
else
  MSG=$MSG"\nCRITICAL - KLMS LDAP Connection Failed."
  RC=$NAGIOS_CRIT
fi


echo -e $MSG
echo $PROGRAM v$Version
exit $RC

# End ###