# patternmatching.ps1
param(
    [string]$file = "",
    [string]$keywords = ""
)

if ([string]::IsNullOrWhiteSpace($keywords) -or [string]::IsNullOrWhiteSpace($file)) {
    exit 0
}

if (-not (Test-Path -Path $file -PathType Leaf)) {
    exit 0
}

$fileName = Split-Path -Leaf $file
$keywordList = $keywords -split '\|' | ForEach-Object { $_.Trim() } | Sort-Object

foreach ($keyword in $keywordList) {
    if ([string]::IsNullOrWhiteSpace($keyword)) {
        continue
    }
    
    try {
        $content = Get-Content -Path $file -Raw -ErrorAction SilentlyContinue
        if ($content) {
            $count = ([regex]::Matches($content, $keyword, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
            Write-Output "$file;$fileName;$keyword;$count"
        }
    } catch {
        # Silently continue on errors
    }
}


