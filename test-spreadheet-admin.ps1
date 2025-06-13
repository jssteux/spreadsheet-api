# delete-spreadsheet.ps1
# Script to delete a spreadsheet from the API

param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$SpreadsheetId,

    [string]$ApiUrl = "http://localhost:8080",
    [string]$Username = "admin",
    [string]$Password = "admin123",
    [switch]$Force,
    [switch]$ListFirst
)

# Function to authenticate and get JWT token
function Get-AuthToken {
    param(
        [string]$ApiUrl,
        [string]$Username,
        [string]$Password
    )

    $loginUrl = "$ApiUrl/auth/login"
    $body = @{
        username = $Username
        password = $Password
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri $loginUrl -Method Post -Body $body -ContentType "application/json"
        return $response.token
    } catch {
        Write-Host "Authentication failed: $_" -ForegroundColor Red
        return $null
    }
}

# Function to get spreadsheet details
function Get-SpreadsheetDetails {
    param(
        [string]$SpreadsheetId,
        [string]$ApiUrl,
        [string]$Token
    )

    $detailsUrl = "$ApiUrl/spreadsheets/$SpreadsheetId"

    try {
        $headers = @{
            "Authorization" = "Bearer $Token"
        }

        $response = Invoke-RestMethod -Uri $detailsUrl -Method Get -Headers $headers
        return $response
    } catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-Host "Spreadsheet not found (ID: $SpreadsheetId)" -ForegroundColor Red
        } else {
            Write-Host "Failed to get spreadsheet details: $_" -ForegroundColor Red
        }
        return $null
    }
}

# Function to list all spreadsheets
function Get-AllSpreadsheets {
    param(
        [string]$ApiUrl,
        [string]$Token
    )

    $listUrl = "$ApiUrl/spreadsheets"

    try {
        $headers = @{
            "Authorization" = "Bearer $Token"
        }

        $response = Invoke-RestMethod -Uri $listUrl -Method Get -Headers $headers
        return $response
    } catch {
        Write-Host "Failed to list spreadsheets: $_" -ForegroundColor Red
        return $null
    }
}

# Function to delete a spreadsheet
function Remove-Spreadsheet {
    param(
        [string]$SpreadsheetId,
        [string]$ApiUrl,
        [string]$Token
    )

    $deleteUrl = "$ApiUrl/spreadsheets/$SpreadsheetId"

    Write-Host "Deleting spreadsheet ID: $SpreadsheetId" -ForegroundColor Yellow

    try {
        $headers = @{
            "Authorization" = "Bearer $Token"
        }

        $response = Invoke-RestMethod -Uri $deleteUrl -Method Delete -Headers $headers

        Write-Host "✓ Spreadsheet deleted successfully" -ForegroundColor Green
        return $true

    } catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-Host "✗ Spreadsheet not found (ID: $SpreadsheetId)" -ForegroundColor Red
        } elseif ($_.Exception.Response.StatusCode -eq 403) {
            Write-Host "✗ Access denied - insufficient permissions" -ForegroundColor Red
        } else {
            Write-Host "✗ Delete failed: $_" -ForegroundColor Red
        }
        return $false
    }
}

# Main script execution
Write-Host "=== Spreadsheet Deletion Tool ===" -ForegroundColor Cyan
Write-Host "API URL: $ApiUrl" -ForegroundColor Gray

# Authenticate
Write-Host "`nAuthenticating..." -ForegroundColor Cyan
$token = Get-AuthToken -ApiUrl $ApiUrl -Username $Username -Password $Password

if (-not $token) {
    Write-Host "Failed to authenticate. Exiting." -ForegroundColor Red
    exit 1
}

Write-Host "✓ Authentication successful" -ForegroundColor Green

# List spreadsheets first if requested
if ($ListFirst) {
    Write-Host "`n=== Available Spreadsheets ===" -ForegroundColor Cyan
    
    $spreadsheets = Get-AllSpreadsheets -ApiUrl $ApiUrl -Token $token
    
    if ($spreadsheets -and $spreadsheets.Count -gt 0) {
        Write-Host "Found $($spreadsheets.Count) spreadsheet(s):" -ForegroundColor Green
        Write-Host ""
        
        foreach ($sheet in $spreadsheets) {
            Write-Host "ID: $($sheet.id)" -ForegroundColor White
            Write-Host "  Name: $($sheet.name)" -ForegroundColor Gray
            if ($sheet.description) {
                Write-Host "  Description: $($sheet.description)" -ForegroundColor Gray
            }
            if ($sheet.createdAt) {
                Write-Host "  Created: $($sheet.createdAt)" -ForegroundColor Gray
            }
            if ($sheet.mediaFiles -and $sheet.mediaFiles.Count -gt 0) {
                Write-Host "  Media Files: $($sheet.mediaFiles.Count)" -ForegroundColor Gray
            }
            Write-Host ""
        }
    } else {
        Write-Host "No spreadsheets found." -ForegroundColor Yellow
    }
    
    Write-Host "Use the ID from above to delete a specific spreadsheet." -ForegroundColor Yellow
    exit 0
}

# Get spreadsheet details before deletion
Write-Host "`nRetrieving spreadsheet details..." -ForegroundColor Cyan
$spreadsheet = Get-SpreadsheetDetails -SpreadsheetId $SpreadsheetId -ApiUrl $ApiUrl -Token $token

if (-not $spreadsheet) {
    Write-Host "Cannot proceed with deletion - spreadsheet not found." -ForegroundColor Red
    exit 1
}

# Display spreadsheet information
Write-Host "`n=== Spreadsheet to Delete ===" -ForegroundColor Yellow
Write-Host "ID: $($spreadsheet.id)" -ForegroundColor White
Write-Host "Name: $($spreadsheet.name)" -ForegroundColor Gray
if ($spreadsheet.description) {
    Write-Host "Description: $($spreadsheet.description)" -ForegroundColor Gray
}
if ($spreadsheet.createdAt) {
    Write-Host "Created: $($spreadsheet.createdAt)" -ForegroundColor Gray
}
if ($spreadsheet.sheets -and $spreadsheet.sheets.Count -gt 0) {
    Write-Host "Sheets: $($spreadsheet.sheets.Count)" -ForegroundColor Gray
    foreach ($sheet in $spreadsheet.sheets) {
        Write-Host "  - $($sheet.name)" -ForegroundColor Gray
    }
}
if ($spreadsheet.mediaFiles -and $spreadsheet.mediaFiles.Count -gt 0) {
    Write-Host "Media Files: $($spreadsheet.mediaFiles.Count)" -ForegroundColor Gray
    foreach ($media in $spreadsheet.mediaFiles) {
        Write-Host "  - $($media.filename)" -ForegroundColor Gray
    }
}

# Confirmation unless -Force is used
if (-not $Force) {
    Write-Host "`n⚠️  WARNING: This action cannot be undone!" -ForegroundColor Red
    $confirmation = Read-Host "`nAre you sure you want to delete this spreadsheet? (type 'DELETE' to confirm)"
    
    if ($confirmation -ne "DELETE") {
        Write-Host "Deletion cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Perform the deletion
Write-Host "`n=== Deleting Spreadsheet ===" -ForegroundColor Red
$success = Remove-Spreadsheet -SpreadsheetId $SpreadsheetId -ApiUrl $ApiUrl -Token $token

if ($success) {
    Write-Host "`n🗑️  Spreadsheet '$($spreadsheet.name)' has been deleted." -ForegroundColor Green
} else {
    Write-Host "`n❌ Failed to delete spreadsheet." -ForegroundColor Red
    exit 1
}

# Write-Host "`n=== Done ===" -ForegroundColor Cyan