; Script generated by the HM NIS Edit Script Wizard.

; run from main agent build directory
; $Id: installer.nsi 147 2011-03-31 14:16:34Z rdk $
; mods by rdk
; 
; Copyright 2010, Krupczak.org, LLC
;
; This program is free software; you can redistribute it and/or
; modify it under the terms of the GNU General Public License as
; published by the Free Software Foundation; either version 2 of the
; License, or (at your option) any later version.
;
; This program is distributed in the hope that it will be useful, but
; WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
; General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
; USA
 
; -----------------------------------------------------------------------
; Variables and defines

; configure service vars
Var serviceCheckbox
Var serviceCheckboxState

; start service vars and start systray vars
Var svcCheckbox
Var svcCheckboxState
Var stCheckbox
Var stCheckboxState

; am I already installed?
Var alreadyInstalled

; am I currently running
; true or false
Var currentlyRunning
Var serviceStatus

; configure system tray vars
Var systrayCheckbox
Var systrayCheckboxState

; must match those from setuplib.[ch]
!define SERVICE_NAME  "cartographer"
!define SERVICE_DESCRIPTION  "Cartographer, XML Management Protocol Daemon from Krupczak.org http://www.krupczak.org"
!define SERVICE_DISPLAYNAME "cartographer"

; HM NIS Edit Wizard helper defines
!define PRODUCT_NAME "Cartographer"
!define PRODUCT_VERSION "1.3"
!define PRODUCT_PUBLISHER "Krupczak.org, LLC"
!define PRODUCT_WEB_SITE "http://www.krupczak.org/cartographer"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\xmpd-win32.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"

; MUI 1.67 compatible ------
; Use MUI2 instead of MUI 1.x
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "servicelib.nsh"
!include "x64.nsh"
!include "WinVer.nsh"

; request application privileges for Vista+
RequestExecutionLevel admin
BrandingText "� 2010 Krupczak.org, LLC.  Installer made with NSIS"

; MUI Settings
!define MUI_ABORTWARNING
!define MUI_ICON "xmpd\src\cartographer-installer.ico"
!define MUI_UNICON "xmpd\src\cartographer-installer.ico"

VIProductVersion "1.3.0.0"
ViAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "Cartographer Agent"
ViAddVersionKey /LANG=${LANG_ENGLISH} "Comments" "Installer produced with NSIS and HM NIS Editor"
ViAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" "Krupczak.org, LLC"
ViAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "Copyright 2011, Krupczak.org, LLC"
ViAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "1.3.0.0"
ViAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "Cartographer Agent Windows Installer"

; -----------------------------------------------------------------------
; install pages

; Welcome page
!insertmacro MUI_PAGE_WELCOME

; License page
!insertmacro MUI_PAGE_LICENSE "korg-license.txt"

; Directory page
!insertmacro MUI_PAGE_DIRECTORY

; Instfiles page
!insertmacro MUI_PAGE_INSTFILES

; Configure service?
Page custom pageServiceCreate pageServiceLeave

; Configure systray shortcut?
Page custom pageSystrayCreate pageSystrayLeave

; Start service now?
Page custom pageSvcStart pageSvcLeave

; Start system tray app now?
Page custom pageStStart pageStLeave

; before we finish, at some point we should present dialogs
; walking user through base configuration of agent engine
; save this for future installer version

; Finish page 
!insertmacro MUI_PAGE_FINISH

; -----------------------------------------------------------------------
; Uninstaller pages

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; Language files
!insertmacro MUI_LANGUAGE "English"

; MUI end ------

; -----------------------------------------------------------------------
; functions and page-functions

; prevent multiple instances of installer and check for other
; parameters at start of the installer
; if x64, set Registry view to 64
; check if already installed; if installed and we wish to continue
; go ahead and try to stop the service anyway
; dont sleep as the service stop will wait for service to finish

Function .onInit

	 ${If} ${RunningX64}
	       SetRegView 64
	 ${EndIf}

	 ${If} ${AtMostWin2000}
	       MessageBox MB_OK|MB_ICONEXCLAMATION "This installer cannot be run on anything below Windows XP"
	       Abort
	 ${EndIf}

         call isCartographerInstalled
	 call isCartographerRunning

	 StrCmp $alreadyInstalled "false" continueInstall 0
	 MessageBox MB_YESNO "Cartographer is already installed.  Do you wish to continue?" IDYES yesContinue IDNO 0
	 Abort

	 yesContinue:

	 MessageBox MB_OK "Please be patient while we stop the Cartographer service and system tray app if they are running"

         Call stopService
	 Call stopSystray

	 continueInstall:

	 System::Call 'kernel32::CreateMutexA(i 0, i 0, t "cartographerInstallerMutex") i .r1 ?e'
	 Pop $R0
	 StrCmp $R0 0 +3
	 MessageBox MB_OK|MB_ICONEXCLAMATION "The installer is already running."
	 Abort
FunctionEnd


Function pageServiceCreate
         !insertmacro MUI_HEADER_TEXT "Create Service?" "Create Windows service entry in Service Control Manager?  Doing so will make sure Cartographer is run each time the system starts."
         nsDialogs::Create 1018
         pop $0
         ${NSD_CreateLabel} 0 5u 100% 20u "Create Service Entry?"
         pop $1
         ${NSD_CreateCheckbox} 0 20u 100% 20u "Yes!"
         pop $serviceCheckbox
         ${NSD_SetState} $serviceCheckbox ${BST_CHECKED}
         nsDialogs::Show
FunctionEnd

Function pageServiceLeave
         ${NSD_GetState} $serviceCheckbox $serviceCheckboxState
	 StrCmp $serviceCheckBoxState ${BST_CHECKED} 0 DontCreateService
	 call createServiceEntry
	 DontCreateService:
         call writeRegistryEntries
FunctionEnd

; -------------

Function createServiceEntry
	 !undef UN
	 !define UN ""
	 !insertmacro SERVICE create "${SERVICE_NAME}" "path=$INSTDIR\xmpd-win32.exe;autostart=1;interact=0;display=${SERVICE_DISPLAYNAME};description=${SERVICE_DESCRIPTION};"
FunctionEnd

; -------------
; service manipulation functions

Function updateServiceEntry
	 call deleteServiceEntry
	 call createServiceEntry
FunctionEnd

Function deleteServiceEntry
	 !undef UN
	 !define UN ""
	 !insertmacro SERVICE delete "${SERVICE_NAME}" ""
FunctionEnd

Function un.deleteServiceEntry
	 !undef UN
	 !define UN "un."
	 !insertmacro SERVICE delete "${SERVICE_NAME}" ""
FunctionEnd

Function startService
	 !undef UN
	 !define UN ""
	 !insertmacro SERVICE start "${SERVICE_NAME}" ""
FunctionEnd

Function stopService
	 !undef UN
	 !define UN ""
	 !insertmacro SERVICE stop "${SERVICE_NAME}" ""
	 sleep 30000
FunctionEnd

Function un.stopService
	 !undef UN
	 !define UN "un."
	 !insertmacro SERVICE stop "${SERVICE_NAME}" ""
	 sleep 30000
FunctionEnd

; -------------

; on win2k08, these entries do not appear to get written despite the
; fact that we ask for admin permissions
; its not win2k08, but 64-bit or 32-bit that is at work here
; use SetRegView to specify 32 or 64-bit

Function writeRegistryEntries
         WriteRegStr HKLM "Software\Krupczak.org\Cartographer Agent" "URL" "${PRODUCT_WEB_SITE}"
         WriteRegStr HKLM "Software\Krupczak.org\Cartographer Agent" "InstallDir" "$INSTDIR"
         WriteRegStr HKLM "Software\Krupczak.org\Cartographer Agent" "HowInstalled" "GUI"
         WriteRegStr HKLM "Software\Krupczak.org\Cartographer Agent" "Version" "${PRODUCT_VERSION}"
FunctionEnd

; -------------
; system tray functions

; on win2k08, this entry does not appear to get written
; despite the fact that we ask for admin permissions

Function createSystrayShortcut
	 WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Run" "Cartographertray" "$INSTDIR\cartographertray.exe"
FunctionEnd

Function removeSystrayShortcut
         Push "Cartographer System Tray Window"
         Call closeProgram
         DeleteRegValue HKLM "Software\Microsoft\Windows\CurrentVersion\run" "Cartographertray"
FunctionEnd

Function un.removeSystrayShortcut
         Push "Cartographer System Tray Window"
         Call un.closeProgram
         DeleteRegValue HKLM "Software\Microsoft\Windows\CurrentVersion\run" "Cartographertray"
FunctionEnd

; start the system tray app; note the single-quote on 
; outside and double-quotes on inside
; Exec might pop up a command-prompt window though which is ugly
;
; Use nsExec plugin function which is included in our plugins dir
; on Vista, this command may not get executed properly due to visa
; security levels and the fact that we run as administrator in order
; to write registry keys
; neither ExecToStack nor Exec work on Vista nor Win2k08
; according to the forums, do not use nsExec with windows apps
; (e.g. system tray apps) since the pluginw as written for dos apps only

Function startSystray
;	 nsExec::ExecToStack /TIMEOUT=1 '"$INSTDIR\cartographertray.exe"'
	 Exec '"$INSTDIR\cartographertray.exe"'
FunctionEnd

Function stopSystray
         Push "Cartographer System Tray Window"
         Call closeProgram
FunctionEnd

; -------------

Function removeRegistryEntries
         DeleteRegKey HKLM "Software\Krupczak.org\Cartographer Agent"
FunctionEnd

Function un.removeRegistryEntries
         DeleteRegKey HKLM "Software\Krupczak.org\Cartographer Agent"
FunctionEnd

; -------------

Function closeProgram
         Exch $1
         Push $0
         loop:
              FindWindow $0 $1
              IntCmp $0 0 done
              # SendMessage $0 ${WM_DESTROY} 0 0
              SendMessage $0 ${WM_CLOSE} 0 0
              Sleep 100
              Goto loop
          done:
          Pop $0
          Pop $1
FunctionEnd

Function un.closeProgram
         Exch $1
         Push $0
         loop:
              FindWindow $0 $1
              IntCmp $0 0 done
              # SendMessage $0 ${WM_DESTROY} 0 0
              SendMessage $0 ${WM_CLOSE} 0 0
              Sleep 100
              Goto loop
          done:
          Pop $0
          Pop $1
FunctionEnd

; -------------
; is Cartographer agent already installed?  Previous installs could have
; been via GUI or via command-line thus we check if service is
; installed and if registry keys exist
; name of service must match exactly what is created via setup
; if service not installed, return is "false", otherwise return 
; is running, etc.

Function isCartographerInstalled
	 !undef UN
	 !define UN ""
         !insertmacro SERVICE "status" "${SERVICE_NAME}" ""
         pop $alreadyInstalled
FunctionEnd

; is Cartographer agent currently running; true or false
Function isCartographerRunning
	 StrCpy $currentlyRunning "true"
	 !undef UN
	 !define UN ""
	 !insertmacro SERVICE "status" ${SERVICE_NAME}" ""
	 pop $serviceStatus
	 StrCmp $serviceStatus "running" IsRunning
	 StrCpy $currentlyRunning "false"
	 IsRunning:
FunctionEnd

; -------------
; should we create system tray shortcut?
; systrayCheckboxState = 1 if yes
; systrayCheckboxState = 0 if no
; compare to ${BST_CHECKED} and we dont have to worry about the
; actual value itself

Function pageSystrayCreate
         !insertmacro MUI_HEADER_TEXT "Create system tray shortcut?" "Create a system shortcut to be automatically started by all users?  This app will appear in each user system tray located on the bottom right of their screen."
         nsDialogs::Create 1018
         pop $0
         ${NSD_CreateLabel} 0 5u 100% 20u "Create system tray shortcut?"
         pop $1
         ${NSD_CreateCheckbox} 0 20u 100% 20u "Yes!"
         pop $systrayCheckbox
         ${NSD_SetState} $systrayCheckbox ${BST_CHECKED}
         nsDialogs::Show
FunctionEnd

Function pageSystrayLeave
         ${NSD_GetState} $systrayCheckbox $systrayCheckboxState
	 StrCmp $systrayCheckboxState ${BST_CHECKED} 0 DontCreateShortcut
	 call createSystrayShortcut
	 DontCreateShortcut:
FunctionEnd

; -------------
; start the service now?

; svcCheckboxState = 1 if yes
; svcCheckboxState = 0 if no

Function pageSvcStart
         !insertmacro MUI_HEADER_TEXT "Start the Cartographer service now?" ""
         nsDialogs::Create 1018
         pop $0

         ${NSD_CreateLabel} 0 5u 100% 20u "Start the Cartographer service now?!"
         pop $1
         ${NSD_CreateCheckbox} 0 20u 100% 20u "Yes!"
         pop $svcCheckbox
         ${NSD_SetState} $svcCheckbox ${BST_CHECKED}

         nsDialogs::Show
FunctionEnd

Function pageSvcLeave
         ${NSD_GetState} $svcCheckbox $svcCheckboxState
	 StrCmp $svcCheckboxState ${BST_CHECKED} 0 DontStartService
	 call startService
	 DontStartService:
FunctionEnd

; -------------
; start the systray now?
; stCheckboxState = 1 if yes
; stCheckboxState = 0 if no

Function pageStStart
         !insertmacro MUI_HEADER_TEXT "Start the system tray app now?" ""
         nsDialogs::Create 1018
         pop $0
         ${NSD_CreateLabel} 0 5u 100% 20u "Start system tray application now?!"
	 pop $1
	 ${NSD_CreateCheckbox} 0 20u 100% 20u "Yes!"
	 pop $stCheckbox
	 ${NSD_SetState} $stCheckbox ${BST_CHECKED}
         nsDialogs::Show
FunctionEnd

Function pageStLeave
	 ${NSD_GetState} $stCheckbox $stCheckboxState
	 StrCmp $stCheckboxState ${BST_CHECKED} 0 DontStartSystray
	 call startSystray
	 DontStartSystray:
FunctionEnd

; -----------------------------------------------------------------------
; sections

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "Release.exe"
InstallDir "$PROGRAMFILES\cartographer"
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
ShowInstDetails show
ShowUnInstDetails show

Section "MainSection" SEC01
  SetOutPath "$INSTDIR"
  SetOverwrite try
  File "release\xmpresponse.xml"
  File "release\xmpgetevent.reply.xml"
  File "release\xmpquery-linux"
  File "release\xmpgetdepends.xml"
  File "release\xmpgetsysinfometrics.xml"
  File "release\mib2-win32.dll"
  File "release\mib2-solaris.so"
  File "release\xmpquery-solaris"
  File "release\testplugin-win32.dll"
  File "release\xmpgetcputable.xml"
  File "release\libxml2.dll"
  File "release\pcre.dll"
  File "release\pthreadVC1.dll"
  File "release\libeay32.dll"
  File "release\xmpd-win32.exe"
  CreateDirectory "$SMPROGRAMS\Cartographer"
  CreateShortCut "$SMPROGRAMS\Cartographer\Cartographer.lnk" "$INSTDIR\xmpd-win32.exe"
  CreateShortCut "$SMPROGRAMS\Cartographer\Cartographertray.lnk" "$INSTDIR\cartographertray.exe"
  File "release\libssl-linux.so"
  File "release\libpcre-linux.so"
  File "release\xmptomrtg-win32.exe"
  File "release\xmpgetiftable.xml"
  File "release\cartographer-solaris.so"
  File "release\xmpgetcoremib.xml"
  File "release\xmpgetfilesys.xml"
  File "release\xmpd-solx86"
  File "release\restartxmpd.sh"
  File "release\cartographer-solx86.so"
  File "release\xmpgetdiskstats.xml"
  File "release\ntsetup.exe"
  File "release\init.solaris"
  File "release\xmpgetsyserror.xml"
  File "release\xmpgetroutes.xml"
  File "release\cartographertray.exe"
  File "release\xmpgetarptable.xml"
  File "release\xmpgetparms.xml"
  File "release\testplugin-linux.so"
  File "release\xmplongresponse.xml"
  File "release\xmptomrtg-solaris"
  File "release\cartographer.xml"
  File "release\cartographer-local.xml"
  File "release\cartographer-linux.so"
  File "release\xmpgettcp.xml"
  File "release\zlib1.dll"
  File "release\xmpgetevent.xml"
  File "release\libcrypto-solx86.so"
  File "release\xmpsetparms.xml"
  File "release\xmpd.xml"
  File "release\mib2-linux.so"
  File "release\xmpquery-win32.exe"
  File "release\appdata.xml"
  File "release\xmptomrtg-linux"
  File "release\xmpgetpeers.xml"
  File "release\xmpget.xml"
  File "release\libssl-sparcv9.so"
  File "release\libpcre-sparcv9.so"
  File "release\xmpd-linux"
  File "release\xmpgettcptable.xml"
  File "release\xmpgetaddrtable.xml"
  File "release\xmptomrtg-solx86"
  File "release\xmpgetcartographer.xml"
  File "release\init.linux"
  File "release\libcrypto-sparcv9.so"
  File "release\cartographer.pem"
  File "release\ssleay32.dll"
  File "release\xmpgetmodules.xml"
  File "release\xmpgetip.xml"
  File "release\xmpgeticmp.xml"
  File "release\xmpgetmodulecontent1.xml"
  File "release\restartxmpd.exe"
  File "release\xmpd-solaris"
  File "release\iconv.dll"
  File "release\xmpgetxmpstats.xml"
  File "release\libssl-solx86.so"
  File "release\libpcre-solx86.so"
  File "release\xmpgetprocs.xml"
  File "release\xmpgetevents.xml"
  File "release\xmpquery-solx86"
  File "release\libcrypto-linux.so"
  File "release\xmpgetsysdescr.xml"
  File "release\xmpgetendpttable.xml"
  File "release\xmpgetiftableresp.xml"
  File "release\xmpcoldstart.xml"
  File "release\testplugin-solaris.so"
  File "release\xmpgetstatus.xml"
  File "release\testplugin-solx86.so"
  File "release\mib2-solx86.so"
  File "release\xmpprune.xml"
  File "release\xmpgetxmpdproc.xml"
  File "release\xmpgetplugins.xml"
  File "release\connectiondata.xml"
  File "release\cartographer-win32.dll"
  File "release\xmpgetmodulecontent.xml"
  File "release\xmpgetudptable.xml"
  File "release\xmptypes-1.0.xsd"
  File "release\xmp-1.0.xsd"
  File "release\xmpgetsubgraph-linux"
  File "release\xmpgetsubgraph-solaris"
  File "release\xmpgetsubgraph-solx86"
  File "release\xmpgetsubgraph-win32.exe"
  File "release\korg-license.txt"
  File "release\Cartographer.gif"
SectionEnd

; ------------------------------------------------

Section -AdditionalIcons
  WriteIniStr "$INSTDIR\${PRODUCT_NAME}.url" "InternetShortcut" "URL" "${PRODUCT_WEB_SITE}"
  CreateShortCut "$SMPROGRAMS\Cartographer\Website.lnk" "$INSTDIR\${PRODUCT_NAME}.url"
  CreateShortCut "$SMPROGRAMS\Cartographer\Uninstall.lnk" "$INSTDIR\uninst.exe"
SectionEnd

; ------------------------------------------------

Section -Post
  WriteUninstaller "$INSTDIR\uninst.exe"
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\xmpd-win32.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\xmpd-win32.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
SectionEnd

; ------------------------------------------------
; this function invoked after successful install

Function un.onUninstSuccess
  HideWindow
  MessageBox MB_ICONINFORMATION|MB_OK "$(^Name) was successfully removed from your computer."
FunctionEnd

; this function invoked before install starts
; prevent multiple instance of uninstaller
; if x64, set Registry view to 64

Function un.onInit

 ${If} ${RunningX64}
       SetRegView 64
 ${EndIf}

  System::Call 'kernel32::CreateMutexA(i 0, i 0, t "cartographerInstallerMutex") i .r1 ?e'
  Pop $R0
  StrCmp $R0 0 +3
  MessageBox MB_OK|MB_ICONEXCLAMATION "The installer is already running."
  Abort
  MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 "Are you sure you want to completely remove $(^Name) and all of its components?" IDYES +2
  Abort
FunctionEnd

; ------------------------------------------------

Section Uninstall
  DetailPrint "Pausing 30 seconds to give service and/or system tray app time to stop..."
  call un.stopService
  DetailPrint "Deleting the service entry"
  call un.deleteServiceEntry
  DetailPrint "Removing registry entries"
  call un.removeRegistryEntries
  DetailPrint "Removing system tray shortcut"
  call un.removeSystrayShortcut
  Sleep 30000

  Delete "$INSTDIR\${PRODUCT_NAME}.url"
  Delete "$INSTDIR\uninst.exe"
  Delete "$INSTDIR\xmpgetudptable.xml"
  Delete "$INSTDIR\xmpgetmodulecontent.xml"
  Delete "$INSTDIR\cartographer-win32.dll"
  Delete "$INSTDIR\connectiondata.xml"
  Delete "$INSTDIR\xmpgetplugins.xml"
  Delete "$INSTDIR\xmpgetxmpdproc.xml"
  Delete "$INSTDIR\xmpprune.xml"
  Delete "$INSTDIR\mib2-solx86.so"
  Delete "$INSTDIR\testplugin-solx86.so"
  Delete "$INSTDIR\xmpgetstatus.xml"
  Delete "$INSTDIR\testplugin-solaris.so"
  Delete "$INSTDIR\xmpcoldstart.xml"
  Delete "$INSTDIR\xmpgetiftableresp.xml"
  Delete "$INSTDIR\xmpgetendpttable.xml"
  Delete "$INSTDIR\xmpgetsysdescr.xml"
  Delete "$INSTDIR\libcrypto-linux.so"
  Delete "$INSTDIR\xmpquery-solx86"
  Delete "$INSTDIR\xmpgetevents.xml"
  Delete "$INSTDIR\xmpgetprocs.xml"
  Delete "$INSTDIR\libssl-solx86.so"
  Delete "$INSTDIR\libpcre-solx86.so"
  Delete "$INSTDIR\xmpgetxmpstats.xml"
  Delete "$INSTDIR\iconv.dll"
  Delete "$INSTDIR\xmpd-solaris"
  Delete "$INSTDIR\restartxmpd.exe"
  Delete "$INSTDIR\xmpgetmodulecontent1.xml"
  Delete "$INSTDIR\xmpgeticmp.xml"
  Delete "$INSTDIR\xmpgetip.xml"
  Delete "$INSTDIR\xmpgetmodules.xml"
  Delete "$INSTDIR\ssleay32.dll"
  Delete "$INSTDIR\cartographer.pem"
  Delete "$INSTDIR\libcrypto-sparcv9.so"
  Delete "$INSTDIR\init.linux"
  Delete "$INSTDIR\xmpgetcartographer.xml"
  Delete "$INSTDIR\xmptomrtg-solx86"
  Delete "$INSTDIR\xmpgetaddrtable.xml"
  Delete "$INSTDIR\xmpgettcptable.xml"
  Delete "$INSTDIR\xmpd-linux"
  Delete "$INSTDIR\libssl-sparcv9.so"
  Delete "$INSTDIR\libpcre-sparcv9.so"
  Delete "$INSTDIR\xmpget.xml"
  Delete "$INSTDIR\xmpgetpeers.xml"
  Delete "$INSTDIR\xmptomrtg-linux"
  Delete "$INSTDIR\appdata.xml"
  Delete "$INSTDIR\xmpquery-win32.exe"
  Delete "$INSTDIR\mib2-linux.so"
  Delete "$INSTDIR\xmpd.xml"
  Delete "$INSTDIR\xmpsetparms.xml"
  Delete "$INSTDIR\libcrypto-solx86.so"
  Delete "$INSTDIR\xmpgetevent.xml"
  Delete "$INSTDIR\zlib1.dll"
  Delete "$INSTDIR\xmpgettcp.xml"
  Delete "$INSTDIR\cartographer-linux.so"
  Delete "$INSTDIR\cartographer.xml"
  Delete "$INSTDIR\cartographer-local.xml"
  Delete "$INSTDIR\xmptomrtg-solaris"
  Delete "$INSTDIR\xmplongresponse.xml"
  Delete "$INSTDIR\testplugin-linux.so"
  Delete "$INSTDIR\xmpgetparms.xml"
  Delete "$INSTDIR\xmpgetarptable.xml"
  Delete "$INSTDIR\cartographertray.exe"
  Delete "$INSTDIR\xmpgetroutes.xml"
  Delete "$INSTDIR\xmpgetsyserror.xml"
  Delete "$INSTDIR\init.solaris"
  Delete "$INSTDIR\ntsetup.exe"
  Delete "$INSTDIR\xmpgetdiskstats.xml"
  Delete "$INSTDIR\cartographer-solx86.so"
  Delete "$INSTDIR\restartxmpd.sh"
  Delete "$INSTDIR\xmpd-solx86"
  Delete "$INSTDIR\xmpgetfilesys.xml"
  Delete "$INSTDIR\xmpgetcoremib.xml"
  Delete "$INSTDIR\cartographer-solaris.so"
  Delete "$INSTDIR\xmpgetiftable.xml"
  Delete "$INSTDIR\xmptomrtg-win32.exe"
  Delete "$INSTDIR\libssl-linux.so"
  Delete "$INSTDIR\libpcre-linux.so"
  Delete "$INSTDIR\xmpd-win32.exe"
  Delete "$INSTDIR\libeay32.dll"
  Delete "$INSTDIR\pthreadVC1.dll"
  Delete "$INSTDIR\libxml2.dll"
  Delete "$INSTDIR\pcre.dll"
  Delete "$INSTDIR\xmpgetcputable.xml"
  Delete "$INSTDIR\testplugin-win32.dll"
  Delete "$INSTDIR\xmpquery-solaris"
  Delete "$INSTDIR\mib2-solaris.so"
  Delete "$INSTDIR\mib2-win32.dll"
  Delete "$INSTDIR\xmpgetsysinfometrics.xml"
  Delete "$INSTDIR\xmpgetdepends.xml"
  Delete "$INSTDIR\xmpquery-linux"
  Delete "$INSTDIR\xmpgetevent.reply.xml"
  Delete "$INSTDIR\xmpresponse.xml"
  Delete "$INSTDIR\xmptypes-1.0.xsd"
  Delete "$INSTDIR\xmp-1.0.xsd"
  Delete "$INSTDIR\xmpgetsubgraph-linux"
  Delete "$INSTDIR\xmpgetsubgraph-solaris"
  Delete "$INSTDIR\xmpgetsubgraph-solx86"
  Delete "$INSTDIR\xmpgetsubgraph-win32.exe"
  Delete "$INSTDIR\korg-license.txt"
  Delete "$INSTDIR\Cartographer.gif"

  ; some files that usually are created once agent has been run
  ; if any of these files do not exist, the uninstaller handles
  ; them gracefully and we dont see errors nor warnings
  Delete "$INSTDIR\xmpd.csr"
  Delete "$INSTDIR\xmpd.pem"
  Delete "$INSTDIR\xmpd.log"
  Delete "$INSTDIR\cartographertray.csr"
  Delete "$INSTDIR\cartographertray.pem"
  Delete "$INSTDIR\cartographertray.log"
  Delete "$INSTDIR\xmpquery.csr"
  Delete "$INSTDIR\xmpquery.pem"
  Delete "$INSTDIR\xmpgetsubgraph.csr"
  Delete "$INSTDIR\xmpgetsubgraph.pem"
  Delete "$INSTDIR\restartxmpd.log"
  Delete "$INSTDIR\peerdata.xml"
  Delete "$INSTDIR\*.old"

  ; finally, remove the install dir
  RmDir	 "$INSTDIR"

  Delete "$SMPROGRAMS\Cartographer\Uninstall.lnk"
  Delete "$SMPROGRAMS\Cartographer\Website.lnk"
  Delete "$SMPROGRAMS\Cartographer\Cartographer.lnk"
  Delete "$SMPROGRAMS\Cartographer\Cartographertray.lnk"

  RMDir "$SMPROGRAMS\Cartographer"

  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
  SetAutoClose true
SectionEnd

; -----------------------------------------------------------------------