import socket
import fileinput
import shutil
import sys
import os.path

#Setup for P5Software socat-ZWave tool
#Copyright 2016, P5Software, LLC

print '\n'
print '=================================='
print '+ P5 Software socat-ZWave Tool   +'
print '+ Initial Setup                  +'
print '=================================='
print '\n'

#define a reusable function with a default value
def default_input( message, defaultVal ):
    if defaultVal:
        return raw_input( "%s [%s]:" % (message,defaultVal) ) or defaultVal
    else:
        return raw_input( "%s " % (message) )

#Define variables the user doesn't get to modify
P5SoftwareHome="/etc/P5Software"
LinuxToolsHome=P5SoftwareHome+"/Linux-Tools"
configurationFile=LinuxToolsHome+"/socat/socat-ZWave.conf"

#Collect the required information from the user
serialServerName=default_input("Serial Server Name?", "")
serialServerPort=default_input("Serial Server Port?", "10001")
localDevice=default_input("Local Device Location?", "/home/shared/zwave")
socatLocation=default_input("Socat Executable Location?", "/usr/bin/socat")

#Confirm the users' input
print '\n'
print '=================================='
print "+         > Confirmation <       +"
print '=================================='
print "Serial Server Name: %s" % serialServerName
print "Serial Server Port: %s" % serialServerPort
print "Local Device: %s" % localDevice
print "Socat Executable Location: %s" % socatLocation

print '\n'
userConfirmed=default_input("Is this Correct (Y/N)?","Y")
print '\n'

if userConfirmed.upper() != "Y":
    print "Destroying the input.  Run setup again to configure."
    sys.exit(1)

#Write the configuration file
fsConfigurationFile = open( configurationFile, 'w')
fsConfigurationFile.write("serialServerName=%s\n" % serialServerName)
fsConfigurationFile.write("serialServerPort=%s\n" % serialServerPort)
fsConfigurationFile.write("localDevice=%s\n" % localDevice)
fsConfigurationFile.write("socatLocation=%s\n" % socatLocation)
fsConfigurationFile.close()

#Display a confirmation
print '=================================='
print "+        > Setup Complete <      +"
print '=================================='
print '\n'
sys.exit(0)