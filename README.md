# Spreadsheet API

A Spring Boot REST API for spreadsheet management with Google Sheets-like functionality.

## Features

- 🔐 **User Authentication** with JWT tokens
- 📊 **Spreadsheet Management** (CRUD operations)
- 📄 **Sheet Management** with cell operations
- 📁 **Media File Upload/Download**
- 🔒 **Permission System** (VIEW, EDIT, ADMIN)
- 📤 **Excel Import/Export**
- 💾 **H2 Database** for development
- 🐘 **PostgreSQL** support for production

## Quick Start

### Prerequisites

- Java 11 or higher
- Maven 3.6 or higher

### Running the Application

1. Navigate to the project directory:
   ```bash
   cd spreadsheet-api
   ```

2. Run the application:
   ```bash
   mvn spring-boot:run
   ```

3. Access the application:
   - API Base URL: `http://localhost:8080/api`
   - H2 Console: `http://localhost:8080/api/h2-console`
     - JDBC URL: `jdbc:h2:mem:spreadsheetdb`
     - Username: `sa`
     - Password: (leave empty)

### Default Users

The application creates two default users on startup:
- **Admin User**: username: `admin`, password: `admin123`
- **Test User**: username: `testuser`, password: `test123`

## API Endpoints

### Authentication

```bash
# Register new user
POST /api/auth/register
{
  "username": "newuser",
  "email": "user@example.com",
  "password": "password123"
}

# Login
POST /api/auth/login
{
  "username": "admin",
  "password": "admin123"
}
```

### Spreadsheets

```bash
# Create spreadsheet
POST /api/spreadsheets
Authorization: Bearer {token}
{
  "name": "My Spreadsheet",
  "description": "Description"
}

# Get spreadsheet
GET /api/spreadsheets/{id}
Authorization: Bearer {token}

# List user spreadsheets
GET /api/spreadsheets
Authorization: Bearer {token}

# Delete spreadsheet
DELETE /api/spreadsheets/{id}
Authorization: Bearer {token}

# Export to Excel
GET /api/spreadsheets/{id}/export
Authorization: Bearer {token}

# Import from Excel
POST /api/spreadsheets/import
Authorization: Bearer {token}
Content-Type: multipart/form-data
file: {excel_file}
```

### Sheets

```bash
# Create sheet
POST /api/sheets/spreadsheet/{spreadsheetId}
Authorization: Bearer {token}
{
  "name": "Sheet2"
}

# Get sheet with cells
GET /api/sheets/{id}
Authorization: Bearer {token}

# Update cells
PUT /api/sheets/{id}/cells
Authorization: Bearer {token}
{
  "cells": [
    {"row": 0, "col": 0, "value": "A1"},
    {"row": 0, "col": 1, "value": "B1"},
    {"row": 1, "col": 0, "value": "A2"}
  ]
}
```

### Permissions

```bash
# Grant permission
POST /api/spreadsheets/{id}/permissions
Authorization: Bearer {token}
{
  "username": "testuser",
  "permissionType": "EDIT"
}

# Revoke permission
DELETE /api/spreadsheets/{id}/permissions/{username}
Authorization: Bearer {token}
```

### Media Files

```bash
# Upload media
POST /api/media/spreadsheet/{spreadsheetId}
Authorization: Bearer {token}
Content-Type: multipart/form-data
file: {media_file}

# Download media
GET /api/media/{id}/download
Authorization: Bearer {token}

# Delete media
DELETE /api/media/{id}
Authorization: Bearer {token}
```

## Using the Existing Cell Update Endpoint for Column Operations

### Insert a column with multiple rows
```bash
PUT /api/sheets/{sheetId}/cells
Authorization: Bearer {token}
{
  "cells": [
    {"row": 0, "col": 5, "value": "Column Header"},
    {"row": 1, "col": 5, "value": "Row 1 Data"},
    {"row": 2, "col": 5, "value": "Row 2 Data"},
    {"row": 3, "col": 5, "value": "Row 3 Data"}
  ]
}
```

### Update multiple columns at once
```bash
PUT /api/sheets/{sheetId}/cells
Authorization: Bearer {token}
{
  "cells": [
    # Column A
    {"row": 0, "col": 0, "value": "Name"},
    {"row": 1, "col": 0, "value": "John"},
    {"row": 2, "col": 0, "value": "Jane"},
    # Column B
    {"row": 0, "col": 1, "value": "Age"},
    {"row": 1, "col": 1, "value": "25"},
    {"row": 2, "col": 1, "value": "30"},
    # Column C
    {"row": 0, "col": 2, "value": "City"},
    {"row": 1, "col": 2, "value": "New York"},
    {"row": 2, "col": 2, "value": "London"}
  ]
}
```

## Database Configuration

### Development (H2)
The application uses H2 in-memory database by default. No configuration needed.

### Production (PostgreSQL)
1. Create a PostgreSQL database:
   ```sql
   CREATE DATABASE spreadsheet_db;
   ```

2. Update `application.properties`:
   ```properties
   spring.profiles.active=prod
   ```

3. Set environment variables:
   ```bash
   export DB_USERNAME=your_db_user
   export DB_PASSWORD=your_db_password
   ```

## Project Structure

```
spreadsheet-api/
├── src/main/java/com/example/spreadsheet/
│   ├── controller/      # REST controllers
│   ├── dto/            # Data transfer objects
│   ├── entity/         # JPA entities
│   ├── exception/      # Exception handlers
│   ├── repository/     # JPA repositories
│   ├── security/       # Security configuration
│   ├── service/        # Business logic
│   └── SpreadsheetApplication.java
├── src/main/resources/
│   ├── application.properties
│   └── application-prod.properties
├── uploads/            # Media file storage
└── pom.xml
```

## Error Handling

The API returns consistent error responses:
```json
{
  "timestamp": "2023-12-08T10:30:00",
  "status": 404,
  "error": "Not Found",
  "message": "Spreadsheet not found",
  "path": "/api/spreadsheets/999"
}
```

## Security

- JWT tokens expire after 24 hours
- Passwords are encrypted using BCrypt
- CORS is enabled for all origins (configure for production)
- File uploads limited to 10MB

## License

This project is open source and available under the MIT License.