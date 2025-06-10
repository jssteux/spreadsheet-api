Write-Host "PostgreSQL logs:" -ForegroundColor Cyan
docker logs spreadsheet-postgres --tail 50 -f
