# API Test Script v2
# Run this after starting the application to test all endpoints

$baseUrl = "http://localhost:8080"
$token = ""

Write-Host "Testing Spreadsheet API..." -ForegroundColor Cyan

# Test if API is running with better error handling
Write-Host "Checking API status..." -ForegroundColor Yellow
$apiRunning = $false
try {
    # Try a simple GET to root
    $test = Invoke-WebRequest -Uri $baseUrl -Method Get -TimeoutSec 5 -ErrorAction Stop
    $apiRunning = $true
    Write-Host "✓ API is running" -ForegroundColor Green
} catch {
    # Even if we get an error response, if the server responded, it's running
    if ($_.Exception.Response) {
        $apiRunning = $true
        Write-Host "✓ API is running (responded with status: $($_.Exception.Response.StatusCode))" -ForegroundColor Green
    } else {
        Write-Host "✗ API is not accessible at $baseUrl" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        exit 1
    }
}

# 1. Register new user
Write-Host "`n1. Registering new user..." -ForegroundColor Yellow
$registerBody = @{
    username = "apitest"
    email = "apitest@example.com"
    password = "test123"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/auth/register" `
        -Method Post `
        -Body $registerBody `
        -ContentType "application/json" `
        -ErrorAction Stop
    Write-Host "✓ Registration successful: $($response.message)" -ForegroundColor Green
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 400 -or $statusCode -eq 409) {
        Write-Host "  User already exists (this is OK)" -ForegroundColor Gray
    } else {
        Write-Host "✗ Registration failed: $_" -ForegroundColor Red
        Write-Host "  Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
}

# 2. Login
Write-Host "`n2. Logging in as admin..." -ForegroundColor Yellow
$loginBody = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    Write-Host "  Attempting login to: $baseUrl/auth/login" -ForegroundColor Gray
    $response = Invoke-RestMethod -Uri "$baseUrl/auth/login" `
        -Method Post `
        -Body $loginBody `
        -ContentType "application/json" `
        -ErrorAction Stop
    
    $token = $response.token
    Write-Host "✓ Login successful!" -ForegroundColor Green
    Write-Host "  Token (first 50 chars): $($token.Substring(0, [Math]::Min(50, $token.Length)))..." -ForegroundColor Gray
} catch {
    Write-Host "✗ Login failed!" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
    if ($_.ErrorDetails) {
        Write-Host "  Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
    Write-Host "`n  Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Check if you see 'Default admin user created' in the Spring Boot console" -ForegroundColor White
    Write-Host "  2. Try accessing H2 Console at http://localhost:8080/h2-console" -ForegroundColor White
    Write-Host "  3. Check if USERS table exists and has admin user" -ForegroundColor White
    exit 1
}

# 3. Create spreadsheet
Write-Host "`n3. Creating spreadsheet..." -ForegroundColor Yellow
$headers = @{
    Authorization = "Bearer $token"
}

$spreadsheetBody = @{
    name = "Test Spreadsheet $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    description = "Created by API test"
} | ConvertTo-Json

try {
    $spreadsheet = Invoke-RestMethod -Uri "$baseUrl/spreadsheets" `
        -Method Post `
        -Headers $headers `
        -Body $spreadsheetBody `
        -ContentType "application/json" `
        -ErrorAction Stop
    
    Write-Host "✓ Spreadsheet created with ID: $($spreadsheet.id)" -ForegroundColor Green
    Write-Host "  Name: $($spreadsheet.name)" -ForegroundColor Gray
    Write-Host "  Sheets: $($spreadsheet.sheets.Count)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Failed to create spreadsheet: $_" -ForegroundColor Red
    if ($_.ErrorDetails) {
        Write-Host "  Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
    exit 1
}

# 4. Update cells
Write-Host "`n4. Updating cells..." -ForegroundColor Yellow
if ($spreadsheet.sheets -and $spreadsheet.sheets.Count -gt 0) {
    $sheetId = $spreadsheet.sheets[0].id
    Write-Host "  Using sheet ID: $sheetId" -ForegroundColor Gray
    
    $cellsBody = @{
        cells = @(
            @{ row = 0; col = 0; value = "Name" },
            @{ row = 0; col = 1; value = "Age" },
            @{ row = 0; col = 2; value = "City" },
            @{ row = 1; col = 0; value = "John Doe" },
            @{ row = 1; col = 1; value = "30" },
            @{ row = 1; col = 2; value = "New York" },
            @{ row = 2; col = 0; value = "Jane Smith" },
            @{ row = 2; col = 1; value = "25" },
            @{ row = 2; col = 2; value = "London" }
        )
    } | ConvertTo-Json -Depth 3
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/sheets/$sheetId/cells" `
            -Method Put `
            -Headers $headers `
            -Body $cellsBody `
            -ContentType "application/json" `
            -ErrorAction Stop
        
        Write-Host "✓ Cells updated successfully" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to update cells: $_" -ForegroundColor Red
        if ($_.ErrorDetails) {
            Write-Host "  Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
        }
    }
    
    # 5. Get sheet data
    Write-Host "`n5. Getting sheet data..." -ForegroundColor Yellow
    try {
        $sheet = Invoke-RestMethod -Uri "$baseUrl/sheets/$sheetId" `
            -Method Get `
            -Headers $headers `
            -ErrorAction Stop
        
        Write-Host "✓ Sheet retrieved successfully" -ForegroundColor Green
        Write-Host "  Sheet name: $($sheet.name)" -ForegroundColor Gray
        Write-Host "  Total cells: $($sheet.cells.Count)" -ForegroundColor Gray
        
        if ($sheet.cells -and $sheet.cells.Count -gt 0) {
            Write-Host "  Cell data:" -ForegroundColor Gray
            $sheet.cells | ForEach-Object {
                Write-Host "    [$($_.row),$($_.col)] = '$($_.value)'" -ForegroundColor Gray
            }
        }
    } catch {
        Write-Host "✗ Failed to get sheet data: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  No sheets found in spreadsheet" -ForegroundColor Red
}

# 6. List spreadsheets
Write-Host "`n6. Listing all spreadsheets..." -ForegroundColor Yellow
try {
    $spreadsheets = Invoke-RestMethod -Uri "$baseUrl/spreadsheets" `
        -Method Get `
        -Headers $headers `
        -ErrorAction Stop
    
    Write-Host "✓ Found $($spreadsheets.Count) spreadsheet(s)" -ForegroundColor Green
    $spreadsheets | ForEach-Object {
        Write-Host "  - $($_.name) (ID: $($_.id), Owner: $($_.ownerUsername))" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ Failed to list spreadsheets: $_" -ForegroundColor Red
}

# Summary
Write-Host "`n" -NoNewline
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "✓ API Test Complete!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan

Write-Host "`nAccess Points:" -ForegroundColor Yellow
Write-Host "  - API Base URL: $baseUrl" -ForegroundColor White
Write-Host "  - H2 Console: http://localhost:8080/h2-console" -ForegroundColor White
Write-Host "    - JDBC URL: jdbc:h2:mem:testdb" -ForegroundColor Gray
Write-Host "    - Username: sa" -ForegroundColor Gray
Write-Host "    - Password: (leave empty)" -ForegroundColor Gray

Write-Host "`nAuthentication Token:" -ForegroundColor Yellow
Write-Host "  $token" -ForegroundColor White

Write-Host "`nExample cURL commands:" -ForegroundColor Yellow
Write-Host '  # Get spreadsheets' -ForegroundColor Gray
Write-Host "  curl -H `"Authorization: Bearer $token`" $baseUrl/spreadsheets" -ForegroundColor White
Write-Host '  # Create new sheet' -ForegroundColor Gray
Write-Host "  curl -X POST -H `"Authorization: Bearer $token`" -H `"Content-Type: application/json`" -d '{`"name`":`"Sheet2`"}' $baseUrl/sheets/spreadsheet/$($spreadsheet.id)" -ForegroundColor White