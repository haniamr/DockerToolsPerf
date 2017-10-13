FROM perf/aspnetcore:2.0
ENV ASPNETCORE_URLS http://+:81
ARG source
WORKDIR /app
EXPOSE 81
COPY ${source:-obj/Docker/publish} .
ENTRYPOINT ["dotnet", "MyCompany.Visitors.CRMSvc.dll"]
