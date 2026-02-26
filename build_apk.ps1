$javaPath = 'C:\Program Files\Microsoft\jdk-17.0.10.7-hotspot'
$env:JAVA_HOME = $javaPath
$env:ANDROID_HOME = 'C:\Android\Sdk'
$env:PATH = "$env:PATH;$javaPath\bin;C:\Android\Sdk\cmdline-tools\latest\bin"

Write-Host "Configurando SDK de Android..."
& "C:\Users\Leonardo\Documents\flutter_new\flutter\bin\flutter.bat" config --android-sdk "C:\Android\Sdk"

Write-Host "Aceptando licencias..."
$y = "y`ny`ny`ny`ny`ny`n"
$y | & "C:\Users\Leonardo\Documents\flutter_new\flutter\bin\flutter.bat" doctor --android-licenses

Write-Host "Iniciando build del APK..."
& "C:\Users\Leonardo\Documents\flutter_new\flutter\bin\flutter.bat" build apk --debug
