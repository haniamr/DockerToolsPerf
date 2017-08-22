$dockerComposeArgs = "-f docker-compose-visitors.yml -f docker-compose-visitors.override.yml -p visitors"

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
		runAndMeasure "msbuild Visitors/MyCompany.Visitors.Server.sln /t:rebuild"
	} else {
		runAndMeasure "msbuild Visitors/MyCompany.Visitors.Server.sln"
	}

	if ($clean) {
		# build and start container
		runAndMeasure "docker-compose $dockerComposeArgs build --force-rm --no-cache"
		
		runAndMeasure "docker-compose $dockerComposeArgs up -d"
	} else {
		# make sure container is up-to-date by calling docker compose up
		runAndMeasure "docker-compose $dockerComposeArgs up -d"
	}
	
	# get container ID for web project
	$webid = runAndMeasure "docker ps --filter ""status=running"" --filter ""name=visitors_mycompany.visitors.web_"" --format ""{{.ID}}"" -n 1"
	
	# get container ID for webapi project
	$webapiid = runAndMeasure "docker ps --filter ""status=running"" --filter ""name=visitors_mycompany.visitors.crmsvc_"" --format ""{{.ID}}"" -n 1"

	# get IP address for web project
	$webip = runAndMeasure "docker inspect --format=""{{.NetworkSettings.Networks.nat.IPAddress}}"" $webid"
	
	# get IP address for webapi project
	$webapiip = runAndMeasure "docker inspect --format=""{{.NetworkSettings.Networks.nat.IPAddress}}"" $webapiid"

	Write-Host "Pinging http://$webip/noauth" -ForegroundColor Yellow
	$m = measure-command { 
		while($true)
		{
			try
			{
				$code = (wget http://$webip/noauth -UseBasicParsing).StatusCode
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
}

function codeChange 
{
	$path = pwd
	$codePath = "$path\Visitors\MyCompany.Visitors.Web\Controllers\HomeController.cs"
	$contents = [System.IO.File]::ReadAllText($codePath)
	[System.IO.File]::WriteAllText($codePath, $contents.Replace("Default Index", "Default Index blah"));
}

#
# Pre-requisites
#
Write-Host "nuget restore..." -ForegroundColor Yellow
.\nuget.exe restore Visitors\MyCompany.Visitors.Server.sln

mkdir -f Visitors\MyCompany.Visitors.Web\empty | out-null
mkdir -f Visitors\MyCompany.Visitors.CRMSvc\empty | out-null

#
# First run
#
Write-Host "First Run..." -ForegroundColor Green

# Clean up old images
Invoke-Expression "docker-compose $dockerComposeArgs down --rmi all --remove-orphans"

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