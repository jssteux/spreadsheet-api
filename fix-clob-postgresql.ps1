# Fix CLOB type issue for PostgreSQL
param(
    [string]$ProjectPath = (Get-Location).Path
)

Write-Host "Fixing CLOB type issue for PostgreSQL..." -ForegroundColor Cyan
Write-Host "Project path: $ProjectPath" -ForegroundColor Yellow

# Update Cell.java to use TEXT instead of CLOB
Write-Host "`nUpdating Cell entity..." -ForegroundColor Yellow

# Build the correct path
$cellEntityPath = Join-Path $ProjectPath "src\main\java\com\example\spreadsheet\entity\Cell.java"

# Check if file exists
if (!(Test-Path $cellEntityPath)) {
    Write-Host "✗ Cell.java not found at: $cellEntityPath" -ForegroundColor Red
    Write-Host "  Current directory: $(Get-Location)" -ForegroundColor Yellow
    Write-Host "  Looking for project structure..." -ForegroundColor Yellow
    
    # Try to find the file
    $foundFiles = Get-ChildItem -Path . -Filter "Cell.java" -Recurse -ErrorAction SilentlyContinue
    if ($foundFiles) {
        Write-Host "  Found Cell.java at:" -ForegroundColor Green
        $foundFiles | ForEach-Object { Write-Host "    $($_.FullName)" -ForegroundColor Gray }
        $cellEntityPath = $foundFiles[0].FullName
    } else {
        Write-Host "  Could not find Cell.java in current directory tree" -ForegroundColor Red
        exit 1
    }
}

$cellEntityContent = @'
package com.example.spreadsheet.entity;

import javax.persistence.*;

@Entity
@Table(name = "cells", indexes = {
    @Index(name = "idx_sheet_row_col", columnList = "sheet_id, row_index, column_index")
})
public class Cell {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sheet_id", nullable = false)
    private Sheet sheet;
    
    @Column(name = "row_index", nullable = false)
    private Integer rowIndex;
    
    @Column(name = "column_index", nullable = false)
    private Integer columnIndex;
    
    @Column(name = "cell_value", columnDefinition = "TEXT")
    private String value;
    
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public Sheet getSheet() { return sheet; }
    public void setSheet(Sheet sheet) { this.sheet = sheet; }
    
    public Integer getRowIndex() { return rowIndex; }
    public void setRowIndex(Integer rowIndex) { this.rowIndex = rowIndex; }
    
    public Integer getColumnIndex() { return columnIndex; }
    public void setColumnIndex(Integer columnIndex) { this.columnIndex = columnIndex; }
    
    public String getValue() { return value; }
    public void setValue(String value) { this.value = value; }
}
'@

# Create directory if it doesn't exist
$cellEntityDir = Split-Path $cellEntityPath -Parent
if (!(Test-Path $cellEntityDir)) {
    New-Item -ItemType Directory -Path $cellEntityDir -Force | Out-Null
}

$utf8NoBOM = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($cellEntityPath, $cellEntityContent, $utf8NoBOM)
Write-Host "✓ Updated Cell.java to use TEXT instead of CLOB" -ForegroundColor Green
Write-Host "  File: $cellEntityPath" -ForegroundColor Gray

# Also ensure proper PostgreSQL dialect in docker-compose
Write-Host "`nUpdating docker-compose for proper PostgreSQL dialect..." -ForegroundColor Yellow
$dockerComposePath = Join-Path $ProjectPath "docker-compose-full.yml"

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
      # Database configuration
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/spreadsheet_db
      SPRING_DATASOURCE_USERNAME: spreadsheet_user
      SPRING_DATASOURCE_PASSWORD: spreadsheet_pass
      # Force proper PostgreSQL dialect
      SPRING_JPA_DATABASE_PLATFORM: org.hibernate.dialect.PostgreSQL10Dialect
      SPRING_JPA_HIBERNATE_DDL_AUTO: create-drop
      SPRING_JPA_SHOW_SQL: "true"
      SPRING_JPA_PROPERTIES_HIBERNATE_JDBC_LOB_NON_CONTEXTUAL_CREATION: "true"
      # Application settings
      JWT_SECRET: ThisIsASecretKeyForJWTTokenGenerationPleaseChangeInProduction2023
      MEDIA_UPLOAD_PATH: /app/uploads
    ports:
      - "8080:8080"
    volumes:
      - ./uploads:/app/uploads
    networks:
      - spreadsheet-network
    restart: unless-stopped

volumes:
  postgres_data:

networks:
  spreadsheet-network:
    driver: bridge
'@

Set-Content -Path $dockerComposePath -Value $dockerComposeContent -Encoding UTF8
Write-Host "✓ Updated docker-compose-full.yml" -ForegroundColor Green

# Create a simple SQL fix as alternative
Write-Host "`nCreating SQL fix script as alternative..." -ForegroundColor Yellow
$sqlFixPath = Join-Path $ProjectPath "fix-cells-table.sql"
$sqlFixContent = @'
-- Fix cells table to use TEXT instead of CLOB
DROP TABLE IF EXISTS cells CASCADE;

CREATE TABLE cells (
    id BIGSERIAL PRIMARY KEY,
    sheet_id BIGINT NOT NULL,
    row_index INTEGER NOT NULL,
    column_index INTEGER NOT NULL,
    cell_value TEXT,
    FOREIGN KEY (sheet_id) REFERENCES sheets(id) ON DELETE CASCADE,
    UNIQUE(sheet_id, row_index, column_index)
);

CREATE INDEX idx_sheet_row_col ON cells(sheet_id, row_index, column_index);
'@

Set-Content -Path $sqlFixPath -Value $sqlFixContent -Encoding UTF8
Write-Host "✓ Created fix-cells-table.sql" -ForegroundColor Green

Write-Host "`n✓ Fix complete!" -ForegroundColor Green
Write-Host "`nNow follow these steps:" -ForegroundColor Cyan
Write-Host "`n1. Stop the containers:" -ForegroundColor Yellow
Write-Host "   docker-compose -f docker-compose-full.yml down" -ForegroundColor White
Write-Host "`n2. Rebuild the API with the fixed code:" -ForegroundColor Yellow
Write-Host "   docker-compose -f docker-compose-full.yml build --no-cache api" -ForegroundColor White
Write-Host "`n3. Start everything fresh:" -ForegroundColor Yellow
Write-Host "   docker-compose -f docker-compose-full.yml up -d" -ForegroundColor White
Write-Host "`nAlternative: If rebuild fails, manually fix the table:" -ForegroundColor Yellow
Write-Host "   docker exec -i spreadsheet-postgres psql -U spreadsheet_user -d spreadsheet_db < fix-cells-table.sql" -ForegroundColor White