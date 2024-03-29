@ECHO OFF
SETLOCAL EnableDelayedExpansion
PUSHD %~dp0

rem If launched from anything other than cmd.exe, will have "%WINDIR%\system32\cmd.exe" in the command line
set INTERACTIVE_BUILD=
IF "%1"=="/NONINTERACTIVE" GOTO NONINTERACTIVE
ECHO.%CMDCMDLINE% | FINDSTR /C:"%COMSPEC% /c" >NUL
IF ERRORLEVEL 1 GOTO NONINTERACTIVE
rem Preserve this as it seems to be corrupted below otherwise?!
SET CMDLINE=%CMDCMDLINE%
rem If launched from anything other than cmd.exe, last character of command line will always be a double quote
IF NOT ^!CMDCMDLINE:~-1!==^" GOTO NONINTERACTIVE
rem If run from Explorer, last-but-one character of command line will be a space
IF NOT "!CMDLINE:~-2,1!"==" " GOTO NONINTERACTIVE
SET INTERACTIVE_BUILD=1
:NONINTERACTIVE

::: Extract version
set VER=
rem for /f "tokens=3 usebackq" %%f in (`type resource.rc ^| findstr /R /C:"#define[ ]VER_MAJOR"`) do set VER=%%f
rem for /f "tokens=3 usebackq" %%f in (`type resource.rc ^| findstr /R /C:"#define[ ]VER_MINOR"`) do set VER=%VER%.%%f
rem for /f "tokens=3 usebackq" %%f in (`type resource.rc ^| findstr /R /C:"#define[ ]VER_BUILD"`) do set VER=%VER%.%%f
rem for /f "tokens=3 usebackq" %%f in (`type resource.rc ^| findstr /R /C:"#define[ ]VER_REVISION"`) do set VER=%VER%.%%f

SET FIND_CL=
FOR %%p IN (cl.exe) DO SET "FIND_CL=%%~$PATH:p"
IF DEFINED FIND_CL (
  ECHO Build tools already on path.
  GOTO BUILD
)

ECHO Build tools not on path, looking for 'vcvarsall.bat'...
rem x86 x64
SET ARCH=x64
SET VCVARSALL=
FOR %%f IN (70 71 80 90 100 110 120 130 140) DO IF EXIST "!VS%%fCOMNTOOLS!\..\..\VC\vcvarsall.bat" SET VCVARSALL=!VS%%fCOMNTOOLS!\..\..\VC\vcvarsall.bat
FOR /F "usebackq tokens=*" %%f IN (`DIR /B /ON "%ProgramFiles(x86)%\Microsoft Visual Studio\????"`) DO FOR %%g IN (BuildTools Community Professional Enterprise) DO IF EXIST "%ProgramFiles(x86)%\Microsoft Visual Studio\%%f\%%g\VC\Auxiliary\Build\vcvarsall.bat" SET "VCVARSALL=%ProgramFiles(x86)%\Microsoft Visual Studio\%%f\%%g\VC\Auxiliary\Build\vcvarsall.bat"
FOR /F "usebackq tokens=*" %%f IN (`DIR /B /ON "%ProgramFiles%\Microsoft Visual Studio\????"`) DO FOR %%g IN (BuildTools Community Professional Enterprise) DO IF EXIST "%ProgramFiles%\Microsoft Visual Studio\%%f\%%g\VC\Auxiliary\Build\vcvarsall.bat" SET "VCVARSALL=%ProgramFiles%\Microsoft Visual Studio\%%f\%%g\VC\Auxiliary\Build\vcvarsall.bat"
IF "%VCVARSALL%"=="" ECHO Cannot find C compiler environment for 'vcvarsall.bat'. & GOTO ERROR
ECHO Setting environment variables for C compiler... %VCVARSALL%
CALL "%VCVARSALL%" %ARCH%

:BUILD
SET NOLOGO=/nologo
ECHO Compiling...
cl %NOLOGO% -c /EHsc /O2 /Tc"agfilter.c" /Tc"butter.c" /Tc"calc-csv.c" /Tc"calc-paee.c" /Tc"calc-sleep.c" /Tc"calc-step.c" /Tc"calc-svm.c" /Tc"calc-wtv.c" /Tc"linearregression.c" /Tc"main.c" /Tc"omcalibrate.c" /Tc"omconvert.c" /Tc"omdata.c" /Tc"wav.c"
IF ERRORLEVEL 1 GOTO ERROR
ECHO Linking...
link %NOLOGO% /out:omconvert.exe agfilter butter calc-csv calc-paee calc-sleep calc-step calc-svm calc-wtv linearregression main omcalibrate omconvert omdata wav /subsystem:console
IF ERRORLEVEL 1 GOTO ERROR
ECHO Done. %VER%
IF DEFINED INTERACTIVE_BUILD COLOR 2F & PAUSE & COLOR
GOTO END

:ERROR
ECHO ERROR: An error occured.
POPD
IF DEFINED INTERACTIVE_BUILD COLOR 4F & PAUSE & COLOR
EXIT /B 1

:END
POPD

