Write-Host "Starting PostgreSQL and PgAdmin..." -ForegroundColor Cyan
docker-compose up -d
Write-Host "`nWaiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "`n✓ All services started!" -ForegroundColor Green
Write-Host "`nAccess points:" -ForegroundColor Yellow
Write-Host "  PostgreSQL: localhost:5432" -ForegroundColor White
Write-Host "  PgAdmin: http://localhost:5050" -ForegroundColor White
Write-Host "    Email: admin@example.com" -ForegroundColor Gray
Write-Host "    Password: admin" -ForegroundColor Gray
