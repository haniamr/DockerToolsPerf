powershell docker rm -f (docker ps -aq)

docker rmi -f dockerperf:latest
docker rmi -f dockerperffx:latest
docker rmi -f mycompany.visitors.web:latest
docker rmi -f mycompany.visitors.crmsvc:latest
docker rmi -f mycompany.visitors.web:dev
docker rmi -f mycompany.visitors.crmsvc:dev

git clean dockerperf/ -fdx
git clean dockerperffx/ -fdx
git clean visitors/ -fdx