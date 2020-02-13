#!/usr/bin/env perl
#
# Zabbix device discovery to monitor Linux CPU interrupts

use warnings;
use strict;
use constant DEBUG => 0;
my $first = 1;

sub display {
    print "{\n";
    print "\t\"data\":[\n\n";

    for (`/bin/cat /proc/diskstats | /usr/bin/awk '{ print \$3 }'`)
    {
        (my $device) = m/(\S+)/;

        print "\t,\n" if not $first;
        $first = 0;

        print "\t{\n";
        print "\t\t\"{#DEVICE}\":\"$device\"\n";
        print "\t}\n";
    }

    print "\n\t]\n";
    print "}\n";
}

