@echo off
REM generate SSL key CSR
REM this script MUST be run with CMD

rem get the domain name
set /P "domainname=Please enter the FQDN: "

rem CSR instructions: https://goo.gl/rbcFhq
echo Generating the CSR...
C:\OpenSSL\bin\openssl req -new -newkey rsa:2048 -nodes -keyout %domainname%.key -out %domainname%.csr
echo.
echo The CSR has been generated:
type %domainname%.csr
rem wait for the cert
echo.
echo Now upload the CSR to godaddy and wait for the cert to be generated.
echo Once it has been generated (you will receive an email), copy it to the same folder where openssl is located
echo.
pause


rem now create the type of cert we need for azure
rem  pfx instructions: https://goo.gl/jNVFQm

rem rnd file fix: https://goo.gl/q96HsG
rem required to write rnd file
set RANDFILE=C:\OpenSSL\.rnd
echo.
echo Creating the pfx file for Azure
set /P "crtfile=Please enter the CRT filename: "
C:\OpenSSL\bin\openssl pkcs12 -export -out %domainname%.pfx -inkey %domainname%.key -in %crtfile%
echo pfx file generated!

rem wont upload without a password, have to start all over again :(