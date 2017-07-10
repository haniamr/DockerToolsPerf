FROM microsoft/aspnetcore:1.1
WORKDIR /app
EXPOSE 80
COPY publish .
ENTRYPOINT ["dotnet", "DockerPerf.dll"]
