; Java Launcher with automatic JRE detection
;-----------------------------------------------

; Include the project header file generated by the nsis-maven-plugin
!include "..\..\..\..\target\project.nsh"
!include "..\..\..\..\target\extra.nsh"

Name "PMS"
Caption "${PROJECT_NAME}"
Icon "${PROJECT_BASEDIR}\src\main\external-resources\icon.ico"
 
VIAddVersionKey "ProductName" "${PROJECT_NAME}"
VIAddVersionKey "Comments" ""
VIAddVersionKey "CompanyName" "${PROJECT_ORGANIZATION_NAME}"
VIAddVersionKey "LegalTrademarks" ""
VIAddVersionKey "LegalCopyright" ""
VIAddVersionKey "FileDescription" "${PROJECT_NAME}"
VIAddVersionKey "FileVersion" "${PROJECT_VERSION}"
VIProductVersion "${PROJECT_VERSION_SHORT}.0"
 
!define JARPATH "${PROJECT_BUILD_DIR}\pms.jar"
!define CLASS "net.pms.PMS"
!define PRODUCT_NAME "PMS"
 
; Definitions for Java
!define JRE6_VERSION "6.0"
!define JRE7_VERSION "7.0"

; use javaw.exe to avoid dosbox.
; use java.exe to keep stdout/stderr
!define JAVAEXE "javaw.exe"
 
RequestExecutionLevel user
SilentInstall silent
AutoCloseWindow true
ShowInstDetails nevershow
 
!include "FileFunc.nsh"
!insertmacro GetFileVersion
!insertmacro GetParameters
!include "WordFunc.nsh"
!insertmacro VersionCompare
!include "x64.nsh"
 
Section ""
  Call GetJRE
  Pop $R0
 
  ; change for your purpose (-jar etc.)
  ${GetParameters} $1
  StrCpy $0 '"$R0" -classpath update.jar;pms.jar -server -Xmx768M -Djava.net.preferIPv4Stack=true -Dfile.encoding=UTF-8 ${CLASS} $1'
 
  SetOutPath $EXEDIR
  ExecWait $0
SectionEnd
  
;  returns the full path of a valid java.exe
;  looks in:
;  1 - .\jre directory (JRE Installed with application)
;  2 - JAVA_HOME environment variable
;  3 - the registry
;  4 - hopes it is in current dir or PATH
Function GetJRE
    Push $R0
    Push $R1
    Push $2
 
  ; 1) Check local JRE
  CheckLocal:
    ClearErrors
    ${If} ${RunningX64}
    StrCpy $R0 "$EXEDIR\jre64\bin\${JAVAEXE}"
    IfFileExists $R0 JreFound
    ${EndIf}
    StrCpy $R0 "$EXEDIR\jre\bin\${JAVAEXE}"
    IfFileExists $R0 JreFound
 
  ; 2) Check for JAVA_HOME
  CheckJavaHome:
    ClearErrors
    ReadEnvStr $R0 "JAVA_HOME"
    StrCpy $R0 "$R0\bin\${JAVAEXE}"
    IfErrors CheckRegistry1     
    IfFileExists $R0 0 CheckRegistry1
    Call CheckJREVersion
    IfErrors CheckRegistry1 JreFound
 
  ; 3) Check for registry
  CheckRegistry1:
    ClearErrors
    ${If} ${RunningX64}
 	SetRegView 64
 	${EndIf}
    ReadRegStr $R1 HKLM "SOFTWARE\Wow6432Node\JavaSoft\Java Runtime Environment" "CurrentVersion"
    ReadRegStr $R0 HKLM "SOFTWARE\Wow6432Node\JavaSoft\Java Runtime Environment\$R1" "JavaHome"
    StrCpy $R0 "$R0\bin\${JAVAEXE}"
    IfErrors CheckRegistry2     
    IfFileExists $R0 0 CheckRegistry2
    Call CheckJREVersion
    IfErrors CheckRegistry2 JreFound
    
  ; 4) Check for registry 
  CheckRegistry2:
    ClearErrors
    ReadRegStr $R1 HKLM "SOFTWARE\JavaSoft\Java Runtime Environment" "CurrentVersion"
    ReadRegStr $R0 HKLM "SOFTWARE\JavaSoft\Java Runtime Environment\$R1" "JavaHome"
    StrCpy $R0 "$R0\bin\${JAVAEXE}"
    IfErrors CheckRegistry3
    IfFileExists $R0 0 CheckRegistry3
    Call CheckJREVersion
    IfErrors CheckRegistry3 JreFound
 
  ; 5) Check for registry
  CheckRegistry3:
    ClearErrors
    ${If} ${RunningX64}
 	SetRegView 32
 	${Else}
 	Goto GoodLuck
 	${EndIf}
    ReadRegStr $R1 HKLM "SOFTWARE\JavaSoft\Java Runtime Environment" "CurrentVersion"
    ReadRegStr $R0 HKLM "SOFTWARE\JavaSoft\Java Runtime Environment\$R1" "JavaHome"
    StrCpy $R0 "$R0\bin\${JAVAEXE}"
    IfErrors CheckRegistry4
    IfFileExists $R0 0 CheckRegistry4
    Call CheckJREVersion
    IfErrors CheckRegistry4 JreFound
    
  ; 6) Check for registry
  CheckRegistry4:
    ClearErrors
    ReadRegStr $R1 HKLM "SOFTWARE\Wow6432Node\JavaSoft\Java Runtime Environment" "CurrentVersion"
    ReadRegStr $R0 HKLM "SOFTWARE\Wow6432Node\JavaSoft\Java Runtime Environment\$R1" "JavaHome"
    StrCpy $R0 "$R0\bin\${JAVAEXE}"
    IfErrors GoodLuck
    IfFileExists $R0 0 GoodLuck
    Call CheckJREVersion
    IfErrors GoodLuck JreFound

  ; 7) wishing you good luck
  GoodLuck:
    StrCpy $R0 "${JAVAEXE}"
    MessageBox MB_ICONSTOP "Cannot find appropriate Java Runtime Environment. Please download and install PMS-setup-full.exe."
    Abort
 
  JreFound:
    Pop $2
    Pop $R1
    Exch $R0
FunctionEnd
 
; Pass the "javaw.exe" path by $R0
Function CheckJREVersion
    ; R1 holds the current JRE version
    Push $R1
    Push $R2
 
    ; Get the file version of javaw.exe
    ${GetFileVersion} $R0 $R1
 
    ClearErrors
    
    ; Check if JRE6 is installed
    ${VersionCompare} ${JRE6_VERSION} $R1 $R2
    StrCmp $R2 "1" 0 CheckDone
    
    ; Check if JRE7 is installed
    ${VersionCompare} ${JRE7_VERSION} $R1 $R2
    StrCmp $R2 "1" 0 CheckDone
    
    SetErrors
 
  CheckDone:
    Pop $R1
    Pop $R2
FunctionEnd
