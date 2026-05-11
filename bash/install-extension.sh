#!/bin/bash

# make sure Docker is running
cd ~/mediawiki || exit
docker compose up -d

# collect extension name
echo "What's the name of the extension? Capitalize it correctly please."
read -r extensionName

# git clone only?
echo "Do you want this extension to work in your browser? y for full install, n to skip database updates and skip wfLoadExtension (but gerrit and linters will still work)"
read -r browser

# git clone
cd ~/mediawiki/extensions || exit
git clone "ssh://novemlinguae@gerrit.wikimedia.org:29418/mediawiki/extensions/$extensionName"

# make .vscode/settings.json file. so that when extension is open in IDE, intellisense loads type hints for objects from mediawiki core
cd "$HOME/mediawiki/extensions/$extensionName" || exit
mkdir .vscode
cd "$HOME/mediawiki/extensions/$extensionName/.vscode" || exit
touch settings.json
printf "{\n\t\"intelephense.environment.includePaths\": [\n\t\t\"../../\"\n\t]\n}\n" >> settings.json

# and .vscode/launch.json for step debugging
cd "$HOME/mediawiki/extensions/$extensionName/.vscode" || exit
cat > launch.json << EOF
{
	// Use IntelliSense to learn about possible attributes.
	// Hover to view descriptions of existing attributes.
	// For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
	"version": "0.2.0",
	"configurations": [
		{
			"name": "Listen for XDebug",
			"type": "php",
			"request": "launch",
			"hostname": "0.0.0.0",
			"port": 9003,
			"pathMappings": {
				"/var/www/html/w/extensions/${extensionName}": "\${workspaceFolder}",
				"/var/www/html/w": "\${workspaceFolder}/../.."
			}
		},
		{
			"name": "Launch currently open script",
			"type": "php",
			"request": "launch",
			"program": "\${file}",
			"cwd": "\${fileDirname}",
			"port": 9003
		}
	]
}
EOF

# composer update
docker compose exec mediawiki composer update --working-dir "extensions/$extensionName"

# npm ci
cd "$HOME/mediawiki/extensions/$extensionName" || exit
npm ci

if [ "$browser" == "y" ]; then
	# add wfLoadExtension to LocalSettings.php
	cd ~/mediawiki || exit
	echo "wfLoadExtension( '$extensionName' );" >> LocalSettings.php

	# composer update for mediawiki core, so that the next step doesn't freak out
	cd ~/mediawiki || exit
	docker compose exec mediawiki composer update

	# update the SQL database
	cd ~/mediawiki || exit
	docker compose exec mediawiki php maintenance/run.php update
fi

# open VS Code for this extension
cd "$HOME/mediawiki/extensions/$extensionName" || exit
code .
