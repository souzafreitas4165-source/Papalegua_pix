# Cria o diretório de destino se não existir
$destDir = "app\src\main\res\font"
if (!(Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir | Out-Null
}

# Caminho para a fonte Roboto
$sourceFile = "..\..\assets\fonts\Roboto-Regular.ttf"
$destFile = "$destDir\roboto_regular.ttf"

# Copia o arquivo
Copy-Item -Path $sourceFile -Destination $destFile -Force

Write-Host "Fonte copiada com sucesso para $destFile"
