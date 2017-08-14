FROM microsoft/windowsservercore

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

RUN Add-WindowsFeature Web-Server; \
    Add-WindowsFeature NET-Framework-45-ASPNET; \
    Add-WindowsFeature Web-Asp-Net45; \
    DISM /online /Enable-Feature /FeatureName:IIS-HttpTracing; \
    Remove-Item -Recurse C:\inetpub\wwwroot\*

ADD ServiceMonitor.exe /

ADD roslyn /roslyn

RUN C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\csc.exe; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\csi.exe; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\Microsoft.Build.Tasks.CodeAnalysis.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\Microsoft.CodeAnalysis.CSharp.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\Microsoft.CodeAnalysis.CSharp.Scripting.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\Microsoft.CodeAnalysis.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\Microsoft.CodeAnalysis.Scripting.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\Microsoft.CodeAnalysis.VisualBasic.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\Microsoft.CSharp.Core.targets; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\Microsoft.DiaSymReader.Native.amd64.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\Microsoft.DiaSymReader.Native.x86.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\Microsoft.VisualBasic.Core.targets; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\Microsoft.Win32.Primitives.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.AppContext.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.Collections.Immutable.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.Console.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.Diagnostics.FileVersionInfo.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.Diagnostics.Process.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.Diagnostics.StackTrace.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.IO.Compression.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.IO.FileSystem.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.IO.FileSystem.DriveInfo.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.IO.FileSystem.Primitives.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.IO.Pipes.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.Reflection.Metadata.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.Security.AccessControl.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.Security.Claims.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.Security.Cryptography.Algorithms.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.Security.Cryptography.Encoding.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.Security.Cryptography.Primitives.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.Security.Cryptography.X509Certificates.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.Security.Principal.Windows.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.Text.Encoding.CodePages.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.Threading.Thread.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.ValueTuple.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.Xml.ReaderWriter.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.Xml.XmlDocument.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.Xml.XPath.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\System.Xml.XPath.XDocument.dll; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\vbc.exe; \
	C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\roslyn\VBCSCompiler.exe

EXPOSE 80

ENTRYPOINT ["C:\\ServiceMonitor.exe", "w3svc"]

