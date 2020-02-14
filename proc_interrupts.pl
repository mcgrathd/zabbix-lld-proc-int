#!/usr/bin/env perl
#
# Zabbix device discovery to monitor Linux CPU interrupts

#
# Use section
#
use warnings;
use strict;
use constant DEBUG => 0;

#
# Globals
#
# Used to store /proc/interrupts
my @lines;
# Split storage of interrupts into key/value pairs
my %interrupts;


#
# Sub routines
#

sub catInterrupts {
    for (`/usr/bin/env cat /proc/interrupts`)
    {
        # Remove the newline
        chomp;

        # Store the current line into the array
        push @lines, $_;
    }
}


sub parseInterrupts {
    # Index into array for current CPU during loops
    my $cpuNum = 0;

    # Store the first line of /proc/interrupts into $line0
    my $line0 = $lines[0];

    # strip preceding/trailing whitespace
    $line0 =~ s/^\s+|\s+$//g;

    # strip in between word whitespace
    $line0 =~ s/\ \ */\ /g;

    # Store cpus in array
    my @cpus = split / /, $line0;

    # The cpu count is the number of array items
    my $cpuCount = $#cpus;

    # For each CPU in /proc/interrupts, set values in hash
    foreach my $cpu (@cpus)
    {
        $cpuNum++;

        # For each line, skipping 0th array, since we have @cpus now
        foreach my $line (1 .. $#lines)
        {
            # eg:
            #$interrupts{'CPU0'}->{'MCE'} = 0;
            #$interrupts{'CPU0'}->{'TRM'} = 0;
            #$interrupts{'CPU1'}->{'MCE'} = 10;
            #$interrupts{'CPU1'}->{'TRM'} = 0;

            # Trim whitespace from line
            $lines[$line] =~ s/^\s+|\s+$//g;
            $lines[$line] =~ s/\ \ */\ /g;

            # Split the line into components
            my @fields = split / /, $lines[$line];

            # Remove colon from first element
            $fields[0] =~ s/://;

            # Set the hash value
            $interrupts{$cpu}->{$fields[0]} = $fields[$cpuNum];
        }
    }
}


sub displayInterrupts {
    # Is this the first item?
    my $first = 1;

    # Display JSON header
    print "{\n";
    print "\t\"data\":[\n\n";

    foreach my $cpu (keys %interrupts)
    {
        print "\t,\n" if not $first;
        $first = 0;

        print "\t{\n";
        print "\t\t\"{#CPU}\":\"$cpu\",\n";

        # for each cpu, display the fields
        foreach my $key (keys %{ $interrupts{$cpu} })
        {
            print "\t\t\"{#INT}\":\"$key\",\n";
        }

        # End of fields delimeter
        print "\t}\n";
    }

    # Display JSON footer
    print "\n\t]\n";
    print "}\n";
}


#
# Main code block
#
BEGIN {
    catInterrupts;
    parseInterrupts;
    displayInterrupts;
}

__END__

=pod

=encoding utf8

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

=item parseInterrupts()

Split the @lines array into the component fields, indexed by CPU number.

=item displayInterrupts()

Display the contents of the @lines array, unless DEBUG is set. The format used
can be found at the L<Zabbix LLD documentation|https://www.zabbix.com/documentation/4.2/manual/discovery/low_level_discovery/>.

=back

=head1 LICENSE

Copyright © 2020 Blender Foundation.  License GPLv3+: GNU GPL version 3 or later L<http://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law.

=head1 AUTHOR

Danny J. McGrath <danmcgrath.ca@gmail.com>

=cut
