powershell docker rm -f (docker ps -aq)
docker rmi -f dockerperf:latest
docker rmi -f dockerperffx:latest
docker rmi -f mycompany.visitors.web:latest
docker rmi -f mycompany.visitors.CRMSvc:latest
git clean -fdx
