# API Test Script v3 - Enhanced with Row/Column Operations
# Run this after starting the application to test all endpoints

$baseUrl = "http://localhost:8080"
$token = ""

Write-Host "Testing Spreadsheet API with Row/Column Operations..." -ForegroundColor Cyan

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
    description = "Created by API test with row/column operations"
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

# 4. Update cells (Initial data)
Write-Host "`n4. Creating initial data..." -ForegroundColor Yellow
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

        Write-Host "✓ Initial data created successfully" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to create initial data: $_" -ForegroundColor Red
        if ($_.ErrorDetails) {
            Write-Host "  Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
        }
    }

    # Helper function to display sheet data
    function Show-SheetData {
        param($sheetId, $title)
        Write-Host "`n  $title" -ForegroundColor Cyan
        try {
            $sheet = Invoke-RestMethod -Uri "$baseUrl/sheets/$sheetId" `
                -Method Get `
                -Headers $headers `
                -ErrorAction Stop

            if ($sheet.cells -and $sheet.cells.Count -gt 0) {
                # Group cells by row for better display
                $groupedCells = $sheet.cells | Group-Object row | Sort-Object Name
                foreach ($rowGroup in $groupedCells) {
                    $rowCells = $rowGroup.Group | Sort-Object col
                    $rowData = $rowCells | ForEach-Object { "[$($_.col)]='$($_.value)'" }
                    Write-Host "    Row $($rowGroup.Name): $($rowData -join ' ')" -ForegroundColor Gray
                }
            } else {
                Write-Host "    (No data)" -ForegroundColor Gray
            }
        } catch {
            Write-Host "    Error retrieving sheet data: $_" -ForegroundColor Red
        }
    }

    Show-SheetData $sheetId "Current sheet data:"

    # 5. TEST ROW OPERATIONS
    Write-Host "`n========== TESTING ROW OPERATIONS ==========" -ForegroundColor Magenta

    # 5a. Update existing row
    Write-Host "`n5a. Updating row 1 with new values..." -ForegroundColor Yellow
    $updateRowBody = @{
        values = @("Bob Wilson", "35", "Paris", "Engineer")
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/sheets/$sheetId/rows/1" `
            -Method Put `
            -Headers $headers `
            -Body $updateRowBody `
            -ContentType "application/json" `
            -ErrorAction Stop

        Write-Host "✓ Row 1 updated successfully" -ForegroundColor Green
        Show-SheetData $sheetId "After updating row 1:"
    } catch {
        Write-Host "✗ Failed to update row: $_" -ForegroundColor Red
        if ($_.ErrorDetails) {
            Write-Host "  Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
        }
    }

    # 5b. Append new row
    Write-Host "`n5b. Appending new row..." -ForegroundColor Yellow
    $appendRowBody = @{
        values = @("Alice Brown", "28", "Tokyo", "Designer")
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/sheets/$sheetId/rows" `
            -Method Post `
            -Headers $headers `
            -Body $appendRowBody `
            -ContentType "application/json" `
            -ErrorAction Stop

        Write-Host "✓ Row appended successfully: $($response.message)" -ForegroundColor Green
        Show-SheetData $sheetId "After appending row:"
    } catch {
        Write-Host "✗ Failed to append row: $_" -ForegroundColor Red
        if ($_.ErrorDetails) {
            Write-Host "  Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
        }
    }

    # 5c. Append another row for deletion test
    Write-Host "`n5c. Adding another row for deletion test..." -ForegroundColor Yellow
    $deleteTestRowBody = @{
        values = @("Test User", "99", "Delete Me", "Temporary")
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/sheets/$sheetId/rows" `
            -Method Post `
            -Headers $headers `
            -Body $deleteTestRowBody `
            -ContentType "application/json" `
            -ErrorAction Stop

        Write-Host "✓ Test row added successfully" -ForegroundColor Green
        Show-SheetData $sheetId "Before row deletion:"
    } catch {
        Write-Host "✗ Failed to add test row: $_" -ForegroundColor Red
    }

    # 5d. Delete single row
    Write-Host "`n5d. Deleting row 4 (the test row)..." -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/sheets/$sheetId/rows/4" `
            -Method Delete `
            -Headers $headers `
            -ErrorAction Stop

        Write-Host "✓ Row deleted successfully: $($response.message)" -ForegroundColor Green
        Show-SheetData $sheetId "After deleting row 4:"
    } catch {
        Write-Host "✗ Failed to delete row: $_" -ForegroundColor Red
        if ($_.ErrorDetails) {
            Write-Host "  Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
        }
    }

    # 6. TEST COLUMN OPERATIONS
    Write-Host "`n========== TESTING COLUMN OPERATIONS ==========" -ForegroundColor Magenta

    # 6a. Insert new column
    Write-Host "`n6a. Inserting new column at position 2..." -ForegroundColor Yellow
    $insertColumnBody = @{
        values = @("Country", "USA", "UK", "Japan")
        columnName = "Country"
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/sheets/$sheetId/columns/2" `
            -Method Post `
            -Headers $headers `
            -Body $insertColumnBody `
            -ContentType "application/json" `
            -ErrorAction Stop

        Write-Host "✓ Column inserted successfully: $($response.message)" -ForegroundColor Green
        Show-SheetData $sheetId "After inserting column at position 2:"
    } catch {
        Write-Host "✗ Failed to insert column: $_" -ForegroundColor Red
        if ($_.ErrorDetails) {
            Write-Host "  Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
        }
    }

    # 6b. Delete a column
    Write-Host "`n6b. Deleting column 4 (the last column)..." -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/sheets/$sheetId/columns/4" `
            -Method Delete `
            -Headers $headers `
            -ErrorAction Stop

        Write-Host "✓ Column deleted successfully: $($response.message)" -ForegroundColor Green
        Show-SheetData $sheetId "After deleting column 4:"
    } catch {
        Write-Host "✗ Failed to delete column: $_" -ForegroundColor Red
        if ($_.ErrorDetails) {
            Write-Host "  Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
        }
    }

    # 7. Test bulk row deletion
    Write-Host "`n7. Testing bulk row deletion..." -ForegroundColor Yellow

    # First add some rows for bulk deletion
    Write-Host "  Adding test rows for bulk deletion..." -ForegroundColor Gray
    for ($i = 0; $i -lt 3; $i++) {
        $bulkTestRowBody = @{
            values = @("Bulk$i", "$($i+50)", "TestCity$i")
        } | ConvertTo-Json

        try {
            Invoke-RestMethod -Uri "$baseUrl/sheets/$sheetId/rows" `
                -Method Post `
                -Headers $headers `
                -Body $bulkTestRowBody `
                -ContentType "application/json" `
                -ErrorAction Stop | Out-Null
        } catch {
            Write-Host "  Failed to add bulk test row $i" -ForegroundColor Red
        }
    }

    Show-SheetData $sheetId "Before bulk deletion:"

    # Delete multiple rows
    Write-Host "  Deleting 2 rows starting from row 4..." -ForegroundColor Gray
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/sheets/$sheetId/rows?startRow=4&count=2" `
            -Method Delete `
            -Headers $headers `
            -ErrorAction Stop

        Write-Host "✓ Bulk row deletion successful: $($response.message)" -ForegroundColor Green
        Show-SheetData $sheetId "After bulk deletion:"
    } catch {
        Write-Host "✗ Failed bulk row deletion: $_" -ForegroundColor Red
        if ($_.ErrorDetails) {
            Write-Host "  Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
        }
    }

    # 8. Final sheet state
    Write-Host "`n8. Final sheet state..." -ForegroundColor Yellow
    Show-SheetData $sheetId "Final sheet data:"

} else {
    Write-Host "  No sheets found in spreadsheet" -ForegroundColor Red
}

# 9. List spreadsheets
Write-Host "`n9. Listing all spreadsheets..." -ForegroundColor Yellow
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
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "✓ Enhanced API Test Complete!" -ForegroundColor Green
Write-Host "  Tested: Row/Column Operations" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Cyan

Write-Host "`nNew Endpoints Tested:" -ForegroundColor Yellow
Write-Host "  Row Operations:" -ForegroundColor White
Write-Host "    PUT /sheets/{id}/rows/{rowIndex} - Update row" -ForegroundColor Gray
Write-Host "    POST /sheets/{id}/rows - Append row" -ForegroundColor Gray
Write-Host "    DELETE /sheets/{id}/rows/{rowIndex} - Delete single row" -ForegroundColor Gray
Write-Host "    DELETE /sheets/{id}/rows?startRow={start}&count={count} - Delete multiple rows" -ForegroundColor Gray
Write-Host "  Column Operations:" -ForegroundColor White
Write-Host "    POST /sheets/{id}/columns/{columnIndex} - Insert column" -ForegroundColor Gray
Write-Host "    DELETE /sheets/{id}/columns/{columnIndex} - Delete column" -ForegroundColor Gray

Write-Host "`nAccess Points:" -ForegroundColor Yellow
Write-Host "  - API Base URL: $baseUrl" -ForegroundColor White
Write-Host "  - H2 Console: http://localhost:8080/h2-console" -ForegroundColor White
Write-Host "    - JDBC URL: jdbc:h2:mem:testdb" -ForegroundColor Gray
Write-Host "    - Username: sa" -ForegroundColor Gray
Write-Host "    - Password: (leave empty)" -ForegroundColor Gray

Write-Host "`nAuthentication Token:" -ForegroundColor Yellow
Write-Host "  $token" -ForegroundColor White

Write-Host "`nExample cURL commands for new endpoints:" -ForegroundColor Yellow
Write-Host '  # Update row 1' -ForegroundColor Gray
Write-Host "  curl -X PUT -H `"Authorization: Bearer $token`" -H `"Content-Type: application/json`" -d '{`"values`":[`"John`",`"30`",`"NYC`"]}' $baseUrl/sheets/$sheetId/rows/1" -ForegroundColor White
Write-Host '  # Append new row' -ForegroundColor Gray
Write-Host "  curl -X POST -H `"Authorization: Bearer $token`" -H `"Content-Type: application/json`" -d '{`"values`":[`"Alice`",`"25`",`"LA`"]}' $baseUrl/sheets/$sheetId/rows" -ForegroundColor White
Write-Host '  # Insert column at position 2' -ForegroundColor Gray
Write-Host "  curl -X POST -H `"Authorization: Bearer $token`" -H `"Content-Type: application/json`" -d '{`"values`":[`"Country`",`"USA`",`"UK`"]}' $baseUrl/sheets/$sheetId/columns/2" -ForegroundColor White
Write-Host '  # Delete row 3' -ForegroundColor Gray
Write-Host "  curl -X DELETE -H `"Authorization: Bearer $token`" $baseUrl/sheets/$sheetId/rows/3" -ForegroundColor White