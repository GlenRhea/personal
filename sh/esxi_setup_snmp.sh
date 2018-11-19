#!/bin/bash
esxcli system snmp get
esxcli system snmp set --communities TYLERMADECOMM
esxcli system snmp set --enable true
esxcli network firewall ruleset set --ruleset-id snmp --allowed-all true

esxcli network firewall ruleset set --ruleset-id snmp --enabled true
/etc/init.d/snmpd restart
