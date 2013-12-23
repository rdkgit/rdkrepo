#!/usr/bin/perl
#
# getwebcaminage.pl
# $Id: getwebcamimage.pl 194 2012-12-10 23:03:10Z rdk $
#                     
# rdk@krupczak.org
# get webcam image from TrendNET TV-IP110W 
# add support for D-Link DCS-920
# add support for Axis Neteye 2120
# add support for TrendNETs that differ on case of authen realm
# add support for command-line username/password
# add support for Foscam snapshots

#
# COPYRIGHT 2010 KRUPCZAK.ORG, LLC.
#
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
#

use warnings;
use strict;
use LWP::UserAgent;
use HTTP::Request::Common;
use Getopt::Long;
use HTTP::Cookies;
use HTTP::Headers;
use Image::ExifTool qw(:Public);
use Image::Magick;

my $ua;
my $result;
my $verbose = 0;
my $help = 0;
my $webcam = "";
my $camtype = "";
my $outfilename = "";
my $username = "";
my $password = "";
my $fillcolor = "white";

# webcam passed in on arg line should include :port

$result = GetOptions(
                     "help" => \$help,
                     "verbose" => \$verbose,
                     "webcam=s" => \$webcam,
                     "camtype=s" => \$camtype,
                     "username=s" => \$username,
                     "password=s" => \$password,
                     "fill=s" => \$fillcolor,
                     "out=s" => \$outfilename
    );

if ($help == 1 || $webcam eq "" || $outfilename eq "") {
    print "getwebcamimage.pl: --verbose --camtype type --username username --password password --fill colorname --webcam hostname/ipaddr:port --out filename\n";
    exit 0;
}

if ($webcam !~ /:/) {
    print "You need to specify a port number\n";
    exit 0;
}

SWITCH: {

    if ($camtype =~ /trendnet/i) { getTrendNet(); }
    if ($camtype =~ /dlink/i) { getDlink(); }
    if ($camtype =~ /neteye/i) { getNeteye(); }
    if ($camtype =~ /foscam/i) { getFoscam(); }
    print "Unsupported webcam type $webcam; I know about 'trendnet' and 'dlink' 'neteye' and 'foscam'\n";
}
exit -1;

# ###########################################################
# foscam

sub getFoscam
{
  # set your username/password here for accessing the image
  if ($username eq "") {
     $username = "guest";
  }
  if ($password eq "") {
     $password = "guest";
  }

  # construct the url
  my $url = "http://$username:$password\@$webcam/snapshot.cgi";

  if ($verbose) {
     print "Attempting to fetch image from '$webcam' with '$url'\n";
  }

  # create a user agent first
  $ua = LWP::UserAgent->new;

  $result = $ua->get($url);

  if ($verbose) {
      print "Response is "; print $result->status_line; print "\n";
  }

  if ($result->is_success) {
     # print $result->decoded_content;
     open(OUTFILE,">$outfilename");
     print OUTFILE $result->decoded_content;
     close OUTFILE;

     my $exifTool = new Image::ExifTool;
     my $info = $exifTool->ImageInfo($outfilename,"FileModifyDate");

     my $image = Image::Magick->new;
     
     $image->Read($outfilename);

     # print "Date/time is $$info{FileModifyDate}\n";

     $image->Annotate(font=>'ariel.ttf', pointsize=>20, 
                      # stroke=>'white',
                      # fill=>'clear',
                      # default fill is black
                      fill=>$fillcolor,
                      text=>$$info{FileModifyDate},
                      gravity=>'NorthEast');

     $image->Write(filename=>$outfilename, compression=>'None');

     exit 0;
  }
  # if that didnt work, 
  exit -1;
}

# ###########################################################
# trendnet

sub getTrendNet
{
  # set your username/password here for accessing the image
  # from the TV-IP110W; dont use your admin username/password
  if ($username eq "") {
     $username = "guest";
  }
  if ($password eq "") {
     $password = "guest";
  }

  # my $username = "stewart";
  # my $password = "slicer1";

  # construct the url
  my $url = "http://$webcam/cgi/jpg/image.cgi";

  if ($verbose) {
     print "Attempting to fetch image from '$webcam' with '$url'\n";
  }

  if ($username eq "admin") {
     print "Really, dont use the 'admin' user; create a guest user\n";
     exit 0;

  }

  # create a user agent first
  $ua = LWP::UserAgent->new;

  $ua->credentials("$webcam","Netcam","$username" => "$password");

  $result = $ua->get($url);

  if ($verbose) {
      print "Response is "; print $result->status_line; print "\n";
  }

  if ($result->is_success) {
     # print $result->decoded_content;
     open(OUTFILE,">$outfilename");
     print OUTFILE $result->decoded_content;
     close OUTFILE;
     exit 0;
  }
  else {

     # retry with lowercase netcam
     $ua->credentials("$webcam","netcam","$username" => "$password");
     $result = $ua->get($url);
     if ($verbose) {
         print "Response is "; print $result->status_line; print "\n";
     }

     if ($result->is_success) {
        # print $result->decoded_content;
        open(OUTFILE,">$outfilename");
        print OUTFILE $result->decoded_content;
        close OUTFILE;
        exit 0;
     }
  }

  # if that didnt work, 
  exit -1;
}

# ###########################################################
# dlink dcs 920
# dlink does not place a date/timestamp in the image;
# we add it using various tools

sub getDlink
{
  # set your username/password here for accessing the image
  if ($username eq "") {
     $username = "guest";
  }
  if ($password eq "") {
     $password = "guest";
  }

  # construct the url
  my $url = "http://$username:$password\@$webcam/image.jpg";

  if ($verbose) {
     print "Attempting to fetch image from '$webcam' with '$url'\n";
  }

  # create a user agent first
  $ua = LWP::UserAgent->new;

  # $ua->credentials("$webcam","blah","$username" => "$password");

  $result = $ua->get($url);

  if ($verbose) {
      print "Response is "; print $result->status_line; print "\n";
  }

  if ($result->is_success) {
     # print $result->decoded_content;
     open(OUTFILE,">$outfilename");
     print OUTFILE $result->decoded_content;
     close OUTFILE;

     my $exifTool = new Image::ExifTool;
     my $info = $exifTool->ImageInfo($outfilename,"FileModifyDate");

     my $image = Image::Magick->new;
     
     $image->Read($outfilename);

     # print "Date/time is $$info{FileModifyDate}\n";

     $image->Annotate(font=>'ariel.ttf', pointsize=>20, 
                      # stroke=>'white',
                      # fill=>'clear',
                      # default fill is black
                      fill=>$fillcolor,
                      text=>$$info{FileModifyDate},
                      gravity=>'NorthEast');

     $image->Write(filename=>$outfilename, compression=>'None');

     exit 0;
  }
  # if that didnt work, 
  exit -1;
}

# ###########################################################

sub getNeteye
{
  # set your username/password here for accessing the image
  $username = "";
  $password = "";

  # construct the url 
  my $url = "http://$webcam/jpg/image.jpg";

  # create a user agent first
  $ua = LWP::UserAgent->new;

  # $ua->credentials("$webcam","blah","$username" => "$password");

  $result = $ua->get($url);

  if ($verbose) {
      print "Response is "; print $result->status_line; print "\n";
  }

  if ($result->is_success) {
     # print $result->decoded_content;
     open(OUTFILE,">$outfilename");
     print OUTFILE $result->decoded_content;
     close OUTFILE;

     my $exifTool = new Image::ExifTool;
     my $info = $exifTool->ImageInfo($outfilename,"FileModifyDate");

     my $image = Image::Magick->new;
     
     $image->Read($outfilename);

     # print "Date/time is $$info{FileModifyDate}\n";

     $image->Annotate(font=>'ariel.ttf', pointsize=>20, 
                      # stroke=>'white',
                      # fill=>'clear',
                      # default fill is black
                      fill=>$fillcolor,
                      text=>$$info{FileModifyDate},
                      gravity=>'NorthEast');

     $image->Write(filename=>$outfilename, compression=>'None');

     exit 0;
  }
  # if that didnt work, 
  exit -1;
}

# ###########################################################
