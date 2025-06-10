@echo off
echo Starting Spring Boot with PostgreSQL profile...
set MAVEN_OPTS=-Dfile.encoding=UTF-8
mvn spring-boot:run -Dspring-boot.run.profiles=postgres
