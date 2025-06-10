# Test-ZipImport-Simple.ps1
# Version simplifiée utilisant curl.exe pour l'upload multipart

# Configuration
$API_BASE_URL = "http://localhost:8080"
$USERNAME = "admin"
$PASSWORD = "admin123"

Write-Host "=== Test d'import ZIP pour Spreadsheet API ===" -ForegroundColor Cyan

# 1. Authentification
Write-Host "`n1. Authentification..." -ForegroundColor Cyan

$loginBody = @{
    username = $USERNAME
    password = $PASSWORD
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "$API_BASE_URL/auth/login" `
    -Method Post `
    -ContentType "application/json" `
    -Body $loginBody

$token = $loginResponse.token
Write-Host "✓ Token obtenu" -ForegroundColor Green

# 2. Créer un fichier ZIP de test
Write-Host "`n2. Création du fichier ZIP de test..." -ForegroundColor Cyan

# Sauvegarder le répertoire actuel
$originalPath = Get-Location

# Créer un dossier temporaire
$tempDir = "$env:TEMP\spreadsheet-test-$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
Set-Location $tempDir

# Créer les dossiers
New-Item -ItemType Directory -Path "sheets" -Force | Out-Null

# Créer metadata.json
$metadata = @{
    name = "Test Import PowerShell"
    description = "Test d'import via PowerShell"
    sheets = @(
        @{
            name = "Données"
            filename = "data.csv"
        }
    )
    mediaFiles = @()
}

$metadata | ConvertTo-Json -Depth 3 | Out-File -FilePath "metadata.json" -Encoding UTF8

# Créer un CSV simple
@"
Nom,Age,Ville
Jean Dupont,25,Paris
Marie Martin,30,Lyon
Pierre Bernard,35,Marseille
"@ | Out-File -FilePath "sheets\data.csv" -Encoding UTF8

# Créer le ZIP
$zipPath = "$tempDir\test.zip"
Compress-Archive -Path "metadata.json", "sheets" -DestinationPath $zipPath -Force

Write-Host "✓ ZIP créé: $zipPath" -ForegroundColor Green

# 3. Import avec curl.exe
Write-Host "`n3. Import du fichier ZIP..." -ForegroundColor Cyan

# Vérifier si curl.exe est disponible
if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
    # Utiliser curl.exe pour l'upload
    $curlOutput = & curl.exe -s -X POST `
        -H "Authorization: Bearer $token" `
        -F "file=@$zipPath" `
        "$API_BASE_URL/spreadsheets/import/zip"
    
    try {
        $importResponse = $curlOutput | ConvertFrom-Json
        Write-Host "✓ Import réussi!" -ForegroundColor Green
        Write-Host "ID du spreadsheet: $($importResponse.id)" -ForegroundColor Green
        Write-Host "Nom: $($importResponse.name)" -ForegroundColor Green
    } catch {
        Write-Host "✗ Erreur lors de l'import" -ForegroundColor Red
        Write-Host $curlOutput
    }
} else {
    Write-Host "curl.exe n'est pas disponible. Essai avec .NET HttpClient..." -ForegroundColor Yellow
    
    # Alternative avec .NET HttpClient
    Add-Type -AssemblyName System.Net.Http
    
    $httpClient = New-Object System.Net.Http.HttpClient
    $httpClient.DefaultRequestHeaders.Add("Authorization", "Bearer $token")
    
    $multipartContent = New-Object System.Net.Http.MultipartFormDataContent
    $fileStream = [System.IO.File]::OpenRead($zipPath)
    $fileContent = New-Object System.Net.Http.StreamContent($fileStream)
    $fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("application/zip")
    $multipartContent.Add($fileContent, "file", "test.zip")
    
    try {
        $response = $httpClient.PostAsync("$API_BASE_URL/spreadsheets/import/zip", $multipartContent).Result
        $responseContent = $response.Content.ReadAsStringAsync().Result
        
        if ($response.IsSuccessStatusCode) {
            $importResponse = $responseContent | ConvertFrom-Json
            Write-Host "✓ Import réussi!" -ForegroundColor Green
            Write-Host "ID: $($importResponse.id)" -ForegroundColor Green
        } else {
            Write-Host "✗ Erreur: $($response.StatusCode)" -ForegroundColor Red
            Write-Host $responseContent
        }
    } finally {
        $fileStream.Close()
        $httpClient.Dispose()
    }
}

# 4. Test d'export (si l'import a réussi)
if ($importResponse -and $importResponse.id) {
    Write-Host "`n4. Test de l'export ZIP..." -ForegroundColor Cyan
    
    $exportPath = "$tempDir\export.zip"
    
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        & curl.exe -s -X GET `
            -H "Authorization: Bearer $token" `
            -o $exportPath `
            "$API_BASE_URL/spreadsheets/$($importResponse.id)/export/zip"
        
        if (Test-Path $exportPath) {
            $fileSize = (Get-Item $exportPath).Length
            Write-Host "✓ Export réussi: $exportPath ($fileSize bytes)" -ForegroundColor Green
        }
    } else {
        Invoke-RestMethod -Uri "$API_BASE_URL/spreadsheets/$($importResponse.id)/export/zip" `
            -Method Get `
            -Headers @{ Authorization = "Bearer $token" } `
            -OutFile $exportPath
        
        Write-Host "✓ Export réussi: $exportPath" -ForegroundColor Green
    }
}

# 5. Nettoyage


# Revenir au répertoire initial
Set-Location $originalPath
Write-Host "✓ Retour au répertoire initial: $originalPath" -ForegroundColor Green

Write-Host "`n=== Test terminé ===" -ForegroundColor Green