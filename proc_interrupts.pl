#!/usr/bin/env perl
#
# Zabbix device discovery to monitor Linux CPU interrupts

#
# Use section
#
use warnings;
use strict;
use Getopt::Long qw(GetOptions);
use JSON;

#
# Globals
#
# Used to store /proc/interrupts
my @lines;
# Split storage of interrupts into key/value pairs
my %interrupts;

#
# Getopt variables
#

# What CPU to display
my $optCpu;
# What interrupt to display
my $optInt;
# Show help/usage?
my $optHelp;
# Debug prints?
my $optDebug;

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
            # Due to a limitation in Zabbix, we have to keep the data to less
            # than 64KB. As a work around, only display the named interrupts.
            # See https://support.zabbix.com/browse/ZBX-5863
            $interrupts{$cpu}->{$fields[0]} = $fields[$cpuNum] unless $fields[0] =~ m/[[:digit:]]/;;
        }
    }
}


sub displayInterrupts {
	# Is $optCpu or $optInt passed?
	if ($optCpu and $optInt) {
		# Single item display and exit

		# Upper case values
		$optCpu = uc($optCpu);
		$optInt = uc($optInt);

		print "DEBUG: \$optCpu = $optCpu\n" if $optDebug;
		print "DEBUG: \$optInt = $optInt\n" if $optDebug;
		# Return the value or empty string if undefined
		print "$interrupts{$optCpu}->{$optInt}\n" if defined $interrupts{$optCpu}->{$optInt};
		exit;
	}

    # Is this the first item?
    my $first = 1;

    # What is the last cpu?
    my $lastCpu;
    foreach my $key (sort keys %interrupts)
    {
        $lastCpu = $key;
    }
    print "DEBUG: lastCpu = $lastCpu\n" if $optDebug;

    # What is the last field for $lastCpu?
    my $lastField;
    foreach my $key (sort keys %{ $interrupts{$lastCpu} })
    {
        $lastField = $key;
    }
    print "DEBUG: lastField = $lastField\n" if $optDebug;

    ##
    my $data;
    foreach my $cpu (sort keys %interrupts)
    {
        foreach my $key (sort keys %{ $interrupts{$cpu} })
        {
            my $cpu_interrupt = {
                '{#CPU}' => $cpu,
                '{#INT}' => $key
            };
            push @$data, $cpu_interrupt;
        }
    }

    my $output = {
        data => $data
    };

    my $json = encode_json( $output );
    print $json . "\n";

}


sub helpMessage {
    print "Usage: $0 [OPTIONS] ...\n\n";

    print "If you specificy cpu, you must specify an interrupt name.\n";
    print "If you don't specify any options, it is assumed that you\n";
    print "want to output the JSON fields to be consumed by Zabbix.\n\n";

    print "Options:\n";
    print "\t-c, --cpu\t\t\tCPU name\n";
    print "\t-i, --int\t\t\tInterrupt name\n";
    print "\t-d, --debug\t\t\tEnable debug prints\n";
    print "\t-h, --help\t\t\tThis help\n\n";

	print "You must either pass both the --cpu and --int options, or neither of\n";
	print "them. The format of the --cpu option is CPU#, where # is a positive\n";
	print "integer. For convenience, the system will uppercase the value for you.\n";

    exit;
}


#
# Main code block
#
BEGIN {
    GetOptions(
        'cpu|c=s'  => \$optCpu,
        'int|i=s'  => \$optInt,
        'debug|d'  => \$optDebug,
        'help|h'   => sub { helpMessage() },
    ) or helpMessage;

	# Check that we are calling either:
	# 1. nothing, or
	# 2. cpu and int, or
	# 3. debug or help
	if ($optCpu or $optInt) {
		# die "You must specify both --cpu and --int. Exiting.";
		if ($optCpu xor $optInt) {
			print "Error: Both --cpu and --int must be set\n\n";
			helpMessage;
		}
	}

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

Usage: proc_interrupts.pl [OPTIONS] ...

If you specificy cpu, you must specify an interrupt name.  If you don't specify
any options, it is assumed that you want to output the JSON fields to be
consumed by Zabbix.

Options:

	-c, --cpu			CPU name
	-i, --int			Interrupt name
	-d, --debug			Enable debug prints
	-h, --help			This help

You must either pass both the B<--cpu> and B<--int> options, or neither of
them. The format of the B<--cpu> option is B<CPU#>, where B<#> is a positive
integer. For convenience, the system will uppercase the value for you.

=head1 DESCRIPTION

Output JSON formatted values of /proc/interrupts for Zabbix consumption.

=head1 FUNCTIONS

=over

=item catInterrupts()

Store the contents of /proc/interrupts into the global array @lines.

=item parseInterrupts()

Split the @lines array into the component fields, indexed by CPU number.

=item displayInterrupts()

Display the contents of the @lines array, unless $optDebug is set. The format used
can be found at the L<Zabbix LLD documentation|https://www.zabbix.com/documentation/4.2/manual/discovery/low_level_discovery/>.

=item helpMesage()

Show the usage for the program and exit.

=back

=head1 LICENSE

Copyright © 2020 Blender Foundation.  License GPLv3+: GNU GPL version 3 or later L<http://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law.

=head1 AUTHOR

Danny J. McGrath <danmcgrath.ca@gmail.com>

=cut
