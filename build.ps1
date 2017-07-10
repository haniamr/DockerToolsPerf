function build
{
	Write-Host "dotnet restore..." -ForegroundColor Yellow
	dotnet restore DockerPerf.sln

	Write-Host "dotnet publish..." -ForegroundColor Yellow
	dotnet publish -o publish

	Write-Host "docker-compose kill..." -ForegroundColor Yellow
	docker-compose -f docker-compose.yml -p dockerperf kill

	Write-Host "docker-compose down..." -ForegroundColor Yellow
	docker-compose -f docker-compose.yml -p dockerperf down --rmi all --remove-orphans

	Write-Host "docker-compose up..." -ForegroundColor Yellow
	docker-compose -f docker-compose.yml -p dockerperf up -d --build

	$id=(docker ps --filter "status=running" --filter "name=dockerperf" --format "{{.ID}}" -n 1)

	$port=(docker inspect --format='{{(index (index .NetworkSettings.Ports \"80/tcp\") 0).HostPort}}' $id)

	Write-Host "Pinging http://localhost:$port..." -ForegroundColor Yellow
	while($true)
	{
		try
		{
			$code = (wget http://localhost:$port -UseBasicParsing).StatusCode
			if ($code -eq 200) 
			{
				break;
			}
		}
		catch
		{
		}
		
		Start-Sleep 0.1
	}
}

$measure = measure-command { build }

Write-Host "E2E Time: $measure" -ForegroundColor Yellow
Write-Host "Done!!!"