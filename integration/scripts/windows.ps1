# Windows is the driver's most involved path: it generates a PowerShell user
# data script that enables WinRM (without which the transport cannot connect at
# all), then fetches and decrypts the generated Administrator password with the
# private key of the key pair it created.
#
# Reaching this script at all proves both. What follows checks the rest.
$ErrorActionPreference = 'Stop'

$token = Invoke-RestMethod -Method Put -Uri 'http://169.254.169.254/latest/api/token' `
  -Headers @{ 'X-aws-ec2-metadata-token-ttl-seconds' = '120' }
$imdsHeaders = @{ 'X-aws-ec2-metadata-token' = $token }

$instanceType = Invoke-RestMethod -Uri 'http://169.254.169.254/latest/meta-data/instance-type' -Headers $imdsHeaders
Write-Host "instance-type: $instanceType"
Write-Host "whoami:        $(whoami)"
Write-Host "os:            $((Get-CimInstance Win32_OperatingSystem).Caption)"

if ($instanceType -ne 't3.medium') {
  Write-Error "FAIL: expected the configured instance type t3.medium, got $instanceType"
  exit 1
}

# The generated user data writes its own log. Finding it proves the script the
# driver built was accepted and executed, rather than silently rejected.
$log = Get-ChildItem -Path 'C:\ProgramData\Amazon', 'C:\Program Files\Amazon' `
  -Filter 'kitchen-ec2.log' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $log) {
  Write-Error 'FAIL: the generated user data never ran; kitchen-ec2.log was not written'
  exit 1
}
Write-Host "user data log: $($log.FullName)"

# The extra 20 GiB volume must come up initialized and formatted. GPT, not MBR:
# Initialize-Disk does not fail on a disk larger than MBR can address, it caps
# it, so an MBR default would silently strand capacity on a big volume.
$extra = Get-Disk | Where-Object { $_.Size -gt 15GB -and $_.Size -lt 25GB } | Select-Object -First 1
if (-not $extra) {
  Write-Error 'FAIL: the extra 20G volume from block_device_mappings is not attached'
  exit 1
}
Write-Host "extra disk:    number $($extra.Number), $([math]::Round($extra.Size / 1GB))GB, $($extra.PartitionStyle)"

if ($extra.PartitionStyle -ne 'GPT') {
  Write-Error "FAIL: the extra volume is $($extra.PartitionStyle), expected GPT"
  exit 1
}

$volume = Get-Partition -DiskNumber $extra.Number -ErrorAction SilentlyContinue |
  Get-Volume -ErrorAction SilentlyContinue |
  Where-Object { $_.FileSystemType -eq 'NTFS' } | Select-Object -First 1
if (-not $volume) {
  Write-Error 'FAIL: the extra volume was never formatted'
  exit 1
}
Write-Host "extra volume:  $($volume.DriveLetter): $($volume.FileSystemType)"

Write-Host 'OK: windows'
