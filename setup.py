import socket
import fileinput
import os.path

#Setup for P5Software linux tools
#Copyright 2016, P5Software, LLC

print '=================================='
print '+ P5 Software Linux Tools        +'
print '+ Initial Setup                  +'
print '=================================='

#define a reusable function with a default value
def default_input( message, defaultVal ):
    if defaultVal:
        return raw_input( "%s [%s]:" % (message,defaultVal) ) or defaultVal
    else:
        return raw_input( "%s " % (message) )

#Define variables the user doesn't get to modify
P5SoftwareHome="/etc/P5Software/Linux-Tools"
configurationFile=P5SoftwareHome+"/s3cmd.conf"
s3IncludeFile=P5SoftwareHome+"/s3cmd/s3cmd.include"
s3ExcludeFile=P5SoftwareHome+"/s3cmd/s3cmd.include"
s3BucketName = ""

#Collect the required information from the user
serverHostname=default_input("Server Hostname?", socket.gethostname().upper())
serverFQDN=default_input("Server FQDN?", socket.getfqdn())

#Use the inverse of the FQDN as the default bucket name
s3BucketName_array = [x.strip() for x in serverFQDN.split('.')]

#Iterate through the FQDN to get the suggested S3 bucket name
i = len(s3BucketName_array)-1
while i > 0:
        s3BucketName = s3BucketName + s3BucketName_array[i] + "."
        i = i-1

#Append the hostname to the bucket name
s3BucketName = s3BucketName + serverHostname

s3BucketName=default_input("S3 Bucket?",s3BucketName.lower())
emailAddress=default_input("Confirmation E-Mail Address?","")
isDatabaseServer=default_input("Is this a MongoDB Server? (Y/N)", "N")
isDryRun=default_input("Enable Dry-Run? (Y/N)", "Y")

#Confirm the users' input
print '=================================='
print "Confirmation"
print '=================================='
print "Server Hostname: %s" % serverHostname
print "Server FQDN: %s" % serverFQDN
print "Amazon S3 Bucket Name: %s" % s3BucketName
print "Confirmation E-Mail Address: %s" % emailAddress
print "MongoDB Server: %s" % isDatabaseServer.upper()
print "Dry-Run Enabled: %s" % isDryRun.upper()

userConfirmed=default_input("Is this Correct (Y/N)?","Y")

#Replace the Y/N values with true/false values

if isDatabaseServer.upper == "Y":
        isDatabaseServer="true"
else:
        isDatabaseServer="false"

if isDryRun.upper == "Y":
        isDryRun="true"
else:
        isDryRun="false"

#Change the file names of the example include and excludes if the files don't already exist
if os.path.isfile(s3IncludeFile):
    print "Maintaining your existing S3 include file."
else:
    move(s3IncludeFile+".example", s3IncludeFile)

if os.path.isfile(s3ExcludeFile):
    print "Maintaining your existing S3 exclude file."
else:
    move(s3ExcludeFile+".example", s3ExcludeFile)

#See if the user confirmed the data is correct.  If so, write it out
if userConfirmed.upper() == "Y":
        fsConfigurationFile = open( configurationFile, 'w')
        fsConfigurationFile.write("serverHostname=%s\n" % serverHostname)
        fsConfigurationFile.write("serverFQDN=%s\n" % serverFQDN)
        fsConfigurationFile.write("s3BucketName=%s\n" % s3BucketName)
        fsConfigurationFile.write("emailAddress=%s\n" % emailAddress)
        fsConfigurationFile.write("isDatabaseServer=%s\n" % isDatabaseServer)
        fsConfigurationFile.write("isDryRun=%s\n" % isDryRun)
        fsConfigurationFile.close()
else:
        print "Destroying the input.  Run setup again to configure."

