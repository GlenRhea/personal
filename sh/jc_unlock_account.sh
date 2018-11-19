#!/bin/bash

echo "Please enter the user ID, followed by [ENTER]:"

read userid

curl -X 'PUT' -H 'Content-Type: application/json' -H 'Accept: application/json' -H "x-api-key:APIKEYHERE" -d '{ "account_locked" : "false" }' "https://console.jumpcloud.com/api/systemusers/$userid"