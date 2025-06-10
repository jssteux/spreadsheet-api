# Setup PostgreSQL with Docker for Spreadsheet API
param(
    [string]$ProjectPath = (Get-Location).Path
)

# Function to create directory
function Create-Directory {
    param($path)
    if (!(Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        Write-Host "✓ Created directory: $path" -ForegroundColor Green
    }
}

Write-Host "Setting up PostgreSQL with Docker for Spreadsheet API" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "Project Path: $ProjectPath" -ForegroundColor Yellow

# Check if Docker is installed
Write-Host "`nChecking Docker installation..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "✓ Docker found: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker is not installed or not in PATH" -ForegroundColor Red
    Write-Host "  Please install Docker Desktop from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    exit 1
}

# Check if Docker is running
Write-Host "Checking if Docker is running..." -ForegroundColor Yellow
try {
    docker ps | Out-Null
    Write-Host "✓ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Create docker-compose.yml
Write-Host "`nCreating Docker configuration files..." -ForegroundColor Yellow
$dockerComposeContent = @'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: spreadsheet-postgres
    environment:
      POSTGRES_DB: spreadsheet_db
      POSTGRES_USER: spreadsheet_user
      POSTGRES_PASSWORD: spreadsheet_pass
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - spreadsheet-network

  pgadmin:
    image: dpage/pgadmin4:latest
    container_name: spreadsheet-pgadmin
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@example.com
      PGADMIN_DEFAULT_PASSWORD: admin
      PGADMIN_CONFIG_SERVER_MODE: 'False'
      PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED: 'False'
    ports:
      - "5050:80"
    depends_on:
      - postgres
    networks:
      - spreadsheet-network

volumes:
  postgres_data:

networks:
  spreadsheet-network:
    driver: bridge
'@

$dockerComposePath = Join-Path $ProjectPath "docker-compose.yml"
Set-Content -Path $dockerComposePath -Value $dockerComposeContent -Encoding UTF8
Write-Host "✓ Created docker-compose.yml" -ForegroundColor Green

# Create application-postgres.properties
Write-Host "Creating PostgreSQL configuration..." -ForegroundColor Yellow
$postgresPropertiesContent = @'
# PostgreSQL Configuration
spring.datasource.url=jdbc:postgresql://localhost:5432/spreadsheet_db
spring.datasource.username=spreadsheet_user
spring.datasource.password=spreadsheet_pass
spring.datasource.driver-class-name=org.postgresql.Driver

# JPA Configuration for PostgreSQL
spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true

# Keep other configurations
server.port=8080
spring.servlet.multipart.max-file-size=10MB
spring.servlet.multipart.max-request-size=10MB
media.upload.path=./uploads
jwt.secret=ThisIsASecretKeyForJWTTokenGenerationPleaseChangeInProduction2023
jwt.expiration=86400000

# Logging
logging.level.com.example.spreadsheet=INFO
logging.level.org.springframework.security=INFO
logging.level.org.hibernate.SQL=DEBUG

# Character encoding
spring.http.encoding.charset=UTF-8
spring.http.encoding.enabled=true
spring.http.encoding.force=true
'@

$resourcesPath = Join-Path $ProjectPath "src\main\resources"
Create-Directory $resourcesPath
$postgresPropertiesPath = Join-Path $resourcesPath "application-postgres.properties"
$utf8NoBOM = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($postgresPropertiesPath, $postgresPropertiesContent, $utf8NoBOM)
Write-Host "✓ Created application-postgres.properties" -ForegroundColor Green

# Create .env file for environment variables
$envContent = @'
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=spreadsheet_db
DB_USER=spreadsheet_user
DB_PASSWORD=spreadsheet_pass

# PgAdmin Configuration
PGADMIN_EMAIL=admin@example.com
PGADMIN_PASSWORD=admin
'@

$envPath = Join-Path $ProjectPath ".env"
Set-Content -Path $envPath -Value $envContent -Encoding UTF8
Write-Host "✓ Created .env file" -ForegroundColor Green

# Create run scripts for PostgreSQL profile
$runPostgresBatContent = @'
@echo off
echo Starting Spring Boot with PostgreSQL profile...
set MAVEN_OPTS=-Dfile.encoding=UTF-8
mvn spring-boot:run -Dspring-boot.run.profiles=postgres
'@

$runPostgresBatPath = Join-Path $ProjectPath "run-postgres.bat"
Set-Content -Path $runPostgresBatPath -Value $runPostgresBatContent -Encoding ASCII
Write-Host "✓ Created run-postgres.bat" -ForegroundColor Green

$runPostgresPs1Content = @'
Write-Host "Starting Spring Boot with PostgreSQL profile..." -ForegroundColor Cyan
$env:MAVEN_OPTS = "-Dfile.encoding=UTF-8"
mvn spring-boot:run -D"spring-boot.run.profiles=postgres"
'@

$runPostgresPs1Path = Join-Path $ProjectPath "run-postgres.ps1"
Set-Content -Path $runPostgresPs1Path -Value $runPostgresPs1Content -Encoding UTF8
Write-Host "✓ Created run-postgres.ps1" -ForegroundColor Green

# Create database management scripts
$dbScriptsDir = Join-Path $ProjectPath "db-scripts"
Create-Directory $dbScriptsDir

# Start script
$startDbContent = @'
Write-Host "Starting PostgreSQL database..." -ForegroundColor Cyan
docker-compose up -d postgres
Write-Host "`nWaiting for PostgreSQL to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Check if database is ready
$attempts = 0
$maxAttempts = 30
while ($attempts -lt $maxAttempts) {
    try {
        docker exec spreadsheet-postgres pg_isready -U spreadsheet_user | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ PostgreSQL is ready!" -ForegroundColor Green
            break
        }
    } catch {}
    $attempts++
    Write-Host "  Waiting... ($attempts/$maxAttempts)" -ForegroundColor Gray
    Start-Sleep -Seconds 2
}

if ($attempts -eq $maxAttempts) {
    Write-Host "✗ PostgreSQL failed to start" -ForegroundColor Red
    exit 1
}

Write-Host "`nPostgreSQL is running on port 5432" -ForegroundColor Green
Write-Host "Connection details:" -ForegroundColor Yellow
Write-Host "  Host: localhost" -ForegroundColor White
Write-Host "  Port: 5432" -ForegroundColor White
Write-Host "  Database: spreadsheet_db" -ForegroundColor White
Write-Host "  Username: spreadsheet_user" -ForegroundColor White
Write-Host "  Password: spreadsheet_pass" -ForegroundColor White
'@

Set-Content -Path (Join-Path $dbScriptsDir "start-db.ps1") -Value $startDbContent -Encoding UTF8
Write-Host "✓ Created db-scripts/start-db.ps1" -ForegroundColor Green

# Stop script
$stopDbContent = @'
Write-Host "Stopping PostgreSQL database..." -ForegroundColor Cyan
docker-compose down
Write-Host "✓ PostgreSQL stopped" -ForegroundColor Green
'@

Set-Content -Path (Join-Path $dbScriptsDir "stop-db.ps1") -Value $stopDbContent -Encoding UTF8
Write-Host "✓ Created db-scripts/stop-db.ps1" -ForegroundColor Green

# Start all script
$startAllContent = @'
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
'@

Set-Content -Path (Join-Path $dbScriptsDir "start-all.ps1") -Value $startAllContent -Encoding UTF8
Write-Host "✓ Created db-scripts/start-all.ps1" -ForegroundColor Green

# Connect to database script
$connectDbContent = @'
Write-Host "Connecting to PostgreSQL database..." -ForegroundColor Cyan
docker exec -it spreadsheet-postgres psql -U spreadsheet_user -d spreadsheet_db
'@

Set-Content -Path (Join-Path $dbScriptsDir "connect-db.ps1") -Value $connectDbContent -Encoding UTF8
Write-Host "✓ Created db-scripts/connect-db.ps1" -ForegroundColor Green

# View logs script
$viewLogsContent = @'
Write-Host "PostgreSQL logs:" -ForegroundColor Cyan
docker logs spreadsheet-postgres --tail 50 -f
'@

Set-Content -Path (Join-Path $dbScriptsDir "view-logs.ps1") -Value $viewLogsContent -Encoding UTF8
Write-Host "✓ Created db-scripts/view-logs.ps1" -ForegroundColor Green

# Create test data script
$testDataContent = @'
-- Test data for PostgreSQL
-- This will be executed after tables are created by Hibernate

-- You can add test data here if needed
-- Example:
-- INSERT INTO users (username, email, password, created_at) 
-- VALUES ('testuser2', 'test2@example.com', '$2a$10$...', NOW());
'@

$testDataPath = Join-Path $dbScriptsDir "test-data.sql"
Set-Content -Path $testDataPath -Value $testDataContent -Encoding UTF8
Write-Host "✓ Created db-scripts/test-data.sql" -ForegroundColor Green

# Create README for database setup
$dbReadmeContent = @'
# PostgreSQL Database Setup

## Quick Start

1. Start PostgreSQL only:
   ```powershell
   .\db-scripts\start-db.ps1
   ```

2. Start PostgreSQL and PgAdmin:
   ```powershell
   .\db-scripts\start-all.ps1
   ```

3. Stop all services:
   ```powershell
   .\db-scripts\stop-db.ps1
   ```

4. Connect to database via psql:
   ```powershell
   .\db-scripts\connect-db.ps1
   ```

5. View PostgreSQL logs:
   ```powershell
   .\db-scripts\view-logs.ps1
   ```

## Run Application with PostgreSQL

```powershell
# First, start the database
.\db-scripts\start-db.ps1

# Then run the application
.\run-postgres.bat
# or
.\run-postgres.ps1
```

## Access Points

- **PostgreSQL**: `localhost:5432`
  - Database: `spreadsheet_db`
  - Username: `spreadsheet_user`
  - Password: `spreadsheet_pass`

- **PgAdmin**: `http://localhost:5050`
  - Email: `admin@example.com`
  - Password: `admin`

## Useful Commands

### View logs
```powershell
docker logs spreadsheet-postgres
```

### Execute SQL
```powershell
docker exec spreadsheet-postgres psql -U spreadsheet_user -d spreadsheet_db -c "SELECT * FROM users;"
```

### Backup database
```powershell
docker exec spreadsheet-postgres pg_dump -U spreadsheet_user spreadsheet_db > backup.sql
```

### Restore database
```powershell
docker exec -i spreadsheet-postgres psql -U spreadsheet_user spreadsheet_db < backup.sql
```

## Troubleshooting

### Connection refused
- Make sure Docker is running
- Wait a few seconds after starting PostgreSQL
- Check if port 5432 is already in use

### Permission denied
- Run PowerShell as Administrator
- Make sure Docker Desktop is running

### Cannot find docker-compose
- Make sure Docker Desktop is installed
- Restart your terminal after Docker installation
'@

$dbReadmePath = Join-Path $dbScriptsDir "README.md"
Set-Content -Path $dbReadmePath -Value $dbReadmeContent -Encoding UTF8
Write-Host "✓ Created db-scripts/README.md" -ForegroundColor Green

Write-Host "`n✓ PostgreSQL Docker setup complete!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Start PostgreSQL:" -ForegroundColor Yellow
Write-Host "   .\db-scripts\start-db.ps1" -ForegroundColor White
Write-Host "`n2. Run application with PostgreSQL:" -ForegroundColor Yellow
Write-Host "   .\run-postgres.ps1" -ForegroundColor White
Write-Host "`n3. (Optional) Start PgAdmin:" -ForegroundColor Yellow
Write-Host "   .\db-scripts\start-all.ps1" -ForegroundColor White
Write-Host "   Access at: http://localhost:5050" -ForegroundColor Gray
Write-Host "`n4. Test the API with PostgreSQL:" -ForegroundColor Yellow
Write-Host "   .\test-api-v2.ps1" -ForegroundColor White
Write-Host "`n5. View logs if needed:" -ForegroundColor Yellow
Write-Host "   .\db-scripts\view-logs.ps1" -ForegroundColor White