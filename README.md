# DockerToolsPerf
Docker Tools perf comparison between Linux container, Windows Nano container and Windows Server Core container.


## Pre-requisites

### To get perf data on Linux containter or windows nano container
- Install dotnet core SDK 1.1
- Install Docker For Windows
- Run "docker pull microsoft/aspnetcore:1.1" to retrieve/update the Linux/Nano image.
- Run "./build-core.ps1" in powershell

### To get perf data on Windows Server Core container
- Install Docker for Windows
- Switch Docker for Windows to windows container mode
- Run "docker pull microsoft/aspnet:4.6.2"
- Run "./build-fx.ps1" in powershell




