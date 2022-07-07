#!/bin/bash
clear

echo Welcome to the MightyCanary webhook setup!
echo This example uses your Tableau Personal Access Token.

echo Please, type the Account ID that you received from MightyCanary
echo or navigate to https://app.mightycanary.com/accounts and check
echo the URL of your account to receive an ID
read account_id

echo You can check the \"Explore\" page url 
echo and look for the CONTENT_URL and DNS.HOST
echo in format https://DNS.HOST/#/site/CONTENT_URL/explore

echo Please, type the DNS.HOST name of your Tableau Server
echo "(e.g. https://10ay.online.tableau.com)"
read server

echo Please, type the Content URL for the site of your Tableau Account
echo If you are running your own Tableau Server, you can leave this blank
read contentUrl

echo Now we need to create new API Token for MightyCanary to access your
echo Tableau information. Navigate to:
echo Tableau -> Users -> Select User -> Settings -> Personal Access Tokens
echo Please, create a new token and save this information for the next steps.

echo Please, type your Tableau Access Token Name
read access_token_name

echo Please, type your Tableau Access Token
read access_token

LOGIN_RESPONSE=$(curl --location --request POST 'https://$server/api/3.6/auth/signin' \
--header 'Content-Type: application/json' \
--header 'Accept: application/json' \
--data-raw '{
  "credentials": {
     "site": {
        "contentUrl": "'"${contentUrl}"'"
     },
     "personalAccessTokenName": "'"${access_token_name}"'",
     "personalAccessTokenSecret": "'"${access_token}"'"
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

CREATE_RESPONSE=$(curl --location --request POST 'https://$server/api/3.9/sites/'"${site_id}"'/webhooks' \
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

CREATE_RESPONSE=$(curl --location --request POST 'https://$server/api/3.9/sites/'"${site_id}"'/webhooks' \
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

CREATE_RESPONSE=$(curl --location --request POST 'https://'"${server}"'/api/3.9/sites/'"${site_id}"'/webhooks' \
--header 'X-Tableau-Auth: '"${token}"'' \
--header 'Content-Type: application/json' \
--header 'Accept: application/json' \
--data-raw '{
   "webhook": {
      "webhook-destination": {
         "webhook-destination-http": {
            "method": "POST",
            "url": "https://app.mightycanary.com/tableau_webhooks/'"${account_id}"'/datasource_refresh_started"
         }
      },
      "event": "WorkbookRefreshStarted",
      "name": "Mighty Canary Workbook Refresh Started Webhook"
   }
}')
echo "${CREATE_RESPONSE}"

CREATE_RESPONSE=$(curl --location --request POST 'https://$server/api/3.9/sites/'"${site_id}"'/webhooks' \
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

CREATE_RESPONSE=$(curl --location --request POST 'https://$server/api/3.9/sites/'"${site_id}"'/webhooks' \
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

CREATE_RESPONSE=$(curl --location --request POST 'https://'"${server}"'/api/3.9/sites/'"${site_id}"'/webhooks' \
--header 'X-Tableau-Auth: '"${token}"'' \
--header 'Content-Type: application/json' \
--header 'Accept: application/json' \
--data-raw '{
   "webhook": {
      "webhook-destination": {
         "webhook-destination-http": {
            "method": "POST",
            "url": "https://app.mightycanary.com/tableau_webhooks/'"${account_id}"'/datasource_refresh_started"
         }
      },
      "event": "DatasourceRefreshStarted",
      "name": "Mighty Canary Datasource Refresh Started Webhook"
   }
}')
echo "${CREATE_RESPONSE}"