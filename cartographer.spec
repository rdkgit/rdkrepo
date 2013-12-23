# $Id: cartographer.spec 149 2011-03-31 14:27:48Z rdk $
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

# build package with rpmbuild -bb pkg.spec
# examine scripts with rpm -qp --scripts pkg.rpm
# examine contents with rpm -qpl pkg.rpm
# install with rpm -i --nodeps pkg.rpm
#    --nodeps due to the fact we bundle all platform binaries in each package
# dry run of install with rpm -i --test pkg.rpm
# actually install with rpm -iUv pkg.rpm
# remove package with rpm -e -vv pkg.rpm
# we rely on 32-bit libxml2 (yum install libxml2.i386)

# keep RPM from making an empty debug package
%define debug_package %{nil}

# disable the automagic dependency generator from
# finding/requiring a whole bunch of solaris dependencies
# also disable the automatic "provides" calcuations
# this tag does both
AutoReqProv: no

# location definitions so we can build in our development/release directory
%define _rpmdir /krupczak/rdk/tmp/rpmbuild
%define release_location /krupczak/rdk/tmp/agent/release
%define instprefix /opt/cartographer

BuildRoot: 	/krupczak/rdk/tmp/rpmbuild
Summary:	Cartographer agent, plugins, tools, and example XMP PDUs
Name:		cartographer
Version:	1.3
Release:	1
Group:		Applications/System
URL:		http://www.krupczak.org/cartographer
Vendor: 	The Krupczak Organization
Requires: 	libxml2
Prefix: 	%{instprefix}
# Icon:		Cartographer.gif
# BuildArch:	noarch
License:	korg-license.txt

# don't strip binaries
%define 	__os_install_post %{nil}

%description
Cartographer implements a novel approach to managing distributed
systems by automatically discovering and tracking the relationships
between its component systems and applications. Cartographer does so
via specially designed agents -- residing on clients, servers and
(potentially) network devices -- that detect, identify, and track the
inter and intra-system dependencies or relationships. Dependencies
include network level services like DNS, DHCP, and SMTP as well as
higher-level application abstractions like filesystems, databases,
directory services, telephony, and middleware.

# ----------------------------------------------------------

# no build/prep needed to build the package; before building
# the RPM, you must actually make release on all the
# supported platforms

%prep
%build

# ----------------------------------------------------------

%install

# copy release files to 
export RELEASE_LOCATION=%{release_location}
mkdir -p $RPM_BUILD_ROOT%{instprefix}
cp -f ${RELEASE_LOCATION}/* $RPM_BUILD_ROOT%{instprefix}

# ----------------------------------------------------------

%clean

rm -rf $RPM_BUILD_ROOT%{instprefix}

# ----------------------------------------------------------
# 
# pre-install commands here
# check for upgrade so we 
# can preserve config files, pem files, csr files
# 
%pre

if [ "$1" -gt 1 ]; then
   cd $RPM_INSTALL_PREFIX0
   for file in cartographer.xml cartographer-local.xml connectiondata.xml xmpd.xml appdata.xml *.pem *.csr; do
       if [ -f $file ]; then
       	  cp $file $file.preserve
       fi
   done
fi

# call echo so script does not bomb due to failure of previous
# commands
echo -n

# ----------------------------------------------------------
# 
# post install script commands here
# $1 is the count option specifying 
# 1 for first time, 2 or higher for upgrades
# 0 for remove last version of package
# 
%post

# figure out which linux we are on

# are we an upgrade?
# if we are an upgrade, copy back the preserved configs, pems, csrs

if [ "$1" -gt 1 ]; then
   cd $RPM_INSTALL_PREFIX0
   for file in *.preserve; do
       mv ${file%.*} ${file%.*}.fcs
       mv $file ${file%.*}
   done
fi

# cp startup script to /etc/init.d/
if [ -x "$RPM_INSTALL_PREFIX0" ]; then
   cp -f $RPM_INSTALL_PREFIX0/init.linux /etc/init.d/cartographer
fi

# register; ignore if its already been registered
/sbin/chkconfig --add cartographer

# ldd the binary? start cartographer agent?  Not now.

# we should check to see if libxml2.i386 is installed
# its the only 32-bit lib we need that is not commonly installed
# on 64-bit machines; it *should* be installed by default but
# is often not; dont fail the install though if its not present
if [ ! -f /usr/lib/libxml2.so.2 ]; then
   echo "32-bit libxml2 may not be installed; please double check."
fi

# call echo so script does not bomb due to failure of previous
# commands
echo -n

# ----------------------------------------------------------
# 
# pre-remove script commands here
# 

%preun

if [ "$1" = 0 ]; then
   /sbin/service cartographer stop > /dev/null 2>&1
   /sbin/chkconfig --del cartographer 
   /usr/bin/pkill -u root xmpd-linux
fi

# call echo 0 so script does not bomb due to failure of previous
# commands
echo -n

# ----------------------------------------------------------
# 
# post uninstall script
# do final cleanup
# use RPM_INSTALL_PREFIX0 which should be set because
# we set prefix in original spec file
# 
%postun

if [ "$1" = 0 ]; then

   if [ -x "$RPM_INSTALL_PREFIX0" ]; then

      # remove any .old files
      rm -f $RPM_INSTALL_PREFIX0/*.old

      # remove any .new files
      rm -f $RPM_INSTALL_PREFIX0/*.new

      # remove any .csr and .pem files
      rm -f $RPM_INSTALL_PREFIX0/*.csr
      rm -f $RPM_INSTALL_PREFIX0/*.pem

      # remove dir
      rmdir $RPM_INSTALL_PREFIX0
   fi

   # just in case chkconfig did not remove this file
   rm -f /etc/init.d/cartographer
fi

# call echo so script does not bomb due to failure of previous
# commands
echo -n

# ----------------------------------------------------------

%files

# -rwxr-xr-x
%defattr(755 root root)
/opt/cartographer/cartographer-linux.so
/opt/cartographer/cartographer-local.xml
/opt/cartographer/cartographer-solaris.so
/opt/cartographer/cartographer-solx86.so
/opt/cartographer/cartographer-win32.dll
/opt/cartographer/cartographertray.exe
/opt/cartographer/iconv.dll
/opt/cartographer/init.linux
/opt/cartographer/init.solaris
/opt/cartographer/libcrypto-linux.so
/opt/cartographer/libcrypto-solx86.so
/opt/cartographer/libcrypto-sparcv9.so
/opt/cartographer/libeay32.dll
/opt/cartographer/libpcre-linux.so
/opt/cartographer/libpcre-solx86.so
/opt/cartographer/libpcre-sparcv9.so
/opt/cartographer/libssl-linux.so
/opt/cartographer/libssl-solx86.so
/opt/cartographer/libssl-sparcv9.so
/opt/cartographer/libxml2.dll
/opt/cartographer/mib2-linux.so
/opt/cartographer/mib2-solaris.so
/opt/cartographer/mib2-solx86.so
/opt/cartographer/mib2-win32.dll
/opt/cartographer/pcre.dll
/opt/cartographer/ntsetup.exe
/opt/cartographer/pthreadVC1.dll
/opt/cartographer/restartxmpd.exe
/opt/cartographer/restartxmpd.sh
/opt/cartographer/ssleay32.dll
/opt/cartographer/testplugin-linux.so
/opt/cartographer/testplugin-solaris.so
/opt/cartographer/testplugin-solx86.so
/opt/cartographer/testplugin-win32.dll
/opt/cartographer/xmpd-linux
/opt/cartographer/xmpd-solaris
/opt/cartographer/xmpd-solx86
/opt/cartographer/xmpd-win32.exe
/opt/cartographer/xmpgetsubgraph-linux
/opt/cartographer/xmpgetsubgraph-win32.exe
/opt/cartographer/xmpgetsubgraph-solaris
/opt/cartographer/xmpgetsubgraph-solx86
/opt/cartographer/xmpquery-linux
/opt/cartographer/xmpquery-solaris
/opt/cartographer/xmpquery-solx86
/opt/cartographer/xmpquery-win32.exe
/opt/cartographer/zlib1.dll
/opt/cartographer/xmptomrtg-linux
/opt/cartographer/xmptomrtg-solaris
/opt/cartographer/xmptomrtg-solx86
/opt/cartographer/xmptomrtg-win32.exe

# -rw-r--r--
%defattr(644 root root 755)
/opt/cartographer/appdata.xml
/opt/cartographer/cartographer.pem
/opt/cartographer/cartographer.xml
/opt/cartographer/connectiondata.xml
/opt/cartographer/xmp-1.0.xsd
/opt/cartographer/xmpcoldstart.xml
/opt/cartographer/xmpd.xml
/opt/cartographer/xmpget.xml
/opt/cartographer/xmpgetaddrtable.xml
/opt/cartographer/xmpgetarptable.xml
/opt/cartographer/xmpgetcartographer.xml
/opt/cartographer/xmpgetcoremib.xml
/opt/cartographer/xmpgetcputable.xml
/opt/cartographer/xmpgetdepends.xml
/opt/cartographer/xmpgetdiskstats.xml
/opt/cartographer/xmpgetendpttable.xml
/opt/cartographer/xmpgetevent.reply.xml
/opt/cartographer/xmpgetevent.xml
/opt/cartographer/xmpgetevents.xml
/opt/cartographer/xmpgetfilesys.xml
/opt/cartographer/xmpgetgraph.xml
/opt/cartographer/xmpgeticmp.xml
/opt/cartographer/xmpgetiftable.xml
/opt/cartographer/xmpgetiftableresp.xml
/opt/cartographer/xmpgetip.xml
/opt/cartographer/xmpgetmodulecontent.xml
/opt/cartographer/xmpgetmodulecontent1.xml
/opt/cartographer/xmpgetmodules.xml
/opt/cartographer/xmpgetparms.xml
/opt/cartographer/xmpgetpeers.xml
/opt/cartographer/xmpgetplugins.xml
/opt/cartographer/xmpgetprocs.xml
/opt/cartographer/xmpgetroutes.xml
/opt/cartographer/xmpgetstatus.xml
/opt/cartographer/xmpgetsysdescr.xml
/opt/cartographer/xmpgetsyserror.xml
/opt/cartographer/xmpgetsysinfometrics.xml
/opt/cartographer/xmpgettcp.xml
/opt/cartographer/xmpgettcptable.xml
/opt/cartographer/xmpgetudptable.xml
/opt/cartographer/xmpgetxmpdproc.xml
/opt/cartographer/xmpgetxmpstats.xml
/opt/cartographer/xmplongresponse.xml
/opt/cartographer/xmpprune.xml
/opt/cartographer/xmpresponse.xml
/opt/cartographer/xmpsetparms.xml
/opt/cartographer/xmptypes-1.0.xsd
/opt/cartographer/korg-license.txt
/opt/cartographer/Cartographer.gif

%changelog
