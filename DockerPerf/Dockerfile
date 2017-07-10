FROM microsoft/aspnetcore:1.1
ARG source
WORKDIR /app
EXPOSE 80
COPY publish .
ENTRYPOINT ["dotnet", "DockerPerf.dll"]
