@echo off
if exist "assets\images\App icon.png" (
    echo Renaming "App icon.png" to "logo.png"...
    ren "assets\images\App icon.png" logo.png
)

echo Generating icons using logo.png...
echo Ensure "assets/images/logo.png" exists before running this.
call dart run flutter_launcher_icons
echo Setup Complete!
pause
