#!/bin/bash
clear

function Help()
{
   # Display Help
   echo "This script handles Tableau webhook registration with Mighty Canary."
   echo
   echo "Syntax: $0 [-h|d] [-a <acnt_id>] [-u <url>] [-s <site name>] [-n <PAT name>] [-t <PAT token>]"
   echo "options:"
   echo "a     Mighty Canary account id. (go to https://app.mightycanary.com/accounts"
   echo "        then copy the last number on resulting url)"
   echo "u     Tableau server base url (e.g. https://10ay.online.tableau.com)"
   echo "        go to the \"Explore\" page in Tableau and look at the base url"
   echo "s     Tableau site name (optional if you have your own Tableau install)"
   echo "        again, \"Explore\" url: SERVER_URL/#/site/SITE_NAME/explore"
   echo "n     Tableau user name"
   echo
   echo "h     Print this Help."
   echo "x     Debug mode. Prints all shell output to screen."
   echo "D     Delete all webhooks for this account."
   echo
   echo "If you do not pass any options, the script will prompt for them."
   echo
}

while getopts ":hdlDa:u:s:n:" option; do
  case $option in
    h) # display Help
      Help
      exit;;
    x) # debug mode
      set -x;;
    l) # list all webhooks
      list_webhooks="true";;
    a) # account id
      account_id=$OPTARG;;
    u) # tableau server base url
      server=$OPTARG;;
    s) # tableau server optional site name
      site=$OPTARG;;
    n) # tableau user name
      login=$OPTARG;;
    D) # delete all webhooks
      delete_all_webhooks="true";;
    \?) # Invalid option
      echo "Error: Invalid option"
      exit;;
  esac
done

function print_output()
{
  which jq >/dev/null 2>&1
  if (( $# == 0 )) ; then
    jq . < /dev/stdin
  else
    cat -
  fi
}

function downcase()
{
  echo "$(tr '[:upper:]' '[:lower:]' <<< ${1})"
}

echo "Welcome to the MightyCanary webhook setup!"
echo "This example uses your Tableau Username and Password for Access."

if [ -z "$account_id" ]; then
  echo "Please, type the Account ID that you received from MightyCanary"
  echo "or navigate to https://app.mightycanary.com/accounts and check"
  echo "the URL of your account to receive an ID - the last number on the URL."
  read account_id
fi

if [ -z "$server" ]; then
   echo "In Tableau, go to the \"Explore\" page url and look at the base url"
   echo "Please, type the base server url of your Tableau Server"
   echo "(e.g. https://10ay.online.tableau.com)"
   read server
fi

if [ -z "$site" ]; then
   echo "Please, type the SITE_NAME for your Tableau Account also found in"
   echo "the \"Explore\" page url: SERVER_URL/#/site/SITE_NAME/explore"
   echo "If you are running your own Tableau Server, you can leave this blank"
   read site
fi

if [ -z "$login" ]; then
  echo "Please, type your Tableau User name"
  read login
fi

echo "Please, type your Tableau Password"
stty_orig=$(stty -g) # saving state
stty -echo # disabling password
read password
stty $stty_orig

LOGIN_RESPONSE=$(curl --location --request POST "$server/api/3.9/auth/signin" \
--header 'Content-Type: application/json' \
--header 'Accept: application/json' \
--data-raw '{
  "credentials": {
     "site": {
        "contentUrl": "'"$site"'"
     },
     "name": "'"$login"'",
     "password": "'"$password"'"
  }
}')

echo "${LOGIN_RESPONSE}"

jsonValue() {
  KEY=$1
  num=$2
  awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'$KEY'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p
}

site_id=$(echo "${LOGIN_RESPONSE}" | jsonValue id 1)
echo "Your site id is: "
echo "${site_id}"
token=$(echo "${LOGIN_RESPONSE}" | jsonValue token)
echo "Your token is: "
echo "${token}"

wh_url="$server/api/3.9/sites/$site_id/webhooks" # URL for webhooks

# if list_webhooks is set, list all webhooks
if [ -n "$list_webhooks" ]; then
  echo "Listing all webhooks for site: $site_id"
  echo $wh_url -X GET -H '"X-Tableau-Auth:'${token}'" -H "Accept: application/json" | jq .'
  curl "$wh_url" -X GET -H "X-Tableau-Auth:${token}" -H "Accept: application/json" | print_output
  exit
fi

# if delete_all_webhooks is set, delete all webhooks
if [ -n "$delete_all_webhooks" ]; then
  echo "Deleting all webhooks for site: $site_id ... ARE YOU SURE?"
  read -p "Are you sure? (y/n) " -n 1 -r

   if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo "Deleting all webhooks for site: $site_id"
      curl "$wh_url" -X GET -H "X-Tableau-Auth:${token}" -H "Accept: application/json" | \
      jq '.webhooks.webhook | [map(.) | .[] | .id]' | while read -r wh_id; do
        wid=$(echo $wh_id | sed 's/[",]//g')
        if [[ ${#wid} -gt 20 ]]; then
          echo "Deleting webhook: $wid"
          curl "$wh_url/$wid" -X DELETE -H "X-Tableau-Auth:${token}" -H "Accept: application/json"
        fi
      done
   fi
  exit
fi

for tabobj in Workbook Datasource; do
  for action in Started Succeeded Failed; do
    act=$(downcase ${action})
    echo "Registering webhook for ${tabobj} ${action}..."
    mc_url="https://${MCAPP:-app}.mightycanary.com/tableau_webhooks/$account_id/datasource_refresh_$act"
    curl --location --request POST "$wh_url" --header "X-Tableau-Auth:$token" \
    --header 'Content-Type: application/json' --header 'Accept: application/json' \
    --data-raw '{
      "webhook": {
        "webhook-destination": {
          "webhook-destination-http": {
            "method": "POST",
            "url": "'"${mc_url}"'"
          }
        },
        "event": "'"$tabobj"'Refresh'"$action"'",
        "name": "Mighty Canary '"$tabobj"' Refresh '"$action"' Webhook"
      }
    }' | print_output
  done
done
echo "Webhooks registered!"
