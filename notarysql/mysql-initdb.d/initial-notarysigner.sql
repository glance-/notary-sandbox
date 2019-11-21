CREATE DATABASE IF NOT EXISTS `notarysigner`;

GRANT
	SELECT, INSERT, UPDATE, DELETE ON `notarysigner`.*
	TO "signer"@"%";
