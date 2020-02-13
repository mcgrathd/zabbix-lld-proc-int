#!/usr/bin/env perl
#
# Zabbix device discovery to monitor Linux devices
# https://www.kernel.org/doc/Documentation/iostats.txt 

$first = 1;
 
print "{\n";
print "\t\"data\":[\n\n";
 
for (`/bin/cat /proc/diskstats | /usr/bin/awk '{ print \$3 }'`)
{
    ($device) = m/(\S+)/;

    print "\t,\n" if not $first;
    $first = 0;
 
    print "\t{\n";
    print "\t\t\"{#DEVICE}\":\"$device\"\n";
    print "\t}\n";
}
 
print "\n\t]\n";
print "}\n";
