CREATE DATABASE IF NOT EXISTS `notaryserver`;

CREATE USER "server"@"%" IDENTIFIED BY "";

GRANT
	SELECT, INSERT, UPDATE, DELETE ON `notaryserver`.*
	TO "server"@"%";
