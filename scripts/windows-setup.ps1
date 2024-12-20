# Install Scoop
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
}

# Install Winget
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Winget is not installed. Please install Winget manually from the Microsoft Store."
    exit
}

# List of apps to check and install
$scoopApps = @(
    'git',
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
    'delta',
    'bottom'
)

$wingetApps = @(
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
