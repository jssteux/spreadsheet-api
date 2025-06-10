Write-Host "Recreating database tables..." -ForegroundColor Cyan

# Drop existing tables
Write-Host "Dropping existing tables..." -ForegroundColor Yellow
docker exec spreadsheet-postgres psql -U spreadsheet_user -d spreadsheet_db -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO spreadsheet_user;"

Write-Host "Tables dropped. The API will recreate them on restart." -ForegroundColor Green
