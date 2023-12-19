@echo off

SET SELF=%~f0

:init
    if "%WORKSPACE%" == "" (
        set WORKSPACE=%~dp0
    )
    set STAR_INSTALL_DIR=
    set COMPILER=
    set STAR_LIB_TRASH_LIST=xttranslator_3dx.exe xttranslator_3dx_salt.exe xttranslator_3dx_ugs.exe 
    set CAD_IMPORT_TRASH_LIST=xttranslator_3dx

goto :process_arguments 


REM ============================================START_FUNCTIONS==============================================
:usage
    echo %SELF% is a tool to scrub the HOOPS exchange library
    echo -----------------------------------------------------------------------bch
    echo USAGE: %SELF% -p ^<STAR INSTALLATION DIR^>
    echo    -p     # relative or absolute path to the Versioned STAR installation
    echo           # e.g. /home/installs/STAR-CCM+18.04.009-R8
    EXIT 1

:process_arguments
    if "%~1"==""              goto :validate 
    if /i "%~1"=="/?"         goto :usage
    if /i "%~1"=="-?"         goto :usage
    if /i "%~1"=="-h"         goto :usage
    if /i "%~1"=="--help"     goto :usage

    if /i "%~1"=="-p"         set "STAR_INSTALL_DIR=%~2" & shift & shift & goto :process_arguments 
    if /i "%~1"=="-P"         set "STAR_INSTALL_DIR=%~2" & shift & shift & goto :process_arguments

    shift
    goto :process_arguments


:validate
    if "%STAR_INSTALL_DIR%" == "" (
        echo NO DIR specified
	goto :usage
    )

    if not exist "%STAR_INSTALL_DIR%\" (
        echo DIR %STAR_INSTALL_DIR% doesn't exist
        goto :usage
    )

    if not exist "%STAR_INSTALL_DIR%\star\bin\starccm+.bat" (
        echo star executable expected at ${STAR_INSTALL_DIR}/star/bin/starccm+.bat
        goto :usage
    )

:main

REM for TRASH in ${TRASH_LIST}; do
REM     find ${STAR_INSTALL_DIR}/${TRASH} -print -delete
REM done

for /F %%N in ( 'dir /B %STAR_INSTALL_DIR%\star\lib\win64\' ) do @set COMPILER=%%N

for %%t in ( %STAR_LIB_TRASH_LIST% ) do (
	echo %STAR_INSTALL_DIR%\star\lib\win64\%COMPILER%\lib\%%t
	del /q %STAR_INSTALL_DIR%\star\lib\win64\%COMPILER%\lib\%%t
)

for %%t in ( %CAD_IMPORT_TRASH_LIST% ) do (
        echo %STAR_INSTALL_DIR%\cad-import\win64\%%t\
        rmdir /q /s %STAR_INSTALL_DIR%\cad-import\win64\%%t\

)

goto :eof