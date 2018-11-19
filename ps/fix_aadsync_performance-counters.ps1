#reference:
#https://goo.gl/4urPyU

#stop the services
Stop-Service AzureADConnectHealthSyncInsights
Stop-Service AzureADConnectHealthSyncMonitor
Stop-Service ADSync

#backup, delete and recreate the registry entry here

#after the empty registry entry has been created, remove all old performance counters
unlodctr.exe ADSync

#register the new counters
lodctr.exe “C:\Program Files\Microsoft Azure AD Sync\Bin\mmsperf.ini”

Start-Service AzureADConnectHealthSyncInsights
Start-Service AzureADConnectHealthSyncMonitor
Start-Service ADSync