<#
PowerShell setup script for ergodic_test_app
Runs basic checks and attempts to automate local onboarding steps on Windows.
#>

Param(
    [switch]$SkipInstall
)

Write-Host "== Ergoddic Test App: Local setup helper =="

function Ensure-Command {
    param($cmd, $installHint)
    $exists = Get-Command $cmd -ErrorAction SilentlyContinue
    if (-not $exists) {
        Write-Warning "$cmd not found. $installHint"
        return $false
    }
    return $true
}

$okFlutter = Ensure-Command -cmd flutter -installHint "Install Flutter: https://docs.flutter.dev/get-started/install"
$okNode = Ensure-Command -cmd node -installHint "Install Node.js from https://nodejs.org/"
$okNpm = Ensure-Command -cmd npm -installHint "npm comes with Node.js"

if ($okFlutter) {
    Write-Host "Running 'flutter doctor'..."
    flutter doctor
}

if (-not $SkipInstall) {
    if ($okFlutter) {
        Write-Host "Running 'flutter pub get'..."
        flutter pub get
    }

    if ($okNpm) {
        if (-Not (Get-Command firebase -ErrorAction SilentlyContinue)) {
            Write-Host "firebase CLI not found. Installing firebase-tools globally..."
            npm install -g firebase-tools
        } else {
            Write-Host "firebase CLI detected."
        }

        if (Test-Path "functions\package.json") {
            Write-Host "Installing functions dependencies..."
            Push-Location functions
            npm install
            Pop-Location
        }
    }
}

Write-Host "Setup script finished. Next steps: start an emulator (or attach a device) and run 'flutter run'."
Write-Host "If you need to configure Firebase functions local config, run:"
Write-Host "  firebase functions:config:set gemini.key=\"<YOUR_KEY>\""
Write-Host "And avoid committing secrets to the repository."

