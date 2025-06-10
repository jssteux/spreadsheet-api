# Fix PostgreSQL Authentication Issues
Write-Host "Fixing PostgreSQL Authentication..." -ForegroundColor Cyan

# Clean up existing containers and volumes
Write-Host "`nCleaning up existing Docker resources..." -ForegroundColor Yellow
docker-compose -f docker-compose-full.yml down -v 2>$null
docker-compose down -v 2>$null
docker volume rm spreadsheet-api_postgres_data -f 2>$null
docker volume rm $(docker volume ls -q | Select-String "postgres") -f 2>$null

Write-Host "✓ Cleanup complete" -ForegroundColor Green

# Create a simplified docker-compose for testing
Write-Host "`nCreating fixed docker-compose configuration..." -ForegroundColor Yellow
$dockerComposeContent = @'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: spreadsheet-postgres
    environment:
      # These MUST match what the API uses
      POSTGRES_DB: spreadsheet_db
      POSTGRES_USER: spreadsheet_user
      POSTGRES_PASSWORD: spreadsheet_pass
      # This ensures the password is set correctly
      POSTGRES_HOST_AUTH_METHOD: md5
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - spreadsheet-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U spreadsheet_user -d spreadsheet_db"]
      interval: 5s
      timeout: 5s
      retries: 10

  api:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: spreadsheet-api
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      # Exact same credentials as postgres service
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/spreadsheet_db
      SPRING_DATASOURCE_USERNAME: spreadsheet_user
      SPRING_DATASOURCE_PASSWORD: spreadsheet_pass
      SPRING_JPA_HIBERNATE_DDL_AUTO: update
      SPRING_JPA_DATABASE_PLATFORM: org.hibernate.dialect.PostgreSQLDialect
      JWT_SECRET: ThisIsASecretKeyForJWTTokenGenerationPleaseChangeInProduction2023
      MEDIA_UPLOAD_PATH: /app/uploads
      # Add connection pool settings
      SPRING_DATASOURCE_HIKARI_CONNECTION_TIMEOUT: 30000
      SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE: 10
    ports:
      - "8080:8080"
    volumes:
      - ./uploads:/app/uploads
    networks:
      - spreadsheet-network
    restart: unless-stopped

volumes:
  postgres_data:
    driver: local

networks:
  spreadsheet-network:
    driver: bridge
'@

Set-Content -Path "docker-compose-full.yml" -Value $dockerComposeContent -Encoding UTF8
Write-Host "✓ Created fixed docker-compose-full.yml" -ForegroundColor Green

# Update application-docker.properties to ensure it uses environment variables
Write-Host "`nUpdating application-docker.properties..." -ForegroundColor Yellow
$dockerPropertiesContent = @'
# Docker Profile Configuration
server.port=8080

# Database Configuration - MUST use environment variables
spring.datasource.url=${SPRING_DATASOURCE_URL}
spring.datasource.username=${SPRING_DATASOURCE_USERNAME}
spring.datasource.password=${SPRING_DATASOURCE_PASSWORD}
spring.datasource.driver-class-name=org.postgresql.Driver

# Connection pool
spring.datasource.hikari.connection-timeout=${SPRING_DATASOURCE_HIKARI_CONNECTION_TIMEOUT:30000}
spring.datasource.hikari.maximum-pool-size=${SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE:10}

# JPA Configuration
spring.jpa.database-platform=${SPRING_JPA_DATABASE_PLATFORM:org.hibernate.dialect.PostgreSQLDialect}
spring.jpa.hibernate.ddl-auto=${SPRING_JPA_HIBERNATE_DDL_AUTO:update}
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.format_sql=true
spring.jpa.properties.hibernate.jdbc.lob.non_contextual_creation=true

# File Upload
spring.servlet.multipart.max-file-size=10MB
spring.servlet.multipart.max-request-size=10MB
media.upload.path=${MEDIA_UPLOAD_PATH:/app/uploads}

# JWT
jwt.secret=${JWT_SECRET:ThisIsASecretKeyForJWTTokenGenerationPleaseChangeInProduction2023}
jwt.expiration=86400000

# Logging
logging.level.com.example.spreadsheet=INFO
logging.level.org.springframework.security=INFO
logging.level.org.hibernate.SQL=INFO
'@

$resourcesPath = "src\main\resources"
$dockerPropertiesPath = Join-Path $resourcesPath "application-docker.properties"
$utf8NoBOM = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($dockerPropertiesPath, $dockerPropertiesContent, $utf8NoBOM)
Write-Host "✓ Updated application-docker.properties" -ForegroundColor Green

Write-Host "`n✓ Configuration fixed!" -ForegroundColor Green
Write-Host "`nNow run these commands:" -ForegroundColor Cyan
Write-Host "1. Start fresh:" -ForegroundColor Yellow
Write-Host "   docker-compose -f docker-compose-full.yml up -d postgres" -ForegroundColor White
Write-Host "`n2. Wait for PostgreSQL to be ready (10-15 seconds)" -ForegroundColor Yellow
Write-Host "`n3. Test the connection:" -ForegroundColor Yellow
Write-Host "   docker exec -it spreadsheet-postgres psql -U spreadsheet_user -d spreadsheet_db -c 'SELECT 1;'" -ForegroundColor White
Write-Host "`n4. If that works, start the API:" -ForegroundColor Yellow
Write-Host "   docker-compose -f docker-compose-full.yml up -d api" -ForegroundColor White