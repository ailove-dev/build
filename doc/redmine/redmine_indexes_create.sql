ALTER TABLE `users` ADD INDEX(`login`);
ALTER TABLE `members` ADD INDEX(`user_id`);
