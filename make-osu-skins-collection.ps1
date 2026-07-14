param(
    [string]$HeaderText,
    [string]$FooterText,
    [switch]$NoPrompt
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = $root
Set-Location $repoRoot

$skinsDir = Join-Path $repoRoot 'skins'
$imagesDir = Join-Path $repoRoot 'images'
$outputRoot = Join-Path $repoRoot 'skins-collection'
$targetSkinsDir = Join-Path $outputRoot 'skins'
$targetImagesDir = Join-Path $outputRoot 'images'
$readmePath = Join-Path $outputRoot 'README.md'

New-Item -ItemType Directory -Force -Path $skinsDir, $imagesDir, $outputRoot, $targetSkinsDir, $targetImagesDir | Out-Null

function Read-MultilineInput {
    param([string]$Prompt)

    Write-Host $Prompt
    Write-Host 'You can enter multiple lines. Type [END] to finish.'
    Write-Host 'Basic Markdown examples:'
    Write-Host '- Heading: # Title'
    Write-Host '- Bold: **bold**'
    Write-Host '- Italic: *italic*'
    Write-Host '- Image: ![alt](images/example.jpg)'
    Write-Host '- Link: [text](skins/example.osk)'
    Write-Host ''

    $lines = New-Object System.Collections.Generic.List[string]
    while ($true) {
        $line = Read-Host '>>>'
        if ($null -eq $line) {
            continue
        }
        if ($line.Trim() -eq '[END]') {
            break
        }
        $lines.Add($line)
    }

    return ($lines -join [Environment]::NewLine).Trim()
}

function Move-ContentsToOutput {
    param([string]$SourceDir, [string]$TargetDir)

    if (-not (Test-Path $SourceDir)) {
        return
    }

    New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null

    foreach ($item in Get-ChildItem -Path $SourceDir -Force) {
        $destinationPath = Join-Path $TargetDir $item.Name
        if (Test-Path -LiteralPath $destinationPath) {
            Remove-Item -Recurse -Force -LiteralPath $destinationPath
        }
        Move-Item -LiteralPath $item.FullName -Destination $destinationPath -Force
    }
}

function ConvertTo-MarkdownPath {
    param([string]$Value)

    $parts = $Value -split '/'
    $escaped = foreach ($part in $parts) {
        [System.Uri]::EscapeDataString($part)
    }

    return ($escaped -join '/')
}

function ConvertTo-MarkdownText {
    param([string]$Value)

    if ([string]::IsNullOrEmpty($Value)) {
        return $Value
    }

    # Only escape square brackets in link text; parentheses are safe in Markdown
    return ($Value -replace '\[', '\\[' -replace '\]', '\\]')
}

function Get-RelativeMarkdownPath {
    param([string]$RootDir, [string]$FilePath)

    $RootDir = (Resolve-Path -LiteralPath $RootDir).Path
    $FilePath = (Resolve-Path -LiteralPath $FilePath).Path
    
    if ($FilePath.StartsWith($RootDir, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relativePath = $FilePath.Substring($RootDir.Length).TrimStart('\')
    } else {
        $relativePath = $FilePath
    }
    
    return $relativePath -replace '\\', '/'
}

Move-ContentsToOutput -SourceDir $skinsDir -TargetDir $targetSkinsDir
Move-ContentsToOutput -SourceDir $imagesDir -TargetDir $targetImagesDir

if ($HeaderText) {
    $header = $HeaderText
}
elseif ($NoPrompt) {
    $header = ''
}
else {
    $header = Read-MultilineInput 'Enter the content for the header section.'
}

if ($FooterText) {
    $footer = $FooterText
}
elseif ($NoPrompt) {
    $footer = ''
}
else {
    $footer = Read-MultilineInput 'Enter the content for the footer section.'
}

$skinFiles = Get-ChildItem -Path $targetSkinsDir -Recurse -Filter '*.osk' -File -ErrorAction SilentlyContinue | Sort-Object FullName
$imageFiles = Get-ChildItem -Path $targetImagesDir -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    $_.Extension -in @('.jpg', '.jpeg', '.png', '.gif', '.webp')
} | Sort-Object FullName

$paired = [System.Collections.Generic.List[object]]::new()
$missing = [System.Collections.Generic.List[object]]::new()
$pairedNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

foreach ($skinFile in $skinFiles) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($skinFile.Name)
    $matchingImage = $imageFiles | Where-Object {
        $_.BaseName -ieq $baseName -or $_.Name -ieq "$baseName.jpg" -or $_.Name -ieq "$baseName.png"
    } | Select-Object -First 1

    if ($matchingImage) {
        $paired.Add([pscustomobject]@{
            Name = $baseName
            SkinFileName = $skinFile.Name
            SkinRelativePath = Get-RelativeMarkdownPath -RootDir $outputRoot -FilePath $skinFile.FullName
            ImageFileName = $matchingImage.Name
            ImageRelativePath = Get-RelativeMarkdownPath -RootDir $outputRoot -FilePath $matchingImage.FullName
        })
        [void]$pairedNames.Add($baseName)
    }
    else {
        $missing.Add([pscustomobject]@{
            Name = $baseName
            MissingImage = $true
            SkinFileName = $skinFile.Name
            ImageFileName = $null
        })
    }
}

foreach ($imageFile in $imageFiles) {
    $baseName = $imageFile.BaseName
    if ($pairedNames.Contains($baseName)) {
        continue
    }

    $matchingSkin = $skinFiles | Where-Object {
        [System.IO.Path]::GetFileNameWithoutExtension($_.Name) -ieq $baseName -or $_.Name -ieq "$baseName.osk"
    } | Select-Object -First 1
    if (-not $matchingSkin) {
        $missing.Add([pscustomobject]@{
            Name = $baseName
            MissingSkin = $true
            SkinFileName = $null
            ImageFileName = $imageFile.Name
        })
    }
}

$lines = [System.Collections.Generic.List[string]]::new()
if ($header) {
    $lines.Add($header)
}
$lines.Add('')
$lines.Add('![visitors](https://visitor-badge.laobi.icu/badge?page_id=Inlayo.Inlayo-skins)')
$lines.Add('')

if ($paired.Count -gt 0) {
    foreach ($item in $paired) {
        $encodedSkin = ConvertTo-MarkdownPath -Value $item.SkinRelativePath
        $encodedImage = ConvertTo-MarkdownPath -Value $item.ImageRelativePath
        $displayName = ConvertTo-MarkdownText -Value $item.Name
        $lines.Add('')
        $lines.Add('---')
        $lines.Add('')
        $lines.Add("## [$displayName]($encodedSkin)")
        $lines.Add('')
        $lines.Add("[![$displayName]($encodedImage)]($encodedSkin)")
    }
}
else {
    $lines.Add('')
    $lines.Add('No valid skin/image pairs were found yet.')
    $lines.Add('')
}

if ($missing.Count -gt 0) {
    $lines.Add('')
    $lines.Add('## Missing Files')
    $lines.Add('')
    foreach ($item in $missing) {
        $notes = [System.Collections.Generic.List[string]]::new()
        if ($item.MissingImage) {
            $notes.Add('missing image')
        }
        if ($item.MissingSkin) {
            $notes.Add('missing .osk')
        }
        $detail = if ($notes.Count -gt 0) { ' (' + ($notes -join ', ') + ')' } else { '' }
        $lines.Add("- $($item.Name)$detail")
    }
    $lines.Add('')
}

if ($footer) {
    $lines.Add('')
    $lines.Add($footer)
}

$content = ($lines -join [Environment]::NewLine).TrimEnd() + [Environment]::NewLine
Set-Content -Path $readmePath -Value $content -Encoding utf8

Write-Host ''
Write-Host 'Generated README created successfully.'
Write-Host "Saved to: $readmePath"
Write-Host ''
Write-Host '--- Preview ---'
Write-Host $content
