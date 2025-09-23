# escape=`
# Use the latest Windows Server Core 2022 image.
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Install Azure CLI
RUN powershell -Command `
    "Write-Host 'Installing Azure CLI...' -ForegroundColor Green; `
    try { `
        & az version 2>$null; `
        Write-Host 'Azure CLI already available' -ForegroundColor Yellow; `
    } catch { `
        Write-Host 'Azure CLI not found, installing...' -ForegroundColor Yellow; `
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; `
        Invoke-WebRequest -Uri 'https://aka.ms/installazurecliwindows' -OutFile 'AzureCLI.msi' -UseBasicParsing; `
        Write-Host 'Downloaded Azure CLI installer' -ForegroundColor Green; `
        Start-Process msiexec.exe -ArgumentList '/I', 'AzureCLI.msi', '/quiet', '/norestart' -Wait; `
        Write-Host 'Azure CLI installation completed' -ForegroundColor Green; `
        Remove-Item 'AzureCLI.msi' -Force; `
    }"

# Add Azure CLI to PATH permanently
RUN powershell -Command `
    "$azCliPath = 'C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin'; `
    $currentPath = [Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::Machine); `
    if ($currentPath -notlike '*Azure*CLI*') { `
        $newPath = $azCliPath + ';' + $currentPath; `
        [Environment]::SetEnvironmentVariable('PATH', $newPath, [EnvironmentVariableTarget]::Machine); `
        Write-Host 'Added Azure CLI to system PATH' -ForegroundColor Green; `
    } else { `
        Write-Host 'Azure CLI already in PATH' -ForegroundColor Yellow; `
    }"

# Set the working directory for the Azure DevOps agent
WORKDIR /azp/

# Copy the Azure DevOps agent startup script
COPY ./start.ps1 ./

CMD powershell .\start.ps1