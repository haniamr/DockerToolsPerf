function build
{
	Write-Host "docker-compose -f docker-compose-fx.yml -p dockerperffx kill" -ForegroundColor Yellow
	$m = measure-command { docker-compose -f docker-compose-fx.yml -p dockerperffx kill }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green 

	Write-Host "docker-compose -f docker-compose-fx.yml -p dockerperffx down --rmi all --remove-orphans" -ForegroundColor Yellow
	$m = measure-command { docker-compose -f docker-compose-fx.yml -p dockerperffx down --rmi all --remove-orphans }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green 
	
	Write-Host "msbuild DockerPerfFx.sln /t:rebuild" -ForegroundColor Yellow
	$m = measure-command { msbuild DockerPerfFx.sln /t:rebuild }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green 

	Write-Host "docker-compose -f docker-compose-fx.yml -p dockerperffx up -d --build" -ForegroundColor Yellow
	$m = measure-command { docker-compose -f docker-compose-fx.yml -p dockerperffx up -d --build }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green 

	Write-Host "docker ps --filter ""status=running"" --filter ""name=dockerperffx"" --format ""{{.ID}}"" -n 1" -ForegroundColor Yellow
	$m = measure-command { $id=(docker ps --filter "status=running" --filter "name=dockerperffx" --format "{{.ID}}" -n 1) }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green 

	Write-Host "docker inspect --format=""{{.NetworkSettings.Networks.nat.IPAddress}}""" -ForegroundColor Yellow
	$m = measure-command { $ip=(docker inspect --format="{{.NetworkSettings.Networks.nat.IPAddress}}" $id) }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green 

	Write-Host "Pinging http://$ip/" -ForegroundColor Yellow
	$m = measure-command { 
		while($true)
		{
			try
			{
				$code = (wget http://$ip/ -UseBasicParsing).StatusCode
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

Write-Host "nuget restore..." -ForegroundColor Yellow
.\nuget.exe restore DockerPerfFx.sln

$m = measure-command { build }

Write-Host
Write-Host E2E Time: $m.Seconds seconds -ForegroundColor Green