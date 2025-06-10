Write-Host "Starting Spring Boot with UTF-8 encoding..." -ForegroundColor Cyan
$env:MAVEN_OPTS = "-Dfile.encoding=UTF-8"
mvn spring-boot:run
