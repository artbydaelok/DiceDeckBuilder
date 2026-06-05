@echo off
setlocal
title Oddside Level Planner

set "PLANNER=%~dp0tools\oddside-level-planner"
pushd "%PLANNER%" || (
  echo Could not find: %PLANNER%
  pause
  exit /b 1
)

where node >nul 2>&1
if errorlevel 1 (
  echo Node.js is not installed or not on PATH.
  echo Install from https://nodejs.org/ then run this again.
  pause
  exit /b 1
)

if not exist "node_modules\" (
  echo First run: installing dependencies...
  call npm install
  if errorlevel 1 (
    echo npm install failed.
    pause
    exit /b 1
  )
)

echo Refreshing icons and enemy / deck catalog...
call npm run icons
call npm run catalog
if errorlevel 1 (
  echo Catalog step failed; continuing anyway...
)

echo.
echo Starting planner at http://localhost:5173
echo.
echo IMPORTANT: Keep this window open while you use the planner.
echo            Closing it stops the server and the browser will refuse to connect.
echo            Press Ctrl+C here when you are done.
echo.
call npm run dev
set EXITCODE=%ERRORLEVEL%

popd
if not %EXITCODE%==0 (
  echo.
  echo Dev server exited with an error. See messages above.
  pause
)
endlocal
exit /b %EXITCODE%
