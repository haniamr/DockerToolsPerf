FROM microsoft/dotnet:1.1-runtime-nanoserver
ENV ASPNETCORE_URLS http://+:81
ARG source
WORKDIR /app
EXPOSE 81
COPY ${source:-obj/Docker/publish} .
ENTRYPOINT ["dotnet", "MyCompany.Visitors.CRMSvc.dll"]
