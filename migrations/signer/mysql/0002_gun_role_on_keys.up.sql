ALTER TABLE `private_keys` ADD COLUMN `gun` VARCHAR(255) NOT NULL, ADD COLUMN `role` VARCHAR(255) NOT NULL, ADD COLUMN `last_used` DATETIME NULL DEFAULT NULL;
