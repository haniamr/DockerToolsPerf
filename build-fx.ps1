function build($clean)
{
	if ($clean) {
		# Kill container
		Write-Host "docker-compose -f docker-compose-fx.yml -f docker-compose-fx.override.yml -p dockerperffx kill" -ForegroundColor Yellow
		$m = measure-command { docker-compose -f docker-compose-fx.yml -f docker-compose-fx.override.yml -p dockerperffx kill }
		Write-Host $m.TotalSeconds seconds -ForegroundColor Green 

		# Remove old images
		Write-Host "docker-compose -f docker-compose-fx.yml -f docker-compose-fx.override.yml -p dockerperffx down --rmi local --remove-orphans" -ForegroundColor Yellow
		$m = measure-command { docker-compose -f docker-compose-fx.yml -f docker-compose-fx.override.yml -p dockerperffx down --rmi local --remove-orphans }
		Write-Host $m.TotalSeconds seconds -ForegroundColor Green 
	}
	
	# docker-compose config, the result is not used in the script but in VS scenario, just keep this here to mimic the process
	Write-Host "docker-compose -f docker-compose-fx.yml -f docker-compose-fx.override.yml -p dockerperffx config" -ForegroundColor Yellow
	$m = measure-command { docker-compose -f docker-compose-fx.yml -f docker-compose-fx.override.yml -p dockerperffx config }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green 
	
	# build the project
	Write-Host "msbuild DockerPerfFx.sln /t:rebuild" -ForegroundColor Yellow
	$m = measure-command { msbuild DockerPerfFx.sln /t:rebuild }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green 

	if ($clean) {
		# build and start container
		Write-Host "docker-compose -f docker-compose-fx.yml -f docker-compose-fx.override.yml -p dockerperffx up -d --build" -ForegroundColor Yellow
		$m = measure-command { docker-compose -f docker-compose-fx.yml -f docker-compose-fx.override.yml -p dockerperffx up -d --build }
		Write-Host $m.TotalSeconds seconds -ForegroundColor Green 
	} else {
		# make sure container is up-to-date by calling docker compose up
		Write-Host "docker-compose -f docker-compose-fx.yml -f docker-compose-fx.override.yml -p dockerperffx up -d" -ForegroundColor Yellow
		$m = measure-command { docker-compose -f docker-compose-fx.yml -f docker-compose-fx.override.yml -p dockerperffx up -d }
		Write-Host $m.TotalSeconds seconds -ForegroundColor Green 
	}
	
	# get container ID
	Write-Host "docker ps --filter ""status=running"" --filter ""name=dockerperffx"" --format ""{{.ID}}"" -n 1" -ForegroundColor Yellow
	$m = measure-command { $id=(docker ps --filter "status=running" --filter "name=dockerperffx" --format "{{.ID}}" -n 1) }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green 
	
	if ($clean) {
		Write-Host "docker exec $id C:\PerfView.exe start c:\perf.etl -AcceptEULA -LogFile:C:\perf.log -Zip:True -Merge:True -ThreadTime -NoView -CircularMB:0 -Providers:Microsoft-Windows-IIS"
		docker exec $id C:\PerfView.exe start c:\perf.etl -AcceptEULA -LogFile:C:\perf.log -Zip:True -Merge:True -ThreadTime -NoView -CircularMB:0
	}

	# get IP address
	Write-Host "docker inspect --format=""{{.NetworkSettings.Networks.nat.IPAddress}}"" $id" -ForegroundColor Yellow
	$m = measure-command { $ip=(docker inspect --format="{{.NetworkSettings.Networks.nat.IPAddress}}" $id) }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green 
	
	# start debugger if it is not already started
	Write-Host "docker exec $id powershell -Command if ((Get-Process msvsmon -ErrorAction SilentlyContinue).Count -eq 0) {  Start-Process C:\remote_debugger\msvsmon.exe -ArgumentList /noauth, /anyuser, /silent, /nostatus, /noclrwarn, /nosecuritywarn, /nofirewallwarn, /nowowwarn, /timeout:2147483646}" -ForegroundColor Yellow
	$m = measure-command { docker exec $id powershell -Command { if ((Get-Process msvsmon -ErrorAction SilentlyContinue).Count -eq 0) {  Start-Process C:\remote_debugger\msvsmon.exe -ArgumentList /noauth, /anyuser, /silent, /nostatus, /noclrwarn, /nosecuritywarn, /nofirewallwarn, /nowowwarn, /timeout:2147483646} } }
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
			
			# cannot decrease this ping, if ping too frequently the container will freeze
			Start-Sleep 1
		}
	}
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green
	
	if (-not $clean) {
		Write-Host "docker exec $id C:\PerfView.exe stop -AcceptEULA -LogFile:C:\perf.log -NoView -Providers:Microsoft-Windows-IIS"
		docker exec $id C:\PerfView.exe stop -AcceptEULA -LogFile:C:\perf.log -NoView
	}
}

function codeChange 
{
	$path = pwd
	$codePath = "$path\DockerPerfFx\Controllers\HomeController.cs"
	$contents = [System.IO.File]::ReadAllText($codePath)
	[System.IO.File]::WriteAllText($codePath, $contents.Replace("description", "more description"));
}

#
# Pre-requisites
#
Write-Host "nuget restore..." -ForegroundColor Yellow
.\nuget.exe restore DockerPerfFx.sln

#
# First run
#
Write-Host "First Run..." -ForegroundColor Green

# Clean up old images
docker-compose -f docker-compose-fx.yml -f docker-compose-fx.override.yml -p dockerperffx down --rmi all --remove-orphans

$e2e = measure-command { 
	build $true
}

Write-Host
Write-Host E2E Time: $e2e.Seconds seconds -ForegroundColor Green
Write-Host
Write-Host

#
# Second run
#

Write-Host "Second run..." -ForegroundColor Green

# Simulate a code change
Write-Host "Simulate a code change..." -ForegroundColor Green
codeChange

# Sleep 30 seconds to avoid file locking issue
Write-Host "Sleep 30 seconds to avoid file locking issue..." -ForegroundColor Green
Start-Sleep 30

$e2e = measure-command { 
	build $false
}

Write-Host
Write-Host E2E Time: $e2e.Seconds seconds -ForegroundColor Green
Write-Host
Write-Host