DELIMITER $$
DROP FUNCTION IF EXISTS `NVL`$$
CREATE FUNCTION `NVL`(`passed_strVal` VARCHAR(255), `passed_valIfNull` VARCHAR(255)) RETURNS VARCHAR(255)
BEGIN
	SET @valCheck := IFNULL(`passed_strVal`, `passed_valIfNull`);
	RETURN @valCheck;
END$$
DELIMITER ;
-----------------------------------------
DELIMITER $$
DROP PROCEDURE IF EXISTS `OptLoop`$$
CREATE PROCEDURE `OptLoop`()
BEGIN
	DECLARE DONE   BOOL DEFAULT FALSE;
	DECLARE TBL_NM CHAR(255);
	DECLARE CURS   CURSOR FOR SELECT T.TABLE_NAME
							  FROM `information_schema`.`TABLES` T
							  WHERE T.TABLE_SCHEMA = 'botdb'
							  AND   T.TABLE_TYPE   = 'BASE TABLE';
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET DONE = TRUE;
	OPEN CURS;
	LBL: LOOP
		FETCH CURS INTO TBL_NM;
		IF DONE THEN
			LEAVE LBL;
		END IF;
		SET @Q = CONCAT('OPTIMIZE TABLE botdb.', TBL_NM, ';');
		PREPARE QRY FROM @Q;
		EXECUTE QRY;
		DROP PREPARE QRY;
	END LOOP LBL;
	CLOSE CURS;
END$$
DELIMITER ;
-----------------------------------------
DELIMITER $$
DROP TRIGGER IF EXISTS `tr_FriendshipUpdate`$$
CREATE TRIGGER `tr_FriendshipUpdate` BEFORE UPDATE ON `BuddyList` FOR EACH ROW
BEGIN
	IF NEW.`friendship_level` != OLD.`friendship_level` THEN
		SET @sqlCheck := (SELECT `ID`
						  FROM `BuddyList`
						  WHERE `userID` = NEW.`userID`
						  AND   `botID`  = NEW.`botID`);
		IF @sqlCheck IS NOT NULL THEN
			IF NEW.`friendship_level` > 255 THEN
				SET NEW.`friendship_level` = 255;
			ELSEIF NEW.`friendship_level` < -255 THEN
				SET NEW.`friendship_level` = -255;
			END IF;
		END IF;
	END IF;
END$$
DELIMITER ;
-----------------------------------------
DELIMITER $$
DROP TRIGGER IF EXISTS `tr_ActLogsInsert`$$
CREATE TRIGGER `tr_ActLogsInsert` AFTER INSERT ON `activities` FOR EACH ROW
BEGIN
	SET @sqlCheck := (SELECT `ID`
	                  FROM `activities_log`
					  WHERE `botID`        = NEW.`botID`
					  AND `activityTypeID` = NEW.`activityTypeID`
					  AND `activityName`   = NEW.`activityName`);
	IF @sqlCheck IS NULL THEN
		INSERT INTO `activities_log` (`botID`, `activityTypeID`, `activityName`)
		VALUES (NEW.`botID`, NEW.`activityTypeID`, NEW.`activityName`);
	END IF;
END$$
DELIMITER ;
-----------------------------------------
DELIMITER $$
DROP TRIGGER IF EXISTS `tr_ActLogsUpdate`$$
CREATE TRIGGER `tr_ActLogsUpdate` AFTER UPDATE ON `activities` FOR EACH ROW
BEGIN
	SET @sqlCheck := (SELECT `ID`
	                  FROM `activities_log`
					  WHERE `botID`        = NEW.`botID`
					  AND `activityTypeID` = NEW.`activityTypeID`
					  AND `activityName`   = NEW.`activityName`);
	IF @sqlCheck IS NULL THEN
		INSERT INTO `activities_log` (`botID`, `activityTypeID`, `activityName`)
		VALUES (NEW.`botID`, NEW.`activityTypeID`, NEW.`activityName`);
	END IF;
END$$
DELIMITER ;
-----------------------------------------
DELIMITER $$
DROP PROCEDURE IF EXISTS `UpdateActivity`$$
CREATE PROCEDURE `UpdateActivity`(IN `passed_botID` INT)
BEGIN
	SET @randActID := (SELECT `ID`
	                   FROM `activities_log`
					   WHERE `botID` = `passed_botID`
					   ORDER BY RAND()
					   LIMIT 1);
	SET @randActType := (SELECT `activityTypeID`
	                     FROM `activities_log`
						 WHERE `ID` = @randActID);
	SET @randActName := (SELECT `activityName`
	                     FROM `activities_log`
						 WHERE `ID` = @randActID);
	IF @randActID IS NOT NULL THEN
		UPDATE `activities`
		SET `activityTypeID` = @randActType
		   ,`activityName`   = @randActName
		WHERE `botID` = `passed_botID`;
	END IF;
END$$
DELIMITER ;
-----------------------------------------
DELIMITER $$
DROP FUNCTION IF EXISTS `Func_GetActivityName`$$
CREATE FUNCTION `Func_GetActivityName`(`passed_botID` INT) RETURNS VARCHAR(255)
BEGIN
	SET @actName := (SELECT `activityName`
	                 FROM `Activities`
					 WHERE `botID` = `passed_botID`);
	RETURN @actName;
END$$
DELIMITER ;
-----------------------------------------
DELIMITER $$
DROP FUNCTION IF EXISTS `Func_GetActivityType`$$
CREATE FUNCTION `Func_GetActivityType`(`passed_botID` INT) RETURNS VARCHAR(10)
BEGIN
	SET @actTypeID := (SELECT `activityTypeID`
	                   FROM `Activities`
					   WHERE `botID` = `passed_botID`);
	SET @actType := (SELECT
						(CASE
							WHEN(@actTypeID = 1) THEN 'PLAY'
							WHEN(@actTypeID = 2) THEN 'WATCH'
							WHEN(@actTypeID = 3) THEN 'STREAM'
							WHEN(@actTypeID = 4) THEN 'LISTEN'
							ELSE 'CUSTOM'
						 END)
					 FROM DUAL);
	RETURN @actType;
END$$
DELIMITER ;
-----------------------------------------
DELIMITER $$
DROP FUNCTION IF EXISTS `Func_IsBuddy`$$
CREATE FUNCTION `Func_IsBuddy`(`passed_botID` INT, `passed_clientID` VARCHAR(50)) RETURNS BOOLEAN
BEGIN
	SET @userID := (SELECT `ID`
					FROM `Users`
					WHERE `clientID` = `passed_clientID`);
	IF @userID IS NOT NULL THEN
		SET @buddyCheck := (SELECT `ID`
							FROM `BuddyList`
							WHERE `botID`  = `passed_botID`
							AND   `userID` = @userID);
		RETURN NOT(@buddyCheck IS NULL);
	END IF;
END$$
DELIMITER ;
-----------------------------------------
DELIMITER $$
DROP FUNCTION IF EXISTS `Func_GetDefaultResponse`$$
CREATE FUNCTION `Func_GetDefaultResponse`(`passed_botID` INT) RETURNS TEXT
BEGIN
	SET @defaultResponse := (SELECT `response`
	                         FROM `default_responses`
							 WHERE `botID` = `passed_botID`
							 AND `is_active` = 1
							 ORDER BY RAND()
							 LIMIT 1);
	RETURN @defaultResponse;
END$$
DELIMITER ;
--------------------------------------
DELIMITER $$
DROP PROCEDURE IF EXISTS `SetActivity`$$
CREATE PROCEDURE `SetActivity` (IN `passed_botID` INT, IN `passed_actType` VARCHAR(20), IN `passed_actStr` VARCHAR(75))
BEGIN
	SET @sqlCheck := (SELECT `ID`
	                  FROM `Activities`
					  WHERE `botID` = `passed_botID`);
	SET @actID := (SELECT
					(CASE 
						WHEN(UPPER(`passed_actType`) LIKE 'PLAY%' OR 
						     UPPER(`passed_actType`) LIKE 'GAM%')    THEN 1
						WHEN(UPPER(`passed_actType`) LIKE 'WATCH%')  THEN 2
						WHEN(UPPER(`passed_actType`) LIKE 'STREAM%') THEN 3
						WHEN(UPPER(`passed_actType`) LIKE 'LISTEN%') THEN 4
						ELSE 5
					 END)
				   FROM DUAL);
	IF(@sqlCheck IS NULL) THEN
		INSERT INTO `Activities` (`botID`, `activityTypeID`, `activityName`)
		VALUES                   (`passed_botID`, @actID, `passed_actStr`);
		COMMIT;
	ELSE
		UPDATE `Activities`
		SET `activityTypeID` = @actID,
		    `activityName`   = `passed_actStr`
		WHERE `botID` = `passed_botID`;
		COMMIT;
	END IF;
END$$
DELIMITER ;