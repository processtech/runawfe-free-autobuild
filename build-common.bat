@echo Starting autobuild at %TIME%
@for /f "usebackq" %%i in (`powershell -NoProfile -Command "(Get-Date).Ticks"`) do @set "START_TICKS=%%i"
@for /f "usebackq" %%i in (`powershell -NoProfile -Command "(Get-Date).Ticks"`) do @set "STAGE1_TICKS=%%i"
@powershell -NoProfile -Command "Write-Host '=== Stage 1/6: Prepare ===' -ForegroundColor Blue"

@echo Check for orphaned Wildfly/JBoss processes from previous builds
@powershell -NoProfile -Command ^
  "$buildDir = '%BUILD_DIR%';" ^
  "$procs = Get-WmiObject Win32_Process -Filter \"Name='java.exe'\" | Where-Object { $_.CommandLine -like '*jboss-modules.jar*' -and $_.CommandLine -like '*' + $buildDir + '*' };" ^
  "if ($procs) {" ^
  "  Write-Host 'WARNING: Found orphaned Wildfly/JBoss process from previous build!' -ForegroundColor Yellow;" ^
  "  foreach ($p in $procs) {" ^
  "    Write-Host ('  PID: {0}' -f $p.ProcessId) -ForegroundColor Yellow;" ^
  "    Write-Host ('  Cmd: {0}' -f $p.CommandLine) -ForegroundColor Gray;" ^
  "  };" ^
  "  Write-Host 'Please terminate this process manually (e.g. taskkill /F /PID <PID>) and restart the build.' -ForegroundColor Red;" ^
  "  exit 1" ^
  "}" || exit /b 1

@echo Clean artifacts from previous builds
rd /S /Q build
if exist "build" exit /b 1
rd /S /Q %RESULTS_DIR%
if exist "%RESULTS_DIR%" exit /b 1

echo Create folders for artifacts from new build
mkdir build
mkdir %RESULTS_DIR%

echo Copy required zip files and folders (jboss and so on) into build directory
jar -cMf wildfly.zip wildfly || exit /b 1
move wildfly.zip build || exit /b 1

copy readme build


@for /f "usebackq" %%i in (`powershell -NoProfile -Command "(Get-Date).Ticks"`) do @set "STAGE2_TICKS=%%i"
@powershell -NoProfile -Command "Write-Host '=== Stage 2/6: Clone ===' -ForegroundColor Blue"
echo Export source code
cd /D build || exit /b 1

:: 1. Сервер
git clone -b %GIT_BRANCH_NAME% %GIT_SOURCE_URL%/runawfe-%GIT_PROJECT_EDITION%-server.git source/projects/wfe || exit /b 1
cd source/projects/wfe || exit /b 1

git rev-parse HEAD > tmp-hash.txt
set /p BUILD_HASH=<tmp-hash.txt
del tmp-hash.txt

cd ../../../ || exit /b 1

:: Чтобы не было блокировки .git/config.lock
timeout /t 2 /nobreak >nul

:: 2. GPD
git clone --depth 1 -b %GIT_BRANCH_NAME% %GIT_SOURCE_URL%/runawfe-%GIT_PROJECT_EDITION%-devstudio.git source/projects/gpd || exit /b 1
cd source/projects/gpd || exit /b 1
cd ../../../ || exit /b 1
rd /S /Q source\projects\gpd\.git
if exist "source\projects\gpd\.git" exit /b 1

timeout /t 2 /nobreak >nul

:: 3. RTN
git clone --depth 1 -b %GIT_BRANCH_NAME% %GIT_SOURCE_URL%/runawfe-%GIT_PROJECT_EDITION%-notifier-java.git source/projects/rtn || exit /b 1
cd source/projects/rtn || exit /b 1
cd ../../../ || exit /b 1
rd /S /Q source\projects\rtn\.git
if exist "source\projects\rtn\.git" exit /b 1

timeout /t 2 /nobreak >nul

:: 4. Installer
git clone --depth 1 -b %GIT_BRANCH_NAME% %GIT_SOURCE_URL%/runawfe-%GIT_PROJECT_EDITION%-installer.git source/projects/installer || exit /b 1
cd source/projects/installer || exit /b 1
cd ../../../ || exit /b 1
rd /S /Q source\projects\installer\.git
if exist "source\projects\installer\.git" exit /b 1

mkdir source\docs || exit /b 1
mkdir source\docs\guides || exit /b 1
copy readme source\docs\guides\

@for /f "usebackq" %%i in (`powershell -NoProfile -Command "(Get-Date).Ticks"`) do @set "STAGE3_TICKS=%%i"
@powershell -NoProfile -Command "Write-Host '=== Stage 3/6: Update version ===' -ForegroundColor Blue"
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
call mvn tycho-versions:set-version -DnewVersion=%WFE_VERSION%.qualifier || exit /b 1

@for /f "usebackq" %%i in (`powershell -NoProfile -Command "(Get-Date).Ticks"`) do @set "STAGE4_TICKS=%%i"
@powershell -NoProfile -Command "Write-Host '=== Stage 4/6: Package src ===' -ForegroundColor Blue"
cd ..\..\..\..\ || exit /b 1
jar -cMf source.zip source || exit /b 1
mkdir %RESULTS_DIR%\source || exit /b 1
move source.zip %RESULTS_DIR%\source\source-%WFE_VERSION%.zip || exit /b 1

@for /f "usebackq" %%i in (`powershell -NoProfile -Command "(Get-Date).Ticks"`) do @set "STAGE5_TICKS=%%i"
@powershell -NoProfile -Command "Write-Host '=== Stage 5/6: Build distr ===' -ForegroundColor Blue"
cd source\projects\installer\windows\ || exit /b 1

call mvn clean package -Dwfe.edition=%WFE_EDITION% -Dwfe.buildhash=%BUILD_HASH% -Djdk.dir="%~dp0jdk" -Dstatistic.report.url=%STATISTIC_REPORT_URL% -Dstatistic.report.days.after.error=%STATISTIC_REPORT_DAYS_AFTER_ERROR% || exit /b 1

@for /f "usebackq" %%i in (`powershell -NoProfile -Command "(Get-Date).Ticks"`) do @set "STAGE6_TICKS=%%i"
@powershell -NoProfile -Command "Write-Host '=== Stage 6/6: Post-process ===' -ForegroundColor Blue"
echo Remove .git after build
cd /D %BUILD_DIR% || exit /b 1
rd /S /Q source\projects\wfe\.git
if exist "source\projects\wfe\.git" exit /b 1

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

timeout /t 5 /nobreak >nul

ren jboss wildfly || exit /b 1
jar -cMf runawfe-wildfly-%WFE_VERSION%.zip wildfly || exit /b 1
rd /S /Q wildfly
if exist "wildfly" exit /b 1
move runawfe-wildfly-%WFE_VERSION%.zip %RESULTS_DIR%\bin\server\runawfe-wildfly-%WFE_VERSION%.zip || exit /b 1

echo Create bin file for gpd
xcopy /E /Q target\artifacts\gpd\all %RESULTS_DIR%\bin\gpd\ || exit /b 1

echo Create bin file for rtn 
mkdir %RESULTS_DIR%\bin\rtn || exit /b 1

xcopy /E /Q target\artifacts\rtn\64 rtn\ || exit /b 1
jar -cMf runawfe-rtn-win64-%WFE_VERSION%.zip rtn\ || exit /b 1
rd /S /Q rtn
if exist "rtn" exit /b 1
move runawfe-rtn-win64-%WFE_VERSION%.zip %RESULTS_DIR%\bin\rtn\runawfe-rtn-win64-%WFE_VERSION%.zip || exit /b 1


xcopy /E /Q target\artifacts\rtn\linux64 rtn\  || exit /b 1
jar -cMf runawfe-rtn-linux64-%WFE_VERSION%.zip rtn  || exit /b 1
rd /S /Q rtn
if exist "rtn" exit /b 1
move runawfe-rtn-linux64-%WFE_VERSION%.zip %RESULTS_DIR%\bin\rtn\runawfe-rtn-linux64-%WFE_VERSION%.zip  || exit /b 1

@echo ========================================
@echo            BUILD TIME SUMMARY
@echo ========================================
@powershell -NoProfile -Command ^
  "$s1 = [TimeSpan]::FromTicks(%STAGE2_TICKS% - %STAGE1_TICKS%);" ^
  "$s2 = [TimeSpan]::FromTicks(%STAGE3_TICKS% - %STAGE2_TICKS%);" ^
  "$s3 = [TimeSpan]::FromTicks(%STAGE4_TICKS% - %STAGE3_TICKS%);" ^
  "$s4 = [TimeSpan]::FromTicks(%STAGE5_TICKS% - %STAGE4_TICKS%);" ^
  "$s5 = [TimeSpan]::FromTicks(%STAGE6_TICKS% - %STAGE5_TICKS%);" ^
  "$now = (Get-Date).Ticks;" ^
  "$s6 = [TimeSpan]::FromTicks($now - %STAGE6_TICKS%);" ^
  "$total = [TimeSpan]::FromTicks($now - %START_TICKS%);" ^
  "Write-Host '';" ^
  "Write-Host ('1/6 Prepare:       {0}h {1}m {2}s' -f $s1.Hours, $s1.Minutes, $s1.Seconds) -ForegroundColor Gray;" ^
  "Write-Host ('2/6 Clone:         {0}h {1}m {2}s' -f $s2.Hours, $s2.Minutes, $s2.Seconds) -ForegroundColor Gray;" ^
  "Write-Host ('3/6 Update version:{0}h {1}m {2}s' -f $s3.Hours, $s3.Minutes, $s3.Seconds) -ForegroundColor Gray;" ^
  "Write-Host ('4/6 Package src:   {0}h {1}m {2}s' -f $s4.Hours, $s4.Minutes, $s4.Seconds) -ForegroundColor Gray;" ^
  "Write-Host ('5/6 Build distr:   {0}h {1}m {2}s' -f $s5.Hours, $s5.Minutes, $s5.Seconds) -ForegroundColor Gray;" ^
  "Write-Host ('6/6 Post-process:  {0}h {1}m {2}s' -f $s6.Hours, $s6.Minutes, $s6.Seconds) -ForegroundColor Gray;" ^
  "Write-Host '';" ^
  "Write-Host ('Total build time:  {0}h {1}m {2}s' -f $total.Hours, $total.Minutes, $total.Seconds) -ForegroundColor Green"

