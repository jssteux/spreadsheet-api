Write-Host "Starting Docker containers..." -ForegroundColor Cyan
docker-compose -f docker-compose-full.yml up -d
Write-Host "`nView logs with: docker-compose -f docker-compose-full.yml logs -f" -ForegroundColor Yellow
