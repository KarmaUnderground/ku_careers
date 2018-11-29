USE `essentialmode`;

CREATE TABLE `user_skills` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(255) COLLATE utf8mb4_bin NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_bin NOT NULL,
  `level` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

INSERT INTO `items` (`name`, `label`, `limit`, `rare`, `can_remove`) VALUES ('gas', 'Essence', '200', '0', '1');
INSERT INTO `items` (`name`, `label`, `limit`, `rare`, `can_remove`) VALUES ('refined_oil', 'Pétrole Raffiné', '200', '0', '1');
INSERT INTO `items` (`name`, `label`, `limit`, `rare`, `can_remove`) VALUES ('oil', 'Pétrole', '200', '0', '1');

INSERT INTO `jobs` (`name`, `label`) VALUES ('gas', 'Essence');

INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES ('gas', '0', 'employee', 'Intérimaire', '0', '{}', '{}');
