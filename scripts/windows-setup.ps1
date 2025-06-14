# Install Scoop
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
}

# Install Winget
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Winget is not installed. Please install Winget manually from the Microsoft Store."
    exit
}

# Setup dotfiles
$symlinks = @(
    @{source="$HOME\dotfiles\.config\nvim"; target="$HOME\AppData\Local\nvim"},
    @{source="$HOME\dotfiles\.wezterm.lua"; target="$HOME\.wezterm.lua"},
    @{source="$HOME\dotfiles\.ideavimrc"; target="$HOME\.ideavimrc"},
    @{source="$HOME\dotfiles\.gitconfig"; target="$HOME\.gitconfig"},
    @{source="$HOME\dotfiles\.gitconfig-windows"; target="$HOME\.gitconfig-windows"},
    @{source="$HOME\dotfiles\.ssh\config-windows"; target="$HOME\.ssh\config"}
)

foreach ($link in $symlinks) {
    $sourcePath = $link.source
    $targetPath = $link.target

    if (Test-Path $targetPath) {
        $response = Read-Host "Directory '$($targetPath)' already exists. Do you want to delete and replace with symlink? (Y/N)"
        if ($response -eq 'Y' -or $response -eq 'Yes') {
            Remove-Item -Recurse -Force $targetPath
            New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath
            Write-Host "Symbolic link created successfully for $targetPath."
        } else {
            Write-Host "Operation cancelled for $targetPath."
        }
    } else {
        New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath
        Write-Host "Symbolic link created successfully for $targetPath."
    }
}

# List of apps to check and install
$scoopApps = @(
    'git',
    'lazygit'
    'logseq',
    'wezterm',
    'nvm',
    'difftastic',
    'neovim-nightly',
    'autohotkey',
    '7zip',
    'ripgrep',
    'nmap',
    'fzf',
    'bottom'
)

$wingetApps = @(
    'GitHub.cli',
    'Postman.Postman',
    'JetBrains.IntelliJIDEA.Ultimate',
    'JetBrains.Rider',
    'JetBrains.DataGrip',
    'Docker.DockerDesktop'
)

# Check and install each Scoop app
foreach ($app in $scoopApps) {
    if (-not (scoop list $app -q)) {
        scoop install $app
    }
}

# Check and install each Winget app
foreach ($app in $wingetApps) {
    $installed = winget list --id $app -q
    if (-not $installed) {
        winget install --id $app --silent
    }
}

Write-Host "Installation Complete."
Write-Host "Download latest NetPad: https://github.com/tareqimbasher/NetPad/releases/latest"
