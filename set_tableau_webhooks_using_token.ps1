# This is a powershell script that will help you setup
# webhooks for Mighty Canary
Write-Output ""
Write-Output "########################################"
Write-Output "Welcome to the MightyCanary webhook setup!"
Write-Output "This example uses your Tableau Personal Access Token."
Write-Output ""
Write-Output "Please, type the Account ID that you received from MightyCanary"
Write-Output "or navigate to https://app.mightycanary.com/accounts and check"
$account_id = Read-Host "the end of the URL of your account to find an ID"
Write-Output $account_id
Write-Output ""
Write-Output "You can check your Tableau *Explore* page url "
Write-Output "and look for the SERVER and SITE"
Write-Output "in format SERVER/#/site/SITE/explore"
Write-Output ""
Write-Output "Please, type the SERVER name of your Tableau Server"
$server = Read-Host "(e.g. https://10ay.online.tableau.com)"
$api_url = "$server/api/3.9"
Write-Output $api_url
Write-Output ""
Write-Output "Please, type the SITE for your Tableau Account"
$site = Read-Host "If you are running your own Tableau Server, you can leave this blank"
Write-Output ""
Write-Output "Now we need to create new API Token for MightyCanary to access your"
Write-Output "Tableau information. Navigate to:"
Write-Output "Tableau -> Users -> Select User -> Settings -> Personal Access Tokens"
Write-Output "Please, create a new token and save this information for the next steps."
Write-Output ""
$access_token_name = Read-Host "Please, type your Tableau Access Token Name"
Write-Output ""
$access_token = Read-Host "Please, type your Tableau Access Token"
Write-Output ""
# handle login to Tableau Server
$creds = @{
   credentials= @{
      site= @{
         contentUrl=$site
      }
      personalAccessTokenName=$access_token_name
      personalAccessTokenSecret=$access_token
   }
}
$json = $creds | ConvertTo-Json -Depth 5
# Write-Output $json
$response = Invoke-RestMethod -Uri "$api_url/auth/signin" -Method Post -Body $json -ContentType 'application/json'
$token = $response.tsResponse.credentials.token
# Write-Output "auth token: $token"
$site_id = $response.tsResponse.credentials.site.id
$myUserID = $response.tsResponse.credentials.user.id
Write-Output "site id: $site_id, user id: $myUserID, token: $token"
Write-Output "########################################"
# set up header fields with auth token
$global:headers = New-Object “System.Collections.Generic.Dictionary[[String],[String]]”
# add X-Tableau-Auth header with our auth token
$headers.Add(“X-Tableau-Auth”, $token)
$headers.Add("Accept", "application/json")
$wh_url = "$api_url/sites/$site_id/webhooks"
# Write-Output "Webhook URL: $wh_url"
$mcwh_url = "https://app.mightycanary.com/tableau_webhooks/$account_id"
# Write-Output "Webhook URL: $mcwh_url"
# add the webhooks by iterating over the webhooks definition dictionary
$webhook_registrations = @{
   WorkbookRefreshSucceeded=@{
      url="$mcwh_url/datasource_refresh_succeeded"
      name="Mighty Canary Workbook Refresh Succeeded Webhook"
   }
   WorkbookRefreshStarted=@{
      url="$mcwh_url/datasource_refresh_started"
      name="Mighty Canary Workbook Refresh Started Webhook"
   }
   WorkbookRefreshFailed=@{
      url="$mcwh_url/datasource_refresh_failed"
      name="Mighty Canary Workbook Refresh Failed Webhook"
   }
   DatasourceRefreshSucceeded=@{
      url="$mcwh_url/datasource_refresh_succeeded"
      name="Mighty Canary Datasource Refresh Succeeded Webhook"
   }
   DatasourceRefreshStarted=@{
      url="$mcwh_url/datasource_refresh_started"
      name="Mighty Canary Datasource Refresh Started Webhook"
   }
   DatasourceRefreshFailed=@{
      url="$mcwh_url/datasource_refresh_failed"
      name="Mighty Canary Datasource Refresh Failed Webhook"
   }
}

foreach ($key in $webhook_registrations.Keys) {
   $webhooks = @{
      webhook= @{
         "webhook-destination"= @{
            "webhook-destination-http"= @{
               method= "POST"
               url= $webhook_registrations.$key.url
            }
         }
         event= $key
         name= $webhook_registrations.$key.name
      }
   }
   $json = $webhooks | ConvertTo-Json -Depth 5
   Write-Output $json
   Invoke-RestMethod -Uri $wh_url -Method Post -Headers $headers -Body $json -ContentType 'application/json'
   Write-Output "Registered $($webhook_registrations.$key.name)"
}
Write-Output "############## Finished ################"