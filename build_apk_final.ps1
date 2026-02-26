# Script de automatización para build de APK
$javaPath = 'C:\Program Files\Microsoft\jdk-17.0.10.7-hotspot'
$env:JAVA_HOME = $javaPath
$env:ANDROID_HOME = 'C:\Android\Sdk'
$env:PATH = "$env:PATH;$javaPath\bin;C:\Android\Sdk\cmdline-tools\latest\bin"

Write-Host "--- Configurando SDK de Android ---" -ForegroundColor Cyan
& "C:\Users\Leonardo\Documents\flutter_new\flutter\bin\flutter.bat" config --android-sdk "C:\Android\Sdk"

Write-Host "--- Aceptando Licencias ---" -ForegroundColor Cyan
$yes = "y`ny`ny`ny`ny`ny`ny`n"
$yes | & "C:\Users\Leonardo\Documents\flutter_new\flutter\bin\flutter.bat" doctor --android-licenses

Write-Host "--- Limpiando proyecto ---" -ForegroundColor Cyan
& "C:\Users\Leonardo\Documents\flutter_new\flutter\bin\flutter.bat" clean

Write-Host "--- Iniciando Build de APK Debug ---" -ForegroundColor Cyan
& "C:\Users\Leonardo\Documents\flutter_new\flutter\bin\flutter.bat" build apk --debug

Write-Host "--- Proceso finalizado ---" -ForegroundColor Green
Write-Host "Si el build fue exitoso, el APK estará en: build\app\outputs\flutter-apk\app-debug.apk"
Pause
