# test-zip-import.ps1
# Script to test ZIP file imports with sample media files

param(
    [Parameter(Position=0)]
    [string]$ZipFile,

    [string]$ApiUrl = "http://localhost:8080",
    [string]$Username = "admin",
    [string]$Password = "admin123",
    [switch]$CreateSampleZip,
    [string]$SampleZipName = "test-import-with-media.zip",
    [switch]$SkipExport,
    [switch]$KeepFiles,
    [switch]$CleanupOnly
)

# Function to create a sample ZIP with spreadsheet and media files
function Create-SampleZipWithMedia {
    param(
        [string]$ZipFileName = "test-import-with-media.zip"
    )

    Write-Host "`nCreating sample ZIP file with media..." -ForegroundColor Cyan

    # Ensure we use full path for the ZIP file
    if (-not [System.IO.Path]::IsPathRooted($ZipFileName)) {
        $ZipFileName = Join-Path (Get-Location) $ZipFileName
    }

    # Create temp directory in current location
    $tempDir = Join-Path (Get-Location) "temp-import-$(Get-Random)"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    try {
        # Create sample CSV file
        $csvPath = Join-Path $tempDir "sample-spreadsheet.csv"
        Write-Host "  Creating sample CSV file..." -ForegroundColor Gray

        $csvContent = @"
Name,Category,Price,Quantity
Product A,Electronics,299.99,50
Product B,Electronics,199.99,75
Product C,Clothing,49.99,100
Product D,Clothing,79.99,60
Product E,Home,129.99,30
"@
        $csvContent | Out-File -FilePath $csvPath -Encoding UTF8

        # Create media directory
        $mediaDir = New-Item -ItemType Directory -Path (Join-Path $tempDir "media") -Force

        # Create sample image file (PNG)
        Write-Host "  Creating sample image file..." -ForegroundColor Gray
        $imagePath = Join-Path $mediaDir "sample-image.png"

        # Create a simple PNG file (1x1 pixel red image)
        $pngBytes = [byte[]](
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
            0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
            0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
            0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
            0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
            0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
            0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D,
            0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
            0x44, 0xAE, 0x42, 0x60, 0x82
        )
        [System.IO.File]::WriteAllBytes($imagePath, $pngBytes)

        # Create sample text document
        Write-Host "  Creating sample document file..." -ForegroundColor Gray
        $docPath = Join-Path $mediaDir "readme.txt"
        @"
Sample Media File for Spreadsheet Import Test
=============================================

This is a sample text document that will be included
as a media file in the spreadsheet import.

Created: $(Get-Date)
Purpose: Testing media file import functionality
"@ | Out-File -FilePath $docPath -Encoding UTF8

        # Create metadata.json for the import
        Write-Host "  Creating metadata file..." -ForegroundColor Gray
        $metadataPath = Join-Path $tempDir "metadata.json"

        # Get file sizes and content types for media files
        $imageInfo = Get-Item $imagePath
        $docInfo = Get-Item $docPath

        $metadata = @{
            name = "Test Import with Media"  # CORRECT: "name" not "spreadsheetName"
            description = "Sample spreadsheet with media files"
            sheets = @(
                @{
                    name = "Products"
                    filename = "sample-spreadsheet.csv"  # CORRECT: "filename" not "dataFile"
                }
            )
            mediaFiles = @(
                @{
                    filename = "sample-image.png"  # Just the filename, no path
                    size = $imageInfo.Length
                    contentType = "image/png"
                },
                @{
                    filename = "readme.txt"  # Just the filename, no path
                    size = $docInfo.Length
                    contentType = "text/plain"
                }
            )
        }

        # Convert to JSON and save without BOM
        $jsonContent = $metadata | ConvertTo-Json -Depth 10
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($metadataPath, $jsonContent, $utf8NoBom)

        # Create ZIP file
        Write-Host "  Creating ZIP archive..." -ForegroundColor Gray

        if (Test-Path $ZipFileName) {
            Remove-Item $ZipFileName -Force
        }

        # Use PowerShell's Compress-Archive cmdlet
        Compress-Archive -Path "$tempDir\*" -DestinationPath $ZipFileName -Force

        # Verify the ZIP was created
        if (-not (Test-Path $ZipFileName)) {
            throw "Failed to create ZIP file"
        }

        # Get file info
        $zipInfo = Get-Item $ZipFileName
        $sizeMB = [math]::Round($zipInfo.Length / 1MB, 2)

        Write-Host "`n✓ Created sample ZIP file: $ZipFileName ($sizeMB MB)" -ForegroundColor Green
        Write-Host "  Full path: $ZipFileName" -ForegroundColor Gray
        Write-Host "  Contents:" -ForegroundColor Gray
        Write-Host "    - 1 CSV file (sample-spreadsheet.csv)" -ForegroundColor Gray
        Write-Host "    - 2 Media files:" -ForegroundColor Gray
        Write-Host "      • sample-image.png (image)" -ForegroundColor Gray
        Write-Host "      • readme.txt (document)" -ForegroundColor Gray
        Write-Host "    - metadata.json (import configuration)" -ForegroundColor Gray

        return $ZipFileName

    } finally {
        # Cleanup temp directory
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force
        }
    }
}

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

# Function to import ZIP file
function Import-ZipFile {
    param(
        [string]$FilePath,
        [string]$ApiUrl,
        [string]$Token
    )

    if (-not (Test-Path $FilePath)) {
        Write-Host "File not found: $FilePath" -ForegroundColor Red
        return $null
    }

    $fileName = Split-Path $FilePath -Leaf
    $importUrl = "$ApiUrl/spreadsheets/import"

    # Check if it's a ZIP file and use the correct endpoint
    if ($fileName -like "*.zip") {
        $importUrl = "$ApiUrl/spreadsheets/import/zip"
    }

    Write-Host "`nImporting: $fileName" -ForegroundColor Cyan

    try {
        # Read file as bytes
        $fileBytes = [System.IO.File]::ReadAllBytes($FilePath)

        # Create multipart form using .NET HttpClient
        Add-Type -AssemblyName System.Net.Http

        $httpClient = New-Object System.Net.Http.HttpClient
        $httpClient.DefaultRequestHeaders.Add("Authorization", "Bearer $Token")

        $multipartContent = New-Object System.Net.Http.MultipartFormDataContent
        $fileStream = New-Object System.IO.MemoryStream(,$fileBytes)
        $streamContent = New-Object System.Net.Http.StreamContent($fileStream)

        # Set content type based on file extension
        if ($fileName -like "*.xlsx") {
            $streamContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        } elseif ($fileName -like "*.xls") {
            $streamContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("application/vnd.ms-excel")
        } elseif ($fileName -like "*.zip") {
            $streamContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("application/zip")
        } else {
            $streamContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("application/octet-stream")
        }

        $multipartContent.Add($streamContent, "file", $fileName)

        $response = $httpClient.PostAsync($importUrl, $multipartContent).Result
        $responseContent = $response.Content.ReadAsStringAsync().Result

        $fileStream.Dispose()
        $httpClient.Dispose()

        if ($response.IsSuccessStatusCode) {
            $result = $responseContent | ConvertFrom-Json
            Write-Host "  ✓ Import successful" -ForegroundColor Green
            Write-Host "    - Spreadsheet ID: $($result.id)" -ForegroundColor Gray
            Write-Host "    - Name: $($result.name)" -ForegroundColor Gray

            # Check for media files in response
            if ($result.mediaFiles) {
                Write-Host "    - Media files imported: $($result.mediaFiles.Count)" -ForegroundColor Green
                foreach ($media in $result.mediaFiles) {
                    Write-Host "      • $($media.filename)" -ForegroundColor Gray
                }
            }

            return $result
        } else {
            Write-Host "  ✗ Import failed: HTTP $($response.StatusCode)" -ForegroundColor Red
            Write-Host "  Response: $responseContent" -ForegroundColor Gray
            return $null
        }

    } catch {
        Write-Host "  ✗ Import failed: $_" -ForegroundColor Red
        return $null
    }
}

# Function to export spreadsheet as ZIP
function Export-Spreadsheet {
    param(
        [string]$SpreadsheetId,
        [string]$ApiUrl,
        [string]$Token,
        [string]$OutputPath = "."
    )

    $exportUrl = "$ApiUrl/spreadsheets/$SpreadsheetId/export/zip"

    Write-Host "`nExporting spreadsheet as ZIP ID: $SpreadsheetId" -ForegroundColor Cyan

    try {
        $headers = @{
            "Authorization" = "Bearer $Token"
        }

        # Generate output filename
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $outputFile = Join-Path $OutputPath "exported-$SpreadsheetId-$timestamp.zip"

        # Download the export
        Invoke-WebRequest -Uri $exportUrl -Method Get -Headers $headers -OutFile $outputFile

        # Get file info
        $fileInfo = Get-Item $outputFile
        $sizeMB = [math]::Round($fileInfo.Length / 1MB, 2)

        Write-Host "  ✓ Export successful" -ForegroundColor Green
        Write-Host "    - File: $($fileInfo.Name)" -ForegroundColor Gray
        Write-Host "    - Size: $sizeMB MB" -ForegroundColor Gray

        return $outputFile

    } catch {
        Write-Host "  ✗ Export failed: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            Write-Host "    - Status Code: $statusCode" -ForegroundColor Gray
        }
        return $null
    }
}

# Function to verify ZIP contents
function Compare-ZipContents {
    param(
        [string]$OriginalZip,
        [string]$ExportedZip
    )

    Write-Host "`n=== Verifying Export Contents ===" -ForegroundColor Cyan

    # Create temp directories for extraction
    $originalDir = New-Item -ItemType Directory -Path ".\temp-original-$(Get-Random)" -Force
    $exportedDir = New-Item -ItemType Directory -Path ".\temp-exported-$(Get-Random)" -Force

    try {
        # Extract both ZIPs
        Write-Host "Extracting ZIP files for comparison..." -ForegroundColor Gray
        Expand-Archive -Path $OriginalZip -DestinationPath $originalDir -Force
        Expand-Archive -Path $ExportedZip -DestinationPath $exportedDir -Force

        # Get all files from both directories
        $originalFiles = Get-ChildItem -Path $originalDir -Recurse -File | ForEach-Object {
            @{
                RelativePath = $_.FullName.Replace($originalDir.FullName, "").TrimStart("\", "/")
                Size = $_.Length
                Name = $_.Name
            }
        }

        $exportedFiles = Get-ChildItem -Path $exportedDir -Recurse -File | ForEach-Object {
            @{
                RelativePath = $_.FullName.Replace($exportedDir.FullName, "").TrimStart("\", "/")
                Size = $_.Length
                Name = $_.Name
            }
        }

        # Compare file counts
        Write-Host "`nFile Count Comparison:" -ForegroundColor Yellow
        Write-Host "  Original ZIP: $($originalFiles.Count) files" -ForegroundColor Gray
        Write-Host "  Exported ZIP: $($exportedFiles.Count) files" -ForegroundColor Gray

        # Check for media files specifically
        $originalMedia = $originalFiles | Where-Object { $_.RelativePath -like "*media*" }
        $exportedMedia = $exportedFiles | Where-Object { $_.RelativePath -like "*media*" }

        Write-Host "`nMedia Files:" -ForegroundColor Yellow
        Write-Host "  Original: $($originalMedia.Count) media files" -ForegroundColor Gray
        Write-Host "  Exported: $($exportedMedia.Count) media files" -ForegroundColor Gray

        # List media files
        if ($originalMedia.Count -gt 0) {
            Write-Host "`n  Original media files:" -ForegroundColor Gray
            foreach ($media in $originalMedia) {
                Write-Host "    - $($media.Name) ($('{0:N2}' -f ($media.Size / 1KB)) KB) - Path: $($media.RelativePath)" -ForegroundColor Gray
            }
        }

        if ($exportedMedia.Count -gt 0) {
            Write-Host "`n  Exported media files:" -ForegroundColor Gray
            foreach ($media in $exportedMedia) {
                Write-Host "    - $($media.Name) ($('{0:N2}' -f ($media.Size / 1KB)) KB) - Path: $($media.RelativePath)" -ForegroundColor Gray
            }
        }

        # Also check all files in exported ZIP
        Write-Host "`nAll files in exported ZIP:" -ForegroundColor Yellow
        foreach ($file in $exportedFiles) {
            Write-Host "    - $($file.RelativePath)" -ForegroundColor Gray
        }

        # Overall verification
        $allMediaExported = $true
        $missingFiles = @()

        foreach ($origMedia in $originalMedia) {
            # Check if file exists with same name (regardless of path)
            $found = $exportedFiles | Where-Object { $_.Name -eq $origMedia.Name }
            if (-not $found) {
                Write-Host "`n  ✗ Missing media file in export: $($origMedia.Name)" -ForegroundColor Red
                $missingFiles += $origMedia.Name
                $allMediaExported = $false
            } else {
                Write-Host "`n  ✓ Found exported file: $($found.Name) at $($found.RelativePath)" -ForegroundColor Green
            }
        }

        # Check if media count is different
        if ($exportedMedia.Count -ne $originalMedia.Count) {
            Write-Host "`n  ⚠ Media file count mismatch: Original=$($originalMedia.Count), Exported=$($exportedMedia.Count)" -ForegroundColor Yellow
        }

        if ($allMediaExported) {
            Write-Host "`n✓ All media files were successfully exported!" -ForegroundColor Green
        } else {
            Write-Host "`n✗ Media files missing in export: $($missingFiles -join ', ')" -ForegroundColor Red
        }

        return @{
            Success = $allMediaExported
            OriginalCount = $originalFiles.Count
            ExportedCount = $exportedFiles.Count
            MediaPreserved = ($exportedMedia.Count -eq $originalMedia.Count)
        }

    } finally {
        # Cleanup temp directories
        if (Test-Path $originalDir) {
            Remove-Item $originalDir -Recurse -Force
        }
        if (Test-Path $exportedDir) {
            Remove-Item $exportedDir -Recurse -Force
        }
    }
}

# Function to cleanup files
function Cleanup-Files {
    Write-Host "`n=== Cleaning up files ===" -ForegroundColor Cyan

    $filesToClean = @()
    $filesToClean += Get-ChildItem -Path "." -Filter "*.zip" -File
    $filesToClean += Get-ChildItem -Path "." -Filter "exported-*.zip" -File

    $filesToClean = $filesToClean | Sort-Object -Property FullName -Unique

    if ($filesToClean.Count -eq 0) {
        Write-Host "No files to clean." -ForegroundColor Green
        return
    }

    Write-Host "Files to clean:" -ForegroundColor Yellow
    foreach ($file in $filesToClean) {
        Write-Host "  - $($file.Name)" -ForegroundColor Gray
    }

    $confirm = Read-Host "`nDelete these files? (Y/N)"
    if ($confirm -eq 'Y') {
        foreach ($file in $filesToClean) {
            try {
                Remove-Item -Path $file.FullName -Force
                Write-Host "  ✓ Deleted: $($file.Name)" -ForegroundColor Green
            } catch {
                Write-Host "  ✗ Failed to delete: $($file.Name)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "Cleanup cancelled." -ForegroundColor Yellow
    }
}

# Get the script's directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrEmpty($scriptDir)) {
    $scriptDir = Get-Location
}

# Main script execution
Write-Host "=== Spreadsheet API ZIP Import Test ===" -ForegroundColor Cyan
Write-Host "Working Directory: $scriptDir" -ForegroundColor Gray
Write-Host "API URL: $ApiUrl" -ForegroundColor Gray

# Change to script directory
Push-Location $scriptDir

try {
    # Cleanup only mode
    if ($CleanupOnly) {
        Cleanup-Files
        exit
    }

    # Create sample ZIP if requested
    if ($CreateSampleZip) {
        # Delete any existing test ZIP files first - with full path
        $existingTestZip = Join-Path $scriptDir $SampleZipName
        if (Test-Path $existingTestZip) {
            Write-Host "Removing existing test ZIP file..." -ForegroundColor Yellow
            Remove-Item $existingTestZip -Force
        }

        $createdZip = Create-SampleZipWithMedia -ZipFileName $SampleZipName
        if (-not $ZipFile) {
            $ZipFile = $createdZip  # Already a full path from the function
        }
    }

    # If no ZIP file specified and no sample created, look for existing
    if (-not $ZipFile) {
        $existingZips = Get-ChildItem -Path $scriptDir -Filter "*.zip" -File
        if ($existingZips.Count -eq 0) {
            Write-Host "`nNo ZIP files found in current directory. Use -CreateSampleZip to create a test file." -ForegroundColor Yellow
            exit
        }
        # Use the first ZIP file found with full path
        $ZipFile = $existingZips[0].FullName
        Write-Host "`nUsing found ZIP file: $($existingZips[0].Name)" -ForegroundColor Yellow
    } else {
        # Ensure ZIP file path is absolute
        if (-not [System.IO.Path]::IsPathRooted($ZipFile)) {
            $ZipFile = Join-Path $scriptDir $ZipFile
        }
    }

    Write-Host "Using ZIP file: $ZipFile" -ForegroundColor Cyan

    # Authenticate
    Write-Host "`nAuthenticating..." -ForegroundColor Cyan
    $token = Get-AuthToken -ApiUrl $ApiUrl -Username $Username -Password $Password

    if (-not $token) {
        Write-Host "Failed to authenticate. Exiting." -ForegroundColor Red
        exit 1
    }

    Write-Host "  ✓ Authentication successful" -ForegroundColor Green

    # Import the ZIP file
    $importResult = Import-ZipFile -FilePath $ZipFile -ApiUrl $ApiUrl -Token $token

    # Test export if import was successful and not skipped
    if ($importResult -and -not $SkipExport) {
        Write-Host "`n=== Testing Export ===" -ForegroundColor Cyan

        # Wait a moment for the import to be fully processed
        Write-Host "Waiting for import to be processed..." -ForegroundColor Gray
        Start-Sleep -Seconds 2

        # Export the imported spreadsheet
        $exportedFile = Export-Spreadsheet -SpreadsheetId $importResult.id -ApiUrl $ApiUrl -Token $token

        if ($exportedFile) {
            Write-Host "`n✓ Round-trip test successful!" -ForegroundColor Green
            Write-Host "  - Imported: $ZipFile" -ForegroundColor Gray
            Write-Host "  - Exported: $exportedFile" -ForegroundColor Gray

            # Compare contents if both are ZIP files
            if ($ZipFile -like "*.zip" -and $exportedFile -like "*.zip") {
                $comparison = Compare-ZipContents -OriginalZip $ZipFile -ExportedZip $exportedFile

                if ($comparison.Success) {
                    Write-Host "`n✅ VERIFICATION PASSED: Export contains all imported content!" -ForegroundColor Green
                } else {
                    Write-Host "`n❌ VERIFICATION FAILED: Export content differs from import!" -ForegroundColor Red
                }
            }
        } else {
            Write-Host "`n✗ Export test failed" -ForegroundColor Red
        }
    }

    # Cleanup if not keeping files
    if (-not $KeepFiles) {
        Write-Host "`nAuto-cleanup in 3 seconds..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
        Cleanup-Files
    } else {
        Write-Host "`nFiles kept. Run with -CleanupOnly to clean up later." -ForegroundColor Yellow
    }

} finally {
    # Return to original directory
    Pop-Location
}

Write-Host "`n=== Done ===" -ForegroundColor Cyan