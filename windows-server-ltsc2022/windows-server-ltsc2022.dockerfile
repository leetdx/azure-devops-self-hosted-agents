# escape=`
FROM mcr.microsoft.com/windows/server:ltsc2022

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

RUN Invoke-WebRequest -Uri https://dl.google.com/chrome/install/GoogleChromeStandaloneEnterprise64.msi -OutFile .\chrome.msi; `
    Start-Process msiexec.exe -Wait -ArgumentList '/I chrome.msi /quiet'; `
    Remove-Item .\chrome.msi -Force

RUN $Env:CHROME_BIN = 'C:\Program Files\Google\Chrome\Application\chrome.exe'; `
    [Environment]::SetEnvironmentVariable('CHROME_BIN', $env:CHROME_BIN, [EnvironmentVariableTarget]::Machine)

# Copy the CodeQL installation script
COPY codeql-install-windows.ps1 C:\temp\

# Set the AGENT_TOOLSDIRECTORY environment variable and install CodeQL
RUN $Env:AGENT_TOOLSDIRECTORY = 'C:\azp\agent\_work\_tool'; `
    & 'C:\temp\codeql-install-windows.ps1'; `
    Remove-Item 'C:\temp\codeql-install-windows.ps1'

# Download and install Chocolatey
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; `
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Download and install Node.js (using correct version)
RUN choco install nodejs --version="22.12.0" -y
RUN choco install azure-cli --version="2.75.0" -y
RUN choco install sqlcmd -y

RUN npm install -g @azure/static-web-apps-cli
RUN npm install --global yarn

# Set the working directory for the Azure DevOps agent
WORKDIR /azp/

# Copy the Azure DevOps agent startup script
COPY ./start.ps1 ./

# Define the entry point for the docker container.
# This entry point starts the developer command prompt and launches the agent startup script
ENTRYPOINT ["powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass", "-File", ".\\start.ps1"]