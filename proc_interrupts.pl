#!/usr/bin/env perl
#
# Zabbix device discovery to monitor Linux CPU interrupts

use warnings;
use strict;
use Data::Dumper qw(Dumper);
use constant DEBUG => 0;
my @lines; # Used to store /proc/interrupts
my %interrupts; # Split storage of interrupts into key/value pairs

sub catInterrupts {
    for (`/usr/bin/env cat /proc/interrupts`)
    {
        chomp;
        push @lines, $_; # Store the current line into the array
        print "DEBUG: Pushed => $_\n" if DEBUG;
    }
}

sub parseInterrupts {
    my $cpuNum = 0; # Index into array for current CPU during loops

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

    if (DEBUG) {
        print "DEBUG: line0 = $line0\n" if DEBUG;
        print "DEBUG: lines[0] = $lines[0]\n" if DEBUG;
        print "DEBUG: cpuCount = $cpuCount\n" if DEBUG;
        print "DEBUG: " . Dumper \@cpus if DEBUG;
    }

    # For each CPU in /proc/interrupts, set values in hash
    foreach my $cpu (@cpus)
    {
        $cpuNum++;
        print "DEBUG: Loop: $cpu ($cpuNum)\n" if DEBUG;

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
            foreach my $field (@fields)
            {
                print "DEBUG: Field: $field\n" if DEBUG;
            }

            # Remove colon from first element
            $fields[0] =~ s/://;

            print "DEBUG: cpuNum = $cpuNum\n" if DEBUG;
            print "DEBUG: @fields: \n" . Dumper(@fields) . "\n" if DEBUG;

            # Set the hash value
            $interrupts{$cpu}->{$fields[0]} = $fields[$cpuNum];
        }
    }
    foreach my $cpu (keys %interrupts)
    {
        next unless DEBUG;
        print "$cpu\n";
        print '=' x length($cpu), "\n";
        foreach my $int (keys %{ $interrupts{$cpu} })
        {
            print "$int: $interrupts{$cpu}->{$int}\n";
        }
        print "\n";
    }
}

sub display {
    my $first = 1; # Is this the first item?

    print "{\n";
    print "\t\"data\":[\n\n";

    foreach my $i (0 .. $#lines)
    {
        print "\t,\n" if not $first;
        $first = 0;

        print "\t{\n";
        print "\t\t\"{#DEVICE}\":\"$lines[$i]\"\n";
        print "\t}\n";
    }

    print "\n\t]\n";
    print "}\n";
}

BEGIN {
    catInterrupts;
    parseInterrupts;
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

=item parseInterrupts()

Split the @lines array into the component fields, indexed by CPU number.

=item display()

Display the contents of the @lines array, unless DEBUG is set.

=back

=head1 LICENSE

TODO

=head1 AUTHOR

Danny J. McGrath <danmcgrath.ca@gmail.com>

=cut
