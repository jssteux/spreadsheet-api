@echo off
echo Starting Spring Boot with UTF-8 encoding...
set MAVEN_OPTS=-Dfile.encoding=UTF-8
mvn spring-boot:run
