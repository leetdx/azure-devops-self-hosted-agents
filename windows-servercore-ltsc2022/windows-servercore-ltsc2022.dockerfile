# escape=`
FROM mcr.microsoft.com/windows/servercore:ltsc2022

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

RUN Invoke-WebRequest -Uri https://builds.dotnet.microsoft.com/dotnet/scripts/v1/dotnet-install.ps1 -OutFile .\dotnet-install.ps1; `
    ./dotnet-install.ps1;

RUN Invoke-WebRequest -Uri https://aka.ms/dacfx-msi -OutFile .\DacFramework.msi; `
    msiexec.exe /i "DacFramework.msi" /qn

# Install Azure CLI using MSI
RUN Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; `
    Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; `
    Remove-Item .\AzureCLI.msi

# Verify Azure CLI installation
RUN az --version


# Copy the CodeQL installation script
COPY codeql-install-windows.ps1 C:\temp\

# Set the AGENT_TOOLSDIRECTORY environment variable and install CodeQL
RUN $Env:AGENT_TOOLSDIRECTORY = 'C:\azp\agent\_work\_tool'; `
    & 'C:\temp\codeql-install-windows.ps1'; `
    Remove-Item 'C:\temp\codeql-install-windows.ps1'


# Restore the default Windows shell for correct batch processing.
SHELL ["cmd", "/S", "/C"]

RUN `
    # Download the Build Tools bootstrapper.
    curl -SL --output vs_buildtools.exe https://aka.ms/vs/17/release/vs_buildtools.exe `
    `
    # Install Build Tools with workloads needed for .NET development, Azure DevOps, and SQL Server Data Tools
    && (start /w vs_buildtools.exe --quiet --wait --norestart --nocache `
        --installPath "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools" `
        --add Microsoft.VisualStudio.Workload.AzureBuildTools `
        --add Microsoft.VisualStudio.Workload.NetCoreBuildTools `
        --add Microsoft.VisualStudio.Workload.WebBuildTools `
        --add Microsoft.VisualStudio.Workload.MSBuildTools `
        --add Microsoft.NetCore.Component.SDK `
        --add Microsoft.NetCore.Component.Web `
        --add Microsoft.VisualStudio.Workload.DataBuildTools `
        --add Microsoft.VisualStudio.Component.SQL.SSDTBuildSku `
        --add Microsoft.VisualStudio.Component.NuGet.BuildTools `
        --remove Microsoft.VisualStudio.Component.Windows10SDK.10240 `
        --remove Microsoft.VisualStudio.Component.Windows10SDK.10586 `
        --remove Microsoft.VisualStudio.Component.Windows10SDK.14393 `
        --remove Microsoft.VisualStudio.Component.Windows81SDK `
        || IF "%ERRORLEVEL%"=="3010" EXIT 0) `
    `
    # Cleanup
    && del /q vs_buildtools.exe

# Set the working directory for the Azure DevOps agent
WORKDIR /azp/

# Copy the Azure DevOps agent startup script
COPY ./start.ps1 ./

# Define the entry point for the docker container.
# This entry point starts the developer command prompt and launches the agent startup script
ENTRYPOINT ["C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools\\Common7\\Tools\\VsDevCmd.bat", "&&", "powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass", "-File", ".\\start.ps1"]