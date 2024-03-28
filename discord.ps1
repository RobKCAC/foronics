winget.exe source reset --force
winget.exe source update --silent --accept-package-agreements --accept-source-agreements --exact --scope machine
winget.exe install discord.discord --silent --accept-package-agreements --accept-source-agreements
