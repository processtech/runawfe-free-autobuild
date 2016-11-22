rem First parameter is a path to JDK7 and second parameter is a path to JDK8
rem Third parameter is a path to results dir (it will be recreated)
rem Fourth parameter is a artifacts version
rem Copy to jdk folder files jre-7u80-windows-i586.exe jre-7u80-windows-x64.exe jre-8u92-windows-i586.exe jre-8u92-windows-x64.exe

if %1 == "" exit
if %2 == "" exit
if %3 == "" exit
if %4 == "" exit

set wfeVersion=%4

rem Clean artifacts from previous builds
rd /S /Q build
rd /S /Q %3

rem Create folders for artifacts from new build
mkdir build
mkdir %3

rem Copy required zip files and folders (jboss and so on) into build directory
move jboss7 jboss
jar -cMf jboss.zip jboss
move jboss jboss7
move jboss.zip build

jar -cMf wildfly.zip wildfly
move wildfly.zip build

copy readme build


rem Export source code
cd /D build
set SOURCE_URL=https://github.com/processtech
git clone %SOURCE_URL%/runawfe-server.git source/projects/wfe
rd /S /Q source\projects\wfe\.git
git clone %SOURCE_URL%/runawfe-devstudio.git source/projects/gpd
rd /S /Q source\projects\gpd\.git
git clone %SOURCE_URL%/runawfe-notifier-java.git source/projects/rtn
rd /S /Q source\projects\rtn\.git
git clone %SOURCE_URL%/runawfe-installer.git source/projects/installer
rd /S /Q source\projects\installer\.git

rem svn export %SOURCE_URL%/docs source/docs
mkdir source\docs
mkdir source\docs\guides
copy readme source\docs\guides\

copy ..\jdk\jdk-7u7-windows-i586.exe source\projects\installer\windows\resources\jdk_setup.exe

rem Update projects version
cd source\projects\installer\windows\
call mvn versions:set -DnewVersion=%wfeVersion% -Dtycho.disableP2Mirrors=true
cd ../../wfe/wfe-appserver
call mvn versions:set -DnewVersion=%wfeVersion% -Dtycho.disableP2Mirrors=true
cd ../wfe-webservice-client
call mvn versions:set -DnewVersion=%wfeVersion% -Dtycho.disableP2Mirrors=true
cd ../wfe-app
call mvn versions:set -DnewVersion=%wfeVersion% -Dtycho.disableP2Mirrors=true
cd ../../rtn
call mvn versions:set -DnewVersion=%wfeVersion% -Dtycho.disableP2Mirrors=true
cd ../gpd/plugins
call mvn tycho-versions:set-version -DnewVersion=%wfeVersion% -Dtycho.disableP2Mirrors=true

cd ..\..\..\..\
jar -cMf source.zip source
mkdir %3\source
move source.zip %3\source\source-%4.zip

cd source\projects\installer\windows\
rem Build distr
call mvn clean package -Djdk.dir="%~dp0jdk" -l build.log -Djava.home.7=%1 -Djava.home.8=%2

xcopy /E /Q target\test-result %3\test-result\
mkdir %3\Execution\jboss7
copy target\artifacts\Installer32\jboss7\RunaWFE-Installer.exe %3\Execution\jboss7\RunaWFE-%4-Jboss-java7_32.exe
copy target\artifacts\Installer64\jboss7\RunaWFE-Installer.exe %3\Execution\jboss7\RunaWFE-%4-Jboss-java7_64.exe
mkdir %3\Execution\wildfly
copy target\artifacts\Installer32\wildfly\RunaWFE-Installer.exe %3\Execution\wildfly\RunaWFE-%4-Wildfly-java8_32.exe
copy target\artifacts\Installer64\wildfly\RunaWFE-Installer.exe %3\Execution\wildfly\RunaWFE-%4-Wildfly-java8_64.exe
mkdir %3\ISO
copy target\*.iso %3\ISO\

mkdir %3\bin
rem Create bin file for jboss server
jar xf target\artifacts\jboss7\app-simulation\wfe-appserver-full-%4.zip 
xcopy /E /Q target\artifacts\jboss7\simulation-data jboss
jar -cMf runawfe-jboss-java7-%4.zip jboss
rd /S /Q jboss
move runawfe-jboss-java7-%4.zip %3\bin\runawfe-jboss-java7-%4.zip

rem Create bin file for wildfly server
jar xf target\artifacts\wildfly\app-simulation\wfe-appserver-full-%4.zip 
xcopy /E /Q target\artifacts\wildfly\simulation-data jboss
move jboss wildfly
jar -cMf runawfe-wildfly-java8-%4.zip wildfly
rd /S /Q wildfly
move runawfe-wildfly-java8-%4.zip %3\bin\runawfe-wildfly-java8-%4.zip
