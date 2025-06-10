Write-Host "Starting Spring Boot with PostgreSQL profile..." -ForegroundColor Cyan
$env:MAVEN_OPTS = "-Dfile.encoding=UTF-8"
mvn spring-boot:run -D"spring-boot.run.profiles=postgres"
