#!/usr/bin/env python

# -*- coding: iso8859-1 -*-
#
# $Id: check_smartmon.py,v 1.11 2015/08/03 17:17:18 root Exp $
#
# check_smartmon
# Copyright (C) 2006  daemogorgon.net
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.


"""Package versioning
"""


import os.path
import subprocess
import sys

from optparse import OptionParser


__author__ = "fuller <fuller@daemogorgon.net>"
__version__ = "$Revision: 1.11 $"


# path to smartctl
_smartctlPath = "/usr/sbin/smartctl"

# application wide verbosity (can be adjusted with -v [0-3])
_verbosity = 0


def parseCmdLine(args):
        """Commandline parsing."""

        usage = "usage: %prog [options] device"
        version = "%%prog %s" % (__version__)

        parser = OptionParser(usage=usage, version=version)
	parser.add_option("-d", "--device", action="store", dest="device", default="", metavar="DEVICE",
			help="device to check")
        parser.add_option("-v", "--verbosity", action="store",
                        dest="verbosity", type="int", default=0,
                        metavar="LEVEL", help="set verbosity level to LEVEL; defaults to 0 (quiet), \
                                        possible values go up to 3")
        parser.add_option("-w", "--warning-threshold", metavar="TEMP", action="store",
                        type="int", dest="warningThreshold", default=43,
                        help="set temperature warning threshold to given temperature (defaults to 45)")
        parser.add_option("-c", "--critical-threshold", metavar="TEMP", action="store",
                        type="int", dest="criticalThreshold", default="55",
                        help="set temperature critical threshold to given temperature (defaults to 55)")

        return parser.parse_args(args)
# end


def checkDevice(path):
        """Check if device exists and permissions are ok.
        
        Returns:
                - 0 ok
                - 1 no such device
                - 2 no read permission given
        """

        vprint(3, "Check if %s does exist and can be read" % path)
        if not os.access(path, os.F_OK):
                return (1, "UNKNOWN: no such device found")
        elif not os.access(path, os.R_OK):
                return (2, "UNKNOWN: no read permission given")
        else:
                return (0, "")
        # fi
# end


def checkSmartMonTools(path):
        """Check if smartctl is available and can be executed.

        Returns:
                - 0 ok
                - 1 no such file
                - 2 cannot execute file
        """

        vprint(3, "Check if %s does exist and can be read" % path)
        if not os.access(path, os.F_OK):
                return (1, "UNKNOWN: cannot find %s" % path)
        elif not os.access(path, os.X_OK):
                return (2, "UNKNOWN: cannot execute %s" % path)
        else:
                return (0, "")
        # fi
# end


def callSmartMonTools(path, device):
        # get health status
        #cmd = "%s -H %s" % (path, device)
        #vprint(3, "Get device health status: %s" % cmd)
        #(child_stdin, child_stdout, child_stderr) = os.popen3(cmd)
        p = subprocess.Popen([ path, '-Hi', device ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        child_stdout, child_stderr = p.communicate()
        p.wait()
        """
        if p.returncode != 0 and p.returncode != 32:
                return (3, "UNKNOWN: call exits unexpectedly (%s)" % child_stdout, "",
                                "", 0, 0, 0, 0)
        """
        healthStatusOutput = ""
        for line in child_stdout:
                healthStatusOutput = healthStatusOutput + line
        # done

        # get temperature and sector status
        #cmd = "%s -A %s" % (path, device)
        #vprint(3, "Get device sector and temperature status: %s" % cmd)
        #(child_stdin, child_stdout, child_stderr) = os.popen3(cmd)
        #line = child_stderr.readline()
        p = subprocess.Popen([ path, '-A', device ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        p.wait()
        if p.returncode != 0:
                return (3, "UNKNOWN: call2 exits unexpectedly (%s)" % line, "",
                                "", 0, 0, 0, 0)
        child_stdout, child_stderr = p.communicate()

        temperatureOutput = ""
        id5Output = ""
        id196Output = ""
        id197Output = ""
        id198Output = ""
        for line in child_stdout:
                temperatureOutput = temperatureOutput + line
                id5Output = id5Output + line
                id196Output = id196Output + line
                id197Output = id197Output + line
                id198Output = id198Output + line
        # done

        return (0 ,"", healthStatusOutput, temperatureOutput, id5Output, id196Output, id197Output, id198Output)
 # end


def parseOutput(healthMessage, temperatureMessage, id5Message, id196Message, id197Message, id198Message):
        """Parse smartctl output

        Returns (health status, temperature, sector status).
        """

        # parse health status
        #
        # look for line '=== START OF READ SMART DATA SECTION ==='
        statusLine = ""
        lines = healthMessage.split("\n")
        getNext = 0
        serialNumber = ""
        for line in lines:
                if getNext:
                        statusLine = line
                        break
                elif line == "=== START OF READ SMART DATA SECTION ===":
                        getNext = 1
                elif line[0:14] == "Serial Number:":
                        serialNumber = line.split()[2]
                # fi
        # done
        parts = statusLine.split()
        healthStatus = parts[-1]
        vprint(3, "Health status: %s" % healthStatus)
              
        # parse Reallocated_Sector_Ct
        id5Line = 0
        lines = id5Message.split("\n")
        for line in lines:
                parts = line.split()
                if len(parts):
                        # 5 is the reallocated_sector_ct id
                        if parts[0] == "5":
                                id5Line = int(parts[9])
                                break
                        # fi
                # fi
        # done
        vprint(3, "Reallocated_Sector_Ct: %d" %id5Line)
              
               # parse temperature attribute line
        temperature = 0
        lines = temperatureMessage.split("\n")
        for line in lines:
                parts = line.split()
                if len(parts):
                        # 194 is the temperature value id
                        if parts[0] == "194":
                                temperature = int(parts[9])
                                break
                        # fi
                # fi
        # done
        vprint(3, "Temperature: %d" %temperature)
              
               # parse Reallocated_Event_Count
        id196Line = 0
        lines = id196Message.split("\n")
        for line in lines:
                               parts = line.split()
                               if len(parts):
                                               # 196 is the reallocated_event_count id
                                               if parts[0] == "196":
                                                               id196Line = int(parts[9])
                                                               break
                                               # fi
                               # fi
               # done
        vprint(3, "Reallocated_Event_Count: %d" %id196Line)
              
               # parse Current_Pending_Sector
        id197Line = 0
        lines = id197Message.split("\n")
        for line in lines:
                               parts = line.split()
                               if len(parts):
                                               # 197 is the current_pending_sector id
                                               if parts[0] == "197":
                                                               id197Line = int(parts[9])
                                                               break
                                               # fi
                               # fi
               # done
        vprint(3, "Current_Pending_Sector: %d" %id197Line)
              
               # parse Offline_Uncorrectable
        id198Line = 0
        lines = id198Message.split("\n")
        for line in lines:
                               parts = line.split()
                               if len(parts):
                                               # 198 is the offline_uncorrectable id
                                               if parts[0] == "198":
                                                               id198Line = int(parts[9])
                                                               break
                                               # fi
                               # fi
               # done
        vprint(3, "Offline_Uncorrectable: %d" %id198Line)

        return (healthStatus, temperature, serialNumber, id5Line, id196Line, id197Line, id198Line)
# end


def createReturnInfo(healthStatus, tolerated, temperature, serialNumber, 
                     id5Line, id196Line, id197Line, id198Line, warningThreshold,
                     criticalThreshold):
        """Create return information according to given thresholds."""

        # this is absolutely critical!
        if healthStatus != "PASSED":
                return (2, "CRITICAL: device does not pass health status")
        # fi
              
        # check sectors
        if id5Line > 0 or id196Line > 0 or id197Line > 0 or id198Line > 0:
                msg = "TOLERATED: " if tolerated else "CRITICAL: "
                if id5Line > 0:
                    msg += "Reallocated_Sector_Count=%d, " % id5Line
                if id196Line > 0:
                    msg += "Reallocated_Event_Count=%d, " % id196Line
                if id197Line > 0:
                    msg += "Current_Pending_Sector=%d, " % id197Line
                if id198Line > 0:
                    msg += "Offline_UNC=%d, " % id198Line
                if not tolerated:
                    return(2, "%stemp=%d, serial=%s" % (msg, temperature, serialNumber))
                elif temperature <= warningThreshold:
                    return(0, "%stemp=%d, serial=%s" % (msg, temperature, serialNumber))
        # fi

        if temperature > criticalThreshold:
                return (2, "CRITICAL: temp (%d) exceeds critical (%s) on %s" % (temperature, criticalThreshold, serialNumber))
        elif temperature > warningThreshold:
                return (1, "WARNING: temp (%d) exceeds warning (%s) on %s" % (temperature, warningThreshold, serialNumber))
        else:
                return (0, "OK: device temp=%d serial=%s" % (temperature, serialNumber))
        # fi
# end


def exitWithMessage(value, message):
        """Exit with given value and status message."""

        print message
        sys.exit(value)
# end


def vprint(level, message):
        """Verbosity print.

        Decide according to the given verbosity level if the message will be
        printed to stdout.
        """

        if level <= verbosity:
                print message
        # fi
# end


if __name__ == "__main__":
        (options, args) = parseCmdLine(sys.argv)
        verbosity = options.verbosity

        vprint(2, "Get device name")
        device = options.device
        vprint(1, "Device: %s" % device)

        # check if we can access 'path'
        vprint(2, "Check device")
        (value, message) = checkDevice(device)
        if value != 0:
                exitWithMessage(3, message)
        # fi

        # check if we have smartctl available
        (value, message) = checkSmartMonTools(_smartctlPath)
        if value != 0:
                exitWithMessage(3, message)
        # fi
        vprint(1, "Path to smartctl: %s" % _smartctlPath)

        # call smartctl and parse output
        vprint(2, "Call smartctl")
        (value, message, healthStatusOutput, temperatureOutput, id5Output, id196Output, id197Output, id198Output) = callSmartMonTools(_smartctlPath, device)
        if value != 0:
                exitWithMessage(value, message)
        vprint(2, "Parse smartctl output")
        (healthStatus, temperature, serialNumber, id5Line, id196Line, id197Line, id198Line) = parseOutput(healthStatusOutput, temperatureOutput, id5Output, id196Output, id197Output, id198Output)
        vprint(2, "Generate return information")
        # Tolerated errors
        tolerated = False
        if ((id5Line == 18 and id198Line == 0 and serialNumber == 'PN2334PCKT7UMB') or
            (id5Line == 8 and id198Line == 0 and serialNumber == 'W1F1GW6Q') or
            (id198Line == 16 and serialNumber == 'Z1F0T2FE') or
            (id5Line == 1776 and id198Line == 0 and serialNumber == 'Z1F0TAH8') or
            (id5Line == 0 and id197Line == 1069 and id198Line == 1069 and serialNumber == '5XW07ALG') or
            (id5Line == 8 and id198Line == 40 and serialNumber == 'W1F1GV68') or
            (id5Line == 45 and id196Line == 45 and serialNumber == '170815FF2689') or
            (id5Line == 12 and id196Line == 12 and serialNumber == '1631137A183D')):
            tolerated = True
       
        (value, message) = createReturnInfo(healthStatus, tolerated, temperature, serialNumber, id5Line, id196Line, id197Line, id198Line,
                        options.warningThreshold, options.criticalThreshold)

        # exit program
        exitWithMessage(value, message)

# fi
