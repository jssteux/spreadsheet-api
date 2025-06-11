Write-Host "Rebuilding API image..." -ForegroundColor Cyan
docker-compose -f docker-compose-full.yml build --no-cache api
docker-compose -f docker-compose-full.yml up -d api
Write-Host "✓ Rebuild complete. Run start.ps1 to start services." -ForegroundColor Green
