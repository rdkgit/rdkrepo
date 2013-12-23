#!/usr/bin/perl

# Copyright 2008, Bobby Krupczak
# rdk@krupczak.org
# $Id: convertwebcal.pl 168 2012-05-03 02:15:08Z rdk $

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
# USA
# 
# For more information, visit:
# http://www.krupczak.org/

# convert webcal data file into ical output

# outlook (lookout) chokes on our ics format but google reads
# it fine; many many others seem to have same problem with LookOut

# add DTSTAMP for each VEVENT; we use the current date/time as
# the value but that slows down the program as foreach entry,
# we make a call to DateTime;

# added before/after filtering but need to add it to
# reoccurring XXX

# need to fix some outlook 2007 calendar import rulings
# with respect to recurrence patterns
# 
# add DTEND to all VEVENTS
# also, for our notion of TODOs, fudge the date/time so
# that VTODO are really written as VEVENTS

use Getopt::Long;
use DateTime;

my $result;
my $verbose = 0;
my $help = 0;
my $datafile = "";

my $before = "";
my $after = "";

my %dowhash = ('MO',1,
               'TU',2,
               'WE',3,
               'TH',4,
               'FR',5,
               'SA',6,
               'SU',7);

my %dowhash1 = ('1','MO',
                '2','TU',
                '3','WE',
                '4','TH',
                '5','FR',
                '6','SA',
                '7','SU');

# -------------------------------------------------------------

sub usage()
{
    print "usage: convertwebcal.pl --help --verbose --before YYYYMMDD --after YYYYMMDD --datafile datafile\n";
    exit -1;
}

# -------------------------------------------------------------
# check after < date < before, return true(1), false(0)

sub checkBeforeAfter()
{
    my ($before,$after,$date) = @_;

    # print STDERR "checkBeforeAfter: '$before' $date '$after'\n";

    # simple case
    if (($before eq "") && ($after eq "")) {
       return 1;
    }

    if ($before ne "") {
       if ($date ge $before) {
	  return 0;
       }
    }

    if ($after ne "") {
	if ($date le $after) {
	   return 0;
        }
    }

    if ($verbose) {
       print STDERR "checkBeforeAfter: '$after' < '$date' < '$before' \n";
    }

    # got this far then we passed test  after < date < before
    return 1;
}

# -------------------------------------------------------------

# parse a calendar record line and split aprt into fields that are
# returned in an associative array
#
# field separator is '|||'
#
# format of webcal data file is
#  index
#  subindex
#  modified 
#  user 
#  date   - YYYMMDD or some reg expression
#  start time - 4 digit military time
#  end time - 4 digit military time
#  entry - the item/description
#  link - 0 = no link, otherwise URL
#  reminder - 0 for no reminder, number seconds prior to event
#  notes - notes 

sub parseCalEntry()
{
    my ($linetoparse) = @_;
    my (%record) = ();

    ($record{"index"},
     $record{"subindex"},
     $record{"modified"},
     $record{"user"},
     $record{"date"},
     $record{"start"},
     $record{"end"},
     $record{"entry"},
     $record{"link"},
     $record{"reminder"},
     $record{"notes"}) = split /\|\|\|/, $linetoparse;

     # do any cleanup now
     $record{'reoccurring'} = 0;

     if ($record{'notes'} eq "0") {
	$record{'notes'} = "";
     }

     if ($record{'start'} eq "0") {
	 $record{'start'} = "";
     }
     if ($record{'end'} eq "0") {
	 $record{'end'} = "";
     }

     # look for regular expressions in the date field
     # which means reoccurring items

     if ($record{'date'} =~ m/\*/ ) {
        if ($verbose) {
           print STDERR "Entry '$record{'entry'}' '$record{'date'}' reoccurring\n";
        }
        $record{'reoccurring'} = 1;

        # split apart into fields: year,month,day,dayOfweek

        ($record{'year'},
         $record{'month'},
         $record{'day'},
         $record{'dow'}) = split /,/, $record{'date'};

     }

     # cleanup dow if present
     if ($record{'dow'} =~ /mon/i ) { $record{'dow'} = "MO"; }
     if ($record{'dow'} =~ /tue/i ) { $record{'dow'} = "TU"; }
     if ($record{'dow'} =~ /wed/i ) { $record{'dow'} = "WE"; }
     if ($record{'dow'} =~ /thu/i ) { $record{'dow'} = "TH"; }
     if ($record{'dow'} =~ /fri/i ) { $record{'dow'} = "FR"; }
     if ($record{'dow'} =~ /sat/i ) { $record{'dow'} = "SA"; }
     if ($record{'dow'} =~ /sun/i ) { $record{'dow'} = "SU"; }
     
     return %record;
}

# -------------------------------------------------------------
# get current date/time and return as a DATE-TIME

sub getDtstamp()
{
    $dt = DateTime->now;

    $ret = sprintf "%4d%02d%02dT%02d%02d%02d",
          $dt->year,
          $dt->month,
          $dt->day,
          $dt->hour,
          $dt->minute,
          $dt->second;
      
    # print STDERR "$ret\n";

    return $ret;
}

# -------------------------------------------------------------
# given year,month,dow (e.g. SA), find the first dow of that month

sub findFirstDowOfMonth()
{
    my ($year,$month,$dow) = @_;
    my ($dt);

    # print STDERR "findFirstDowOfMonth: $year $month $dow\n";

    $daynumber = $dowhash{$dow};

    for ($i=1; $i<8; $i++) {

        # print STDERR "findFirstDowOfMonth: checking $i\n";

        $dt = DateTime->new(year => $year, month => $month, day => $i);
        
        $tempdow = $dt->day_of_week;

        # print STDERR "findFirstDow: day $i is $tempdow\n";

        if ($tempdow == $daynumber) {
	    # print STDERR "findFirstDow: first $dow of $month/$year is $i\n";
            return "0$i";
        }
    }

    return 0;
}

# -------------------------------------------------------------

sub printCalEntry()
{
    my (%record) = @_;

    print STDERR "CalEntry: $record{'index'} $record{'date'} \n";

    if ($calrecord{'start'} eq "") {
       print STDERR "Entry $record{'entry'} has no start\n";
    }
    if ($calrecord{'end'} eq "") {
       print STDERR "Entry $record{'entry'} has no end\n";
    }



}

# -------------------------------------------------------------

sub printVTODO()
{
    my ($stamp,%record) = @_;

    if (&checkBeforeAfter($before,$after,$record{'date'}) == 0) {
       return;
    }

    # if entry is absent, dont bother
    if ($record{'entry'} eq "") {
       if ($verbose) {
          print STDERR "Null entry, skipping\n";
       }
       return;
    }

}

# -------------------------------------------------------------
# TODO: fix repeated/reoccurring entries

sub printRepeatVCAL()
{
    my ($stamp,%record) = @_;

    if ($verbose) {
       print STDERR "Date $record{'date'} reoccurring\n";
    }

    # dtstart is earliest we want the repeating event to occur
    #    if no year, we start with 2003

    # yearly event RRULE:FREQ=YEARLY
    #    year and dow are wildcards
    if (($record{'year'} =~ /\*/) && ($record{'dow'} =~ /\*/)) {

        # printf STDERR "Yearly event '$record{'date'}'\n";

        print "BEGIN:VEVENT\n";
        print "DTSTAMP:$stamp\n";
        print "DTSTART;VALUE=DATE:2003$record{'month'}$record{'day'}\n";
        print "RRULE:FREQ=YEARLY\n";
        print "SUMMARY:$record{'entry'}\n";
        if ($record{'notes'} ne "") {
           print "DESCRIPTION:$record{'notes'}\n";
        }
        print "UID:webcal-$record{'index'}-$record{'subindex'}:$record{'user'}\@mankato.krupczak.org\n";
        print "END:VEVENT\n";
        return;
    }

    # static year,month,dow,wildcard day
    # FREQ=WEEKLY;BYDAY=DOW;BYMONTH=1

    if (($record{'day'} =~ /\*/) && ($record{'month'} !~ /\*/) &&
        ($record{'dow'} !~ /\*/)) {

        # for a monthly/weekly event, check before/after
        if (&checkBeforeAfter($before,$after,$record{'date'}) == 0) {
           return;
        }

        # print STDERR "Weekly reoccurring entry '$record{'date'}'\n";

        $first = &findFirstDowOfMonth($record{'year'},$record{'month'},
                                      $record{'dow'});

        print "BEGIN:VEVENT\n";
        print "DTSTAMP:$stamp\n";

        if ($record{'start'} ne "") {
           print "DTSTART:$record{'year'}$record{'month'}$first";
           print "T$record{'start'}00\n";
        }
        else {
           print "DTSTART;VALUE=DATE:$record{'year'}$record{'month'}$first\n";
        }

        # put an end time
        if ($record{'end'} ne "")  {
           print "DTEND:$record{'year'}$record{'month'}$first";
           print "T$record{'end'}00\n";
        }

        # print "RRULE:FREQ=WEEKLY;BYDAY=$record{'dow'};BYMONTH=1\n";
        print "RRULE:FREQ=WEEKLY;BYDAY=$record{'dow'};COUNT=4\n";

        print "SUMMARY:$record{'entry'}\n";
        if ($record{'notes'} ne "") {
           print "DESCRIPTION:$record{'notes'}\n";
        }

        print "UID:webcal-$record{'index'}-$record{'subindex'}:$record{'user'}\@mankato.krupczak.org\n";
        print "END:VEVENT\n";
        return;
    }

    # dont handle (yet) every dow for entire year (mistake)
    
    # dont handle two cases where month, day were regexp

}

# -------------------------------------------------------------

sub printVEVENT()
{
    my ($stamp,%record) = @_;

    # print STDERR "printVCAL: dtstamp is $stamp\n";

    # look for reoccurring entries and skip them for right now XXX
    if ($record{'reoccurring'} == 1) {
       &printRepeatVCAL($stamp,%record);
       return;
    }

    if (&checkBeforeAfter($before,$after,$record{'date'}) == 0) {
       return;
    }

    # if entry is absent, dont bother
    if ($record{'entry'} eq "") {
       if ($verbose) {
          print STDERR "Null entry, skipping\n";
       }
       return;
    }

    print "BEGIN:VEVENT\n";
    print "DTSTAMP:$stamp\n";

    if ($record{'start'} ne "") {
       print "DTSTART:$record{'date'}T$record{'start'}00\n";
    }
    else {
       print "DTSTART;VALUE=DATE:$record{'date'}\n";
    }
    if ($record{'end'} ne "")  {
       print "DTEND:$record{'date'}T$record{'end'}00\n";
    }
    else {
       # must have a DTEND
       if ($record{'start'} ne "") {
          print "DTEND:$record{'date'}T$record{'start'}00\n";
       }
       else {
          print "DTEND;VALUE=DATE:$record{'date'}\n";
      }
    }

    print "SUMMARY:$record{'entry'}\n";
    if ($record{'notes'} ne "") {
       print "DESCRIPTION:$record{'notes'}\n";
    }
    print "UID:webcal-$record{'index'}-$record{'subindex'}:$record{'user'}\@mankato.krupczak.org\n";
    
    print "END:VEVENT\n";
}

# -------------------------------------------------------------
# -------------------------------------------------------------

sub printVCALHeader()
{
  print <<"EOVH"
BEGIN:VCALENDAR
PRODID:rdk\@krupczak.org -- convertwebcal.pl generated
VERSION:2.0
CALSCALE:GREGORIAN
METHOD:PUBLISH
EOVH
}

sub printVCALTrailer()
{
    print "END:VCALENDAR\n";
}

# -------------------------------------------------------------
# -------------------------------------------------------------
# main program

$result = GetOptions(
                     "help" => \$help,
                     "verbose" => \$verbose,
                     "before=s" => \$before,
                     "after=s" => \$after,
                     "datafile=s" => \$datafile
);

if ($help == 1) {
    usage();
}

if ($datafile eq "") {
    usage();
}

if ($verbose) {
   print STDERR "Filename is '$datafile' \n";
}

my %calrecord = ();

my $dtstamp = &getDtstamp();

if ($verbose) {
   print STDERR "Starting conversion at $dtstamp\n";
}

&printVCALHeader();

# open the file
open(FILE,$datafile);
while ($line = <FILE>) {

   # get rid of newline parse line
   chomp($line);

   if ($verbose) {
      print STDERR "Read data line '$line'\n";
   }

   %calrecord = &parseCalEntry($line);

   if ($verbose) {
       &printCalEntry(%calrecord);
   }

   # check to see if there are no start/end dates/times
   if (($calrecord{'start'} eq "") && ($calrecord{'end'} eq "")) {

       if ($verbose) {       
          print STDERR "We have a VTODO entry $calrecord{'entry'} \n";
       }

   }

   &printVEVENT($dtstamp,%calrecord);


}
close FILE;

&printVCALTrailer();

