param (
    [ValidateSet("Linux", "Windows")]
    [string]$platform = "Linux"
)

if ($platform -eq "Linux") {
    Write-Host "Running dotnet core application on Linux container" -ForegroundColor Green
    Write-Host
    $dockerComposeArgs = "-f docker-compose.yml -f docker-compose.override.yml -p dockerperf"
} else {
    Write-Host "Running dotnet core application on Windows Nano container" -ForegroundColor Green
    Write-Host
    $dockerComposeArgs = "-f docker-compose.yml -f docker-compose.override.nano.yml -p dockerperf"
}

function runAndMeasure($command) {
    Write-Host $command -ForegroundColor Yellow
    $m = measure-command { $res = Invoke-Expression $command }
    Write-Host $m.TotalSeconds seconds -ForegroundColor Green 
    $script:e2e += $m.TotalSeconds
    
    return $res
}

function getAppUrl($id) {
    if ($platform -eq "Linux") {
        $port = runAndMeasure "docker inspect --format=""{{range .NetworkSettings.Ports}}{{range .}}{{.HostPort}}{{end}}{{end}}"" $id"
        return "http://localhost:$port"
    } else {
        $ip = runAndMeasure "docker inspect --format=""{{.NetworkSettings.Networks.nat.IPAddress}}"" $id"
        return "http://$ip/"
    }
}

function killExistingDotnetProcess($id) {
    if ($platform -eq "Linux") {
        runAndMeasure "docker exec $id /bin/bash -c ""kill ```$(pidof -x dotnet)"""
    } else {
        runAndMeasure "docker exec $id C:\\Tools\\KillProcess.exe dotnet.exe"
    }
}

function startDotnetApplication($id) {
    if ($platform -eq "Linux") {
        runAndMeasure "docker exec -d $id dotnet --additionalProbingPath /root/.nuget/packages --additionalProbingPath /root/.nuget/fallbackpackages bin/Debug/netcoreapp2.0/DockerPerf.dll"
    } else {
        runAndMeasure "docker exec -d $id dotnet --additionalProbingPath c:\\.nuget\\packages --additionalProbingPath C:\\.nuget\\fallbackpackages bin\\Debug\\netcoreapp2.0\\DockerPerf.dll"
    }
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

    if ($clean) {
        # build and start container
        runAndMeasure "docker-compose $dockerComposeArgs build --force-rm --no-cache | out-null"
        
        runAndMeasure "docker-compose $dockerComposeArgs up -d | out-null"
    } else {
        # make sure container is up-to-date by calling docker compose up
        runAndMeasure "docker-compose $dockerComposeArgs up -d | out-null"
    }
    
    # get container ID for web project
    $id = runAndMeasure "docker ps --filter ""status=running"" --filter ""name=dockerperf"" --format ""{{.ID}}"" -n 1"
    
    # build the project
    if ($clean) {
        runAndMeasure "msbuild .\DockerPerf.sln /t:rebuild | out-null"
    } else {
        # kill existing dotnet process inside the running container
        killExistingDotnetProcess $id
        
        # rebuild the project
        runAndMeasure "msbuild .\DockerPerf.sln | out-null"
    }
    
    # start dotnet application inside running container
    startDotnetApplication $id

    # get application URL for web project
    $url = getAppUrl $id
    
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

function codeChange 
{
    $path = pwd
    $codePath = "$path\DockerPerf\Controllers\HomeController.cs"
    $contents = [System.IO.File]::ReadAllText($codePath)
    [System.IO.File]::WriteAllText($codePath, $contents.Replace("Your application description page", "Your application description page blah"));
}

# Clean up
Write-Host "cleaning up..." -ForegroundColor Green
.\clean.cmd 2>&1 | out-null

#
# Pre-requisites
#
Write-Host "dotnet restore..." -ForegroundColor Yellow
dotnet restore DockerPerf.sln | out-null


if ($platform -eq "Linux") {
    docker pull microsoft/aspnetcore:2.0
    docker tag microsoft/aspnetcore:2.0 perf/aspnetcore:2.0
}

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

$script:e2e = 0
build $false

Write-Host
Write-Host E2E Time: $([math]::Round($script:e2e)) seconds -ForegroundColor Green
Write-Host
Write-Host