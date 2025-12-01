
$arg = ""
if ($args.Count -ge 1) {
    $arg = $args[0]
}

# Exit if empty
if ([string]::IsNullOrWhiteSpace($arg)) {
    exit 0
}

# HashSet for deduplication
$seen = New-Object System.Collections.Generic.HashSet[string]

# Split on commas, trim, skip empty
$patterns = $arg.Split(',') |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne "" }

foreach ($pattern in $patterns) {

    # Expand wildcards
    $matches = @(Get-ChildItem -Path $pattern -File -ErrorAction SilentlyContinue |
                 Select-Object -ExpandProperty FullName)

    # If no wildcard matches but literal file exists → include it
    if ($matches.Count -eq 0 -and (Test-Path -LiteralPath $pattern -PathType Leaf)) {
        $matches = @((Resolve-Path -LiteralPath $pattern).Path)
    }

    # Output each matched file exactly once
    foreach ($path in $matches) {
        if (-not $seen.Contains($path)) {
            $seen.Add($path) | Out-Null
            Write-Output $path
        }
    }
}
