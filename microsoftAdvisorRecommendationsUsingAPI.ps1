<##########################################################################################################

	.SYNOPSIS
		Use Azure Rest API to collect generated Azure Advisor reports for all subscriptions.
	
	.INPUTS
        None.

	.OUTPUTS
		No direct output. Script creates new csv files in ".\AzureAdvisorReports\" during course of script.
 
##########################################################################################################>

# Sign in with your Azure account
Connect-AzAccount

# Debugging, confirm it works with a single subscription
# $subs = Get-AzSubscription | Where-Object { $_.Name -eq "CSS Supportability" }

# Variables
$subs = Get-AzSubscription
$token = Get-AzAccessToken
$bearerToken = $token.Token
$exportFolder = ".\AzureAdvisorReports\"

# Create folder if it doesn't exist
If (!(Test-Path $exportFolder)) {
	New-Item -ItemType Directory -Force -Path $exportFolder;
}

# Get Azure Advisor recommendations for the sub from the API
foreach ($sub in $subs) {
	$subscription = $sub.Id

	# https://docs.microsoft.com/en-us/rest/api/advisor/recommendations/list
	$parameters = @{
		Uri         = "https://management.azure.com/subscriptions/$($subscription)/providers/Microsoft.Advisor/recommendations?api-version=2017-04-19"
		ContentType = 'application/json'
		Method      = 'GET'
		headers     = @{
			authorization = "Bearer $bearerToken"
			host          = 'management.azure.com'
		}
	}

	try {
		# Call API
		$results = Invoke-RestMethod @parameters

		# Export to CSV file
		$results.value | Select-Object -Property id, name, type, { $_.properties.category }, { $_.properties.impact }, { $_.properties.impactedField }, { $_.properties.impactedValue }, { $_.properties.lastUpdated }, { $_.properties.recommedationTypeId }, { $_.properties.shortDescription.problem }, { $_.properties.shortDescription.solution }, { $_.properties.extendedProperties.assessmentKey }, { $_.properties.extendedProperties.score }, { $_.properties.resourceMetadata.resourceId }, { $_.properties.resourceMetadata.source } | Export-Csv -Path "$($exportFolder)$($subscription).csv" -NoTypeInformation

		Write-Host "Printed Azure Advisor reports for subscription $($subscription) at $($exportFolder)$($subscription).csv"
	}
 catch {
		Write-Host "Error on $($subscription)"
		Write-Host $_
	}
}

Write-Host "Finished script"
