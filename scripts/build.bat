@echo on

set SOLUTION_FILE=ReconArtRelease.sln
echo Using solution file: %SOLUTION_FILE%

set SOLUTION_FILE_DB=.\ReconArt.Database\ReconArt.Database.sln
echo Using solution file for the DB build: %SOLUTION_FILE_DB%

:: Check if Visual Studio version is passed as the second parameter
if "%1"=="" (
    set VS_VERSION=2022
    echo No VS version provided, using default version: %VS_VERSION%
) else (
    set VS_VERSION=%1
    echo Using Visual Studio version: %VS_VERSION%
)

:: Set the base path based on the version
if "%VS_VERSION%"=="2022" (
    set VS_DEV_CMD="C:\Program Files\Microsoft Visual Studio\%VS_VERSION%\Community\Common7\Tools\VsDevCmd.bat"
    echo Using VS 2022 Developer Command Prompt at: %VS_DEV_CMD%
) else (
    set VS_DEV_CMD="C:\Program Files (x86)\Microsoft Visual Studio\%VS_VERSION%\Community\Common7\Tools\VsDevCmd.bat"
    echo Using VS %VS_VERSION% Developer Command Prompt at: %VS_DEV_CMD%
)

:: Check if the specified path exists
if not exist %VS_DEV_CMD% (
    echo Error: Could not find %VS_DEV_CMD%. Please ensure the version is installed.
    exit /b 1
)

:: Call the Visual Studio Developer Command Prompt
echo Calling VS Developer Command Prompt...
call %VS_DEV_CMD%

:: Verify if msbuild is now available
echo Verifying if msbuild is available...
msbuild -version >nul 2>&1
if errorlevel 1 (
    echo Error: msbuild command not found. Ensure Visual Studio is properly installed.
    exit /b 1
)

:: Call the NuGet installation script for ReconArt.sln
echo Executing NuGet installation script: install_nugets.ps1 %SOLUTION_FILE%
powershell -ExecutionPolicy Bypass -File install_nugets.ps1 %SOLUTION_FILE%
if errorlevel 1 (
    echo Error: NuGet package installation or restore failed.
    exit /b 1
)

:: Call the NuGet installation script with solution name
echo Executing NuGet installation script: install_nugets.ps1 %SOLUTION_FILE_DB%
powershell -ExecutionPolicy Bypass -File install_nugets.ps1 %SOLUTION_FILE_DB%
if errorlevel 1 (
    echo Error: NuGet package installation or restore failed.
    exit /b 1
)

:: Perform Clean and Build if "rebuild" is passed as the second parameter
if "%2"=="rebuild" (
    echo Performing Clean and Build...
    msbuild %SOLUTION_FILE% /t:Clean /p:Configuration=NewInstaller
    msbuild %SOLUTION_FILE_DB% /t:Clean /p:Configuration=Release
)

:: Perform the ReconArt build
echo Performing ReconArt Build...

:: msbuild %SOLUTION_FILE% /t:Build /p:"Platform=Mixed Platforms" /p:Configuration=NewInstaller /p:VisualStudioVersion=17.0 /consoleloggerparameters:ErrorsOnly /v:m /nologo /m:2
msbuild %SOLUTION_FILE% /restore /t:Build /p:"Platform=Mixed Platforms" /p:Configuration=NewInstaller /p:VisualStudioVersion=17.0 /v:n /m:8

:: Perform the DB build
echo Performing DB Build...

:: msbuild .\ReconArt.Database\ReconArt.Database.sln /t:Rebuild /p:Configuration=Release /v:m /nologo /consoleloggerparameters:ErrorsOnly /m:2 /p:SqlCmdVar__1=New
msbuild .\ReconArt.Database\ReconArt.Database.sln /t:Rebuild /p:Configuration=Release /v:n /m:8 /p:SqlCmdVar__1=New

echo Build SUCCESS
