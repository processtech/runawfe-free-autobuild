set BUILD_DIR=%~dp0
git clone https://github.com/processtech/runawfe-autobuild.git
git checkout rc4.4.0
rd /S /Q %BUILD_DIR%\.git
xcopy %~dp0jdk %BUILD_DIR%\runawfe-autobuild\jdk\
cd /D %BUILD_DIR%/runawfe-autobuild
call autorun.bat "C:/Dofs/jdk1.8.0_181" %~dp0results 4.4.0 rc4.4.0