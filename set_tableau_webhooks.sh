#!/bin/bash

echo Welcome to the MightyCanary webhook setup!
echo Please, type the Account ID that you received from MightyCanary
echo or navigate to https://app.mightycanary.com/accounts and check the URL of your account to receive an ID
read account_id
echo Please, type the Content URL of your Tableau Account
echo You can check the \"Explore\" page url and look for the CONTENT_URL in format https://server.online.tableau.com/#/site/CONTENT_URL/explore
read contentUrl
echo Please, type your Tableau Login
read login
echo Please, type your Tableau Password
stty_orig=$(stty -g) # saving state
stty -echo # disabling password
read password
stty $stty_orig
echo $password

LOGIN_RESPONSE=$(curl --location --request POST 'https://10ay.online.tableau.com/api/3.6/auth/signin' \
--header 'Content-Type: application/json' \
--header 'Accept: application/json' \
--data-raw '{
  "credentials": {
     "site": {
        "contentUrl": "'"${contentUrl}"'"
     },
     "name": "'"${login}"'",
     "password": "'"${password}"'"
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

# echo Please, paste your "site id" from the response above
# read site_id
# echo Please, paste your "token" from the response above
# read token

# LIST_RESPONSE=$(curl --location --request GET 'https://10ay.online.tableau.com/api/3.6/sites/'"${site_id}"'/webhooks' \
# --header 'X-Tableau-Auth: '"${token}"'' \
# --header 'Accept: application/json')
#
# echo "${LIST_RESPONSE}"

CREATE_RESPONSE=$(curl --location --request POST 'https://10ay.online.tableau.com/api/3.9/sites/'"${site_id}"'/webhooks' \
--header 'X-Tableau-Auth: '"${token}"'' \
--header 'Content-Type: application/json' \
--header 'Accept: application/json' \
--data-raw '{
   "webhook": {
      "webhook-destination": {
         "webhook-destination-http": {
            "method": "POST",
            "url": "https://app.mightycanary.com/tableau_webhooks/'"${account_id}"'/datasource_refresh_failed"
         }
      },
      "event": "WorkbookRefreshFailed",
      "name": "Mighty Canary Workbook Refresh Failed Webhook"
   }
}')
echo "${CREATE_RESPONSE}"

CREATE_RESPONSE=$(curl --location --request POST 'https://10ay.online.tableau.com/api/3.9/sites/'"${site_id}"'/webhooks' \
--header 'X-Tableau-Auth: '"${token}"'' \
--header 'Content-Type: application/json' \
--header 'Accept: application/json' \
--data-raw '{
   "webhook": {
      "webhook-destination": {
         "webhook-destination-http": {
            "method": "POST",
            "url": "https://app.mightycanary.com/tableau_webhooks/'"${account_id}"'/datasource_refresh_succeeded"
         }
      },
      "event": "WorkbookRefreshSucceeded",
      "name": "Mighty Canary Workbook Refresh Succeeded Webhook"
   }
}')
echo "${CREATE_RESPONSE}"

CREATE_RESPONSE=$(curl --location --request POST 'https://10ay.online.tableau.com/api/3.9/sites/'"${site_id}"'/webhooks' \
--header 'X-Tableau-Auth: '"${token}"'' \
--header 'Content-Type: application/json' \
--header 'Accept: application/json' \
--data-raw '{
   "webhook": {
      "webhook-destination": {
         "webhook-destination-http": {
            "method": "POST",
            "url": "https://app.mightycanary.com/tableau_webhooks/'"${account_id}"'/datasource_refresh_failed"
         }
      },
      "event": "DatasourceRefreshFailed",
      "name": "Mighty Canary Datasource Refresh Failed Webhook"
   }
}')
echo "${CREATE_RESPONSE}"

CREATE_RESPONSE=$(curl --location --request POST 'https://10ay.online.tableau.com/api/3.9/sites/'"${site_id}"'/webhooks' \
--header 'X-Tableau-Auth: '"${token}"'' \
--header 'Content-Type: application/json' \
--header 'Accept: application/json' \
--data-raw '{
   "webhook": {
      "webhook-destination": {
         "webhook-destination-http": {
            "method": "POST",
            "url": "https://app.mightycanary.com/tableau_webhooks/'"${account_id}"'/datasource_refresh_succeeded"
         }
      },
      "event": "DatasourceRefreshSucceeded",
      "name": "Mighty Canary Datasource Refresh Succeeded Webhook"
   }
}')
echo "${CREATE_RESPONSE}"
