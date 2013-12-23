#!/usr/bin/perl

# parse VCAL/ICS data file 
# rdk@krupczak.org
# $Id: parsevcal.pl 53 2008-09-10 13:07:17Z rdk $

use Getopt::Long;
use iCal::Parser;

my $result;
my $verbose = 0;
my $help = 0;
my $datafile = "";

# -------------------------------------------------------------

sub usage()
{
    print "usage: parsevcal.pl --help --verbose --datafile datafile\n";
    exit -1;
}

# -------------------------------------------------------------
# main program

$result = GetOptions(
                     "help" => \$help,
                     "verbose" => \$verbose,
                     "datafile=s" => \$datafile
);

if ($help == 1) {
    usage();
}

if ($datafile eq "") {
    usage();   
}

if ($verbose) {
   print "Filename is '$datafile' \n";
}

my $parser;

if ($verbose) {
   $parser=iCal::Parser->new(debug=>1);
}
else {
   $parser=iCal::Parser->new();
}

my $hash=$parser->parse($datafile);

print "Parsed vcal data file\n";
