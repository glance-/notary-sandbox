CREATE DATABASE IF NOT EXISTS `notaryserver`;

GRANT
	SELECT, INSERT, UPDATE, DELETE ON `notaryserver`.*
	TO "server"@"%";
