$ErrorActionPreference = 'Stop'

# 生成 mipmap 图标：VALORANT 深蓝底 + 红斜切 + 中心橙色核心
Add-Type -AssemblyName System.Drawing

# 图标输出根目录（相对仓库根，而非脚本自身位置）
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$outRoot   = Join-Path $repoRoot 'android\app\src\main\res'

function New-Icon([int]$size, [string]$dir, [string]$name) {
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half

    $bg  = [System.Drawing.Color]::FromArgb(255, 15, 25, 35)    # #0f1923
    $red = [System.Drawing.Color]::FromArgb(255, 255, 70, 85)   # #ff4655
    $hot = [System.Drawing.Color]::FromArgb(255, 255, 140, 60)

    $g.Clear($bg)

    # 红色斜切条
    $barH = [int]($size * 0.16)
    $barY = [int]($size * 0.62)
    $pts = @(
        [System.Drawing.Point]::new(0, $barY),
        [System.Drawing.Point]::new($size, [int]($barY - $size * 0.18)),
        [System.Drawing.Point]::new($size, [int]($barY - $size * 0.18) + $barH + [int]($size * 0.10)),
        [System.Drawing.Point]::new(0, $barY + $barH)
    )
    $g.FillPolygon((New-Object System.Drawing.SolidBrush $red), $pts)

    # 中心发光核心（三层同心圆）
    $cx = $size / 2.0
    $cy = $size * 0.42
    $rings = @(
        @{ r = $size * 0.30; a = 45  },
        @{ r = $size * 0.20; a = 120 },
        @{ r = $size * 0.11; a = 255 }
    )
    foreach ($ring in $rings) {
        $r = [double]$ring.r
        $d = [int]($r * 2)
        $x = [int]($cx - $r)
        $y = [int]($cy - $r)
        $gp = New-Object System.Drawing.Drawing2D.GraphicsPath
        $gp.AddEllipse([float]$x, [float]$y, [float]$d, [float]$d)
        $brush = New-Object System.Drawing.Drawing2D.PathGradientBrush ($gp)
        $brush.CenterColor = [System.Drawing.Color]::FromArgb([int]$ring.a, $hot.R, $hot.G, $hot.B)
        $brush.SurroundColors = @([System.Drawing.Color]::FromArgb(0, $hot.R, $hot.G, $hot.B))
        $brush.CenterPoint = [System.Drawing.PointF]::new($cx, $cy)
        $g.FillEllipse($brush, $x, $y, $d, $d)
        $brush.Dispose()
    }

    $target = Join-Path $outRoot $dir
    if (-not (Test-Path $target)) { New-Item -ItemType Directory -Path $target -Force | Out-Null }
    $file = Join-Path $target $name
    $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)

    $g.Dispose()
    $bmp.Dispose()
    Write-Host "  -> $dir\$name ($size x $size)"
}

$densities = @(
    @{ d = 'mipmap-mdpi';     s = 48 },
    @{ d = 'mipmap-hdpi';     s = 72 },
    @{ d = 'mipmap-xhdpi';    s = 96 },
    @{ d = 'mipmap-xxhdpi';   s = 144 },
    @{ d = 'mipmap-xxxhdpi';  s = 192 }
)

Write-Host 'Generating launcher icons...'
foreach ($item in $densities) {
    New-Icon -size $item.s -dir $item.d -name 'ic_launcher.png'
}

# 自适应图标前后景（任意 dpi，使用 108dp 画布的 mdpi 基准 108px）
function New-Plain([int]$size, [string]$dir, [string]$name, [string]$hex) {
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.ColorTranslator]::FromHtml($hex))
    $target = Join-Path $outRoot $dir
    if (-not (Test-Path $target)) { New-Item -ItemType Directory -Path $target -Force | Out-Null }
    $file = Join-Path $target $name
    $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    Write-Host "  -> $dir\$name ($size x $size)"
}

Write-Host 'Generating adaptive icon layers...'
New-Plain -size 108 -dir 'mipmap-mdpi'    -name 'ic_launcher_background.png' -hex '#0f1923'
New-Plain -size 162 -dir 'mipmap-hdpi'    -name 'ic_launcher_background.png' -hex '#0f1923'
New-Plain -size 216 -dir 'mipmap-xhdpi'   -name 'ic_launcher_background.png' -hex '#0f1923'
New-Plain -size 324 -dir 'mipmap-xxhdpi'  -name 'ic_launcher_background.png' -hex '#0f1923'
New-Plain -size 432 -dir 'mipmap-xxxhdpi' -name 'ic_launcher_background.png' -hex '#0f1923'

# 前景层：透明底 + 中心橙色核心 + 红斜切
function New-Foreground([int]$size, [string]$dir, [string]$name) {
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)

    $red = [System.Drawing.Color]::FromArgb(255, 255, 70, 85)
    $hot = [System.Drawing.Color]::FromArgb(255, 255, 140, 60)

    # 安全区 66/108 ≈ 0.611，图形集中在中心 66% 区域
    $barH = [int]($size * 0.10)
    $barY = [int]($size * 0.62)
    $pts = @(
        [System.Drawing.Point]::new(0, $barY),
        [System.Drawing.Point]::new($size, [int]($barY - $size * 0.18)),
        [System.Drawing.Point]::new($size, [int]($barY - $size * 0.18) + $barH + [int]($size * 0.10)),
        [System.Drawing.Point]::new(0, $barY + $barH)
    )
    $g.FillPolygon((New-Object System.Drawing.SolidBrush $red), $pts)

    $cx = $size / 2.0
    $cy = $size * 0.42
    foreach ($ring in @(@{ r = $size * 0.20; a = 60 }, @{ r = $size * 0.13; a = 150 }, @{ r = $size * 0.07; a = 255 })) {
        $r = [double]$ring.r
        $d = [int]($r * 2)
        $x = [int]($cx - $r)
        $y = [int]($cy - $r)
        $gp = New-Object System.Drawing.Drawing2D.GraphicsPath
        $gp.AddEllipse([float]$x, [float]$y, [float]$d, [float]$d)
        $brush = New-Object System.Drawing.Drawing2D.PathGradientBrush ($gp)
        $brush.CenterColor = [System.Drawing.Color]::FromArgb([int]$ring.a, $hot.R, $hot.G, $hot.B)
        $brush.SurroundColors = @([System.Drawing.Color]::FromArgb(0, $hot.R, $hot.G, $hot.B))
        $brush.CenterPoint = [System.Drawing.PointF]::new($cx, $cy)
        $g.FillEllipse($brush, $x, $y, $d, $d)
        $brush.Dispose()
    }

    $target = Join-Path $outRoot $dir
    if (-not (Test-Path $target)) { New-Item -ItemType Directory -Path $target -Force | Out-Null }
    $file = Join-Path $target $name
    $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    Write-Host "  -> $dir\\$name ($size x $size)"
}

New-Foreground -size 108 -dir 'mipmap-mdpi'    -name 'ic_launcher_foreground.png'
New-Foreground -size 162 -dir 'mipmap-hdpi'    -name 'ic_launcher_foreground.png'
New-Foreground -size 216 -dir 'mipmap-xhdpi'   -name 'ic_launcher_foreground.png'
New-Foreground -size 324 -dir 'mipmap-xxhdpi'  -name 'ic_launcher_foreground.png'
New-Foreground -size 432 -dir 'mipmap-xxxhdpi' -name 'ic_launcher_foreground.png'

Write-Host 'Icons generated.'
