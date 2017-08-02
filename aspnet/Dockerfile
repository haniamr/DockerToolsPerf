FROM microsoft/windowsservercore

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

RUN Add-WindowsFeature Web-Server; \
    Add-WindowsFeature NET-Framework-45-ASPNET; \
    Add-WindowsFeature Web-Asp-Net45; \
    DISM /online /Enable-Feature /FeatureName:IIS-HttpTracing; \
    Remove-Item -Recurse C:\inetpub\wwwroot\*
	
RUN stop-service W3SVC -force; \
    stop-service WAS -force; \
    Set-Service -Name was -StartupType Disabled; \
    Set-Service -Name w3svc -StartupType Disabled

EXPOSE 80

ENTRYPOINT ["C:\\windows\\system32\\inetsrv\\w3wp.exe", "-u"]

