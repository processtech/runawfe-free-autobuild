set WFE_VERSION=4.6.2
set WFE_EDITION=Free
set RESULTS_DIR=%~dp0results
set BUILD_DIR=%~dp0build
set GIT_SOURCE_URL=https://github.com/processtech
set GIT_BRANCH_NAME=master
set GIT_PROJECT_EDITION=free
set STATISTIC_REPORT_URL=https://usagereport.runawfe.org
set STATISTIC_REPORT_DAYS_AFTER_ERROR=11

pushd .
call build-common.bat
popd