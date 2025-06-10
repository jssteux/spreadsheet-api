Write-Host "Showing logs for all services..." -ForegroundColor Cyan
docker-compose -f docker-compose-full.yml logs -f
