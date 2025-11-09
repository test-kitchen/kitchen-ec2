Function Check-UpdateChef($root, $version) {
  if (-Not (Test-Path "$root\embedded")) { return $true }
  elseif ("$version" -eq "true") { return $false }
  elseif ("$version" -eq "latest") { return $true }

  Try { $chef_version = (Get-Content $root\version-manifest.txt  -ErrorAction stop | select-object -first 1) }
  Catch {
    Try { $chef_version = (& $root\bin\chef-solo.bat -v) }
    Catch { $chef_version = " " }
  }

  if ($chef_version.split(" ", 2)[1].StartsWith($version)) { return $false }
  else { return $true }
}

Function Get-ChefMetadata($url) {
  $response = Get-WebContent $url

  $md = ConvertFrom-StringData $response.Replace("`t", "=")
  return @($md.url, $md.sha256)
}

Function Get-SHA256($src) {
  Try {
    $c = Get-SHA256Converter
    $bytes = $c.ComputeHash(($in = (Get-Item $src).OpenRead()))
    return ([System.BitConverter]::ToString($bytes)).Replace("-", "").ToLower()
  } Finally { if (($c -ne $null) -and ($c.GetType().GetMethod("Dispose") -ne $null)) { $c.Dispose() }; if ($in -ne $null) { $in.Dispose() } }
}

function Get-SHA256Converter {
  if ($(Is-FIPS) -ge 1) {
    New-Object -TypeName Security.Cryptography.SHA256Cng
  } else {
    if($PSVersionTable.PSEdition -eq 'Core') {
      [System.Security.Cryptography.SHA256]::Create()
    }
    else {
      New-Object -TypeName Security.Cryptography.SHA256Managed
    }
  }
}

function Is-FIPS {
  if (!$env:fips){
    $env:fips = (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\FipsAlgorithmPolicy).Enabled
  }
  return $env:fips
}

Function Download-Chef($url, $sha256, $dst) {
  Log "Downloading package from $url"
  Get-WebContent $url $dst
  Log "Download complete."

  if ($sha256 -eq $null) { Log "Skipping sha256 verification" }
  elseif (Verify-SHA256 $dst $sha256) { Log "Successfully verified $dst" }
  else { throw "SHA256 for $dst does not match $sha256" }
}

Function Verify-SHA256($path, $sha256) {
  if ($sha256 -eq $null) { return $false }
  elseif (($dsha256 = Get-SHA256 $path) -eq $sha256) { return $true }
  else { return $false }
}

Function Install-Chef($msi, $chef_omnibus_root) {
  Log "Installing Chef package $msi"
  $installingChef = $True
  $installAttempts = 0
  while ($installingChef) {
    $installAttempts++
    $result = $false
    if($msi.EndsWith(".appx")) {
      $result = Install-ChefAppx $msi $chef_omnibus_root
    }
    else {
      $result = Install-ChefMsi $msi
    }
    if(!$result) { continue }
    $installingChef = $False
  }
  Log "Installation complete"
}

Function Install-ChefMsi($msi) {
  $p = Start-Process -FilePath "msiexec.exe" -ArgumentList "/qn /i $msi" -Passthru -Wait
  $p.WaitForExit()
  if ($p.ExitCode -eq 1618) {
    Log "Another msi install is in progress (exit code 1618), retrying ($($installAttempts))..."
    return $false
  } elseif ($p.ExitCode -ne 0) {
    throw "msiexec was not successful. Received exit code $($p.ExitCode)"
  }
  return $true
}

Function Install-ChefAppx($appx, $chef_omnibus_root) {
  Add-AppxPackage -Path $appx -ErrorAction Stop

  $rootParent = Split-Path $chef_omnibus_root -Parent

  if(!(Test-Path $rootParent)) {
    New-Item -ItemType Directory -Path $rootParent
  }

  # Remove old version of chef if it is here
  if(Test-Path $chef_omnibus_root) {
    Remove-Item -Path $chef_omnibus_root -Recurse -Force
  }

  # copy the appx install to the omnibus_root. There are serious
  # ACL related issues with running chef from the appx InstallLocation
  # Hoping this is temporary and we can eventually just symlink
  $package = (Get-AppxPackage -Name chef).InstallLocation
  Copy-Item $package $chef_omnibus_root -Recurse

  return $true
}

Function Log($m) { Write-Host "       $m" }

function Get-WebContent {
  param ($uri, $filepath)

  try {
    if($PSVersionTable.PSEdition -eq 'Core') {
      Get-WebContentOnCore $uri $filepath
    }
    else {
      Get-WebContentOnFullNet $uri $filepath
    }
  }
  catch {
    $exception = $_.Exception
    Write-Host "There was an error: "
    do {
      Write-Host "`t$($exception.message)"
      $exception = $exception.innerexception
    } while ($exception)
    throw "Failed to download from $uri."
  }
}

function Get-WebContentOnFullNet {
  param ($uri, $filepath)

  $proxy = New-Object -TypeName System.Net.WebProxy
  $wc = new-object System.Net.WebClient
  $proxy.Address = $env:http_proxy
  $wc.Proxy = $proxy

  if ([string]::IsNullOrEmpty($filepath)) {
    $wc.downloadstring($uri)
  }
  else {
    $wc.downloadfile($uri, $filepath)
  }
}

function Get-WebContentOnCore {
  param ($uri, $filepath)

  $handler = New-Object System.Net.Http.HttpClientHandler
  $client = New-Object System.Net.Http.HttpClient($handler)
  $client.Timeout = New-Object System.TimeSpan(0, 30, 0)
  $cancelTokenSource = [System.Threading.CancellationTokenSource]::new()
  $responseMsg = $client.GetAsync([System.Uri]::new($uri), $cancelTokenSource.Token)
  $responseMsg.Wait()
  if (!$responseMsg.IsCanceled) {
    $response = $responseMsg.Result
    if ($response.IsSuccessStatusCode) {
      if ([string]::IsNullOrEmpty($filepath)) {
        $response.Content.ReadAsStringAsync().Result
      }
      else {
        $downloadedFileStream = [System.IO.FileStream]::new($filepath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
        $copyStreamOp = $response.Content.CopyToAsync($downloadedFileStream)
        $copyStreamOp.Wait()
        $downloadedFileStream.Close()
        if ($copyStreamOp.Exception -ne $null) {
          throw $copyStreamOp.Exception
        }
      }
    }
  }
}

Function Unresolve-Path($p) {
  if ($p -eq $null) { return $null }
  else { return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($p) }
}

$chef_omnibus_root = Unresolve-Path $chef_omnibus_root

if (Check-UpdateChef $chef_omnibus_root $version) {
  Write-Host "-----> Installing Chef $pretty_version package"
  if ($chef_metadata_url -ne $null) {
    $url, $sha256 = Get-ChefMetadata "$chef_metadata_url"
  } else {
    $url = $chef_msi_url
    $sha256 = $null
  }
  $msi = Join-Path $download_directory "$url".Split("/")[-1]
  $msi = Unresolve-Path $msi
  if (Verify-SHA256 $msi $sha256) {
    Log "Skipping package download; found a matching package at $msi"
  } else {
    Download-Chef "$url" $sha256 $msi
  }
  Install-Chef $msi $chef_omnibus_root
} else {
  Write-Host "-----> Chef installation detected ($pretty_version)"
}
