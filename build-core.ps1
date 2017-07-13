function build
{
	Write-Host "docker-compose -f docker-compose.yml -p dockerperf kill" -ForegroundColor Yellow
	$m = measure-command { docker-compose -f docker-compose.yml -p dockerperf kill }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green 

	Write-Host "docker-compose -f docker-compose.yml -p dockerperf down --rmi all --remove-orphans" -ForegroundColor Yellow
	$m = measure-command { docker-compose -f docker-compose.yml -p dockerperf down --rmi all --remove-orphans }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green 
	
	Write-Host "dotnet build DockerPerf.sln /t:rebuild" -ForegroundColor Yellow
	$m = measure-command { dotnet build DockerPerf.sln /t:rebuild }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green 

	Write-Host "docker-compose -f docker-compose.yml -p dockerperf up -d --build" -ForegroundColor Yellow
	$m = measure-command { docker-compose -f docker-compose.yml -p dockerperf up -d --build }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green 

	Write-Host "docker ps --filter ""status=running"" --filter ""name=dockerperf"" --format ""{{.ID}}"" -n 1" -ForegroundColor Yellow
	$m = measure-command { $id=(docker ps --filter "status=running" --filter "name=dockerperf" --format "{{.ID}}" -n 1) }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green 

	Write-Host "docker inspect --format='{{(index (index .NetworkSettings.Ports ""80/tcp"") 0).HostPort}}' $id" -ForegroundColor Yellow
	$m = measure-command { $port=(docker inspect --format='{{(index (index .NetworkSettings.Ports \"80/tcp\") 0).HostPort}}' $id) }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green 

	Write-Host "Pinging http://localhost:$port..." -ForegroundColor Yellow
	$m = measure-command { 
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
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green
}

Write-Host "dotnet restore..." -ForegroundColor Yellow
dotnet restore DockerPerf.sln

$m = measure-command { build }

Write-Host
Write-Host E2E Time: $m.Seconds seconds -ForegroundColor Green