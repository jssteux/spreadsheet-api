Write-Host "Stopping all Docker containers..." -ForegroundColor Cyan
docker-compose -f docker-compose-full.yml down
Write-Host "✓ All containers stopped" -ForegroundColor Green
