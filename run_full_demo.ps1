$env:FLUTTER_ROOT = "C:\Users\Leonardo\Documents\flutter_new\flutter"
$env:Path = "C:\Users\Leonardo\Documents\flutter_new\flutter\bin;" + $env:Path
Write-Host "Checking Flutter version..."
& "C:\Users\Leonardo\Documents\flutter_new\flutter\bin\flutter.bat" --version
Write-Host "Running Flutter pub get..."
& "C:\Users\Leonardo\Documents\flutter_new\flutter\bin\flutter.bat" pub get
Write-Host "Starting Web Server..."
& "C:\Users\Leonardo\Documents\flutter_new\flutter\bin\flutter.bat" run -d web-server --web-hostname 0.0.0.0 --web-port 8080
