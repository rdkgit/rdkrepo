#! /bin/sh 
#
# NAME     mk_package
# $Id: mk_package.sh 152 2011-03-31 14:42:06Z rdk $
# rdk
# generate a solaris package
# Copyright 2011, Krupczak.org, LLC
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# license, or (at your option) any later version.
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

# where to fetch files to put in release
DIRS='cartographer'

# 'device' or pkg file to put release in
DEVICE='cartographer.pkg'

# name of package
PKG='KORGcart'

echo 
echo "Making solaris package"
echo

# because we make packages for a variety of platforms, we dont
# store the files in solaris-specific filesystem layout, so
# we have to go massage the names of files in the prototype

echo "Making prototype file . . . "
cp prototype.template prototype
find $DIRS -follow -name '*.svn' -prune -o -print | pkgproto -i | \
#       sed 's/release/KORGcart/g' | \
        sed 's/rdk/root/g' | \
	sed 's/0664/0644/g' | \
	sed 's/0775/0755/g' >> prototype
echo "done"

echo "Going to make package . . "

# pkgmk -o -r `pwd` -d `pwd`/spool 2> /dev/null 
pkgmk -o -r `pwd` -d `pwd`/spool 

if [ "$?" -ne 0 ]
then
   echo "$0: failed to make the package.  Exiting";
   exit 1
fi

echo "done"
echo "Going to transfer package to file . . ."

pkgtrans -s `pwd`/spool $DEVICE $PKG

if [ "$?" -ne 0 ]
then
     echo "$0: pkgtrans failed.  Repeating for error output";
     pkgtrans -s `pwd`/spool $DEVICE $PKG
     exit 1
else
     echo "done"
     echo "Checking package integrity . . "
     pkgchk -d `pwd`/spool/$DEVICE -l $PKG 1> /dev/null
#     pkgchk -d `pwd`/spool/$DEVICE -l $PKG
     if [ "$?" -ne 0 ]
     then
        echo "$0: pkgchk failed.  Exiting";
        exit 1
     fi
     echo "done"
fi

echo
echo "Finished making package"
echo
exit 0

