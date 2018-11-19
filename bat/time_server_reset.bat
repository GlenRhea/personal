rem for pdc emulator
w32tm /config /manualpeerlist:"0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org" /syncfromflags:manual /reliable:yes /update
net stop w32time && net start w32time

rem for other dcs
w32tm /config /syncfromflags:domhier /update
net stop w32time && net start w32time

rem 0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org