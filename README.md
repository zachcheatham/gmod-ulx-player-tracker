ULX Player Tracker
==============
An easy to use player tracking system for ULX.

### Features ###
* Stores every name a player has ever used.
* Stores the last three IP addresses of players.
* Stores the last server a player has connected to.
* Stores the first and last time a player was seen.
* Ability to view a player's Family Sharing status and get the actual owner's Steam ID.
* Backed by MySQL to store and keep information from multiple servers in sync.
* XGUI tab for viewing recent players and searching for players.
* Admins can search the entire database of players using a Steam ID, IP Address, or even part of a name.
* Can optionally automatically ban players who attempt to ban evade by making a Family Sharing account.
* Can optionally display a chat notification when a player joins with a new name.

### Example Uses ###
* Easily find players' alt-accounts.
* Find players' previous aliases further back than Steam can.
* Check if a player is using Family Sharing.
* Quickly ban disconnected players using the recent players list.
* Using the MySQL database on a website to associate Steam IDs with IP addresses.

### Requirements ###
* ULX
* MySQLOO

### Installation ###
1. Extract the archive into your server's "addons" directory.
2. Edit the configuration (ulx-player-tracker/lua/ulx/modules/playertracker/config.lua) to your liking.
3. Launch your server! All of the MySQL tables should be automatically created after its connected.