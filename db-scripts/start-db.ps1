Write-Host "Starting PostgreSQL database..." -ForegroundColor Cyan
docker-compose up -d postgres
Write-Host "`nWaiting for PostgreSQL to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Check if database is ready
$attempts = 0
$maxAttempts = 30
while ($attempts -lt $maxAttempts) {
    try {
        docker exec spreadsheet-postgres pg_isready -U spreadsheet_user | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ PostgreSQL is ready!" -ForegroundColor Green
            break
        }
    } catch {}
    $attempts++
    Write-Host "  Waiting... ($attempts/$maxAttempts)" -ForegroundColor Gray
    Start-Sleep -Seconds 2
}

if ($attempts -eq $maxAttempts) {
    Write-Host "✗ PostgreSQL failed to start" -ForegroundColor Red
    exit 1
}

Write-Host "`nPostgreSQL is running on port 5432" -ForegroundColor Green
Write-Host "Connection details:" -ForegroundColor Yellow
Write-Host "  Host: localhost" -ForegroundColor White
Write-Host "  Port: 5432" -ForegroundColor White
Write-Host "  Database: spreadsheet_db" -ForegroundColor White
Write-Host "  Username: spreadsheet_user" -ForegroundColor White
Write-Host "  Password: spreadsheet_pass" -ForegroundColor White
