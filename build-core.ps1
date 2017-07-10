function build
{
	Write-Host "docker-compose kill..." -ForegroundColor Yellow
	$m = measure-command { docker-compose -f docker-compose.yml -p dockerperf kill }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Yellow 

	Write-Host "docker-compose down..." -ForegroundColor Yellow
	$m = measure-command { docker-compose -f docker-compose.yml -p dockerperf down --rmi all --remove-orphans }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Yellow 

	Write-Host "docker-compose up..." -ForegroundColor Yellow
	$m = measure-command { docker-compose -f docker-compose.yml -p dockerperf up -d --build }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Yellow 

	$id=(docker ps --filter "status=running" --filter "name=dockerperf" --format "{{.ID}}" -n 1)

	$port=(docker inspect --format='{{(index (index .NetworkSettings.Ports \"80/tcp\") 0).HostPort}}' $id)

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
	Write-Host $m.TotalSeconds seconds -ForegroundColor Yellow
}

Write-Host "dotnet restore..." -ForegroundColor Yellow
dotnet restore DockerPerf.sln

Write-Host "dotnet publish..." -ForegroundColor Yellow
dotnet publish -o publish DockerPerf.sln

$m = measure-command { build }

Write-Host
Write-Host E2E Time: $m.Seconds seconds -ForegroundColor Yellow
Write-Host "Done!!!" -ForegroundColor Green