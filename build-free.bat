set WFE_VERSION=4.6.0
set WFE_EDITION=Free
set RESULTS_DIR=%~dp0results
set BUILD_DIR=%~dp0build
set GIT_SOURCE_URL=https://github.com/processtech
set GIT_BRANCH_NAME=master
set GIT_PROJECT_EDITION=free
set STATISTIC_REPORT_URL=https://usagereport.runawfe.org
set STATISTIC_REPORT_DAYS_AFTER_ERROR=11


echo Clean artifacts from previous builds
rd /S /Q build
rd /S /Q %RESULTS_DIR%

echo Create folders for artifacts from new build
mkdir build
mkdir %RESULTS_DIR%

echo Copy required zip files and folders (jboss and so on) into build directory
jar -cMf wildfly.zip wildfly || exit /b 1
move wildfly.zip build || exit /b 1

copy readme build


echo Export source code
cd /D build || exit /b 1
git clone %GIT_SOURCE_URL%/runawfe-%GIT_PROJECT_EDITION%-server.git source/projects/wfe
cd source/projects/wfe || exit /b 1
git checkout %GIT_BRANCH_NAME% || exit /b 1

git rev-parse HEAD > tmp-hash.txt
set /p BUILD_HASH=<tmp-hash.txt
del tmp-hash.txt

cd ../../../ || exit /b 1
git clone %GIT_SOURCE_URL%/runawfe-%GIT_PROJECT_EDITION%-devstudio.git source/projects/gpd || exit /b 1
cd source/projects/gpd || exit /b 1
git checkout %GIT_BRANCH_NAME% || exit /b 1
cd ../../../ || exit /b 1
rd /S /Q source\projects\gpd\.git
git clone %GIT_SOURCE_URL%/runawfe-%GIT_PROJECT_EDITION%-notifier-java.git source/projects/rtn || exit /b 1
cd source/projects/rtn || exit /b 1
git checkout %GIT_BRANCH_NAME% || exit /b 1
cd ../../../ || exit /b 1
rd /S /Q source\projects\rtn\.git
git clone %GIT_SOURCE_URL%/runawfe-%GIT_PROJECT_EDITION%-installer.git source/projects/installer || exit /b 1
cd source/projects/installer || exit /b 1
git checkout %GIT_BRANCH_NAME% || exit /b 1
cd ../../../ || exit /b 1
rd /S /Q source\projects\installer\.git

mkdir source\docs || exit /b 1
mkdir source\docs\guides || exit /b 1
copy readme source\docs\guides\

echo Update projects version
cd source\projects\installer\windows\ || exit /b 1
call mvn versions:set -DnewVersion=%WFE_VERSION% || exit /b 1
cd ../../wfe/wfe-appserver || exit /b 1
call mvn versions:set -DnewVersion=%WFE_VERSION% || exit /b 1
cd ../wfe-webservice-client || exit /b 1
call mvn versions:set -DnewVersion=%WFE_VERSION% || exit /b 1
cd ../wfe-app || exit /b 1
call mvn versions:set -DnewVersion=%WFE_VERSION% || exit /b 1
rem cd ../wfe-remotebots
rem call mvn versions:set -DnewVersion=%WFE_VERSION%
cd ../../rtn || exit /b 1
call mvn versions:set -DnewVersion=%WFE_VERSION% || exit /b 1
cd ../gpd/plugins || exit /b 1
call mvn tycho-versions:set-version -DnewVersion=%WFE_VERSION% || exit /b 1

cd ..\..\..\..\ || exit /b 1
jar -cMf source.zip source || exit /b 1
mkdir %RESULTS_DIR%\source || exit /b 1
move source.zip %RESULTS_DIR%\source\source-%WFE_VERSION%.zip || exit /b 1

cd source\projects\installer\windows\ || exit /b 1

echo Build distr
call mvn clean package -Dwfe.edition=%WFE_EDITION% -Dwfe.buildhash=%BUILD_HASH% -Djdk.dir="%~dp0jdk" -Dstatistic.report.url=%STATISTIC_REPORT_URL% -Dstatistic.report.days.after.error=%STATISTIC_REPORT_DAYS_AFTER_ERROR% || exit /b 1

echo Remove .git after build
cd /D %BUILD_DIR% || exit /b 1
rd /S /Q source\projects\wfe\.git  || exit /b 1

cd source\projects\installer\windows\ || exit /b 1


xcopy /E /Q target\test-result %RESULTS_DIR%\test-result\ || exit /b 1
mkdir %RESULTS_DIR%\Execution\wildfly || exit /b 1
copy target\artifacts\Installer64\wildfly\RunaWFE-Installer.exe %RESULTS_DIR%\Execution\wildfly\RunaWFE-%WFE_VERSION%.exe || exit /b 1

mkdir %RESULTS_DIR%\bin || exit /b 1
mkdir %RESULTS_DIR%\bin\server || exit /b 1
echo Create bin file for wildfly server
jar xf target\artifacts\wildfly\app-server\wfe-appserver-base-%WFE_VERSION%.zip || exit /b 1
jar xf target\artifacts\wildfly\app-server\wfe-appserver-diff-%WFE_VERSION%.zip || exit /b 1
xcopy /E /Q ..\simulation\* jboss\ || exit /b 1
move jboss wildfly || exit /b 1
jar -cMf runawfe-wildfly-%WFE_VERSION%.zip wildfly || exit /b 1
rd /S /Q wildfly || exit /b 1
move runawfe-wildfly-%WFE_VERSION%.zip %RESULTS_DIR%\bin\server\runawfe-wildfly-%WFE_VERSION%.zip || exit /b 1

echo Create bin file for gpd
xcopy /E /Q target\artifacts\gpd\all %RESULTS_DIR%\bin\gpd\ || exit /b 1

echo Create bin file for rtn 
mkdir %RESULTS_DIR%\bin\rtn || exit /b 1

xcopy /E /Q target\artifacts\rtn\64 rtn\ || exit /b 1
jar -cMf runawfe-rtn-win64-%WFE_VERSION%.zip rtn\ || exit /b 1
rd /S /Q rtn
move runawfe-rtn-win64-%WFE_VERSION%.zip %RESULTS_DIR%\bin\rtn\runawfe-rtn-win64-%WFE_VERSION%.zip || exit /b 1


xcopy /E /Q target\artifacts\rtn\linux64 rtn\ || exit /b 1
jar -cMf runawfe-rtn-linux64-%WFE_VERSION%.zip rtn\ || exit /b 1
rd /S /Q rtn || exit /b 1
move runawfe-rtn-linux64-%WFE_VERSION%.zip %RESULTS_DIR%\bin\rtn\runawfe-rtn-linux64-%WFE_VERSION%.zip || exit /b 1

echo Autobuild finished.
