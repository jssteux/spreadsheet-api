Write-Host "Building and running Spring Boot API in Docker..." -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Stop existing containers
Write-Host "`nStopping existing containers..." -ForegroundColor Yellow
docker-compose -f docker-compose-full.yml down

# Build and start all services
Write-Host "`nBuilding API image..." -ForegroundColor Yellow
docker-compose -f docker-compose-full.yml build

Write-Host "`nStarting all services..." -ForegroundColor Yellow
docker-compose -f docker-compose-full.yml up -d

# Wait for services to be ready
Write-Host "`nWaiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Check if API is healthy
$attempts = 0
$maxAttempts = 30
while ($attempts -lt $maxAttempts) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080" -Method Get -ErrorAction Stop
        Write-Host "`n✓ API is ready!" -ForegroundColor Green
        break
    } catch {
        $attempts++
        Write-Host "  Waiting for API... ($attempts/$maxAttempts)" -ForegroundColor Gray
        Start-Sleep -Seconds 2
    }
}

if ($attempts -eq $maxAttempts) {
    Write-Host "`n✗ API failed to start. Check logs with: docker logs spreadsheet-api" -ForegroundColor Red
    exit 1
}

Write-Host "`n✓ All services are running!" -ForegroundColor Green
Write-Host "`nAccess points:" -ForegroundColor Yellow
Write-Host "  API: http://localhost:8080" -ForegroundColor White
Write-Host "  PostgreSQL: localhost:5432" -ForegroundColor White
Write-Host "  PgAdmin: http://localhost:5050" -ForegroundColor White
Write-Host "`nView logs:" -ForegroundColor Yellow
Write-Host "  docker logs spreadsheet-api -f" -ForegroundColor White
