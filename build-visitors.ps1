$dockerComposeArgs = "-f docker-compose-visitors.yml -f docker-compose-visitors.override.yml -p visitors"

function build($clean)
{
	if ($clean) {
		# Kill container
		Write-Host "docker-compose $dockerComposeArgs kill" -ForegroundColor Yellow
		$m = measure-command { Invoke-Expression "docker-compose $dockerComposeArgs kill" }
		Write-Host $m.TotalSeconds seconds -ForegroundColor Green 

		# Remove old images
		Write-Host "docker-compose $dockerComposeArgs down --rmi local --remove-orphans" -ForegroundColor Yellow
		$m = measure-command { Invoke-Expression "docker-compose $dockerComposeArgs down --rmi local --remove-orphans" }
		Write-Host $m.TotalSeconds seconds -ForegroundColor Green 
	}
	
	# docker-compose config, the result is not used in the script but in VS scenario, just keep this here to mimic the process
	Write-Host "docker-compose $dockerComposeArgs config" -ForegroundColor Yellow
	$m = measure-command { Invoke-Expression "docker-compose $dockerComposeArgs config" }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green 
	
	# build the project
	if ($clean) {
		Write-Host "msbuild Visitors/MyCompany.Visitors.Server.sln /t:rebuild" -ForegroundColor Yellow
		$m = measure-command { msbuild Visitors/MyCompany.Visitors.Server.sln /t:rebuild }
	} else {
		Write-Host "msbuild Visitors/MyCompany.Visitors.Server.sln" -ForegroundColor Yellow
		$m = measure-command { msbuild Visitors/MyCompany.Visitors.Server.sln }
	}
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green 

	if ($clean) {
		# build and start container
		Write-Host "docker-compose $dockerComposeArgs up -d --build" -ForegroundColor Yellow
		$m = measure-command { Invoke-Expression "docker-compose $dockerComposeArgs up -d --build" }
		Write-Host $m.TotalSeconds seconds -ForegroundColor Green 
	} else {
		# make sure container is up-to-date by calling docker compose up
		Write-Host "docker-compose $dockerComposeArgs up -d" -ForegroundColor Yellow
		$m = measure-command { Invoke-Expression "docker-compose $dockerComposeArgs up -d" }
		Write-Host $m.TotalSeconds seconds -ForegroundColor Green 
	}
	
	# get container ID for web project
	Write-Host "docker ps --filter ""status=running"" --filter ""name=visitors_mycompany.visitors.web_"" --format ""{{.ID}}"" -n 1" -ForegroundColor Yellow
	$m = measure-command { $webid=(docker ps --filter "status=running" --filter "name=visitors_mycompany.visitors.web_" --format "{{.ID}}" -n 1) }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green 
	
	# get container ID for webapi project
	Write-Host "docker ps --filter ""status=running"" --filter ""name=visitors_mycompany.visitors.crmsvc_"" --format ""{{.ID}}"" -n 1" -ForegroundColor Yellow
	$m = measure-command { $webapiid=(docker ps --filter "status=running" --filter "name=visitors_mycompany.visitors.crmsvc_" --format "{{.ID}}" -n 1) }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green 

	# get IP address for web project
	Write-Host "docker inspect --format=""{{.NetworkSettings.Networks.nat.IPAddress}}"" $webid" -ForegroundColor Yellow
	$m = measure-command { $webip=(docker inspect --format="{{.NetworkSettings.Networks.nat.IPAddress}}" $webid) }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green 
	
	# get IP address for webapi project
	Write-Host "docker inspect --format=""{{.NetworkSettings.Networks.nat.IPAddress}}"" $webapiid" -ForegroundColor Yellow
	$m = measure-command { $webapiip=(docker inspect --format="{{.NetworkSettings.Networks.nat.IPAddress}}" $webapiid) }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green 
	
	# start debugger if it is not already started
	Write-Host "docker exec $id powershell -Command if ((Get-Process msvsmon -ErrorAction SilentlyContinue).Count -eq 0) {  Start-Process C:\remote_debugger\msvsmon.exe -ArgumentList /noauth, /anyuser, /silent, /nostatus, /noclrwarn, /nosecuritywarn, /nofirewallwarn, /nowowwarn, /timeout:2147483646}" -ForegroundColor Yellow
	$m = measure-command { docker exec $webid powershell -Command { if ((Get-Process msvsmon -ErrorAction SilentlyContinue).Count -eq 0) {  Start-Process C:\remote_debugger\msvsmon.exe -ArgumentList /noauth, /anyuser, /silent, /nostatus, /noclrwarn, /nosecuritywarn, /nofirewallwarn, /nowowwarn, /timeout:2147483646} } }
	Write-Host $m.TotalSeconds seconds -ForegroundColor Green 

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
			
			# cannot decrease this ping, if ping too frequently the container will freeze
			Start-Sleep 1
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