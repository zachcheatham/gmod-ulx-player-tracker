local config = {}
config.mysql = {}

--
-- EDIT BELOW THIS!
--

-- MySQL credentials
config.mysql.host = ""
config.mysql.db = ""
config.mysql.user = ""
config.mysql.pass = ""

-- Your Steam API (Needed for checking Family Sharing)
config.steamapikey = ""

-- If true, will display a chat message if a user joins with a new name.
config.namechangealert = true

-- If true, family shared alt-accounts will automatically be re-banned for the remaining 
config.fsevadeban = true

--
-- EDIT ABOVE THIS!
--

ulx.playertracker.config = config