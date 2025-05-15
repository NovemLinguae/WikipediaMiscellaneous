#!/bin/bash

# A script for developers to delete and recreate their localhost MediaWiki. Deletes and recreates core, extensions, and skins. Specify extensions and skins in the array below.

# This script assumes:
#    - Docker, WSL/Ubuntu, MariaDB not SQLite, installation location of MediaWiki core is ~/mediawiki, VS Code
#    - Wiki farm. Will create wiki #1 at /wiki/, /w/, and database my_database. Will create wiki #2 at /secondwiki/, /w2/, and database secondwiki. Wiki farms are useful for testing extensions like CentralAuth, SecurePoll's jump-url feature, etc.
#    - You should have git and nvm installed. `sudo apt install git`, `curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash`, close and reopen bash window, `nvm install 18`
#    - Your Gerrit SSH key should be saved at ~/.ssh/id_ed25519

# TODO: just use advanced patchdemo docker instead of this script? https://gitlab.wikimedia.org/samtar/patchdemo/-/commit/d0fbe70728113c29520fad280bdc5a31ee2221b3

# UPDATE THESE VARIABLES BEFORE RUNNING THE SCRIPT ************************
extensions=("PageTriage" "Echo" "WikiLove" "ORES" "FlaggedRevs" "SecurePoll" "VisualEditor")
skins=("Vector")
sshUsername="novemlinguae"
ubuntuUsername="novemlinguae"
branch="master" # "master" "REL1_42"
apacheImage="docker-registry.wikimedia.org/dev/bookworm-apache2:1.0.1" # this must stay in sync with what's in mediawiki/docker-compose.yml -> mediawiki-web -> image. else the wikifarm / second wiki might break.
nodeVersion="20" # helpful to keep this in sync with Wikimedia CI. https://phabricator.wikimedia.org/T343827
# *************************************************************************

# docker: make sure docker engine is running
dockerStatus=$(docker --help)
if [[ $dockerStatus =~ "could not be found" ]]; then
  echo "Error: Docker is not running. Please start Docker Desktop, then try again."
  exit 1
fi

# set node version
export NVM_DIR=$HOME/.nvm;
source "$NVM_DIR/nvm.sh";
nvm use $nodeVersion

# save password for this session. will prevent shell constantly asking the user for it
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# docker: delete database (volume = mediawiki_mariadbdata)
if [ -d "$HOME/mediawiki" ]; then
  cd ~/mediawiki || exit
  docker compose down --volumes
fi

# delete files from previous installation
sudo rm -rfv ~/mediawiki

# mediawiki core: download files
# docker: download files (e.g. docker-compose.yml)
cd ~/ || exit
git clone -b $branch "ssh://$sshUsername@gerrit.wikimedia.org:29418/mediawiki/core" ~/mediawiki

# docker: create .env file
cat > ~/mediawiki/.env << EOF
MW_SCRIPT_PATH=/w
MW_SERVER=http://localhost:8080
MW_DOCKER_PORT=8080
MEDIAWIKI_USER=Admin
MEDIAWIKI_PASSWORD=dockerpass
XDEBUG_ENABLE=true
XDEBUG_CONFIG='mode=debug start_with_request=yes client_host=host.docker.internal client_port=9003 idekey=VSCODE'
XDEBUG_MODE=debug,coverage
XHPROF_ENABLE=true
PHPUNIT_LOGS=0
PHPUNIT_USE_NORMAL_TABLES=1
MW_DOCKER_UID=
MW_DOCKER_GID=
EOF

# docker: create MariaDB & wikifarm configuration file
# https://www.mediawiki.org/wiki/MediaWiki-Docker/Configuration_recipes/Alternative_databases#MariaDB_(single_database_server)
# https://www.mediawiki.org/wiki/MediaWiki-Docker/Configuration_recipes/Wiki_farm
cat > ~/mediawiki/docker-compose.override.yml << EOF
services:
  mariadb:
    image: 'bitnami/mariadb:latest'
    volumes:
      - mariadbdata:/bitnami/mariadb
    environment:
      - MARIADB_ROOT_PASSWORD=root_password
      - MARIADB_USER=my_user
      - MARIADB_PASSWORD=my_password
      - MARIADB_DATABASE=my_database
    ports:
      - 3306:3306
  mediawiki:
    # On Linux, these lines ensure file ownership is set to your host user/group
    user: "${MW_DOCKER_UID}:${MW_DOCKER_GID}"
    volumes:
      - ./:/var/www/html/w2:cached
  mediawiki-web:
    user: "${MW_DOCKER_UID}:${MW_DOCKER_GID}"
    volumes:
      - ./:/var/www/html/w2:cached
    build:
      context: ~/
      dockerfile: Dockerfile
  mediawiki-jobrunner:
    volumes:
      - ./:/var/www/html/w2:cached
volumes:
  mariadbdata:
    driver: local
EOF

# docker: create wikifarm configuration file
# https://www.mediawiki.org/wiki/MediaWiki-Docker/Configuration_recipes/Wiki_farm
cat > ~/Dockerfile << EOF
# Important: Make sure the version here matches the latest version of the mediawiki-web image in docker-compose.yml
FROM $apacheImage

RUN grep -q "secondwiki" /etc/apache2/sites-available/000-default.conf || sed -i '/RewriteEngine On/a RewriteRule ^/?secondwiki(/.*)?$ %{DOCUMENT_ROOT}/w2/index.php' /etc/apache2/sites-available/000-default.conf
EOF

# start Docker, using the Dockerfile in that version of MediaWiki
cd ~/mediawiki || exit
docker compose up -d

# mediawiki core: install PHP dependencies
cd ~/mediawiki || exit
docker compose exec mediawiki composer update

# mediawiki core: install Node dependencies
cd ~/mediawiki || exit
npm ci

# mediawiki core: do initial database creation and initial LocalSettings.php file creation
source ~/mediawiki/.env # import .env variables. else we can't see their values
cd ~/mediawiki || exit
# don't switch this to maintenance/run.php. need to stay compatible with old MW versions
docker compose exec mediawiki php maintenance/install.php --dbname=my_database --dbuser=my_user --dbpass=my_password --dbserver=mariadb --server="${MW_SERVER}" --scriptpath="${MW_SCRIPT_PATH}" --lang en --pass "${MEDIAWIKI_PASSWORD}" Wikipedia "${MEDIAWIKI_USER}"

# wiki farm: create 2nd database
cd ~/mediawiki || exit
docker compose exec mariadb mariadb -u root -proot_password -e "CREATE DATABASE secondwiki" || exit
docker compose exec mariadb mariadb -u root -proot_password -e "GRANT ALL PRIVILEGES ON secondwiki.* TO 'my_user'@'%' IDENTIFIED BY 'my_password'; FLUSH PRIVILEGES;" || exit
mv LocalSettings.php LocalSettings2.php || exit
docker compose exec mediawiki php maintenance/install.php --dbname=secondwiki --dbuser=my_user --dbpass=my_password --dbserver=mariadb --server="${MW_SERVER}" --scriptpath="${MW_SCRIPT_PATH}" --lang en --pass "${MEDIAWIKI_PASSWORD}" Wikipedia "${MEDIAWIKI_USER}"
rm -f LocalSettings.php
mv LocalSettings2.php LocalSettings.php

# wiki farm: create different SVG logos for each wiki
mkdir ~/mediawiki/images/temp
cat > ~/mediawiki/images/temp/change-your-logo-1.svg << EOF
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg
   width="135"
   height="135"
   version="1.1"
   id="svg2"
   sodipodi:docname="change-your-logo-1.svg"
   inkscape:version="1.4 (86a8ad7, 2024-10-11)"
   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
   xmlns="http://www.w3.org/2000/svg"
   xmlns:svg="http://www.w3.org/2000/svg">
  <rect
     style="fill:#ffd42a;stroke-width:5.66929"
     id="rect2"
     width="128.11765"
     height="128.51471"
     x="3.5735295"
     y="3.4411764" />
  <text
     x="67.897057"
     y="43.691177"
     text-anchor="middle"
     dominant-baseline="middle"
     font-family="Arial"
     font-size="20px"
     fill="#000000"
     id="text2"><tspan
       x="67.897057"
       dy="24"
       id="tspan2">Test Wiki #1</tspan></text>
</svg>
EOF
cat > ~/mediawiki/images/temp/change-your-logo-2.svg << EOF
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg
   width="135"
   height="135"
   version="1.1"
   id="svg2"
   sodipodi:docname="change-your-logo-2.svg"
   inkscape:version="1.4 (86a8ad7, 2024-10-11)"
   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
   xmlns="http://www.w3.org/2000/svg"
   xmlns:svg="http://www.w3.org/2000/svg">
  <rect
     style="fill:#00ffff;stroke-width:5.66929"
     id="rect2"
     width="128.11765"
     height="128.51471"
     x="3.5735295"
     y="3.4411764" />
  <text
     x="67.897057"
     y="43.691177"
     text-anchor="middle"
     dominant-baseline="middle"
     font-family="Arial"
     font-size="20px"
     fill="#000000"
     id="text2"><tspan
       x="67.897057"
       dy="24"
       id="tspan2">Test Wiki #2</tspan></text>
</svg>
EOF

# mediawiki core: append some settings to LocalSettings.php configuration file
# This overwrites some previously set settings. It is easier to append these settings to the bottom of the file, than to try to surgically edit the LocalSettings.php generated by the install script.
sudo tee -a ~/mediawiki/LocalSettings.php << EOL
// ***************** WIKI FARM CODE ********************

// This maps URL paths to DB names. Note that we need to include both long and short URLs
\$wikis = [
   'wiki' => 'my_database',
   'w' => 'my_database',
   'secondwiki' => 'secondwiki',
   'w2' => 'secondwiki',
];
if ( defined( 'MW_DB' ) ) {
   // Automatically set from --wiki option to maintenance scripts.
   \$wikiID = MW_DB;
} else {
   \$path = explode( '/', \$_SERVER['REQUEST_URI'] ?? '', 3 )[1] ?? '';
   // Note that we are falling back to the main wiki for convenience. You could also throw an exception instead.
   \$wikiID = \$_SERVER['MW_DB'] ?? \$wikis[ \$path ] ?? 'my_database';
}

/** @var SiteConfiguration \$wgConf */
\$wgLocalDatabases = \$wgConf->wikis = array_values( array_unique( \$wikis ) );
\$wgConf->suffixes = [ 'wiki' ];
\$wgDBname = \$wikiID;

// These are the only settings you will have to include here. Everything else is optional.
\$wgConf->settings = [
   'wgCanonicalServer' => [
      'default' => 'http://localhost:8080'
   ],
   'wgArticlePath' => [
      'my_database' => '/wiki/\$1',
      'secondwiki' => '/secondwiki/\$1',
   ],
   'wgScriptPath' => [
      'my_database' => '/w',
      'secondwiki' => '/w2',
   ],
   'wgLogos' => [
	  'my_database' => [
		 '1x' => '/w/images/temp/change-your-logo-1.svg',
		 'icon' => '/w/resources/assets/change-your-logo-icon.svg',
	  ],
	  'secondwiki' => [
		 '1x' => '/w2/images/temp/change-your-logo-2.svg',
		 'icon' => '/w2/resources/assets/change-your-logo-icon.svg',
	  ],
   ],
];

\$wgConfGlobals = \$wgConf->getAll( \$wgDBname );
extract( \$wgConfGlobals );

## The URL path to static resources (images, scripts, etc.)
\$wgResourceBasePath = \$wgScriptPath;

// ***************** EXTRA SETTINGS ********************

\$wgMaxArticleSize = 2048; // default is 20, which is way too small

\$wgGroupPermissions['autoreviewer']['autopatrol'] = true; // autoreviewed
\$wgGroupPermissions['patroller']['patrol'] = true; // NPP
\$wgGroupPermissions['sysop']['autopatrol'] = false; // to better match enwiki
\$wgGroupPermissions['sysop']['deleterevision'] = true; // revision deletion
\$wgGroupPermissions['sysop']['deletelogentry'] = true; // revision deletion

// let sysop group (which doesn't have userrights permission) add and remove these groups
\$wgAddGroups['sysop'][] = 'autoreviewer';
\$wgAddGroups['sysop'][] = 'patroller';
\$wgRemoveGroups['sysop'][] = 'autoreviewer';
\$wgRemoveGroups['sysop'][] = 'patroller';

\$wgShowExceptionDetails = true; // verbose error messages

// user script stuff
\$wgAllowUserJs = true;
\$wgAllowUserCss = true;
\$wgResourceLoaderValidateJS = false;

\$wgWatchlistExpiry = true;

\$wgEnableUploads = true;

\$wgDefaultSkin = "vector";

// ORES & PageTriage configuration
\$wgPageTriageDraftNamespaceId = 118;
\$wgExtraNamespaces[ \$wgPageTriageDraftNamespaceId ] = 'Draft';
\$wgExtraNamespaces[ \$wgPageTriageDraftNamespaceId + 1 ] = 'Draft_talk';
\$wgPageTriageNoIndexUnreviewedNewArticles = true;
\$wgPageTriageEnableCopyvio = true;
\$wgPageTriageEnableOresFilters = true;
\$wgOresWikiId = 'enwiki';
\$wgOresModels = [
	'articlequality' => [ 'enabled' => true, 'namespaces' => [ 0 ], 'cleanParent' => true ],
	'draftquality' => [ 'enabled' => true, 'namespaces' => [ 0 ], 'types' => [ 1 ] ]
];

// Turn off all caches. Very annoying to debug when stuff is getting cached. This overrides the cache setting on line 79.
\$wgMainCacheType = CACHE_NONE;
\$wgMessageCacheType = CACHE_NONE;
\$wgParserCacheType = CACHE_NONE;
\$wgResourceLoaderMaxage = [
  'versioned' => 0,
  'unversioned' => 0
];

\$wgGroupPermissions['electionadmin']['securepoll-create-poll'] = true;
\$wgGroupPermissions['electionadmin']['securepoll-edit-poll'] = true;
\$wgGroupPermissions['electionadmin']['securepoll-view-voter-pii'] = true;
\$wgSecurePollUseLogging = true;
\$wgSecurePollEditOtherWikis = true;
// \$wgSecurePollUseNamespace = true; // commenting out since this is currently broken in localhost. T381230. the error appears when creating a poll

\$wgRCMaxAge = 30 * 24 * 60 * 60; // 30 days, to match enwiki. In seconds

// ***************** EXTENSIONS & SKINS ********************
EOL

# VS Code: create debugger configuration file that works in WSL. the hostname: "0.0.0.0" line is particularly important.
mkdir ~/mediawiki/.vscode
cat > ~/mediawiki/.vscode/launch.json << EOF
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
			  "/var/www/html/w": "\${workspaceFolder}"
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

# make uploads directory writeable
chmod 0777 ~/mediawiki/images

# make cache directory writeable. this will let mediawiki write detailed debug logs (mw-debug-web.log)
chmod 0777 ~/mediawiki/cache

# install extensions
for extensionName in "${extensions[@]}"; do
  cd ~/mediawiki/extensions || exit
  git clone -b $branch "ssh://$sshUsername@gerrit.wikimedia.org:29418/mediawiki/extensions/$extensionName"
  docker compose exec mediawiki composer update --working-dir "extensions/$extensionName"
  cd "$extensionName" || exit
  npm ci
  mkdir .vscode
  cd .vscode || exit
  touch settings.json
  printf "{\n\t\"intelephense.environment.includePaths\": [\n\t\t\"../../\"\n\t]\n}\n" >> settings.json
  echo "wfLoadExtension( '$extensionName' );" | sudo tee -a ~/mediawiki/LocalSettings.php
done

# install skins
for skinName in "${skins[@]}"; do
  cd ~/mediawiki/skins || exit
  git clone -b $branch "ssh://$sshUsername@gerrit.wikimedia.org:29418/mediawiki/skins/$skinName"
  docker compose exec mediawiki composer update --working-dir "skins/$skinName"
  cd "$skinName" || exit
  npm ci
  mkdir .vscode
  cd .vscode || exit
  touch settings.json
  printf "{\n\t\"intelephense.environment.includePaths\": [\n\t\t\"../../\"\n\t]\n}\n" >> settings.json
  echo "wfLoadSkin( '$skinName' );" | sudo tee -a ~/mediawiki/LocalSettings.php
done

# VisualEditor needs some extra stuff
cd ~/mediawiki/extensions/VisualEditor || exit
git submodule update --init

# run database update
cd ~/mediawiki || exit
# don't switch this to maintenance/run.php. need to stay compatible with old MW versions
docker compose exec mediawiki php maintenance/update.php --quick

# wiki farm: run database update on second database
cd ~/mediawiki || exit
# don't switch this to maintenance/run.php. need to stay compatible with old MW versions
docker compose exec mediawiki php maintenance/update.php --quick --wiki secondwiki

# install script saves some files as root for some reason. this is annoying when trying to edit files in Windows Notepad++ (won't let you save). set them as owned by local user instead.
sudo chown -R $ubuntuUsername:$ubuntuUsername ~/mediawiki
sudo chown $ubuntuUsername:$ubuntuUsername ~/Dockerfile
