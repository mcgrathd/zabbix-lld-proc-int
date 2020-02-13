#!/usr/bin/env perl
#
# Zabbix device discovery to monitor Linux CPU interrupts

use warnings;
use strict;
use constant DEBUG => 0;
my $first = 1;
my @lines; # Users to store /proc/interrupts

sub catInterrupts {
    for (`/usr/bin/env cat /proc/interrupts`)
    {
        chomp;
        push @lines, $_; # Store the current line into the array
        print "DEBUG: Pushed => $_\n" if DEBUG;
    }
}

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

BEGIN {
    catInterrupts;
    display;
}

__END__

=pod

=head1 NAME

proc_interrupts.pl - Linux interrupts Zabbix LLD script

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

Output JSON formatted values of /proc/interrupts for Zabbix consumption.

=head1 FUNCTIONS

=over

=item catInterrupts()

Store the contents of /proc/interrupts into the global array @lines.

=item display()

Display the contents of the @lines array, unless DEBUG is set.

=back

=head1 LICENSE

TODO

=head1 AUTHOR

Danny J. McGrath <danmcgrath.ca@gmail.com>

=cut
