function Print-Header ($header) {
  Write-Host "`n${header}`n" -ForegroundColor Cyan
}

if (-not (Test-Path Env:AZP_URL)) {
  Write-Error "error: missing AZP_URL environment variable"
  exit 1
}

if (-not (Test-Path Env:AZP_TOKEN_FILE)) {
  if (-not (Test-Path Env:AZP_TOKEN)) {
    Write-Host "info: not found AZP_TOKEN environment variable"
    Write-Host "info: try AZP_CLIENTID, AZP_CLIENTSECRET and AZP_TENANTID"
    if ((-not (Test-Path Env:AZP_CLIENTID)) -or (-not (Test-Path Env:AZP_CLIENTSECRET)) -or (-not (Test-Path Env:AZP_TENANTID))) {
        Write-Error "error: missing AZP_CLIENTID or AZP_CLIENTSECRET or AZP_TENANTID"
        exit 1
    }

    try {
      Write-Host "Using service principal credentials to get token"
      
      az login --allow-no-subscriptions --service-principal --username "$env:AZP_CLIENTID" --password "$env:AZP_CLIENTSECRET" --tenant "$env:AZP_TENANTID" --verbose
      
      # adapted from https://learn.microsoft.com/en-us/azure/databricks/dev-tools/user-aad-token
      $env:AZP_TOKEN = az account get-access-token --query accessToken --verbose --output tsv
      
      Write-Host "Token retrieved"

    } catch {
      Write-Error "error: An error occurred: $($_.Exception.Message)"
      exit 1
    }
  }

$Env:AZP_TOKEN_FILE = "\azp\.token"
  $Env:AZP_TOKEN | Out-File -FilePath $Env:AZP_TOKEN_FILE
}

Remove-Item Env:AZP_TOKEN

if ((Test-Path Env:AZP_WORK) -and -not (Test-Path $Env:AZP_WORK)) {
  New-Item $Env:AZP_WORK -ItemType directory | Out-Null
}

New-Item "\azp\agent" -ItemType directory | Out-Null

# Let the agent ignore the token env variables
$Env:VSO_AGENT_IGNORE = "AZP_TOKEN,AZP_TOKEN_FILE"

Set-Location agent

Print-Header "1. Determining matching Azure Pipelines agent..."

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$(Get-Content ${Env:AZP_TOKEN_FILE})"))
$package = Invoke-RestMethod -Headers @{Authorization=("Basic $base64AuthInfo")} "$(${Env:AZP_URL})/_apis/distributedtask/packages/agent?platform=win-x64&`$top=1"
$packageUrl = $package[0].Value.downloadUrl

Write-Host $packageUrl

Print-Header "2. Downloading and installing Azure Pipelines agent..."

$wc = New-Object System.Net.WebClient
$wc.DownloadFile($packageUrl, "$(Get-Location)\agent.zip")

Expand-Archive -Path "agent.zip" -DestinationPath "\azp\agent"

try {
  Print-Header "3. Configuring Azure Pipelines agent..."

.\config.cmd --unattended --agent "$(if (Test-Path Env:AZP_AGENT_NAME) { ${Env:AZP_AGENT_NAME} } else { hostname })" --url "$(${Env:AZP_URL})" --auth SP --clientid "$(${Env:AZP_CLIENTID})" --clientsecret "$(${Env:AZP_CLIENTSECRET})" --tenantid "$(${Env:AZP_TENANTID})" --pool "$(if (Test-Path Env:AZP_POOL) { ${Env:AZP_POOL} } else { 'Default' })" --work "$(if (Test-Path Env:AZP_WORK) { ${Env:AZP_WORK} } else { '_work' })" --replace

Print-Header "4. Running Azure Pipelines agent..."

.\run.cmd
} finally {
  Print-Header "Cleanup. Removing Azure Pipelines agent..."

.\config.cmd remove --unattended --auth SP --clientid "$(${Env:AZP_CLIENTID})" --clientsecret "$(${Env:AZP_CLIENTSECRET})" --tenantid "$(${Env:AZP_TENANTID})"
}