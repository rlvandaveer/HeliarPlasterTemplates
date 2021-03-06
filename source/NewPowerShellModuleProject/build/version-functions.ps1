function Initialize-GitVersion {

	try {

		Write-Debug "Checking for Gitversion install..."
		$ver = Exec { return gitversion -version }
		Write-Debug "Gitversion $ver installed"

	} catch {

		Write-Debug "Gitversion not installed, installing..."

		if ($IsLinux) {

			#TODO: RLV - determine how to install/execute gitversion on Linux
			Exec {
				Write-Host 'Downloading GitVersion...'
				wget 'https://github.com/GitTools/GitVersion/releases/download/5.1.3/gitversion-linux-5.1.3.tar.gz'
				Write-Host 'Unzipping GitVersion...'
				tar xvzf 'gitversion-linux-5.1.3.tar.gz'
			}

		} elseif ($IsMacOS) {

			Exec { brew install gitversion }

		} elseif ($IsWindows) {

			Exec { choco install gitversion.portable -y }

		}
	}
}

function Get-VersionInfo {

	$null = Initialize-GitVersion
	return (Exec { return gitversion } | ConvertFrom-Json -AsHashtable)
}

function Write-VersionInfoToAzureDevOps {
	[CmdletBinding()]
	param (
		[HashTable]
		$Version
	)

	Write-Host "##vso[build.updatebuildnumber]$($Version.NuGetVersionV2).$ENV:BUILD_BUILDNUMBER"
	Write-Host "##vso[task.setvariable variable=versionNumber]$($Version.NuGetVersionV2)"
	Write-Host "##vso[task.setvariable variable=preReleaseTag]$($Version.NuGetPreReleaseTagV2)"
	Write-Host "##vso[task.setvariable variable=isPreRelease]$(-not ([String]::IsNullOrWhiteSpace($Version.NuGetPreReleaseTagV2)))"

}