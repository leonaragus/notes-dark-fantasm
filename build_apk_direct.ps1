$javaPath = 'C:\Program Files\Microsoft\jdk-17.0.10.7-hotspot'
$env:JAVA_HOME = $javaPath
$env:ANDROID_HOME = 'C:\Android\Sdk'
$env:PATH = "$env:PATH;$javaPath\bin;C:\Android\Sdk\cmdline-tools\latest\bin"

Write-Host "Iniciando build del APK directamente..."
& "C:\Users\Leonardo\Documents\flutter_new\flutter\bin\flutter.bat" build apk --debug
