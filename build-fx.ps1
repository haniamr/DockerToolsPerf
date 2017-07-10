function build
{
	Write-Host "docker-compose kill..." -ForegroundColor Yellow
	$m = measure-command { docker-compose -f docker-compose-fx.yml -p dockerperffx kill }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Yellow 

	Write-Host "docker-compose down..." -ForegroundColor Yellow
	$m = measure-command { docker-compose -f docker-compose-fx.yml -p dockerperffx down --rmi all --remove-orphans }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Yellow 

	Write-Host "docker-compose up..." -ForegroundColor Yellow
	$m = measure-command { docker-compose -f docker-compose-fx.yml -p dockerperffx up -d --build }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Yellow 

	$id=(docker ps --filter "status=running" --filter "name=dockerperf" --format "{{.ID}}" -n 1)

	$ip=(docker inspect --format="{{.NetworkSettings.Networks.nat.IPAddress}}" $id)

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
	Write-Host $m.TotalSeconds seconds -ForegroundColor Yellow
}

Write-Host "nuget restore..." -ForegroundColor Yellow
.\nuget.exe restore DockerPerfFx.sln

Write-Host "msbuild /t:DeployOnBuild..." -ForegroundColor Yellow
msbuild /p:DeployOnBuild=true /p:PublishProfile=FolderProfile DockerPerfFx.sln

$m = measure-command { build }

Write-Host
Write-Host E2E Time: $m.Seconds seconds -ForegroundColor Yellow
Write-Host "Done!!!" -ForegroundColor Green