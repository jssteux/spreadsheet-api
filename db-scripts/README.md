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
