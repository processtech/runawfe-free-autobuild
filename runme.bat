set BUILD_DIR=%~dp0
git clone https://github.com/processtech/runawfe-autobuild.git
git checkout master
rd /S /Q %BUILD_DIR%\.git
xcopy %~dp0jdk %BUILD_DIR%\runawfe-autobuild\jdk\
cd /D %BUILD_DIR%/runawfe-autobuild
call autorun.bat "C:/jdk1.8.0_191" %~dp0results 4.4.0 master >> autobuild.log 2>&1