$dockerComposeArgs = "-f docker-compose-fx.yml -f docker-compose-fx.override.yml -p dockerperffx"

function runAndMeasure($command) {
	Write-Host $command -ForegroundColor Yellow
	$m = measure-command { $res = Invoke-Expression $command }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green 
	
	return $res
}

function build($clean)
{
	if ($clean) {
		# Kill container
		runAndMeasure "docker-compose $dockerComposeArgs kill"

		# Remove old images
		runAndMeasure "docker-compose $dockerComposeArgs down --rmi local --remove-orphans"
	}
	
	# docker-compose config, the result is not used in the script but in VS scenario, just keep this here to mimic the process
	runAndMeasure "docker-compose $dockerComposeArgs config"
	
	# build the project
	if ($clean) {
		runAndMeasure "msbuild DockerPerfFx.sln /t:rebuild"
	} else {
		runAndMeasure "msbuild DockerPerfFx.sln"
	}

	if ($clean) {
		# build and start container
		runAndMeasure "docker-compose $dockerComposeArgs up -d --build"
	} else {
		# make sure container is up-to-date by calling docker compose up
		runAndMeasure "docker-compose $dockerComposeArgs up -d"
	}
	
	# get container ID
	$id= runAndMeasure "docker ps --filter ""status=running"" --filter ""name=dockerperffx"" --format ""{{.ID}}"" -n 1"

	# get IP address
	$ip = runAndMeasure "docker inspect --format=""{{.NetworkSettings.Networks.nat.IPAddress}}"" $id"
	
	# start debugger if it is not already started
	runAndMeasure "docker exec $id powershell -Command if ((Get-Process msvsmon -ErrorAction SilentlyContinue).Count -eq 0) {  Start-Process C:\remote_debugger\msvsmon.exe -ArgumentList /noauth, /anyuser, /silent, /nostatus, /noclrwarn, /nosecuritywarn, /nofirewallwarn, /nowowwarn, /timeout:2147483646}"

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
			Start-Sleep 200
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
Write-Host "nuget restore..." -ForegroundColor Green
.\nuget.exe restore DockerPerfFx.sln

# Clean up old images
Write-Host "cleaning up..." -ForegroundColor Green
docker-compose $dockerComposeArgs down --rmi all --remove-orphans

#
# First run
#
Write-Host "First Run..." -ForegroundColor Green

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