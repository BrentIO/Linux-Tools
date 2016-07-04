import fileinput
import os.path
import sys
#import shutil

#Setup for P5Software linux tools
#Copyright 2016, P5Software, LLC

print '\n'
print '=================================='
print '+ P5 Software Linux Tools        +'
print '+ USBIP Setup                    +'
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
USBIPHome=LinuxToolsHome+"/usbip"

#Collect the required information from the user
machineType=default_input("Setup this machine as a server or client?", "Server")

if machineType.upper() == "SERVER":
    machineType = "Server"
else:
    machineType = "Client"


if machineType == "Client":
    serverFQDN=default_input("What is the FQDN of the server?", "")
    
    print '\n'
    os.system("usbip list -r %s" % serverFQDN)
else:
    print '\n'
    os.system("usbip list -l")

busID=default_input("What bus ID should be used?", "")
installServiceOnCompletion=default_input("Install Service on Completion (Y/N)?","Y")

if installServiceOnCompletion.upper() != "Y":
    installServiceOnCompletion = "N"

installServiceOnCompletion = installServiceOnCompletion.upper()

#Confirm the users' input
print '\n'
print '=================================='
print "+         > Confirmation <       +"
print '=================================='
print "Machine Type: %s" % machineType

if machineType == "Client":
    print "Server FQDN: %s" %serverFQDN

print "Bus ID: %s" % busID
print "Install Service on Completion? %s" % installServiceOnCompletion

print '\n'
userConfirmed=default_input("Is this Correct (Y/N)?","Y")
print '\n'

#Replace the Y/N values with true/false values

if userConfirmed.upper() != "Y":
    print "Destroying the input.  Run setup again to configure."
    sys.exit(1)

if machineType == "Client":
    configurationFile = USBIPHome+"/usbip-Client.conf"
else:
    configurationFile = USBIPHome+"/usbip-Server.conf"

#Write the configuration file
fsConfigurationFile = open( configurationFile, 'w+')

if machineType == "Client":
    fsConfigurationFile.write("serverFQDN=%s\n" % serverFQDN)

fsConfigurationFile.write("busID=%s\n" % busID)
fsConfigurationFile.close()

#Copy the service object over

if installServiceOnCompletion == "Y":
    
    if machineType == "Client":
        print 'Installing the Client Service...'
        os.system("cp /etc/P5Software/Linux-Tools/usbip/usbip-Client /etc/init.d/usbip-Client")
        os.system("touch /var/log/usbip-Client.log && chown root /var/log/usbip-Client.log")
        os.system("update-rc.d usbip-Client defaults")
        os.system("service usbip-Client start")
        print 'Done Installing Client Service.'
    else:
        print 'Installing the Server Service...'
        os.system("cp /etc/P5Software/Linux-Tools/usbip/usbip-Server /etc/init.d/usbip-Server")
        os.system("touch /var/log/usbip-Server.log && chown root /var/log/usbip-Server.log")
        os.system("update-rc.d usbip-Server defaults")
        os.system("service usbip-Server start")
        print 'Done Installing Server Service.'
else:
    print 'The service was not installed at your request.'

#Display a confirmation
print '=================================='
print "+        > Setup Complete <      +"
print '=================================='
print '\n'
sys.exit(0)