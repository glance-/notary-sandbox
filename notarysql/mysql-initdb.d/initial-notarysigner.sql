CREATE DATABASE IF NOT EXISTS `notarysigner`;

CREATE USER "signer"@"%" IDENTIFIED BY "";

GRANT
	SELECT, INSERT, UPDATE, DELETE ON `notarysigner`.*
	TO "signer"@"%";
