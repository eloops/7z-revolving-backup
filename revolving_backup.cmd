@echo off
setlocal EnableDelayedExpansion
setlocal EnableExtensions

:: When configuring includelist.txt & excludelist.txt - 
::    Includelist.txt:
::      - Can put absolute pathnames in includelist.txt e.g.
::        - c:\a folder\goes here\
::        - c:\another\folder\*.pdf
::    Excludelist.txt
::      - Best to put wildcards at the start and end of entries in excludelist
::      - Examples:
::        - *\filename-or-folder*
::        - *thumbs.db should catch all instances of these files
::        - add detail to further identify files/folders:
::        - rather than *\Drivers* put *\System32\Drivers*


:: _workdir=
:: Working directory where executables etc are kept. 
:: Need:  - 7z.exe
::        - 7z.dll
::        - excludelist.txt
::        - includelist.txt
set _workdir=C:\Users\Stephen\SkyDrive\Documents\Work\Scripts\Backup

:: _outputdir
:: Sets destination for backup files
set _outputdir=C:\tmp

:: _nobackups=
:: This sets how many backups you want in the revolving backup. 
:: I just changed this, this is set to -1 below (some trickery involved here). 
set _numbackups=2

:: _basename=
:: This sets the base name for the backup files
set _basename=slp-backup

:: ------ Thats it for variables -------

:: I'll try to explain: to find the oldest backup file, we do a 'dir /b /O-D' on the output directory.
:: this returns a list of files in reverse date order (oldest to newest)
:: this list is then piped to 'more +[number of backups - 1]'.
:: Essentially this returns a list of existing backup files, but removes the x number of newest files from the list, where x == the number of files minus one.
:: Hence why we need this variable here.
set /a _realnumbackups=%_numbackups% - 1

cd %_workdir%

:: Replace spaces & slashes in date with dashes
set newdate=%DATE%
set newdate=%newdate: =-%
set newdate=%newdate:/=-%

:: Remove colons etc from time, format it nicely
set hour=%time:~0,2%
:: if its a single digit hour, add a 0
if "%hour:~0,1%"==" " set hour=0%time:~1,1%
set newtime=%hour%%time:~3,2%

:: Determine if there are two or more backup files already existing, if not, just create a new one
:: Note if there are zero files it will return 'file not found' - it still works as the test will fail

:: grab the number of existing backup files and save it to a variable
For /F "delims=" %%g in ('dir /b /A-d ^"%_outputdir%\%_basename%-*.7z^" ^| find ^"^" /v /n /c') Do set _nobufiles=%%g
:: do the actual comparison and go forward
if %_nobufiles% LEQ %_realnumbackups% @goto LimitReached

:: If required number of files already exist, determine the oldest one & delete it
:: Then create a new backup
For /F "Delims=" %%i In ('dir /b /O-D ^"%_outputdir%\%_basename%-*.7z^" ^| more +%_realnumbackups%') Do del "%_outputdir%\%%i"
echo Creating backup 7z file for condition: there are %_numbackups% or more files existing
%_workdir%\7z.exe a -y -x@"%_workdir%\excludelist.txt" -i@"%_workdir%\includelist.txt" -t7z -mmt -mx9 "%_outputdir%\%_basename%-%newdate%-%newtime%.7z"

goto finish

:: If there are less than two files, create a new one
:LimitReached
echo Creating backup 7z file for condition: there are less than %_numbackups% files existing
%_workdir%\7z.exe a -y -x@"%_workdir%\excludelist.txt" -i@"%_workdir%\includelist.txt" -t7z -mmt -mx9 "%_outputdir%\%_basename%-%newdate%-%newtime%.7z"

:finish
REM pause
exit
