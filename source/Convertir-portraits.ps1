param([Parameter(Mandatory)][string]$Source, [Parameter(Mandatory)][string]$Target)
Add-Type -AssemblyName System.Drawing.Common
$null = New-Item -ItemType Directory -Path $Target -Force
foreach ($file in Get-ChildItem -LiteralPath $Source -Filter '*.png') {
    $out = Join-Path $Target ($file.BaseName + '.tga')
    if (Test-Path -LiteralPath $out) { continue }
    try { $image = [Drawing.Image]::FromFile($file.FullName) } catch { continue }
    $bitmap = [Drawing.Bitmap]::new(256,256,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $scale = [Math]::Min(256.0 / $image.Width, 256.0 / $image.Height)
            $width = [int]($image.Width * $scale)
            $height = [int]($image.Height * $scale)
            $graphics.DrawImage($image, [int]((256-$width)/2), [int]((256-$height)/2), $width, $height)
        } finally { $graphics.Dispose() }
        $data = $bitmap.LockBits([Drawing.Rectangle]::new(0,0,256,256),[Drawing.Imaging.ImageLockMode]::ReadOnly,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $pixelBytes = [byte[]]::new(256*256*4)
            [Runtime.InteropServices.Marshal]::Copy($data.Scan0,$pixelBytes,0,$pixelBytes.Length)
            $header = [byte[]](0,0,2,0,0,0,0,0,0,0,0,0,0,1,0,1,32,40)
            [IO.File]::WriteAllBytes((Join-Path $PWD $out), $header + $pixelBytes)
        } finally { $bitmap.UnlockBits($data) }
    } finally {
        $bitmap.Dispose()
        $image.Dispose()
    }
}

