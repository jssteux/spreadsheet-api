Write-Host "Stopping PostgreSQL database..." -ForegroundColor Cyan
docker-compose down
Write-Host "✓ PostgreSQL stopped" -ForegroundColor Green
