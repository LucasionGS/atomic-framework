-- Import this file into your database to create the tables needed for the gamemode.
CREATE DATABASE IF NOT EXISTS `atomic` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

-- If necessary, create a user for the database and grant it all privileges.
-- CREATE USER 'atomic'@'localhost' IDENTIFIED BY 'atomic';
-- GRANT ALL PRIVILEGES ON `atomic`.* TO 'atomic'@'localhost';
-- FLUSH PRIVILEGES;

-- DROP TABLE IF EXISTS `atomic`.`characters`;
CREATE TABLE IF NOT EXISTS `atomic`.`characters` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  -- SteamID
  `steamid` varchar(255) NOT NULL UNIQUE,
  -- First name
  `firstname` varchar(255) NOT NULL,
  -- Last name
  `lastname` varchar(255) NOT NULL,
  -- Sex of the character
  `sex` varchar(255) NOT NULL,
  -- Player model used for the citizen job
  `model` varchar(255) NOT NULL,
  -- Player style index
  `style` int(11) NOT NULL DEFAULT '1',
  -- Player bodygroups in JSON format
  `bodygroups` TEXT NOT NULL DEFAULT '{}' COMMENT 'JSON object of bodygroups',
  -- Money in the player's wallet
  `money` int(11) NOT NULL DEFAULT '0',
  -- Money in the player's bank account
  `bank` int(11) NOT NULL DEFAULT '0',
  -- Rank on the server. This ranges from "user", "donater tiers", to "admin", and is used for permissions and other privileges.
  `rank` varchar(255) NOT NULL DEFAULT 'user',
  -- The organization the player is in.
  `organization` varchar(255) NULL,
  -- Organization rank
  `organization_rank` varchar(255) NULL,
  -- Time played in seconds. Updated every periodically.
  `time_played` int(11) NOT NULL DEFAULT '0',
  -- The last time the player logged in.
  `last_login` datetime NULL,
  -- The last time the player died.
  `last_death` datetime NULL,
  -- Amount of kills the player has.
  `kills` int(11) NOT NULL DEFAULT '0',
  -- Amount of deaths the player has.
  `deaths` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
);