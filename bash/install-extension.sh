#!/bin/bash

# make sure Docker is running
cd ~/mediawiki || exit
docker compose up -d

# collect extension name
echo "What's the name of the extension? Capitalize it correctly please."
read -r extensionName

# git clone
cd ~/mediawiki/extensions || exit
git clone "ssh://novemlinguae@gerrit.wikimedia.org:29418/mediawiki/extensions/$extensionName"

# composer update
docker compose exec mediawiki composer update --working-dir "extensions/$extensionName"

# npm ci
cd "$HOME/mediawiki/extensions/$extensionName" || exit
npm ci

# make .vscode/settings.json file. so that when extension is open in IDE, intellisense loads type hints for objects from mediawiki core
cd "$HOME/mediawiki/extensions/$extensionName" || exit
mkdir .vscode
cd "$HOME/mediawiki/extensions/$extensionName/.vscode" || exit
touch settings.json
printf "{\n\t\"intelephense.environment.includePaths\": [\n\t\t\"../../\"\n\t]\n}\n" >> settings.json

# add wfLoadExtension to LocalSettings.php
cd ~/mediawiki || exit
echo "wfLoadExtension( '$extensionName' );" >> LocalSettings.php

# composer update for mediawiki core, so that the next step doesn't freak out
cd ~/mediawiki || exit
docker compose exec mediawiki composer update

# update the SQL database
cd ~/mediawiki || exit
docker compose exec mediawiki php maintenance/run.php update

# cd to the extension's directory. for easy git reviewing
cd "$HOME/mediawiki/extensions/$extensionName" || exit

# open VS Code for this extension
code .
