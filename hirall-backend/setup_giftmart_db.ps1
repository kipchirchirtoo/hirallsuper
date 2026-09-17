param (
    [string]$DbHost = "localhost",
    [int]$DbPort = 5432,
    [string]$DbUser = "postgres",
    [string]$DbPassword = "postgrespassword",
    [string]$DbName = "giftmart"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$MigrationsDir = Join-Path $ScriptDir "migrations"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "GIFTMART SUPERMARKET: DATABASE INITIALIZATION AND MIGRATION" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "Target Database: $DbName on ${DbHost}:${DbPort} (User: $DbUser)" -ForegroundColor Yellow

$SqlFile = Join-Path $ScriptDir "setup_giftmart_db.sql"
Write-Host "Compiling SQL migrations into $SqlFile..." -ForegroundColor Green

$MigrationFiles = Get-ChildItem -Path $MigrationsDir -Filter "*.sql" | Sort-Object Name
$CombinedSql = New-Object System.Collections.Generic.List[string]

$CombinedSql.Add("-- ==============================================================================")
$CombinedSql.Add("-- GIFTMART SUPERMARKET: CONSOLIDATED DATABASE SCHEMA AND SEED")
$CombinedSql.Add("-- Generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$CombinedSql.Add("-- ==============================================================================")
$CombinedSql.Add("")

foreach ($file in $MigrationFiles) {
    Write-Host "  -> Adding $($file.Name)" -ForegroundColor DarkGray
    $CombinedSql.Add("-- ------------------------------------------------------------------------------")
    $CombinedSql.Add("-- Migration: $($file.Name)")
    $CombinedSql.Add("-- ------------------------------------------------------------------------------")
    $content = [System.IO.File]::ReadAllText($file.FullName)
    $CombinedSql.Add($content)
    $CombinedSql.Add("")
}

[System.IO.File]::WriteAllLines($SqlFile, $CombinedSql)
Write-Host "[OK] Successfully generated $SqlFile ($($MigrationFiles.Count) migrations merged)." -ForegroundColor Green

$env:PGPASSWORD = $DbPassword

$hasPsql = Get-Command psql -ErrorAction SilentlyContinue
$hasDocker = Get-Command docker -ErrorAction SilentlyContinue

if ($hasPsql) {
    Write-Host "Executing via local psql..." -ForegroundColor Cyan
    try {
        & psql -h $DbHost -p $DbPort -U $DbUser -d postgres -c "CREATE DATABASE $DbName;" 2>$null
        & psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -f $SqlFile
        Write-Host "[OK] Database $DbName successfully initialized and seeded!" -ForegroundColor Green
    } catch {
        Write-Warning "Local psql execution encountered an issue: $_"
    }
} elseif ($hasDocker) {
    Write-Host "Attempting execution via Docker PostgreSQL container..." -ForegroundColor Cyan
    try {
        $containerId = docker ps -q -f "ancestor=postgres:16-alpine" | Select-Object -First 1
        if ($containerId) {
            docker cp $SqlFile "${containerId}:/setup_giftmart_db.sql"
            docker exec -i $containerId psql -U $DbUser -d postgres -c "CREATE DATABASE $DbName;"
            docker exec -i $containerId psql -U $DbUser -d $DbName -f /setup_giftmart_db.sql
            Write-Host "[OK] Database $DbName successfully initialized inside Docker!" -ForegroundColor Green
        } else {
            Write-Host "Docker is installed, but no PostgreSQL container is currently running." -ForegroundColor Yellow
        }
    } catch {
        Write-Warning "Docker execution note: $_"
    }
} else {
    Write-Host "Note: Neither 'psql' nor 'docker' CLI was detected in PATH." -ForegroundColor Yellow
    Write-Host "You can execute the generated SQL file directly in pgAdmin, DBeaver, or via Docker:" -ForegroundColor White
    Write-Host "File: $SqlFile" -ForegroundColor Cyan
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "[OK] Setup compilation complete!" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
