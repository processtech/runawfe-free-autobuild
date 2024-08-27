set WFE_VERSION=4.6.0.marina
rem "Free", "Industrial", "Professional"
set WFE_EDITION=Professional
set RESULTS_DIR=%~dp0results
set GIT_SOURCE_URL=git@gitlab.processtech.ru:private
set GIT_PROJECT_EDITION=professional
set GIT_BRANCH_NAME=professional
set STATISTIC_REPORT_URL=https://usagereport.runawfe.org
set STATISTIC_REPORT_DAYS_AFTER_ERROR=9


rem Clean artifacts from previous builds
rd /S /Q build
rd /S /Q %RESULTS_DIR%

rem Create folders for artifacts from new build
mkdir build
mkdir %RESULTS_DIR%

rem Copy required zip files and folders (jboss and so on) into build directory
jar -cMf wildfly.zip wildfly
move wildfly.zip build

copy readme build


rem Export source code
cd /D build
git clone %GIT_SOURCE_URL%/runawfe-%GIT_PROJECT_EDITION%-server.git source/projects/wfe
cd source/projects/wfe
git checkout %GIT_BRANCH_NAME%

git rev-parse HEAD > tmp-hash.txt
set /p BUILD_HASH=<tmp-hash.txt
del tmp-hash.txt

cd ../../../
rd /S /Q source\projects\wfe\.git
git clone %GIT_SOURCE_URL%/runawfe-%GIT_PROJECT_EDITION%-devstudio.git source/projects/gpd
cd source/projects/gpd
git checkout %GIT_BRANCH_NAME%
cd ../../../
rd /S /Q source\projects\gpd\.git
git clone %GIT_SOURCE_URL%/runawfe-%GIT_PROJECT_EDITION%-notifier-java.git source/projects/rtn
cd source/projects/rtn
git checkout %GIT_BRANCH_NAME%
cd ../../../
rd /S /Q source\projects\rtn\.git
git clone %GIT_SOURCE_URL%/runawfe-%GIT_PROJECT_EDITION%-installer.git source/projects/installer
cd source/projects/installer
git checkout %GIT_BRANCH_NAME%
cd ../../../
rd /S /Q source\projects\installer\.git

mkdir source\docs
mkdir source\docs\guides
copy readme source\docs\guides\

rem Update projects version
cd source\projects\installer\windows\
call mvn versions:set -DnewVersion=%WFE_VERSION%
cd ../../wfe/wfe-appserver
call mvn versions:set -DnewVersion=%WFE_VERSION%
cd ../wfe-webservice-client
call mvn versions:set -DnewVersion=%WFE_VERSION%
cd ../wfe-app
call mvn versions:set -DnewVersion=%WFE_VERSION%
rem cd ../wfe-remotebots
rem call mvn versions:set -DnewVersion=%WFE_VERSION%
cd ../../rtn
call mvn versions:set -DnewVersion=%WFE_VERSION%
cd ../gpd/plugins
call mvn tycho-versions:set-version -DnewVersion=%WFE_VERSION%

cd ..\..\..\..\
jar -cMf source.zip source
mkdir %RESULTS_DIR%\source
move source.zip %RESULTS_DIR%\source\source-%WFE_VERSION%.zip

cd source\projects\installer\windows\
rem Build distr
call mvn clean package -Dwfe.edition=%WFE_EDITION% -Dwfe.buildhash=%BUILD_HASH% -Djdk.dir="%~dp0jdk" -Djava.home.8=%JDK8_HOME% -Dstatistic.report.url=%STATISTIC_REPORT_URL% -Dstatistic.report.days.after.error=%STATISTIC_REPORT_DAYS_AFTER_ERROR%

xcopy /E /Q target\test-result %RESULTS_DIR%\test-result\
mkdir %RESULTS_DIR%\Execution\wildfly
copy target\artifacts\Installer64\wildfly\RunaWFE-Installer.exe %RESULTS_DIR%\Execution\wildfly\RunaWFE-%WFE_VERSION%-x64.exe

mkdir %RESULTS_DIR%\bin
mkdir %RESULTS_DIR%\bin\server
rem Create bin file for wildfly server
jar xf target\artifacts\wildfly\app-server\wfe-appserver-base-%WFE_VERSION%.zip 
jar xf target\artifacts\wildfly\app-server\wfe-appserver-diff-%WFE_VERSION%.zip 
xcopy /E /Q ..\simulation\* jboss\
move jboss wildfly
jar -cMf runawfe-%WFE_VERSION%.zip wildfly
rd /S /Q wildfly
move runawfe-%WFE_VERSION%.zip %RESULTS_DIR%\bin\server\runawfe-%WFE_VERSION%.zip

rem Create bin file for gpd
xcopy /E /Q target\artifacts\gpd\all %RESULTS_DIR%\bin\gpd\

rem Create bin file for rtn 
mkdir %RESULTS_DIR%\bin\rtn

xcopy /E /Q target\artifacts\rtn\64 rtn\
jar -cMf runawfe-rtn-%WFE_VERSION%-x64.zip rtn
rd /S /Q rtn
move runawfe-rtn-win64-%WFE_VERSION%.zip %RESULTS_DIR%\bin\rtn\runawfe-rtn-win64-%WFE_VERSION%.zip

