

INSERT INTO `addon_account` (name, label, shared) VALUES
	('society_ferrailleur', 'ferrailleur', 1)
;

INSERT INTO `addon_inventory` (name, label, shared) VALUES
	('society_ferrailleur', 'ferrailleur', 1)
;

INSERT INTO `jobs` (name, label) VALUES
	('ferrailleur', 'ferrailleur')
;

INSERT INTO `job_grades` (job_name, grade, name, label, salary, skin_male, skin_female) VALUES
	('ferrailleur',0,'recrue','Recrue',120,'{}','{}'),
	('ferrailleur',1,'novice','Novice',240,'{}','{}'),
	('ferrailleur',2,'experimente','Expert',360,'{}','{}'),
	('ferrailleur',3,'chief',"Chef d\'équipe",480,'{}','{}'),
	('ferrailleur',4,'boss','Patron',600,'{}','{}')
;
