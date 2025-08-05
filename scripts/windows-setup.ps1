<#
.SYNOPSIS
Setup new windows machine dotfiles and applications


#>

# Ensure Scoop is installed
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    try {
        Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
    } catch {
        Write-Host "❌ Scoop is not installed. Please install it manually."
        exit
    }
}


# Ensure Winget is installed
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Winget is not installed. Please install it manually from the Microsoft Store."
    exit
}

# Define items
$dotfiles = @(
    @{label="Symlink nvim config"; source="$HOME\dotfiles\.config\nvim"; target="$HOME\AppData\Local\nvim"},
    @{label="Symlink wezterm config"; source="$HOME\dotfiles\.wezterm.lua"; target="$HOME\.wezterm.lua"},
    @{label="Symlink ideavimrc"; source="$HOME\dotfiles\.ideavimrc"; target="$HOME\.ideavimrc"},
    @{label="Symlink gitconfig"; source="$HOME\dotfiles\.gitconfig"; target="$HOME\.gitconfig"},
    @{label="Symlink gitconfig-windows"; source="$HOME\dotfiles\.gitconfig-windows"; target="$HOME\.gitconfig-windows"},
    @{label="Symlink ssh config"; source="$HOME\dotfiles\.ssh\config-windows"; target="$HOME\.ssh\config"}
)

$scoopApps = @(
    'lazygit', 'logseq', 'mingw', 'nvm', 'difftastic',
    'autohotkey', 'ripgrep', 'nmap', 'fzf', 'bottom'
)

$wingetApps = @(
    'Alacritty.Alacritty', 'Git.Git', 'GitHub.cli', 'icsharpcode.ILSpy', 'Neovim.Neovim.Nightly'
    'Postman.Postman', 'JetBrains.IntelliJIDEA.Ultimate', 'JetBrains.Rider',
    'JetBrains.DataGrip', 'Microsoft.PowerShell', 'Docker.DockerDesktop'
)

function Show-Menu {
    Write-Host "`n0. Configure dotfile symlinks"
    $i = 1
    foreach ($app in $scoopApps) {
        Write-Host "$i. Scoop: $app"
        $i++
    }
    foreach ($app in $wingetApps) {
        Write-Host "$i. Winget: $app"
        $i++
    }
}

function Parse-Selection($userInput) {
    $total = $scoopApps.Count + $wingetApps.Count
    $selected = @()

    if ($userInput -eq "all") {
        $selected = 0..$total
    } else {
        $parts = $userInput -split ","
        foreach ($part in $parts) {
            if ($part -match "^\d+$") {
                $selected += [int]$part
            } elseif ($part -match "^(\d+)-(\d+)$") {
                $start = [int]$matches[1]
                $end = [int]$matches[2]
                $selected += $start..$end
            } else {
                Write-Host "Invalid input: $part"
            }
        }
    }

    return $selected
}

function Configure-Dotfiles {
    foreach ($link in $dotfiles) {
        $source = $link.source
        $target = $link.target
        $parent = Split-Path $target

        if (-not (Test-Path $parent)) {
            New-Item -ItemType Directory -Path $parent | Out-Null
        }

        if (Test-Path $target) {
            $response = Read-Host "Directory '$target' exists. Replace with symlink? (Y/N)"
            if ($response -match "^(Y|Yes)$") {
                Remove-Item -Recurse -Force $target
                New-Item -ItemType SymbolicLink -Path $target -Target $source
                Write-Host "✅ Symlink created for $target"
            } else {
                Write-Host "⏭️ Skipped $target"
            }
        } else {
            New-Item -ItemType SymbolicLink -Path $target -Target $source
            Write-Host "✅ Symlink created for $target"
        }
    }
}

function Ensure-7zip {
    $installed = winget list --id "7zip.7zip" | Select-String "7zip.7zip"
    if (-not $installed) {
        Write-Host "Installing 7zip via Winget (required for Scoop decompression)..."
        winget install --id "7zip.7zip" --silent
    } else {
        Write-Host "✅ 7zip already installed via Winget"
    }
}

function Install-Apps($selected) {
    $totalScoop = $scoopApps.Count
    $totalWinget = $wingetApps.Count

    # Ensure required Scoop buckets are added
    $requiredBuckets = @("main", "extras", "versions")
    foreach ($bucket in $requiredBuckets) {
        if (-not (scoop bucket list | Select-String $bucket)) {
            scoop bucket add $bucket
        }
    }

    foreach ($index in $selected) {
        if ($index -eq 0) {
            Configure-Dotfiles
        } elseif ($index -ge 1 -and $index -le $totalScoop) {
            $app = $scoopApps[$index - 1]
            if (-not (scoop list | Select-String "^$app\s")) {
                scoop install $app
            } else {
                Write-Host "✅ $app already installed (Scoop)"
            }
        } elseif ($index -gt $totalScoop -and $index -le ($totalScoop + $totalWinget)) {
            $app = $wingetApps[$index - $totalScoop - 1]
            $installed = winget list --id $app | Select-String $app
            if (-not $installed) {
                winget install --id $app --silent
            } else {
                Write-Host "✅ $app already installed (Winget)"
            }
        } else {
            Write-Host "❌ Invalid selection: $index"
        }
    }
}

#
# Main
#

# Validate scoop dependencies
if (-not (Get-Command 7z -ErrorAction SilentlyContinue) -and -not (scoop list | Select-String "^7zip\s")) {
    Write-Host "Installing 7zip (required for decompression)..."
    Ensure-7zip 
}

Show-Menu
$userInput = Read-Host "`nEnter numbers to install (e.g. 0,1,3-5 or 'all')"
$selected = Parse-Selection $userInput
Install-Apps $selected

Write-Host "`n✅ Setup complete!"
Write-Host "Download latest NetPad: https://github.com/tareqimbasher/NetPad/releases/latest"
