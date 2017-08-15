FROM microsoft/windowsservercore

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

RUN Add-WindowsFeature Web-Server; \
    Add-WindowsFeature NET-Framework-45-ASPNET; \
    Add-WindowsFeature Web-Asp-Net45; \
    DISM /online /Enable-Feature /FeatureName:IIS-HttpTracing; \
    Remove-Item -Recurse C:\inetpub\wwwroot\*

ADD ServiceMonitor.exe /

ADD roslyn /roslyn

RUN C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\csc.exe /execonfig:c:\roslyn\csc.exe; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\vbc.exe /execonfig:c:\roslyn\vbc.exe; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\VBCSCompiler.exe /execonfig:c:\roslyn\VBCSCompiler.exe

EXPOSE 80

ENTRYPOINT ["C:\\ServiceMonitor.exe", "w3svc"]

