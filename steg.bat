@echo off
setlocal EnableDelayedExpansion

:: Prompt the user to choose between hiding or extracting text
echo Do you want to hide or extract text?
set /p mode=

:: If the user chooses to hide text, run the "hide" code block
if "%mode%"=="hide" (
    :: Enter the name of the image file and the text file to hide
    echo Enter the name of the image file:
    set /p image=
    echo Enter the name of the text file to hide:
    set /p text=

    :: Read the text file and encode it in base64
    set /p secret=<%text%
    set encoded=
    for /f "tokens=3 delims= " %%a in ('certutil -encode "!text!" temp.b64 ^| findstr /i /v /c:"- "') do set encoded=!encoded!%%a
    set encoded=!encoded:~0,-2!

    :: Hide the encoded text in the image
    echo Enter a password to secure the image:
    set /p password=
    echo Hiding text inside the image...
    set "hex="
    for /f "delims=" %%a in ('certutil -tca.info') do set "hex=!hex!%%a"
    set "hex=!hex:~-40!"
    echo !password!>temp.txt
    set "cmd=certutil -f -encode -t"""!hex!""" temp.txt temp.enc&for /f "skip=1 delims=" %%a in ('certutil -f -split -urlcache -temp -decode ""temp.enc"" *') do (set secret=!secret!%%a)&del temp.enc temp.txt
    echo !secret!>secret.b64
    copy /b !image!+secret.b64 !image!.jpg
    del secret.b64

    echo Text file hidden inside the image.
)

:: If the user chooses to extract text, run the "extract" code block
if "%mode%"=="extract" (
    :: Enter the name of the output file and extract the hidden text
    echo Enter the name of the output file:
    set /p output=
    echo Enter the password used to secure the image:
    set /p password=
    echo Extracting text from the image...
    copy /b !output!+secret.b64 secret2.b64
    set /p secret2=<secret2.b64
    set decoded=
    for /f "tokens=3 delims= " %%a in ('certutil -decode secret2.b64 temp.txt ^| findstr /i /v /c:"- "') do set decoded=!decoded!%%a
    set decoded=!decoded:~0,-2!
    echo !decoded!>%output%

    echo Text extracted from the image.
)

:: Clean up temporary files
del temp.b64 secret.b64 secret2.b64 temp.txt

endlocal
