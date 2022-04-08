USE `essentialmode`;

INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES ('gas', 'Essence', '200', '0', '1');
INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES ('refined_oil', 'Pétrole Raffiné', '200', '0', '1');
INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES ('oil', 'Pétrole', '200', '0', '1');

INSERT INTO `jobs` (`name`, `label`) VALUES ('gas', 'Essence');

INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES ('gas', '0', 'employee', 'Intérimaire', '0', '{}', '{}');
