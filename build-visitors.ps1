$dockerComposeArgs = "-f docker-compose-visitors.yml -f docker-compose-visitors.override.yml -p visitors"

function runAndMeasure($command) {
    Write-Host $command -ForegroundColor Yellow
    $m = measure-command { $res = Invoke-Expression $command }
    Write-Host $m.TotalSeconds seconds -ForegroundColor Green 
    $script:e2e += $m.TotalSeconds
    
    return $res
}

function pingUrl($url) {
    Write-Host "Pinging $url" -ForegroundColor Yellow
    $m = measure-command { 
        while($true)
        {
            try
            {
                $code = (wget $url -UseBasicParsing).StatusCode
                if ($code -eq 200) 
                {
                    break;
                }
            }
            catch
            {
            }
            Start-Sleep -m 200
        }
    }
    Write-Host $m.TotalSeconds seconds -ForegroundColor Green
    $script:e2e += $m.TotalSeconds
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
    runAndMeasure "docker-compose $dockerComposeArgs config | out-null"
    
    # build the project
    if ($clean) {
        runAndMeasure "msbuild Visitors/MyCompany.Visitors.Server_no_compose.sln /t:rebuild | out-null"
    } else {
        runAndMeasure "msbuild Visitors/MyCompany.Visitors.Server_no_compose.sln | out-null"
    }

    if ($clean) {
        # build and start container
        runAndMeasure "docker-compose $dockerComposeArgs build --force-rm --no-cache | out-null"
        
        runAndMeasure "docker-compose $dockerComposeArgs up -d | out-null"
    } else {
        # make sure container is up-to-date by calling docker compose up
        runAndMeasure "docker-compose $dockerComposeArgs up -d | out-null"
    }
    
    # get container ID for web project
    $webid = runAndMeasure "docker ps --filter ""status=running"" --filter ""name=visitors_mycompany.visitors.web_"" --format ""{{.ID}}"" -n 1"
    
    # get container ID for webapi project
    $webapiid = runAndMeasure "docker ps --filter ""status=running"" --filter ""name=visitors_mycompany.visitors.crmsvc_"" --format ""{{.ID}}"" -n 1"

    # get IP address for web project
    $webip = runAndMeasure "docker inspect --format=""{{.NetworkSettings.Networks.nat.IPAddress}}"" $webid"
    
    # get IP address for webapi project
    $webapiip = runAndMeasure "docker inspect --format=""{{.NetworkSettings.Networks.nat.IPAddress}}"" $webapiid"

    # ping web application
    pingUrl "http://$webip/noauth"
    
    # ping web api application
    pingUrl "http://${webapiip}:81/api/CRMData/"
}

function codeChange 
{
    $path = pwd
    $codePath = "$path\Visitors\MyCompany.Visitors.Web\Controllers\HomeController.cs"
    $contents = [System.IO.File]::ReadAllText($codePath)
    [System.IO.File]::WriteAllText($codePath, $contents.Replace("Default Index", "Default Index blah"));
}

# Clean up
Write-Host "cleaning up..." -ForegroundColor Green
.\clean.cmd 2>&1 | out-null

#
# Pre-requisites
#
Write-Host "nuget restore..." -ForegroundColor Green
.\nuget.exe restore Visitors\MyCompany.Visitors.Server_no_compose.sln | out-null

mkdir -f Visitors\MyCompany.Visitors.Web\empty | out-null
mkdir -f Visitors\MyCompany.Visitors.CRMSvc\empty | out-null

#
# First run
#
Write-Host "First Run..." -ForegroundColor Green

$script:e2e = 0
build $true

Write-Host
Write-Host E2E Time: $([math]::Round($script:e2e)) seconds -ForegroundColor Green
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

$script:e2e = 0
build $false

Write-Host
Write-Host E2E Time: $([math]::Round($script:e2e)) seconds -ForegroundColor Green
Write-Host
Write-Host