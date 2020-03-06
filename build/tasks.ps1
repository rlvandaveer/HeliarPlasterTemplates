# Defines all of the psake tasks used to build, test, and publish this project

Include "build-functions.ps1"
Include "package-functions.ps1"
Include "version-functions.ps1"

Properties {
	$BuildContext = @{
		distributionPath = (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "dist")
		rootPath = (Split-Path -Parent $PSScriptRoot)
		sourcePath = (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "source")
		testPath = (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "tests")
		versionInfo = $null
		nugetSource = $null
	}
}

Task default -depends Test

Task Clean -description "Deletes all build artifacts and the distribution (dist) folder" {

	Remove-Item $BuildContext.distributionPath -Recurse -Force -ErrorAction SilentlyContinue

}

Task Build -depends Clean, Init -description "Creates ready to distribute modules with all required files" {

	$BuildContext.versionInfo = @{ MajorMinorPatch = '1.0.0'; NuGetVersionV2 = '1.0.0' } #GetVersionInfo

	New-Item $BuildContext.distributionPath -ItemType Directory

	Build-Module -BuildContext $BuildContext
	PackModule -BuildContext $BuildContext

}

Task Init -description "Initializes the build chain by installing dependencies" {

	$psd = Get-Module PSDepend -listAvailable
	if ($null -eq $psd) {
	  Install-Module PSDepend -AcceptLicense -Force
	}
	Import-Module PSDepend

	Invoke-PSDepend $PSScriptRoot -Force

}

Task Test -depends Init, Build -description "Executes all unit tests" {

	$testOutput = (Join-Path -Path $BuildContext.rootPath -ChildPath 'Test-Results.xml')
	Invoke-Pester -Script $BuildContext.testPath -OutputFile $testOutput -OutputFormat NUnitXml
	Write-Host "Test output found: " + (Test-Path -Path $testOutput)
}

Task Publish -depends Init -description "Publishes the HeliarStandardsAzure module and all submodules to Azure Artifacts" {

	Assert (Test-Path -Path (Join-Path -Path $BuildContext.DistributionPath -ChildPath "*") -Include "*.nupkg") -failureMessage "Module not built. Please build before publishing or use the BuildAndPublish task."
	PublishModule -BuildContext $BuildContext

}

Task BuildAndPublish -depends Build, Test, Publish