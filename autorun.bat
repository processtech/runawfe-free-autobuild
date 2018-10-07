rem Copy to jdk folder jre-8u92-windows-i586.exe jre-8u92-windows-x64.exe

rem path to JDK8
if %1 == "" exit
rem path to results dir (it will be recreated)
if %2 == "" exit
rem artifacts version
if %3 == "" exit
rem tag or version to checkout
if %4 == "" exit

set wfeVersion=%3

rem Clean artifacts from previous builds
rd /S /Q build
rd /S /Q %2

rem Create folders for artifacts from new build
mkdir build
mkdir %2

rem Copy required zip files and folders (jboss and so on) into build directory
jar -cMf wildfly.zip wildfly
move wildfly.zip build

copy readme build


rem Export source code
cd /D build
set SOURCE_URL=https://github.com/processtech
git clone %SOURCE_URL%/runawfe-server.git source/projects/wfe
cd source/projects/wfe
git checkout %4
cd ../../../
rd /S /Q source\projects\wfe\.git
git clone %SOURCE_URL%/runawfe-devstudio.git source/projects/gpd
cd source/projects/gpd
git checkout %4
cd ../../../
rd /S /Q source\projects\gpd\.git
git clone %SOURCE_URL%/runawfe-notifier-java.git source/projects/rtn
cd source/projects/rtn
git checkout %4
cd ../../../
rd /S /Q source\projects\rtn\.git
git clone %SOURCE_URL%/runawfe-installer.git source/projects/installer
rd /S /Q source\projects\installer\.git

rem svn export %SOURCE_URL%/docs source/docs
mkdir source\docs
mkdir source\docs\guides
copy readme source\docs\guides\

rem Update projects version
cd source\projects\installer\windows\
call mvn versions:set -DnewVersion=%wfeVersion%
cd ../../wfe/wfe-appserver
call mvn versions:set -DnewVersion=%wfeVersion%
cd ../wfe-webservice-client
call mvn versions:set -DnewVersion=%wfeVersion%
cd ../wfe-app
call mvn versions:set -DnewVersion=%wfeVersion%
cd ../../rtn
call mvn versions:set -DnewVersion=%wfeVersion%
cd ../gpd/plugins
call mvn tycho-versions:set-version -DnewVersion=%wfeVersion%

cd ..\..\..\..\
jar -cMf source.zip source
mkdir %2\source
move source.zip %2\source\source-%3.zip

cd source\projects\installer\windows\
rem Build distr
call mvn clean package -Djdk.dir="%~dp0jdk" -l build.log -Djava.home.8=%1

xcopy /E /Q target\test-result %2\test-result\
mkdir %2\Execution\wildfly
copy target\artifacts\Installer32\wildfly\RunaWFE-Installer.exe %2\Execution\wildfly\RunaWFE-%3-Wildfly-java8_32.exe
copy target\artifacts\Installer64\wildfly\RunaWFE-Installer.exe %2\Execution\wildfly\RunaWFE-%3-Wildfly-java8_64.exe
mkdir %2\ISO
copy target\*.iso %2\ISO\

mkdir %2\bin
mkdir %2\bin\server
rem Create bin file for wildfly server
jar xf target\artifacts\wildfly\app-server\wfe-appserver-base-%3.zip 
jar xf target\artifacts\wildfly\app-server\wfe-appserver-diff-%3.zip 
xcopy /E /Q ..\simulation\* jboss\
move jboss wildfly
jar -cMf runawfe-wildfly-java8-%3.zip wildfly
rd /S /Q wildfly
move runawfe-wildfly-java8-%3.zip %2\bin\server\runawfe-wildfly-java8-%3.zip

rem Create bin file for gpd
xcopy /E /Q target\artifacts\gpd\all %2\bin\gpd\

rem Create bin file for rtn 
mkdir %2\bin\rtn

xcopy /E /Q target\artifacts\rtn\32 rtn\
jar -cMf runawfe-rtn-win32-%3.zip rtn
rd /S /Q rtn
move runawfe-rtn-win32-%3.zip %2\bin\rtn\runawfe-rtn-win32-%3.zip

xcopy /E /Q target\artifacts\rtn\64 rtn\
jar -cMf runawfe-rtn-win64-%3.zip rtn
rd /S /Q rtn
move runawfe-rtn-win64-%3.zip %2\bin\rtn\runawfe-rtn-win64-%3.zip

