rem First parameter is a path to JDK7 and second parameter is a path to JDK8
rem Copy to jdk folder files jre-7u80-windows-i586.exe jre-7u80-windows-x64.exe jre-8u92-windows-i586.exe jre-8u92-windows-x64.exe

set wfeVersion=4.3.0

rem Clean artifacts from previous builds
rd /S /Q build
rd /S /Q results

rem Create folders for artifacts from new build
mkdir build
mkdir results

rem Copy required zip files and folders (jboss, eclipse and so on) into build directory
move jboss7 jboss
jar -cMf jboss.zip jboss
move jboss jboss7
move jboss.zip build

jar -cMf wildfly.zip wildfly
move wildfly.zip build

xcopy /E /Q eclipse build\eclipse\
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
call mvn versions:set -DnewVersion=%wfeVersion%

cd ..\..\installer\windows\
rem Build distr
call mvn clean package -Declipse.home.dir=../../../../eclipse -Djdk.dir="%~dp0jdk" -l build.log -Djava.home.7=%1 -Djava.home.8=%2

xcopy /E /Q target\test-result ..\..\..\..\..\results\test-result\
mkdir ..\..\..\..\..\results\Execution\jboss7
copy target\artifacts\Installer32\jboss7\RunaWFE-Installer.exe ..\..\..\..\..\results\Execution\jboss7\RunaWFE-Jboss-java7_32.exe
copy target\artifacts\Installer64\jboss7\RunaWFE-Installer.exe ..\..\..\..\..\results\Execution\jboss7\RunaWFE-Jboss-java7_64.exe
mkdir ..\..\..\..\..\results\Execution\wildfly
copy target\artifacts\Installer32\wildfly\RunaWFE-Installer.exe ..\..\..\..\..\results\Execution\wildfly\RunaWFE-Wildfly-java8_32.exe
copy target\artifacts\Installer64\wildfly\RunaWFE-Installer.exe ..\..\..\..\..\results\Execution\wildfly\RunaWFE-Wildfly-java8_64.exe
mkdir ..\..\..\..\..\results\ISO
copy target\*.iso ..\..\..\..\..\results\ISO\
