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

    :: Read the text file and encrypt it using AES
    echo Enter a password to encrypt the text:
    set /p password=
    powershell -Command "$Key=(1..32)|%{[char][byte](Get-Random(0,256))};$IV=(1..16)|%{[char][byte](Get-Random(0,256))};$Key=[Convert]::ToBase64String($Key);$IV=[Convert]::ToBase64String($IV);$Key | Out-File temp.key;$IV | Out-File temp.iv;$secret = Get-Content !text!; $secret | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString -Key $Key -IV $IV | Out-File secret.enc -Encoding ASCII"
    set /p key=<temp.key
    set /p iv=<temp.iv
    set /p secret=<secret.enc

    :: Hide the encrypted text in the image
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
    powershell -Command "$Key=[Convert]::FromBase64String((Get-Content temp.key));$IV=[Convert]::FromBase64String((Get-Content temp.iv));$secret=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR((ConvertTo-SecureString (Get-Content secret2.b64) -Key $Key -IV $IV)));Remove-Item temp.key,temp.iv,secret2.b64;echo $secret" > temp.txt
    set /p decoded=<temp.txt
    echo !decoded!>%output%

    echo Text extracted from the image.
)

