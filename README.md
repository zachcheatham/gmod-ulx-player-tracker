# ULX Player Tracker
A simple (okay, maybe its a little complex) system that logs every player that joins your server.

### Features
- Stores every name a player has ever used.
- Displays a chat notification when a player joins with a new name.
- Uses the Steam API to check if a player is using Family Sharing and stores the Steam ID of the parent account.
- Will automatically ban players who attempt to ban evade by making a Family Sharing account.
- Stores the last three IP addresses of players.
- Stores the last server a player has connected to.
- Stores the first and last time a player was seen.
- Backed by MySQL to store and keep information from multiple servers in sync.
- XGUI tab for viewing recent players and searching for players.
- Admins can search the database for players using a SteamID, IP Address, or even part of a name.
- ULX permissions are used to control who can use the XGUI players tab.

### Example Uses
- Easily finding a player's alt-accounts.
- Checking if a player is using Family Sharing to play Garry's Mod.
- Keeping track of the first time a player joined your server.
- Using a player's IP address on a website to associate them with a Steam ID.

### Planned Changes
- Use ULX group inheritance to check whether an admin can see another admin's player data.
- Autoban for ban evading by joining the server on the same IP using a never-before-seen account.
- Making autobans optional.

## Installation
1. Obviously, you must already have ULib and ULX installed.
2. Download this repository and place it inside your server's addons folder.
3. Download [ZCore](https://github.com/zachcheatham/gmod-zcore) and place it inside your server's addons folder.
4. Make sure you've configured ZCore's configuration file with your MySQL credentials.
5. If you want to use Family Sharing, edit the first line of lua/ulx/modules/playertracker/familysharing.lua with your Steam API key.
6. Start up your server! All of the MySQL tables should be automatically created for you when it launches.

If you have any issues with the addon, please let me know in the issue tracker! Mind you, this addon was created privately for a community and I finally thought it was time to let anyone benefit from it.
