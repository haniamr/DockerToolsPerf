# DockerToolsPerf
Docker Tools perf comparison between Linux container and Windows Server Core container.


## Pre-requisites

### To get perf data on Linux containter
- Install dotnet core SDK 1.1
- Install Docker For Windows
- Run "docker pull microsoft/aspnetcore:1.1" to retrieve/update the Linux base image.
- Run "./build-core.ps1" in powershell

### To get perf data on Windows Server Core container
- Install Visual Studio 2017 Preview 3
- Install Docker for Windows
- Switch Docker for Windows to windows container mode
- Run "build-aspnet-image.cmd" to build the base image
- Run "./build-fx.ps1" in powershell




