Write-Host "Creating database tables manually..." -ForegroundColor Cyan

# Check if postgres container is running
$pgContainer = docker ps --filter "name=spreadsheet-postgres" --format "{{.Names}}"
if (-not $pgContainer) {
    Write-Host "PostgreSQL container is not running!" -ForegroundColor Red
    exit 1
}

# Execute SQL file
Write-Host "Creating tables..." -ForegroundColor Yellow
docker exec -i spreadsheet-postgres psql -U spreadsheet_user -d spreadsheet_db < create-tables.sql

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Tables created successfully!" -ForegroundColor Green
    
    # Verify tables
    Write-Host "`nVerifying tables..." -ForegroundColor Yellow
    docker exec spreadsheet-postgres psql -U spreadsheet_user -d spreadsheet_db -c "\dt"
} else {
    Write-Host "✗ Failed to create tables!" -ForegroundColor Red
}
