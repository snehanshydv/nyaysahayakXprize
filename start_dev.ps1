# start_dev.ps1 - Nyaysahayak Windows Development Environment
Write-Host "Starting Nyaysahayak Development Environment..." -ForegroundColor Cyan

# Ensure we're in the correct directory (the script's directory)
Set-Location $PSScriptRoot

# Check/Create Python Virtual Environment
if (-not (Test-Path "venv")) {
    Write-Host "Creating Python virtual environment..." -ForegroundColor Green
    python -m venv venv
}

# Install Dependencies
# Using the python executable directly from venv to ensure we use the correct environment
Write-Host "Installing dependencies..." -ForegroundColor Green
.\venv\Scripts\python.exe -m pip install -r requirements.txt

# Start Backend Server (FastAPI)
Write-Host "Starting FastAPI Backend..." -ForegroundColor Green
# Start in a new PowerShell window, activate venv, and run uvicorn
Start-Process powershell -ArgumentList "-NoExit", "-Command", "& { . .\venv\Scripts\Activate.ps1; uvicorn main:app --reload --port 8000 }"

# Start Frontend Server (Next.js)
Write-Host "Starting Next.js Frontend..." -ForegroundColor Green
# Start in a new PowerShell window, navigate to web, and run npm run dev
Start-Process powershell -ArgumentList "-NoExit", "-Command", "& { cd web; npm run dev }"

Write-Host "Development environment started. Check the new windows for server logs." -ForegroundColor Cyan
