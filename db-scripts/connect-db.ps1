Write-Host "Connecting to PostgreSQL database..." -ForegroundColor Cyan
docker exec -it spreadsheet-postgres psql -U spreadsheet_user -d spreadsheet_db
