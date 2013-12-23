# $Id: cartographer-gui.spec 151 2011-03-31 14:33:54Z rdk $
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
# actually install package with rpm -iUv pkg.rpm
# remove package with rpm -e pkg

# keep RPM from making an empty debug package
%define debug_package %{nil}

# disable the automagic dependency generator from
# finding/requiring a whole bunch of solaris dependencies
# also disable the automatic "provides" calcuations
# this tag does both
AutoReqProv: no

# location definitions so we can build in our development/release directory
%define _rpmdir /krupczak/rdk/tmp/rpmbuild
%define release_location /krupczak/rdk/tmp/Cartographer/lib
%define instprefix /opt/cartographer-gui

BuildRoot: 	/krupczak/rdk/tmp/rpmbuild
Summary:	Cartographer graphical user interface or GUI
Name:		cartographer-gui
Version:	0.33
Release:	1
Group:		Applications/System
URL:		http://www.krupczak.org/cartographer
Vendor: 	The Krupczak Organization
Prefix: 	%{instprefix}
BuildArch:	noarch
License:	license.txt
# Requires: 	
# Icon:		Cartographer.gif


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

%pre

# ----------------------------------------------------------
# 
# post install script commands here
# $1 is the count option specifying 
# 1 for first time, 2 or higher for upgrades
# 0 for remove last version of package
# 
%post

# ----------------------------------------------------------
# 
# pre-remove script commands here
# 

%preun


# ----------------------------------------------------------
# 
# post uninstall script
# do final cleanup
# use RPM_INSTALL_PREFIX0 which should be set because
# we set prefix in original spec file
# 
%postun

# remove our directory if it still exists
if [ "$1" = 0 ];then
   if [ -x "$RPM_INSTALL_PREFIX0" ]; then
      rmdir $RPM_INSTALL_PREFIX0
   fi
fi
echo -n

# ----------------------------------------------------------

%files
%defattr(644 root root 755)
/opt/cartographer-gui/Cartographer.jar
/opt/cartographer-gui/Xmp.jar
/opt/cartographer-gui/jgraph.jar
/opt/cartographer-gui/jgraphlayout.jar
/opt/cartographer-gui/license.txt

%changelog
