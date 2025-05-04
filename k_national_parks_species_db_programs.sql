USE national_park_species;

DROP VIEW IF EXISTS species_common_names;

-- species common names that have the word "weed" in them
CREATE VIEW species_common_weed AS 
	SELECT species_scientific_name, species_common_name
	FROM species_scientific ss
	JOIN species_common sco ON ss.species_common_id = sco.species_common_id
	HAVING sco.species_common_name LIKE "%weed%"; 
    
    
-- shows the average bird count for all parks
DROP VIEW IF EXISTS avg_bird_count;

CREATE VIEW avg_bird_count AS
	SELECT AVG(bird_count) AS avg_bird_count
    FROM 
		(SELECT p.park_id, COUNT(sp.species_scientific_id) AS bird_count
        FROM park p
        JOIN species_park sp ON p.park_id = sp.park_id
        JOIN species_scientific ss ON sp.species_scientific_id = ss.species_scientific_id
        JOIN species_category sc ON ss.species_category_id = sc.species_category_id
        WHERE sc.species_category = "Bird"
        GROUP BY p.park_id)
	AS bird_count_per_park;
    
-- retrieves the park with the highest amount of insects
DROP VIEW IF EXISTS max_insect_count;

CREATE VIEW max_insect_count AS
	SELECT MAX(total_insect_count) as max_insect_count
    FROM 
		(SELECT p.park_name, COUNT(sc.species_category) AS total_insect_count
        FROM park p
		JOIN species_park sp ON p.park_id = sp.park_id
        JOIN species_scientific ss ON sp.species_scientific_id = ss.species_scientific_id
        JOIN species_category sc ON ss.species_category_id = sc.species_category_id
		WHERE sc.species_category = "Insect"
        GROUP BY p.park_name) insect_count;

-- retrieves the species scientific name that is part of the ~aceae family
DROP VIEW IF EXISTS species_family_aceae;

CREATE VIEW species_family_aceae AS
	SELECT ss.species_scientific_name, sf.species_family 
    FROM species_scientific ss
    JOIN species_family sf ON ss.species_family_id = sf.species_family_id
    HAVING sf.species_family LIKE "%aceae"
    ORDER BY ss.species_scientific_name ASC;
    
-- PROCEDURES
DROP PROCEDURE IF EXISTS filter_family;

DELIMITER // 
CREATE PROCEDURE filter_family (IN keyword VARCHAR(45))
BEGIN
	SELECT * 
    FROM species_family
    WHERE species_family LIKE CONCAT ('%', keyword, '%');
END // 
DELIMITER ;

DROP PROCEDURE IF EXISTS filter_species_category_count;

DELIMITER // 
CREATE PROCEDURE filter_species_category_count (IN keyword VARCHAR(45))
BEGIN
	SELECT COUNT(species_scientific_name) AS total_species_category
    FROM species_scientific ss
    JOIN species_category sc ON ss.species_category_id = sc.species_category_id
    WHERE species_category LIKE CONCAT ('%', keyword, '%');
END // 
DELIMITER ;

-- FUNCTIONS

DROP FUNCTION IF EXISTS count_family_type_in_park;

DELIMITER //
CREATE FUNCTION count_family_type_in_park (park_c VARCHAR(45), family_suffix VARCHAR(45))
RETURNS INT
DETERMINISTIC
BEGIN
	DECLARE family_count INT;
    SELECT COUNT(*) INTO family_count
    FROM species_family sf
    JOIN species_scientific ss ON sf.species_family_id = ss.species_family_id
    JOIN species_park sp ON ss.species_scientific_id = sp.species_scientific_id
    JOIN park p ON sp.park_id = p.park_id
    WHERE p.park_code = park_c 
		AND sf.species_family LIKE CONCAT ('%', family_suffix, '%');
    
    RETURN family_count;

END //
DELIMITER ;



DROP FUNCTION IF EXISTS count_species_order_in_park;

DELIMITER //
CREATE FUNCTION count_species_order_in_park (park_c VARCHAR(45), order_suffix VARCHAR(45))
RETURNS INT
DETERMINISTIC
BEGIN
	DECLARE order_count INT;
    SELECT COUNT(*) INTO order_count
    FROM species_order so
    JOIN species_scientific ss ON so.species_order_id = ss.species_order_id
    JOIN species_park sp ON ss.species_scientific_id = sp.species_scientific_id
    JOIN park p ON sp.park_id = p.park_id
    WHERE p.park_code = park_c 
		AND so.species_order LIKE CONCAT ('%', order_suffix, '%');
    
    RETURN order_count;

END //
DELIMITER ;

-- TRIGGER


CREATE TABLE updated_species_common (
	species_common_id INT PRIMARY KEY,
    species_common_name VARCHAR(45)
);


DROP TRIGGER IF EXISTS update_null_species_common;

DELIMITER //
CREATE TRIGGER update_null_species_common
AFTER UPDATE ON species_common
FOR EACH ROW
BEGIN 
	INSERT INTO updated_species_common (species_common_id, species_common_name)
    VALUES (NEW.species_common_id, NEW.species_common_name);
END //

DELIMITER ;


UPDATE species_common 
SET species_common_name = 'Giant Water Scavenger Beetle'
WHERE species_common_id = 113;

SELECT * FROM species_common;

SELECT * FROM updated_species_common;