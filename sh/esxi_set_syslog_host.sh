esxcli system syslog config set --loghost='192.168.1.1'

esxcli system syslog reload

esxcli system syslog config get

#vmhost01
esxcli system syslog config set --loghost='192.168.1.1'
esxcli system syslog config set --logdir=/vmfs/volumes/volumeidhere/logs/
esxcli network firewall ruleset set -r syslog -e true
esxcli system syslog reload
esxcli system syslog mark --message "Syslog Test Message"

#vmhost02
esxcli system syslog config set --loghost='192.168.1.1'
esxcli system syslog config set --logdir=/vmfs/volumes/volumeidhere/logs/
esxcli network firewall ruleset set -r syslog -e true
esxcli system syslog reload
esxcli system syslog mark --message "Syslog Test Message"