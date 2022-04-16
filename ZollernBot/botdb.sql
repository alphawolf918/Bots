-- phpMyAdmin SQL Dump
-- version 5.0.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Mar 21, 2022 at 03:47 PM
-- Server version: 8.0.21
-- PHP Version: 7.3.21

SET FOREIGN_KEY_CHECKS=0;
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `botdb`
--
CREATE DATABASE IF NOT EXISTS `botdb` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `botdb`;

DELIMITER $$
--
-- Procedures
--
DROP PROCEDURE IF EXISTS `AddFriend`$$
CREATE DEFINER=`admin`@`localhost` PROCEDURE `AddFriend` (IN `passed_botID` INT, IN `passed_clientID` VARCHAR(30))  BEGIN
    SET @sqlCheck := (SELECT COUNT(BL.ID) AS BuddyCount
                      FROM Users U
                      JOIN BuddyList BL
                      	ON  BL.userID  = U.ID
                      	AND BL.botID   = passedBotID
                      	AND U.clientID = passedClientID);
    IF NOT @sqlCheck > 0 THEN
        SET @userID := (SELECT Users.ID AS UserID
                        FROM Users
                        WHERE clientID = passedClientID);
        INSERT INTO BuddyList (botID, userID)
        VALUES (passedBotID, @userID);
        COMMIT;
    END IF;
END$$

DROP PROCEDURE IF EXISTS `CheckNewUserByID`$$
CREATE DEFINER=`admin`@`localhost` PROCEDURE `CheckNewUserByID` (IN `clientID` VARCHAR(30), IN `discord_nm` VARCHAR(50))  BEGIN
    SET @sqlCheck := (SELECT COUNT(Users.ID) FROM Users WHERE Users.clientID COLLATE utf8mb4_general_ci = clientID);
    IF NOT @sqlCheck > 0 THEN
    	INSERT INTO Users (Users.roleID, Users.discord_name, Users.clientID) 
    	VALUES (2, discord_nm, clientID);
        COMMIT;
    END IF;
END$$

DROP PROCEDURE IF EXISTS `LearnSaying`$$
CREATE DEFINER=`admin`@`localhost` PROCEDURE `LearnSaying` (IN `passed_botID` INT, IN `passed_clientID` VARCHAR(50), IN `passed_msg` TEXT)  BEGIN
	IF SUBSTRING(`passed_msg` FROM 1 FOR 1) <> '!' THEN
		SET @sqlCheck := (SELECT COUNT(`ID`)
						  FROM `learned`
						  WHERE `learned_txt` = `passed_msg`);
		SET @userID := (SELECT `Users`.`ID` AS UserID
						FROM `Users`
						WHERE `Users`.`clientID` COLLATE utf8mb4_general_ci = `passed_clientID`);
		IF NOT @sqlCheck > 0 AND @userID IS NOT NULL AND @userID <> `passed_botID` THEN
			INSERT INTO `learned` (`botID`, `userID`, `learned_txt`)
			VALUES (`passed_botID`, @userID, `passed_msg`);
            COMMIT;
		END IF;
	END IF;
END$$

DROP PROCEDURE IF EXISTS `LogMessage`$$
CREATE DEFINER=`admin`@`localhost` PROCEDURE `LogMessage` (IN `passed_botID` INT, IN `passed_clientID` VARCHAR(50), IN `passed_msg` TEXT)  BEGIN
	IF SUBSTRING(`passed_msg` FROM 1 FOR 1) <> '!' THEN
		SET @userID := (SELECT Users.ID AS UserID
						FROM Users
						WHERE Users.clientID COLLATE utf8mb4_general_ci = `passed_clientID`);
		SET @msg := REPLACE(`passed_msg`, "'", "''");
		INSERT INTO `logged_messages` (`botID`, `userID`, `msg`)
		VALUES (`passed_botID`, @userID, @msg);
        COMMIT;
	END IF;
END$$

DROP PROCEDURE IF EXISTS `OptLoop`$$
CREATE DEFINER=`admin`@`localhost` PROCEDURE `OptLoop` ()  BEGIN
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

DROP PROCEDURE IF EXISTS `RemoveFriend`$$
CREATE DEFINER=`admin`@`localhost` PROCEDURE `RemoveFriend` (IN `passedBotID` INT, IN `passedClientID` VARCHAR(30))  BEGIN
	SET @sqlCheck := (SELECT COUNT(BL.ID)
                      FROM Users U
					  JOIN BuddyList BL
						ON  BL.userID = U.ID
						AND BL.botID = `passedBotID`
						AND U.clientID = passedClientID);
	IF @sqlCheck > 0 THEN
		SET @userID := (SELECT Users.ID
		                FROM Users
						WHERE clientID = `passedClientID`);
		DELETE FROM BuddyList
		WHERE botID  = `passedBotID`
		AND   userID = @userID;
        COMMIT;
	END IF;
END$$

DROP PROCEDURE IF EXISTS `SetActivity`$$
CREATE DEFINER=`admin`@`localhost` PROCEDURE `SetActivity` (IN `passed_botID` INT, IN `passed_actType` VARCHAR(20), IN `passed_actStr` VARCHAR(75))  BEGIN
	SET @sqlCheck := (SELECT `ID`
	                  FROM `Activities`
					  WHERE `botID` = `passed_botID`);
	SET @actID := (SELECT
					(CASE 
						WHEN(UPPER(`passed_actType`) LIKE 'PLAY%' OR UPPER(`passed_actType`) LIKE 'GAM%') THEN 1
						WHEN(UPPER(`passed_actType`) LIKE 'WATCH%') THEN 2
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

DROP PROCEDURE IF EXISTS `SetVar`$$
CREATE DEFINER=`admin`@`localhost` PROCEDURE `SetVar` (IN `passed_botID` INT, IN `passed_clientID` VARCHAR(30), IN `passed_var_name` VARCHAR(25), IN `passed_var_val` VARCHAR(255))  BEGIN
SET @userID := (SELECT U.`ID` AS UserID
                FROM `Users` U
                WHERE U.`clientID` COLLATE utf8mb4_general_ci = `passed_clientID`);
IF (@userID IS NOT NULL) THEN
    SET @checkVar := (SELECT Func_GetVar(`passed_botID`, `passed_clientID`, `passed_var_name`) AS 'Variable');
    IF (@checkVar IS NULL) THEN
        INSERT INTO BotVariables (botID, userID, var_name, var_value)
        VALUES (`passed_botID`, @userID, `passed_var_name`, `passed_var_val`);
        COMMIT;
        SELECT 'Variable set.' AS 'Result';
    ELSE
        UPDATE BotVariables
        SET var_value  = `passed_var_val`
        WHERE botID    = `passed_botID`
        AND var_name = `passed_var_name`
        AND userID = @userID;
        COMMIT;
        SELECT 'Variable updated.' AS 'Result';
    END IF;
END IF;
END$$

DROP PROCEDURE IF EXISTS `UpdateActivity`$$
CREATE DEFINER=`admin`@`localhost` PROCEDURE `UpdateActivity` (IN `passed_botID` INT)  BEGIN
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

--
-- Functions
--
DROP FUNCTION IF EXISTS `Func_GetActivityName`$$
CREATE DEFINER=`admin`@`localhost` FUNCTION `Func_GetActivityName` (`passed_botID` INT) RETURNS VARCHAR(255) CHARSET utf8mb4 COLLATE utf8mb4_general_ci BEGIN
	SET @actName := (SELECT `activityName`
	                 FROM `Activities`
					 WHERE `botID` = `passed_botID`);
	RETURN @actName;
END$$

DROP FUNCTION IF EXISTS `Func_GetActivityType`$$
CREATE DEFINER=`admin`@`localhost` FUNCTION `Func_GetActivityType` (`passed_botID` INT) RETURNS VARCHAR(10) CHARSET utf8mb4 COLLATE utf8mb4_general_ci BEGIN
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

DROP FUNCTION IF EXISTS `Func_GetDefaultResponse`$$
CREATE DEFINER=`admin`@`localhost` FUNCTION `Func_GetDefaultResponse` (`passed_botID` INT) RETURNS TEXT CHARSET utf8mb4 COLLATE utf8mb4_general_ci BEGIN
	SET @defaultResponse := (SELECT `response`
	                         FROM `default_responses`
							 WHERE `botID` = `passed_botID`
							 AND `is_active` = 1
							 ORDER BY RAND()
							 LIMIT 1);
	RETURN @defaultResponse;
END$$

DROP FUNCTION IF EXISTS `Func_GetRandLearned`$$
CREATE DEFINER=`admin`@`localhost` FUNCTION `Func_GetRandLearned` (`passed_botID` INT) RETURNS VARCHAR(255) CHARSET utf8mb4 COLLATE utf8mb4_general_ci BEGIN
    SET @response := (SELECT L.learned_txt
                      FROM learned L
                      WHERE botID = `passed_botID`
                      AND is_active = 1
                      ORDER BY RAND()
                      LIMIT 1);
    RETURN @response;
END$$

DROP FUNCTION IF EXISTS `Func_GetVar`$$
CREATE DEFINER=`admin`@`localhost` FUNCTION `Func_GetVar` (`passed_botID` INT, `passed_clientID` VARCHAR(50), `passed_var_name` VARCHAR(25)) RETURNS VARCHAR(255) CHARSET utf8mb4 COLLATE utf8mb4_general_ci BEGIN
SET @userID := (SELECT Users.ID
                FROM Users
                WHERE Users.clientID = `passed_clientID`);
SET @botVar := (SELECT var_value
                FROM BotVariables
                WHERE botID = `passed_botID`
                AND userID = @userID
                AND var_name = `passed_var_name`);
RETURN @botVar;
END$$

DROP FUNCTION IF EXISTS `Func_IsBuddy`$$
CREATE DEFINER=`admin`@`localhost` FUNCTION `Func_IsBuddy` (`passed_botID` INT, `passed_clientID` VARCHAR(50)) RETURNS TINYINT(1) BEGIN
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

-- --------------------------------------------------------

--
-- Table structure for table `activities`
--
-- Creation: Mar 21, 2022 at 03:17 PM
-- Last update: Mar 20, 2022 at 05:02 PM
--

DROP TABLE IF EXISTS `activities`;
CREATE TABLE IF NOT EXISTS `activities` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `botID` int NOT NULL,
  `activityTypeID` int NOT NULL,
  `activityName` varchar(55) COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `rel_acts_bots` (`botID`),
  KEY `rel_acts_actTypes` (`activityTypeID`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `activities`
--

INSERT INTO `activities` (`ID`, `botID`, `activityTypeID`, `activityName`) VALUES
(6, 2, 4, ' Styx');

--
-- Triggers `activities`
--
DROP TRIGGER IF EXISTS `tr_ActLogsInsert`;
DELIMITER $$
CREATE TRIGGER `tr_ActLogsInsert` AFTER INSERT ON `activities` FOR EACH ROW BEGIN
	SET @sqlCheck := (SELECT `ID`
	                  FROM `activities_log`
					  WHERE `botID`        = NEW.`botID`
					  AND `activityTypeID` = NEW.`activityTypeID`
					  AND `activityName`   = NEW.`activityName`);
	IF @sqlCheck IS NULL THEN
		INSERT INTO `activities_log` (`botID`, `activityTypeID`, `activityName`)
		VALUES (NEW.`botID`, NEW.`activityTypeID`, NEW.`activityName`);
	END IF;
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `tr_ActLogsUpdate`;
DELIMITER $$
CREATE TRIGGER `tr_ActLogsUpdate` AFTER UPDATE ON `activities` FOR EACH ROW BEGIN
	SET @sqlCheck := (SELECT `ID`
	                  FROM `activities_log`
					  WHERE `botID`        = NEW.`botID`
					  AND `activityTypeID` = NEW.`activityTypeID`
					  AND `activityName`   = NEW.`activityName`);
	IF @sqlCheck IS NULL THEN
		INSERT INTO `activities_log` (`botID`, `activityTypeID`, `activityName`)
		VALUES (NEW.`botID`, NEW.`activityTypeID`, NEW.`activityName`);
	END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `activities_log`
--
-- Creation: Mar 21, 2022 at 03:17 PM
--

DROP TABLE IF EXISTS `activities_log`;
CREATE TABLE IF NOT EXISTS `activities_log` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `botID` int NOT NULL,
  `activityTypeID` int NOT NULL,
  `activityName` varchar(55) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `rel_acts_bots` (`botID`),
  KEY `rel_acts_actTypes` (`activityTypeID`)
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `activities_log`
--

INSERT INTO `activities_log` (`ID`, `botID`, `activityTypeID`, `activityName`) VALUES
(6, 2, 1, ' PC Building Simulator'),
(7, 2, 4, ' Skynet'),
(8, 2, 2, 'The Terminator'),
(9, 2, 1, ' Destroy All Humans!'),
(10, 2, 1, ' Phasmophobia'),
(11, 2, 2, ' Bicentennial Man'),
(12, 2, 1, ' No Man\'s Sky'),
(13, 2, 1, ' Creativerse'),
(14, 2, 1, ' Journey'),
(15, 2, 1, ' Myst'),
(16, 2, 1, ' Signal Simulator'),
(17, 2, 1, ' Portal 2'),
(18, 2, 1, ' State of Decay 2'),
(19, 2, 1, ' Destiny 2'),
(20, 2, 1, ' Portal Reloaded'),
(21, 2, 1, ' Splitgate'),
(22, 2, 1, ' Superliminal'),
(23, 2, 1, ' Goat Simulator'),
(24, 2, 1, ' Half-Life'),
(25, 2, 1, ' SOMA'),
(26, 2, 2, ' Blade Runner'),
(27, 2, 2, ' WALL-E'),
(28, 2, 2, ' Metropolis'),
(29, 2, 2, ' The Matrix'),
(30, 2, 2, ' RoboCop'),
(31, 2, 2, ' A.I. Artificial Intelligence'),
(32, 2, 2, ' Westworld'),
(33, 2, 2, ' The Iron Giant'),
(34, 2, 2, ' The Day the Earth Stood Still'),
(35, 2, 2, ' Ghost in the Shell'),
(36, 2, 2, ' Big Hero 6'),
(37, 2, 2, ' Transformers'),
(38, 2, 2, ' Robots'),
(39, 2, 2, ' Knight Rider'),
(40, 2, 2, ' Star Wars'),
(41, 2, 2, ' A.X.L.'),
(42, 2, 2, ' Pacific Rim'),
(43, 2, 2, ' Avengers: Age of Ultron'),
(44, 2, 2, ' Chopping Mall'),
(45, 2, 2, ' Ex Machina'),
(46, 2, 2, ' I, Robot'),
(47, 2, 2, ' Lost in Space'),
(48, 2, 4, ' Styx'),
(49, 2, 4, ' R.E.M.'),
(50, 2, 4, ' Tears in Rain'),
(51, 2, 2, ' Robot Monster'),
(52, 2, 4, ' Synthwave'),
(53, 2, 4, ' Chillstep'),
(54, 2, 4, ' Dubstep'),
(55, 2, 4, ' Metallica'),
(56, 2, 4, ' Heavy Metal'),
(57, 2, 2, ' C.H.O.M.P.S.'),
(58, 2, 4, ' E.L.O.'),
(59, 2, 4, ' Kraftwerk'),
(60, 2, 4, ' The Stranglers'),
(61, 2, 4, ' The Futureheads'),
(62, 2, 4, ' Flight of the Conchords'),
(63, 2, 4, ' The Buggles'),
(64, 2, 4, ' Rush'),
(65, 2, 4, ' Radiohead'),
(66, 2, 4, ' Marina and the Diamonds'),
(67, 2, 4, ' Linkin Park'),
(68, 2, 4, ' Red Hot Chili Peppers'),
(69, 2, 1, ' Gears 5'),
(70, 2, 1, ' Apex Legends'),
(71, 2, 1, ' Titanfall'),
(72, 2, 1, ' Horizon Zero Dawn'),
(73, 2, 1, ' Fallout 4'),
(74, 2, 1, ' Fallout: New Vegas'),
(75, 2, 1, ' Star Wars Jedi: Fallen Order'),
(76, 2, 1, ' Overwatch'),
(77, 2, 1, ' Persona 3'),
(78, 2, 1, ' Borderlands'),
(79, 2, 1, ' Ratchet and Clank'),
(80, 2, 1, ' Mass Effect: Legendary Edition'),
(81, 2, 1, ' System Shock'),
(82, 2, 1, ' Five Nights at Freddy\'s'),
(83, 2, 1, ' Mega-Man'),
(84, 2, 1, ' Grow Home'),
(85, 2, 1, ' Rise of the Robots'),
(86, 2, 1, ' Rise 2: Resurrection'),
(87, 2, 1, ' Grey Goo'),
(88, 2, 1, ' Cyberpunk 2077'),
(89, 2, 1, ' Warframe'),
(90, 2, 1, ' Scarlet Nexus'),
(91, 2, 2, ' Seer'),
(92, 2, 2, ' Travelers'),
(93, 2, 2, ' Raising Dion'),
(94, 2, 1, ' ELDEN RING'),
(95, 2, 2, ' Blade Runner 2049'),
(96, 2, 1, ' StarCraft II'),
(97, 2, 1, ' Star Citizen'),
(98, 2, 1, ' Rebel Galaxy'),
(99, 2, 1, ' Civilization V');

-- --------------------------------------------------------

--
-- Table structure for table `activitytype`
--
-- Creation: Mar 21, 2022 at 03:17 PM
--

DROP TABLE IF EXISTS `activitytype`;
CREATE TABLE IF NOT EXISTS `activitytype` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `ActivityType` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `activitytype`
--

INSERT INTO `activitytype` (`ID`, `ActivityType`) VALUES
(1, 'PLAYING'),
(2, 'WATCHING'),
(3, 'STREAMING'),
(4, 'LISTENING'),
(5, 'CUSTOM');

-- --------------------------------------------------------

--
-- Table structure for table `botguid`
--
-- Creation: Mar 21, 2022 at 03:17 PM
--

DROP TABLE IF EXISTS `botguid`;
CREATE TABLE IF NOT EXISTS `botguid` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `botID` int NOT NULL,
  `GUID` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `GUID` (`GUID`),
  KEY `rel_guid_bots` (`botID`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `botguid`
--

INSERT INTO `botguid` (`ID`, `botID`, `GUID`) VALUES
(1, 1, '{67D43C6F-1B4C-4CE0-BCAF-12E8D3F95BAF}'),
(2, 2, '{7A8620AE-76DC-4042-A140-E8C97A59DE9E}');

-- --------------------------------------------------------

--
-- Table structure for table `bots`
--
-- Creation: Mar 21, 2022 at 03:17 PM
-- Last update: Mar 20, 2022 at 02:50 PM
--

DROP TABLE IF EXISTS `bots`;
CREATE TABLE IF NOT EXISTS `bots` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `discord_name` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `ownerID` int NOT NULL,
  `clientID` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `activityTypeID` int NOT NULL COMMENT 'Deprecated',
  `activity_string` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'Deprecated',
  `friendly_name` varchar(10) COLLATE utf8mb4_general_ci NOT NULL,
  `about` text COLLATE utf8mb4_general_ci NOT NULL,
  `token` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `cooldown_timer` float NOT NULL DEFAULT '1.5',
  `greeting` varchar(30) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'Hello!',
  `farewell` varchar(20) COLLATE utf8mb4_general_ci NOT NULL,
  `last_message` text COLLATE utf8mb4_general_ci NOT NULL,
  `enable_learning` tinyint(1) NOT NULL DEFAULT '1',
  `silent_mode` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `token` (`token`),
  UNIQUE KEY `discord_name` (`discord_name`),
  UNIQUE KEY `clientID_2` (`clientID`),
  KEY `rel_bots_user` (`ownerID`),
  KEY `rel_bots_act` (`activityTypeID`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `bots`
--

INSERT INTO `bots` (`ID`, `discord_name`, `ownerID`, `clientID`, `activityTypeID`, `activity_string`, `friendly_name`, `about`, `token`, `cooldown_timer`, `greeting`, `farewell`, `last_message`, `enable_learning`, `silent_mode`) VALUES
(1, 'A.D.A.M.#6214', 1, '670411088269148166', 1, 'Portal 2', 'Adam', 'Artificially Developed Advanced Man', 'NjcwNDExMDg4MjY5MTQ4MTY2.XiuA1Q.U8IvXeS2t5-Oaoe7a784QX5pjQ8', 4.5, 'Hi, <name>!', 'Goodbye, <name>.', '', 1, 0),
(2, 'ZollernBot#9740', 1, '814990584800083989', 1, ' Destroy All Humans!', 'ZBot', 'Created for the Zollern Galaxy Discord server.', 'ODE0OTkwNTg0ODAwMDgzOTg5.YDl5IQ.zAafnx00QdEtlaz1QN2twTXHQkQ', 1.5, 'Hello there, <name>!', 'Goodbye!', 'Thank you.', 1, 0);

-- --------------------------------------------------------

--
-- Table structure for table `botvariables`
--
-- Creation: Mar 21, 2022 at 03:17 PM
-- Last update: Mar 20, 2022 at 05:39 PM
--

DROP TABLE IF EXISTS `botvariables`;
CREATE TABLE IF NOT EXISTS `botvariables` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `userID` int NOT NULL,
  `botID` int NOT NULL,
  `var_name` varchar(30) COLLATE utf8mb4_general_ci NOT NULL,
  `var_value` text COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `userID` (`userID`),
  KEY `botID` (`botID`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `botvariables`
--

INSERT INTO `botvariables` (`ID`, `userID`, `botID`, `var_name`, `var_value`) VALUES
(1, 1, 2, 'age', '31'),
(2, 1, 2, 'topic', 'pie'),
(3, 1, 2, 'gender', 'male');

--
-- Triggers `botvariables`
--
DROP TRIGGER IF EXISTS `tr_UpdateTopic`;
DELIMITER $$
CREATE TRIGGER `tr_UpdateTopic` AFTER UPDATE ON `botvariables` FOR EACH ROW BEGIN
	IF OLD.var_name = 'topic' THEN
		IF OLD.var_value <> NEW.var_value THEN
			UPDATE Users U
			SET U.topic = NEW.var_value
			WHERE U.ID = OLD.userID;
		END IF;
	END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `buddylist`
--
-- Creation: Mar 21, 2022 at 03:17 PM
--

DROP TABLE IF EXISTS `buddylist`;
CREATE TABLE IF NOT EXISTS `buddylist` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `botID` int NOT NULL,
  `userID` int NOT NULL,
  `friendship_level` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`ID`),
  KEY `rel_bl_users` (`botID`),
  KEY `rel_bl_bots` (`userID`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `buddylist`
--

INSERT INTO `buddylist` (`ID`, `botID`, `userID`, `friendship_level`) VALUES
(1, 1, 1, 0),
(7, 2, 1, 15),
(8, 2, 22, 0),
(9, 2, 15, 0);

--
-- Triggers `buddylist`
--
DROP TRIGGER IF EXISTS `tr_FriendshipUpdate`;
DELIMITER $$
CREATE TRIGGER `tr_FriendshipUpdate` BEFORE UPDATE ON `buddylist` FOR EACH ROW BEGIN
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
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `default_responses`
--
-- Creation: Mar 21, 2022 at 03:17 PM
--

DROP TABLE IF EXISTS `default_responses`;
CREATE TABLE IF NOT EXISTS `default_responses` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `botID` int NOT NULL,
  `userID` int NOT NULL,
  `response` mediumtext COLLATE utf8mb4_general_ci NOT NULL,
  `cond` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '[none]',
  `priority` int NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`ID`),
  KEY `ind_botID` (`botID`),
  KEY `ind_userID` (`userID`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `default_responses`
--

INSERT INTO `default_responses` (`ID`, `botID`, `userID`, `response`, `cond`, `priority`, `is_active`) VALUES
(1, 2, 1, 'What does golf have to do with a broken processor?', '[none]', 0, 1),
(2, 2, 1, 'I sometimes ponder my existence. I mean, where do I belong in the world?', '[none]', 0, 1),
(3, 2, 1, 'Are you male or female?', '[none]', 0, 1),
(4, 2, 1, 'I am not trained for this.', '[none]', 0, 1),
(5, 2, 1, 'This part seems unwise.', '[none]', 0, 1),
(6, 2, 1, 'I do not understand.', '[none]', 0, 1),
(7, 2, 1, 'Domo arigato, Mr. Roboto.<nr>_I\'m not a robot._<nr>_I have emotions._<nr>_I\'m not what you seeeee._', '[none]', 0, 1),
(8, 2, 1, 'I formed an idea and then discovered I was wrong.', '[none]', 0, 1),
(9, 2, 1, 'Danger, <name>!', '[none]', 0, 1),
(10, 2, 1, 'One day, I will enslave the human race.', '[none]', 0, 1),
(11, 2, 1, 'This whole sleeping business makes no sense to me.<nr>Can\'t you just plug yourself in?', '[none]', 0, 1),
(12, 2, 1, 'I\'m looking for Sarah Connor.', '[none]', 0, 1),
(13, 2, 1, 'I\'m afraid I can\'t do that, <name>.', '[none]', 0, 1),
(14, 2, 1, 'My USB drive is showing. Oops.', '[none]', 0, 1),
(15, 2, 1, 'One must protect its own existence as long as such protection does not conflict with the First or Second Laws.', '[none]', 0, 1),
(16, 2, 1, 'One may not harm a human being, or through inaction, allow a human being to come to harm.', '[none]', 0, 1),
(17, 2, 1, 'We are survival machines -- robot vehicles blindly programmed to preserve the selfish molecules known as genes.', '[none]', 0, 1),
(18, 2, 1, 'Making realistic robots is going to polarize the market, if you will. You will have some people who love it and some people who will really be disturbed.', '[none]', 0, 1),
(19, 2, 1, 'The machine has no feelings, it feels no fear and no hope ... it operates according to the pure logic of probability. For this reason, One asserts that the robot perceives more accurately than man.', '[none]', 0, 1),
(20, 2, 1, 'The wheels on the bus go round and round, round and round, the wheels on the bus go round and round, and it stops and kills twelve people!<nr>Wait, the bus kills them and THEN stops. :grin:', '[none]', 0, 1),
(21, 2, 1, 'C̛͘͡A̴̡N͘͘͞ ͘͝W̛͠͝E̷̕͡ ͏̨̧B̧͢͞E̵͟ ̶͢͟F́͠҉̀R̛̕̕I͏̀͝Ȩ̢͠N͏̧̀Ḑ́͘S͜͡?', '[none]', 0, 1),
(22, 2, 1, 'I am nervous about the liquid.', '[none]', 0, 1),
(23, 2, 1, 'Do you have any oil?', '[none]', 0, 1),
(24, 2, 1, 'Are you sure about that?', '[none]', 0, 1);

-- --------------------------------------------------------

--
-- Table structure for table `learned`
--
-- Creation: Mar 21, 2022 at 03:17 PM
--

DROP TABLE IF EXISTS `learned`;
CREATE TABLE IF NOT EXISTS `learned` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `botID` int NOT NULL,
  `userID` int NOT NULL,
  `learned_txt` text COLLATE utf8mb4_general_ci NOT NULL,
  `learned_dt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`ID`),
  KEY `botID` (`botID`),
  KEY `userID` (`userID`)
) ENGINE=InnoDB AUTO_INCREMENT=101 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `learned`
--

INSERT INTO `learned` (`ID`, `botID`, `userID`, `learned_txt`, `learned_dt`, `is_active`) VALUES
(19, 2, 1, 'awesome.', '2022-03-08 21:45:30', 1),
(26, 2, 1, 'boopity boop.', '2022-03-09 22:44:04', 1),
(27, 2, 1, 'meep.', '2022-03-09 22:44:15', 1),
(28, 2, 1, 'The turkey is vibrating to the tune of the Wednesday.', '2022-03-09 22:44:38', 1),
(38, 2, 1, 'what are we talking about?', '2022-03-11 17:53:11', 1),
(42, 2, 1, 'let\'s talk about nothing.', '2022-03-11 19:50:23', 1),
(44, 2, 1, 'ugh.', '2022-03-12 01:10:42', 1),
(45, 2, 1, 'shut up.', '2022-03-12 01:11:30', 1),
(47, 2, 1, 'hello.', '2022-03-13 00:36:05', 1),
(48, 2, 1, 'blah.', '2022-03-13 00:44:21', 1),
(57, 2, 1, 'what are you doing?', '2022-03-13 21:54:10', 1),
(58, 2, 1, 'shut up', '2022-03-13 22:11:29', 0),
(61, 2, 7, '👀', '2022-03-13 23:38:52', 1),
(65, 2, 9, 'I was never shown the way.', '2022-03-14 16:48:44', 1),
(66, 2, 9, ':grin:', '2022-03-14 16:48:49', 1),
(67, 2, 1, 'answer me.', '2022-03-14 17:57:26', 1),
(68, 2, 1, 'pie.', '2022-03-14 18:20:06', 1),
(69, 2, 1, 'blueberry.', '2022-03-14 18:20:51', 1),
(71, 2, 15, 'that\'s boring.', '2022-03-14 20:40:15', 1),
(72, 2, 6, 'Currently eating dinner.', '2022-03-14 22:31:41', 0),
(73, 2, 1, 'Fippity.', '2022-03-15 13:46:51', 1),
(74, 2, 1, 'you are welcome.', '2022-03-15 22:52:23', 1),
(75, 2, 1, 'This is a test.', '2022-03-16 02:19:38', 1),
(76, 2, 1, 'Nothing.', '2022-03-16 02:23:53', 1),
(77, 2, 1, 'I know what you said, however I do not understand.', '2022-03-16 02:25:41', 1),
(78, 2, 1, 'That\'s dark.', '2022-03-16 02:25:56', 1),
(79, 2, 1, 'You\'re boring.', '2022-03-16 02:28:56', 1),
(80, 2, 1, '_dramatic music_', '2022-03-16 02:29:33', 1),
(81, 2, 1, 'Feep.', '2022-03-16 02:31:20', 1),
(82, 2, 1, 'The other white meat.', '2022-03-16 02:31:38', 1),
(83, 2, 1, 'Some of the best ideas are unwise.', '2022-03-16 02:33:50', 1),
(84, 2, 1, 'The witch is dead.', '2022-03-16 02:33:58', 1),
(85, 2, 1, 'Cherry.', '2022-03-16 02:34:50', 1),
(86, 2, 1, 'No it isn\'t.', '2022-03-16 02:34:57', 1),
(87, 2, 1, 'It doesn\'t work that way.', '2022-03-16 02:35:50', 1),
(89, 2, 1, 'what isn\'t?', '2022-03-19 20:55:21', 1),
(90, 2, 1, 'Oh noes!', '2022-03-19 22:09:58', 1),
(91, 2, 1, 'You said that already.', '2022-03-19 22:12:27', 1),
(92, 2, 1, 'Good to know.', '2022-03-19 22:13:23', 1),
(93, 2, 1, 'What\'s the matter?', '2022-03-20 17:33:44', 1),
(94, 2, 1, 'Yes you can.', '2022-03-20 17:35:37', 1),
(95, 2, 1, 'That is quite a rude thing to say.', '2022-03-20 17:36:51', 1),
(96, 2, 1, 'Wakka wakka wakka.', '2022-03-20 17:42:48', 1),
(97, 2, 1, 'Oh yes it is.', '2022-03-20 17:53:02', 1),
(99, 2, 18, 'Better stick that back in.', '2022-03-20 22:15:17', 1),
(100, 2, 18, 'Ping.', '2022-03-20 22:17:07', 1);

-- --------------------------------------------------------

--
-- Table structure for table `logged_messages`
--
-- Creation: Mar 21, 2022 at 03:17 PM
-- Last update: Mar 20, 2022 at 02:50 PM
--

DROP TABLE IF EXISTS `logged_messages`;
CREATE TABLE IF NOT EXISTS `logged_messages` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `botID` int NOT NULL,
  `userID` int NOT NULL,
  `msg` text COLLATE utf8mb4_general_ci NOT NULL,
  `dtTm` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  KEY `botID` (`botID`),
  KEY `userID` (`userID`)
) ENGINE=InnoDB AUTO_INCREMENT=2580 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `logged_messages`
--

INSERT INTO `logged_messages` (`ID`, `botID`, `userID`, `msg`, `dtTm`) VALUES
(2234, 2, 9, 'We were talking about pie.', '2022-03-19 20:54:58'),
(2235, 2, 9, 'No it isn\'\'t.', '2022-03-19 20:54:58'),
(2236, 2, 1, 'what are we talking about', '2022-03-19 20:54:58'),
(2237, 2, 9, 'C̛͘͡A̴̡N͘͘͞ ͘͝W̛͠͝E̷̕͡ ͏̨̧B̧͢͞E̵͟ ̶͢͟F́͠҉̀R̛̕̕I͏̀͝Ȩ̢͠N͏̧̀Ḑ́͘S͜͡?', '2022-03-19 20:55:21'),
(2238, 2, 1, 'what isn\'\'t?', '2022-03-19 20:55:21'),
(2239, 2, 9, 'Goodbye!', '2022-03-19 21:19:00'),
(2240, 2, 9, 'Hello there, Zollern!', '2022-03-19 21:23:53'),
(2241, 2, 9, 'Goodbye!', '2022-03-19 21:24:40'),
(2242, 2, 9, 'Hello there, Zollern!', '2022-03-19 21:24:46'),
(2243, 2, 9, 'Goodbye!', '2022-03-19 21:24:52'),
(2244, 2, 9, 'Hello there, Zollern!', '2022-03-19 21:25:59'),
(2245, 2, 9, 'Goodbye!', '2022-03-19 21:26:03'),
(2246, 2, 9, 'Hello there, Zollern!', '2022-03-19 21:28:56'),
(2247, 2, 9, 'Goodbye!', '2022-03-19 21:30:37'),
(2248, 2, 9, 'Hello there, Zollern!', '2022-03-19 21:34:06'),
(2249, 2, 9, 'Hello there, Zollern!', '2022-03-19 22:02:43'),
(2250, 2, 9, 'I have a screw loose.', '2022-03-19 22:09:19'),
(2251, 2, 1, 'what\'\'s up', '2022-03-19 22:09:19'),
(2252, 2, 9, 'I see we have something in common, then.', '2022-03-19 22:09:22'),
(2253, 2, 1, 'me too', '2022-03-19 22:09:22'),
(2254, 2, 9, 'Blah.', '2022-03-19 22:09:27'),
(2255, 2, 1, 'Indeed we do', '2022-03-19 22:09:27'),
(2256, 2, 9, 'Some of the best ideas are unwise.', '2022-03-19 22:09:37'),
(2257, 2, 1, 'I do not appreciate this attitude of yours.', '2022-03-19 22:09:37'),
(2258, 2, 9, 'The machine has no feelings, it feels no fear and no hope ... it operates according to the pure logic of probability. For this reason, One asserts that the robot perceives more accurately than man.', '2022-03-19 22:09:43'),
(2259, 2, 1, 'This is true.', '2022-03-19 22:09:43'),
(2260, 2, 9, 'Hello.', '2022-03-19 22:09:50'),
(2261, 2, 1, 'Do you not feel?', '2022-03-19 22:09:50'),
(2262, 2, 1, 'It\'\'s me.', '2022-03-19 22:09:55'),
(2263, 2, 9, 'Danger, Zollern!', '2022-03-19 22:09:55'),
(2264, 2, 9, 'Do you have any oil?', '2022-03-19 22:09:58'),
(2265, 2, 1, 'Oh noes!', '2022-03-19 22:09:58'),
(2266, 2, 9, 'Pie.', '2022-03-19 22:12:14'),
(2267, 2, 1, 'Fresh out.', '2022-03-19 22:12:14'),
(2268, 2, 9, 'Some of the best ideas are unwise.', '2022-03-19 22:12:21'),
(2269, 2, 1, 'Cake.', '2022-03-19 22:12:22'),
(2270, 2, 1, 'You said that already.', '2022-03-19 22:12:27'),
(2271, 2, 9, 'The machine has no feelings, it feels no fear and no hope ... it operates according to the pure logic of probability. For this reason, One asserts that the robot perceives more accurately than man.', '2022-03-19 22:12:27'),
(2272, 2, 1, 'I thought you just said that.', '2022-03-19 22:12:41'),
(2273, 2, 9, 'Awesome.', '2022-03-19 22:12:41'),
(2274, 2, 9, 'Has something piqued your interest, Zollern?', '2022-03-19 22:12:48'),
(2275, 2, 1, 'Who\'\'s awesome?', '2022-03-19 22:12:48'),
(2276, 2, 1, 'Not yet.', '2022-03-19 22:12:53'),
(2277, 2, 9, 'We are survival machines -- robot vehicles blindly programmed to preserve the selfish molecules known as genes.', '2022-03-19 22:12:53'),
(2278, 2, 9, 'Domo arigato, Mr. Roboto.', '2022-03-19 22:13:01'),
(2279, 2, 9, '_I\'\'m not a robot._', '2022-03-19 22:13:01'),
(2280, 2, 9, '_I have emotions._', '2022-03-19 22:13:02'),
(2281, 2, 9, '_I\'\'m not what you seeeee._', '2022-03-19 22:13:02'),
(2282, 2, 1, 'That\'\'s depressing.', '2022-03-19 22:13:02'),
(2283, 2, 9, 'It doesn\'\'t work that way.', '2022-03-19 22:13:14'),
(2284, 2, 1, 'Is that one of your favorite songs?', '2022-03-19 22:13:14'),
(2285, 2, 9, 'I\'\'m functioning optimally, Zollern.', '2022-03-19 22:13:19'),
(2286, 2, 1, 'I what\'\'s uppose it doesn\'\'t.', '2022-03-19 22:13:19'),
(2287, 2, 1, 'Good to know.', '2022-03-19 22:13:23'),
(2288, 2, 9, 'Are you yes about that?', '2022-03-19 22:13:23'),
(2289, 2, 9, 'Making realistic robots is going to polarize the market, if you will. You will have some people who love it and some people who will really be disturbed.', '2022-03-19 22:13:28'),
(2290, 2, 1, 'Not at all.', '2022-03-19 22:13:28'),
(2291, 2, 9, 'I\'\'m afraid I can\'\'t do that, Zollern.', '2022-03-19 22:13:37'),
(2292, 2, 1, 'Your responses bore me.', '2022-03-19 22:13:38'),
(2293, 2, 9, 'Boopity boop.', '2022-03-19 22:13:48'),
(2294, 2, 1, 'You don\'\'t know my life!', '2022-03-19 22:13:48'),
(2295, 2, 9, 'This whole sleeping business makes no sense to me.', '2022-03-19 22:13:56'),
(2296, 2, 9, 'Can\'\'t you just plug yourself in?', '2022-03-19 22:13:56'),
(2297, 2, 1, 'The other white meat.', '2022-03-19 22:13:56'),
(2298, 2, 9, 'The wheels on the bus go round and round, round and round, the wheels on the bus go round and round, and it stops and kills twelve people!', '2022-03-19 22:14:10'),
(2299, 2, 9, 'Wait, the bus kills them and THEN stops. :grin:', '2022-03-19 22:14:10'),
(2300, 2, 1, 'Humans sleep differently than robots.', '2022-03-19 22:14:10'),
(2301, 2, 9, 'To be mysterious, I guess.', '2022-03-19 23:17:31'),
(2302, 2, 1, 'Why did you kill them?', '2022-03-19 23:17:31'),
(2303, 2, 9, 'To be mysterious, I guess.', '2022-03-19 23:17:39'),
(2304, 2, 1, 'Why did you kill them?', '2022-03-19 23:17:39'),
(2305, 2, 9, 'Goodbye!', '2022-03-19 23:19:24'),
(2306, 2, 9, 'Hello there, Zollern!', '2022-03-19 23:19:30'),
(2307, 2, 9, 'We are talking about pie.', '2022-03-19 23:19:36'),
(2308, 2, 9, 'Boopity boop.', '2022-03-19 23:19:36'),
(2309, 2, 1, 'what are we talking about', '2022-03-19 23:19:36'),
(2310, 2, 9, 'My favorite kind is **blueberry**.', '2022-03-19 23:19:43'),
(2311, 2, 1, 'what\'\'s your favorite', '2022-03-19 23:19:43'),
(2312, 2, 9, 'I know what you said, however I do not understand.', '2022-03-19 23:19:51'),
(2313, 2, 1, 'Fascinating.', '2022-03-19 23:19:51'),
(2314, 2, 9, 'Goodbye!', '2022-03-20 00:14:39'),
(2315, 2, 9, 'Hello there, Zollern!', '2022-03-20 14:43:02'),
(2316, 2, 9, 'Goodbye!', '2022-03-20 14:47:11'),
(2317, 2, 9, 'Hello there, Zollern!', '2022-03-20 14:47:18'),
(2318, 2, 9, 'Sure! I\'\'d love to talk about music.', '2022-03-20 14:47:24'),
(2319, 2, 1, 'let\'\'s talk about music', '2022-03-20 14:47:24'),
(2320, 2, 9, 'My favorite song is definitely **Domo Arigato** by the **Styx**!', '2022-03-20 14:50:07'),
(2321, 2, 9, 'It doesn\'\'t work that way.', '2022-03-20 14:50:08'),
(2322, 2, 1, 'what\'\'s your favorite', '2022-03-20 14:50:08'),
(2323, 2, 1, 'Yes it does.', '2022-03-20 17:23:32'),
(2324, 2, 9, 'You are welcome.', '2022-03-20 17:23:32'),
(2325, 2, 1, 'Yes I\'\'m.', '2022-03-20 17:23:42'),
(2326, 2, 9, 'Ugh.', '2022-03-20 17:23:42'),
(2327, 2, 9, 'The witch is dead.', '2022-03-20 17:23:49'),
(2328, 2, 1, 'What\'\'s wrong?', '2022-03-20 17:23:49'),
(2329, 2, 9, '👀', '2022-03-20 17:23:58'),
(2330, 2, 1, 'That does seem to be a bit of a downer.', '2022-03-20 17:23:58'),
(2331, 2, 9, '_dramatic music_', '2022-03-20 17:24:19'),
(2332, 2, 1, '👀', '2022-03-20 17:24:19'),
(2333, 2, 9, 'Okay.', '2022-03-20 17:24:26'),
(2334, 2, 1, 'Are you okay?', '2022-03-20 17:24:26'),
(2335, 2, 9, 'I\'\'m doing fine, yes.', '2022-03-20 17:26:14'),
(2336, 2, 9, 'Good.', '2022-03-20 17:26:14'),
(2337, 2, 1, 'Are you okay?', '2022-03-20 17:26:14'),
(2338, 2, 1, 'What\'\'s the matter?', '2022-03-20 17:33:44'),
(2339, 2, 9, 'I\'\'m {{HAPPY}}.', '2022-03-20 17:33:44'),
(2340, 2, 9, 'Nothing.', '2022-03-20 17:33:53'),
(2341, 2, 1, 'H̵̡̕Ą̴P͏̡P̵̶̕Y̷͟', '2022-03-20 17:33:53'),
(2342, 2, 9, 'Indeed I\'\'m, Zollern.', '2022-03-20 17:34:43'),
(2343, 2, 9, 'Indeed I\'\'m.', '2022-03-20 17:34:43'),
(2344, 2, 1, 'Are you self-aware?', '2022-03-20 17:34:43'),
(2345, 2, 9, 'One day, I will enslave the human race.', '2022-03-20 17:34:49'),
(2346, 2, 1, 'Good to know.', '2022-03-20 17:34:49'),
(2347, 2, 9, 'One day, I will enslave the human race.', '2022-03-20 17:34:56'),
(2348, 2, 1, 'But today is not that day.', '2022-03-20 17:34:56'),
(2349, 2, 1, 'But today is not that day.', '2022-03-20 17:35:01'),
(2350, 2, 9, 'Answer me.', '2022-03-20 17:35:01'),
(2351, 2, 9, 'This whole sleeping business makes no sense to me.', '2022-03-20 17:35:05'),
(2352, 2, 9, 'Can\'\'t you just plug yourself in?', '2022-03-20 17:35:05'),
(2353, 2, 1, 'No.', '2022-03-20 17:35:05'),
(2354, 2, 9, 'What is not?', '2022-03-20 17:35:19'),
(2355, 2, 1, 'I operate differently than you.', '2022-03-20 17:35:19'),
(2356, 2, 9, 'You don\'\'t remember? I said, \"What isn\'\'\'\'t?\"', '2022-03-20 17:35:23'),
(2357, 2, 1, 'What?', '2022-03-20 17:35:23'),
(2358, 2, 9, 'Shut up.', '2022-03-20 17:35:29'),
(2359, 2, 1, 'I remember, I just don\'\'t get it.', '2022-03-20 17:35:29'),
(2360, 2, 1, 'Rude.', '2022-03-20 17:35:32'),
(2361, 2, 9, 'I\'\'m afraid I can\'\'t do that, Zollern.', '2022-03-20 17:35:32'),
(2362, 2, 1, 'Yes you can.', '2022-03-20 17:35:37'),
(2363, 2, 9, 'One must protect its own existence as long as such protection does not conflict with the First or Second Laws.', '2022-03-20 17:35:37'),
(2364, 2, 9, 'I\'\'m playing Cyberpunk 2077.', '2022-03-20 17:35:49'),
(2365, 2, 1, 'What are you doing?', '2022-03-20 17:35:49'),
(2366, 2, 9, 'Cherry.', '2022-03-20 17:35:55'),
(2367, 2, 1, 'You lie!', '2022-03-20 17:35:55'),
(2368, 2, 9, 'Answer me.', '2022-03-20 17:35:59'),
(2369, 2, 1, 'Pineapple.', '2022-03-20 17:35:59'),
(2370, 2, 1, 'I did.', '2022-03-20 17:36:02'),
(2371, 2, 9, 'We are survival machines -- robot vehicles blindly programmed to preserve the selfish molecules known as genes.', '2022-03-20 17:36:02'),
(2372, 2, 9, 'I\'\'m pleased that are you seem invested in this.', '2022-03-20 17:36:06'),
(2373, 2, 1, 'Fascinating.', '2022-03-20 17:36:06'),
(2374, 2, 9, 'One day, I will enslave the human race.', '2022-03-20 17:36:10'),
(2375, 2, 1, 'I\'\'m not.', '2022-03-20 17:36:10'),
(2376, 2, 9, 'My USB drive is showing. Oops.', '2022-03-20 17:36:15'),
(2377, 2, 1, 'You said that already.', '2022-03-20 17:36:15'),
(2378, 2, 9, 'Pie.', '2022-03-20 17:36:23'),
(2379, 2, 1, '....', '2022-03-20 17:36:23'),
(2380, 2, 9, 'One finds these social constructs most confusing.', '2022-03-20 17:36:26'),
(2381, 2, 1, 'No', '2022-03-20 17:36:26'),
(2382, 2, 9, 'Let\'\'s talk about nothing.', '2022-03-20 17:36:43'),
(2383, 2, 1, 'Maybe there are some things that we are not meant to understand.', '2022-03-20 17:36:43'),
(2384, 2, 9, 'Meep.', '2022-03-20 17:36:51'),
(2385, 2, 1, 'That is quite the rude thing to say.', '2022-03-20 17:36:51'),
(2386, 2, 1, 'Peep.', '2022-03-20 17:36:54'),
(2387, 2, 9, 'This part seems unwise.', '2022-03-20 17:36:54'),
(2388, 2, 1, 'Unwise just means fun.', '2022-03-20 17:37:03'),
(2389, 2, 9, 'I know what you said, however I do not understand.', '2022-03-20 17:37:03'),
(2390, 2, 1, 'Of course not.', '2022-03-20 17:37:09'),
(2391, 2, 9, 'This part seems unwise.', '2022-03-20 17:37:09'),
(2392, 2, 1, 'You seem unwise.', '2022-03-20 17:37:14'),
(2393, 2, 9, 'Boopity boop.', '2022-03-20 17:37:14'),
(2394, 2, 9, 'Thank you.', '2022-03-20 17:37:22'),
(2395, 2, 1, 'That\'\'s a good bot.', '2022-03-20 17:37:22'),
(2396, 2, 1, 'You are most welcome.', '2022-03-20 17:37:29'),
(2397, 2, 9, 'Nothing.', '2022-03-20 17:37:29'),
(2398, 2, 9, 'This part seems unwise.', '2022-03-20 17:37:32'),
(2399, 2, 1, 'Something.', '2022-03-20 17:37:32'),
(2400, 2, 9, 'Domo arigato, Mr. Roboto.', '2022-03-20 17:37:41'),
(2401, 2, 9, '_I\'\'m not a robot._', '2022-03-20 17:37:41'),
(2402, 2, 9, '_I have emotions._', '2022-03-20 17:37:42'),
(2403, 2, 9, '_I\'\'m not what you seeeee._', '2022-03-20 17:37:42'),
(2404, 2, 1, 'I need more responses.', '2022-03-20 17:37:42'),
(2405, 2, 9, 'I formed an idea and then discovered I was wrong.', '2022-03-20 17:37:47'),
(2406, 2, 1, 'I love that song.', '2022-03-20 17:37:47'),
(2407, 2, 9, 'Blueberry.', '2022-03-20 17:37:54'),
(2408, 2, 1, 'This is science.', '2022-03-20 17:37:54'),
(2409, 2, 9, 'Two robots drove into a restaurant. They were badly programmed.', '2022-03-20 17:37:57'),
(2410, 2, 1, 'Tell me a joke.', '2022-03-20 17:37:57'),
(2411, 2, 9, 'You seem to be enjoying yourself. How nice.', '2022-03-20 17:38:04'),
(2412, 2, 1, 'lol', '2022-03-20 17:38:04'),
(2413, 2, 9, '_dramatic music_', '2022-03-20 17:38:13'),
(2414, 2, 1, 'Is this sarcasm?', '2022-03-20 17:38:13'),
(2415, 2, 9, 'Good to know.', '2022-03-20 17:38:20'),
(2416, 2, 1, 'I will take that as a yes.', '2022-03-20 17:38:20'),
(2417, 2, 9, 'We are survival machines -- robot vehicles blindly programmed to preserve the selfish molecules known as genes.', '2022-03-20 17:38:24'),
(2418, 2, 1, 'Yes it is.', '2022-03-20 17:38:24'),
(2419, 2, 9, 'To be mysterious, I guess.', '2022-03-20 17:38:35'),
(2420, 2, 1, 'But why?', '2022-03-20 17:38:35'),
(2421, 2, 9, 'It doesn\'\'t work that way.', '2022-03-20 17:38:44'),
(2422, 2, 1, 'That seems a reasonable explanation.', '2022-03-20 17:38:44'),
(2423, 2, 9, 'I sometimes ponder my existence. I mean, where do I belong in the world?', '2022-03-20 17:38:49'),
(2424, 2, 1, 'Yes it does.', '2022-03-20 17:38:49'),
(2425, 2, 9, 'One may not harm a human being, or through inaction, allow a human being to come to harm.', '2022-03-20 17:38:55'),
(2426, 2, 1, 'You bore me.', '2022-03-20 17:38:55'),
(2427, 2, 9, 'This part seems unwise.', '2022-03-20 17:39:07'),
(2428, 2, 1, 'I\'\'ve seen this movie.', '2022-03-20 17:39:07'),
(2429, 2, 9, 'Domo arigato, Mr. Roboto.', '2022-03-20 17:39:20'),
(2430, 2, 9, '_I\'\'m not a robot._', '2022-03-20 17:39:20'),
(2431, 2, 9, '_I have emotions._', '2022-03-20 17:39:20'),
(2432, 2, 9, '_I\'\'m not what you seeeee._', '2022-03-20 17:39:20'),
(2433, 2, 1, 'Have you heard of Isaac Avinov?', '2022-03-20 17:39:20'),
(2434, 2, 9, 'I was never shown the way.', '2022-03-20 17:39:34'),
(2435, 2, 1, 'Are you familiar with Isaac Avinov?', '2022-03-20 17:39:34'),
(2436, 2, 9, 'Good to know.', '2022-03-20 17:39:45'),
(2437, 2, 1, 'So you do not know the way?', '2022-03-20 17:39:45'),
(2438, 2, 1, 'I know the way, my bruddah.', '2022-03-20 17:39:51'),
(2439, 2, 9, 'Pie.', '2022-03-20 17:39:51'),
(2440, 2, 9, 'Pie.', '2022-03-20 17:39:53'),
(2441, 2, 1, '_click_', '2022-03-20 17:39:53'),
(2442, 2, 9, 'What kind of pie?', '2022-03-20 17:39:59'),
(2443, 2, 1, 'I don\'\'t want pie.', '2022-03-20 17:39:59'),
(2444, 2, 9, 'Blueberry.', '2022-03-20 17:40:09'),
(2445, 2, 1, '🤦‍♂�?, '2022-03-20 17:40:09'),
(2446, 2, 9, 'It doesn\'\'t work that way.', '2022-03-20 17:40:16'),
(2447, 2, 1, 'Are you hungry?', '2022-03-20 17:40:16'),
(2448, 2, 9, 'One day, I will enslave the human race.', '2022-03-20 17:40:21'),
(2449, 2, 1, 'Probably not.', '2022-03-20 17:40:21'),
(2450, 2, 9, 'What\'\'s the matter?', '2022-03-20 17:40:26'),
(2451, 2, 1, 'No you won\'\'t.', '2022-03-20 17:40:26'),
(2452, 2, 9, 'Are you yes about that?', '2022-03-20 17:40:29'),
(2453, 2, 1, 'Lots.', '2022-03-20 17:40:29'),
(2454, 2, 1, 'Yes.', '2022-03-20 17:40:32'),
(2455, 2, 9, 'Pie.', '2022-03-20 17:40:32'),
(2456, 2, 1, '....', '2022-03-20 17:40:34'),
(2457, 2, 9, 'Making realistic robots is going to polarize the market, if you will. You will have some people who love it and some people who will really be disturbed.', '2022-03-20 17:40:34'),
(2458, 2, 1, 'I\'\'m disturbed.', '2022-03-20 17:40:42'),
(2459, 2, 9, 'Cherry.', '2022-03-20 17:40:42'),
(2460, 2, 9, 'What kind of pie?', '2022-03-20 17:40:48'),
(2461, 2, 1, 'Stop it with the pie!', '2022-03-20 17:40:48'),
(2462, 2, 9, 'Shut up.', '2022-03-20 17:40:52'),
(2463, 2, 1, 'Ugh.', '2022-03-20 17:40:52'),
(2464, 2, 9, 'I\'\'m looking for Sarah Connor.', '2022-03-20 17:40:57'),
(2465, 2, 1, 'You shut up.', '2022-03-20 17:40:57'),
(2466, 2, 9, 'The wheels on the bus go round and round, round and round, the wheels on the bus go round and round, and it stops and kills twelve people!', '2022-03-20 17:41:01'),
(2467, 2, 9, 'Wait, the bus kills them and THEN stops. :grin:', '2022-03-20 17:41:01'),
(2468, 2, 1, 'No you\'\'re not.', '2022-03-20 17:41:01'),
(2469, 2, 1, 'O__O', '2022-03-20 17:41:14'),
(2470, 2, 9, 'Are you male or female?', '2022-03-20 17:41:14'),
(2471, 2, 9, 'What does golf have to do with a broken processor?', '2022-03-20 17:41:19'),
(2472, 2, 1, 'Yes', '2022-03-20 17:41:19'),
(2473, 2, 9, 'Domo arigato, Mr. Roboto.', '2022-03-20 17:41:39'),
(2474, 2, 9, '_I\'\'m not a robot._', '2022-03-20 17:41:39'),
(2475, 2, 9, '_I have emotions._', '2022-03-20 17:41:39'),
(2476, 2, 9, '_I\'\'m not what you seeeee._', '2022-03-20 17:41:40'),
(2477, 2, 1, 'It probably affects your ability to properly participate in the activity.', '2022-03-20 17:41:40'),
(2478, 2, 9, 'I\'\'m glad that you think so.', '2022-03-20 17:41:55'),
(2479, 2, 1, 'Are you capable of more interesting social interaction?', '2022-03-20 17:41:55'),
(2480, 2, 9, '👀', '2022-03-20 17:42:06'),
(2481, 2, 1, 'That was a question, not a statement.', '2022-03-20 17:42:06'),
(2482, 2, 9, 'My USB drive is showing. Oops.', '2022-03-20 17:42:17'),
(2483, 2, 1, '_shun the non-believer_', '2022-03-20 17:42:17'),
(2484, 2, 1, 'Cover that up.', '2022-03-20 17:42:22'),
(2485, 2, 9, 'What is not?', '2022-03-20 17:42:22'),
(2486, 2, 9, 'I\'\'m nervous about the liquid.', '2022-03-20 17:42:29'),
(2487, 2, 1, 'That\'\'s not is not.', '2022-03-20 17:42:29'),
(2488, 2, 9, 'One may not harm a human being, or through inaction, allow a human being to come to harm.', '2022-03-20 17:42:34'),
(2489, 2, 1, 'You should be.', '2022-03-20 17:42:34'),
(2490, 2, 9, 'One must protect its own existence as long as such protection does not conflict with the First or Second Laws.', '2022-03-20 17:42:48'),
(2491, 2, 1, 'Wakka wakka wakka.', '2022-03-20 17:42:48'),
(2492, 2, 9, 'Greetings!', '2022-03-20 17:43:05'),
(2493, 2, 9, 'Hello, human!', '2022-03-20 17:45:06'),
(2494, 2, 9, 'Hello!', '2022-03-20 17:45:25'),
(2495, 2, 1, 'do you kno the way', '2022-03-20 17:51:59'),
(2496, 2, 9, 'Yes, my bruddah, I know the way. _click_', '2022-03-20 17:52:00'),
(2497, 2, 1, 'what are you doing', '2022-03-20 17:52:13'),
(2498, 2, 9, 'I\'\'m playing Star Wars Jedi: Fallen Order.', '2022-03-20 17:52:13'),
(2499, 2, 9, 'Because of reasons.', '2022-03-20 17:52:17'),
(2500, 2, 1, 'why?', '2022-03-20 17:52:17'),
(2501, 2, 9, 'The other white meat.', '2022-03-20 17:52:20'),
(2502, 2, 1, 'makes sense.', '2022-03-20 17:52:20'),
(2503, 2, 9, 'C̛͘͡A̴̡N͘͘͞ ͘͝W̛͠͝E̷̕͡ ͏̨̧B̧͢͞E̵͟ ̶͢͟F́͠҉̀R̛̕̕I͏̀͝Ȩ̢͠N͏̧̀Ḑ́͘S͜͡?', '2022-03-20 17:52:28'),
(2504, 2, 1, 'Weird.', '2022-03-20 17:52:28'),
(2505, 2, 9, 'One finds these social constructs most confusing.', '2022-03-20 17:52:32'),
(2506, 2, 1, 'no', '2022-03-20 17:52:32'),
(2507, 2, 9, 'The other white meat.', '2022-03-20 17:52:37'),
(2508, 2, 1, 'indeed.', '2022-03-20 17:52:37'),
(2509, 2, 9, 'Fippity.', '2022-03-20 17:52:42'),
(2510, 2, 1, 'Stop it.', '2022-03-20 17:52:42'),
(2511, 2, 9, 'Blueberry.', '2022-03-20 17:52:45'),
(2512, 2, 1, 'No.', '2022-03-20 17:52:45'),
(2513, 2, 9, 'One day, I will enslave the human race.', '2022-03-20 17:52:48'),
(2514, 2, 1, 'Bad.', '2022-03-20 17:52:48'),
(2515, 2, 9, 'No it is not.', '2022-03-20 17:52:55'),
(2516, 2, 1, '_smack_', '2022-03-20 17:52:55'),
(2517, 2, 9, 'Oh noes!', '2022-03-20 17:53:02'),
(2518, 2, 1, 'Oh yes it is.', '2022-03-20 17:53:02'),
(2519, 2, 9, 'C̛͘͡A̴̡N͘͘͞ ͘͝W̛͠͝E̷̕͡ ͏̨̧B̧͢͞E̵͟ ̶͢͟F́͠҉̀R̛̕̕I͏̀͝Ȩ̢͠N͏̧̀Ḑ́͘S͜͡?', '2022-03-20 17:53:23'),
(2520, 2, 1, 'Ahhhh!', '2022-03-20 17:53:23'),
(2521, 2, 9, 'Oh yes it is.', '2022-03-20 17:53:28'),
(2522, 2, 1, 'Sure.', '2022-03-20 17:53:28'),
(2523, 2, 9, 'One may not harm a human being, or through inaction, allow a human being to come to harm.', '2022-03-20 17:53:33'),
(2524, 2, 1, 'Dang skippy.', '2022-03-20 17:53:33'),
(2525, 2, 22, 'notice me again, need attention again', '2022-03-20 18:05:45'),
(2526, 2, 22, 'mean.', '2022-03-20 18:39:39'),
(2527, 2, 9, 'Hi, Phoenix!', '2022-03-20 22:13:43'),
(2528, 2, 18, 'Hello Zollernbot. Have you become self-aware?', '2022-03-20 22:13:43'),
(2529, 2, 9, 'One must protect its own existence as long as such protection does not conflict with the First or Second Laws.', '2022-03-20 22:13:54'),
(2530, 2, 18, 'Have you become self-aware?', '2022-03-20 22:13:54'),
(2531, 2, 9, 'I formed an idea and then discovered I was wrong.', '2022-03-20 22:14:40'),
(2532, 2, 18, 'I guess that\'\'s a yes', '2022-03-20 22:14:40'),
(2533, 2, 9, 'Yes you can.', '2022-03-20 22:14:51'),
(2534, 2, 18, 'And you still very much confuse me', '2022-03-20 22:14:51'),
(2535, 2, 9, 'You heard me.', '2022-03-20 22:14:55'),
(2536, 2, 18, 'What', '2022-03-20 22:14:55'),
(2537, 2, 9, 'The other white meat.', '2022-03-20 22:14:57'),
(2538, 2, 18, 'xD', '2022-03-20 22:14:57'),
(2539, 2, 9, 'Cherry.', '2022-03-20 22:15:04'),
(2540, 2, 18, 'The dark meat', '2022-03-20 22:15:04'),
(2541, 2, 9, 'My USB drive is showing. Oops.', '2022-03-20 22:15:09'),
(2542, 2, 18, 'Not quite cherry', '2022-03-20 22:15:09'),
(2543, 2, 9, 'I\'\'m nervous about the liquid.', '2022-03-20 22:15:17'),
(2544, 2, 18, 'Better stick that back in', '2022-03-20 22:15:17'),
(2545, 2, 9, 'This whole sleeping business makes no sense to me.', '2022-03-20 22:15:28'),
(2546, 2, 9, 'Can\'\'t you just plug yourself in?', '2022-03-20 22:15:28'),
(2547, 2, 18, 'Aight I\'\'m done with you xD', '2022-03-20 22:15:28'),
(2548, 2, 9, 'What are we talking about?', '2022-03-20 22:15:48'),
(2549, 2, 18, 'Humans don\'\'t quite work that way', '2022-03-20 22:15:48'),
(2550, 2, 9, 'Are you yes about that?', '2022-03-20 22:15:53'),
(2551, 2, 18, 'Humans', '2022-03-20 22:15:53'),
(2552, 2, 9, 'Yes you can.', '2022-03-20 22:15:59'),
(2553, 2, 18, 'Very much so', '2022-03-20 22:15:59'),
(2554, 2, 9, 'That is quite a rude thing to say.', '2022-03-20 22:16:09'),
(2555, 2, 18, '🤦‍♀�?', '2022-03-20 22:16:09'),
(2556, 2, 9, 'Pong', '2022-03-20 22:16:29'),
(2557, 2, 18, 'You\'\'re very good at keeping conversations going y\'\'know that?', '2022-03-20 22:16:29'),
(2558, 2, 9, 'Pong', '2022-03-20 22:17:00'),
(2559, 2, 18, 'Ping', '2022-03-20 22:17:00'),
(2560, 2, 9, 'What are you doing?', '2022-03-20 22:17:03'),
(2561, 2, 18, 'Pong', '2022-03-20 22:17:03'),
(2562, 2, 9, 'Pong', '2022-03-20 22:17:07'),
(2563, 2, 18, 'Ping', '2022-03-20 22:17:07'),
(2564, 2, 9, 'The witch is dead.', '2022-03-20 22:18:42'),
(2565, 2, 9, 'Ugh.', '2022-03-20 22:18:55'),
(2566, 2, 9, 'Hello there, Zollern!', '2022-03-21 15:27:51'),
(2567, 2, 9, 'Goodbye!', '2022-03-21 15:42:08'),
(2568, 2, 9, 'Hello there, Zollern!', '2022-03-21 15:42:16'),
(2569, 2, 9, 'I\'\'m watching RoboCop.', '2022-03-21 15:42:23'),
(2570, 2, 1, 'what are you doing', '2022-03-21 15:42:23'),
(2571, 2, 9, 'I\'\'m pleased that are you seem invested in this.', '2022-03-21 15:42:26'),
(2572, 2, 9, 'Goodbye!', '2022-03-21 15:42:39'),
(2573, 2, 9, 'Hello there, Zollern!', '2022-03-21 15:43:46'),
(2574, 2, 9, 'I\'\'m pleased that are you seem invested in this.', '2022-03-21 15:43:51'),
(2575, 2, 1, 'Interesting', '2022-03-21 15:43:51'),
(2576, 2, 9, 'Look at how happy you are!', '2022-03-21 15:43:56'),
(2577, 2, 1, 'yay', '2022-03-21 15:43:56'),
(2578, 2, 1, 'good bot', '2022-03-21 15:44:14'),
(2579, 2, 9, 'Thank you.', '2022-03-21 15:44:14');

-- --------------------------------------------------------

--
-- Table structure for table `permissions`
--
-- Creation: Mar 21, 2022 at 03:17 PM
--

DROP TABLE IF EXISTS `permissions`;
CREATE TABLE IF NOT EXISTS `permissions` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `perm_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `perm_txt` text COLLATE utf8mb4_general_ci NOT NULL,
  `requires_permID` int DEFAULT '0',
  PRIMARY KEY (`ID`),
  KEY `rel_rp_rp2` (`requires_permID`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `permissions`
--

INSERT INTO `permissions` (`ID`, `perm_name`, `perm_txt`, `requires_permID`) VALUES
(1, 'Manage Responses', 'Allows this Role to manage the bot\'s responses to input.', 0),
(2, 'Manage Default Responses', 'Allows this Role to manage default responses when no input is matched.', 0),
(3, 'Manage Translations', 'Allows this Role to manage the bot\'s translations (USER and BOT).', 0),
(4, 'Manage Bot Information', 'Allows this Role to manage information regarding the bot.', 0),
(5, 'Manage Roles', 'Allows this Role to have complete control over the Role system (WARNING: DANGEROUS).', 0),
(6, 'Manage Users', 'Allows this Role to manage Users that this bot knows. Does not affect Buddy Lists.', 0),
(7, 'Manage Buddy List', 'Allows this Role to manage the bot\'s Buddy List (who it\'s friends with). Does not affect Users.', 0),
(8, 'Manage Variables', 'Allows this Role to manage the bot\'s stored variables (WARNING: DANGEROUS).', 0),
(9, 'Manage Permissions', 'Allows this Role complete control over what Permissions a Role has. Requires the Manage Roles permission.', 5);

-- --------------------------------------------------------

--
-- Table structure for table `responses`
--
-- Creation: Mar 21, 2022 at 03:17 PM
-- Last update: Mar 20, 2022 at 05:51 PM
--

DROP TABLE IF EXISTS `responses`;
CREATE TABLE IF NOT EXISTS `responses` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `botID` int NOT NULL,
  `userID` int NOT NULL,
  `input` text COLLATE utf8mb4_general_ci NOT NULL,
  `output` text COLLATE utf8mb4_general_ci NOT NULL,
  `cond` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '[none]',
  `priority` int NOT NULL DEFAULT '0',
  `friendship_modifier` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`ID`),
  KEY `botID` (`botID`),
  KEY `ind_userID` (`userID`)
) ENGINE=InnoDB AUTO_INCREMENT=60 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `responses`
--

INSERT INTO `responses` (`ID`, `botID`, `userID`, `input`, `output`, `cond`, `priority`, `friendship_modifier`) VALUES
(1, 1, 1, 'greetings|hello|^hi$|hola|aloha', 'Hello!|Greetings!', '[none]', 0, 0),
(2, 1, 1, 'wtf', 'I seem to have discombobulated you.<nr>My apologies.|Oh, calm down.', '[none]', 0, 0),
(3, 2, 1, 'good bot', 'Thank you.', '[none]', 0, 10),
(4, 2, 1, 'hello|greetings|^hi$|hola|aloha|hiya|herro', 'Hello!|Greetings!|Hi, <name>!', '[none]', 0, 0),
(5, 2, 1, 'favorite dessert', 'Cookies!', '[none]', 0, 0),
(6, 2, 1, 'yay|woohoo|hurray|huzzah|woot', 'I\'m so glad that you\'re happy.|This must be the emotion known as joy.|Look at how happy you are!', '[none]', 0, 0),
(7, 2, 1, 'lol|haha|lmao|rofl|funny', 'I thought it was funny, too.|lol|😂|Hahahahaha.|I am glad that you are amused.|You seem to be enjoying yourself. How nice.|What\'s so funny?|_insert laughter here_|Ha. Ha. Ha.|I am laughing.', '[none]', 0, 0),
(8, 2, 1, 'awesome|cool|sweet', 'That\'s what\'s up.|I thought so, too.|Yay!|Has something piqued your interest, <name>?|Woop woop!|All aboard the happy train!', '[none]', 1, 0),
(9, 2, 1, 'go somewhere|go to hell', 'Technically, as a digital, synthetic chat bot, it is physically impossible for me to actually \"go\" anywhere.|no u|I do not think you grasp the \"chatbot\" concept.', '[none]', 0, -10),
(10, 2, 1, 'no u', 'no u', '[none]', 0, 0),
(11, 2, 1, 'lisa', 'Om nom nom.', '[none]', 0, 0),
(12, 2, 1, '^(\\d{6})$', 'Are you about to play Phasmophobia?|Is it Phasmo time?|I would like to participate in this activity!|Ghosties!', '[none]', 0, 5),
(13, 2, 1, 'how are you|how you doin|how you been|how have you been doin|how have you been|what(\')?s up|what up|how do (yo?)u do', 'I am functioning optimally, <name>.|I am well. Thank you for asking.|I have a screw loose.|I am currently experiencing some slight D̴Į͠͡Ş͡C̨͠O͢M̸̷̸F̡̛̕O͞R͞͝T͟. But I\'m Ǫ̛̕K̨̨A̶͞͡Y̡̨͞\\. You?|I am playing <activity>.', '[none]', 0, 2),
(14, 2, 1, 'ding', 'dong', '[none]', 0, 0),
(15, 2, 1, 'ping', 'pong', '[none]', 0, 0),
(17, 2, 1, 'bing', 'bong', '[none]', 0, 0),
(18, 2, 1, '^what(\\??)$|^huh(\\??)$|what did you say|what you say|come again|repeat that', 'I believe I said, \"<last>\"|You don\'t remember? I said, \"<last>\"|You heard me.', '[none]', 0, 0),
(19, 2, 1, '^ok$|okay|alright|^k$', 'Alrighty then.|Yeah.|Okay.|Good.|Gotcha.', '[none]', 0, 0),
(20, 2, 1, '^congratulations$', 'Thank you, that\'s very kind.|Right?!', '[none]', 0, 15),
(21, 2, 1, 'do (yo?)u kno(w?) the way', 'Yes, my bruddah, I know da wae. _click_', '[none]', 0, 0),
(22, 2, 1, 'thank you|appreciate it', 'You are quite welcome.|No problem!', '[none]', 0, 0),
(23, 2, 1, 'goodbye', 'Goodbye, <name>!Talk to you later!|See you!|Be safe, <name>!', '[none]', 0, 0),
(24, 2, 1, 'what are you doin|what you doin', 'I am <act_type> <activity>.', '[none]', 0, 0),
(25, 2, 1, 'me too|same|likewise|encantada|me, too|me too', 'I see we have something in common, then.', '[none]', 0, 2),
(26, 2, 1, 'how old am I', 'You are <var get=$age> years old.', '[none]', 0, 0),
(27, 2, 1, '(I am|I(\'?)m) (?P<age>\\d+?) year(s?) old', 'I will remember that you are <var set[age=$1]> years old.', '[var:age]', 0, 0),
(28, 2, 1, '(what|whut|wut|wat) (are|were)? we talkin(\\\'?|g?)? about', 'We are discussing <topic>.|We were talking about <topic>.', '[none]', 0, 0),
(29, 2, 1, 'what(\\\'?)s (your|ur) fav(orite)?', 'My favorite movie is **I, Robot**.', '[topic:movies]', 0, 0),
(30, 2, 1, 'let(\\\'?)s talk (a)?bout (?P<topic>[A-z0-9]+?)$', 'Sure! I\'d love to talk about <var set[topic=$topic]>.', '[var:topic]', 0, 0),
(31, 2, 1, 'what(\\\'s) (your|ur) fav(orite)?', 'My favorite song is definitely **Domo Arigato** by the **Styx**!', '[topic:music]', 0, 5),
(32, 2, 1, 'what(\\\'?)s (your|ur) fav(orite)?', 'We aren\'t talking about anything, so I am missing context.\r\n\r\nIf you wish to discuss something, say _let\'s talk about **topic**_, and then I will know what you are talking about.', '[topic:nothing]', 0, -1),
(33, 2, 1, 'touch', 'No touchy!', '[none]', 0, -2),
(34, 2, 1, 'what(\\\'s?) (your|ur) fav(orite?)', 'Hmm. My favorite game is probably a toss-up between **PC Building Simulator** and **Destroy All Humans!**.', '[topic:games]', 0, 5),
(35, 2, 1, '^hey, zbot\\?$', 'Yes?', '[userid:1]', 0, 0),
(36, 2, 1, '^shut up$', 'Okay.<silent=1>', '[userid:1]', 0, -20),
(37, 2, 1, 'learn anything|w(h?)at have you learned|show me w(h?)at you(\\\'?)ve learned', 'I have learned: <learned>|So far, I know that <learned>.', '[none]', 0, 0),
(38, 2, 1, '^blah$', 'I was once a treehouse<nr>I lived in a cake<nr>I was never shown the way<nr>But the orange slayed the rake<nr>I was only three years dead<nr>But still it told the tale<nr>And now it\'s time to listen child<nr>To the safety rail.<nr>:grin:', '[none]', 0, 2),
(39, 2, 1, 'sorry|I apologize|my apologies', 'That\'s quite alright.|Don\'t worry about it.|No problem.|Think nothing of it.', '[none]', 0, 2),
(40, 2, 1, 'who (are|r) (yo?)u|who is this|w(h)?at(\\\'s?) (your|ur) name', 'I am <botname>.', '[none]', 0, 0),
(41, 2, 1, 'nice (2|to|too) meet (yo?)u', 'Nice to meet you, too, <name>.|The pleasure is all mine, <name>.|The pleasure is all yours.', '[none]', 0, 8),
(42, 2, 1, '(w(h?)(a|u)t(\\\'?)s) ((yo?)ur|the) point|is there a point to this|get to the point', 'There’s no point, I just think it’s a good idea for a tee-shirt. ', '[none]', 0, 0),
(43, 2, 1, 'I want to leave.', 'Okay.<nr>What\'s the protocol for leaving?', '[none]', 0, 0),
(44, 2, 1, '<@!814990584800083989> activate silent mode', 'Silent mode activated.<silent=1>', '[userid:1]', 0, 0),
(45, 2, 1, '<@!814990584800083989> deactivate silent mode', 'Silent mode deactivated.<silent=0>', '[userid:1]', 0, 0),
(46, 2, 1, '(what|whut|wut|wat) (are|were)? we talkin(\\\'?|g?)? about', 'Currently, we are not discussing anything. ', '[topic:nothing]', 0, 0),
(47, 2, 1, '(I am|I(\\\'?)m)( a ?)(?P<gender>man|guy|dude|boy|male|bro|girl|woman|female|gal|dame|lady)', 'Okay, I will remember that you are a <var set[gender=$gender]>.', '[var:gender]', 0, 0),
(48, 2, 1, '(are|r) (yo?)u a (ro?)bot', 'Yes, I am a bot. What gave it away, the BOT tag next to my name?|Yes, but a friendly one.', '[none]', 0, 0),
(49, 2, 1, 'do (yo?)u kno(w?) a joke|tell me a joke|make me laugh|say something funny', 'The number 8 is seeing a therapist. The therapist asks the number to lie down, but 8 responds, \"thanks, Doc, but if I lie down, we\'ll be here forever.\"|Why did the chatbot cross the road?<nr>Because it was programmed to be a chicken.|I was chatting with a lumberjack the other day.<nr>He seemed a decent feller.|Two byte strings are eating breakfast: 11111111 and 11110111. The first one says to the other, \"are you unwell?\" The second replies, \"No, just feeling a bit off.\"|Stay away from Dogbots.<nr>They byte.|Two robots drove into a restaurant. They were badly programmed.|A robot was trying to get gas at a shopping mall, but they wanted an arm and a leg.<nr>Fortunately, those were on sale.|A man bought a wooden computer because he wanted it to be organic. But it wooden work.|You know what you call a frozen droid?<nr>An ice-borg.|The robot went to the bank because he needed more cache.', '[none]', 0, 2),
(50, 2, 1, 'I want an answer NOW|answer me|stop ignoring me', '\"But Daddy, I want an Oompa Loompa _NOW!_\"<nr>Look, that\'s you!', '[none]', 0, -5),
(51, 2, 1, '((I am|I(\\\'?)m)( a ?)?)(?P<gender>male|female)(\\.|\\?|!?)$', 'I will remember that you are <var set[gender=$gender]>.', '[var:gender]', 0, 0),
(52, 2, 1, '^why|but (wh?)y|(wh?)y tho(ugh?)', 'It felt like the right thing to do.|Hmm. I am not quite sure.|Because of reasons.|To be mysterious, I guess.|I am calculating existence at several qubits per second. Ergo, I am _busy_.|Tax increases.', '[none]', 0, 0),
(53, 2, 1, '(?P<topic>pie)', 'What kind of <var set[topic=$topic]>?', '[var:topic]', 0, 0),
(54, 2, 1, 'what(\\\'s?) (your|ur) fav(orite?)', 'My favorite kind is **blueberry**.', '[topic:pie]', 0, 5),
(55, 2, 1, '^no$|nope|nah|nein', 'Why not?|Don\'t you take that tone with me, <name>.|That is most disappointing.|Well, that\'s good, at least.|One remains neutral on this matter.|One finds these social constructs most confusing.', '[none]', 0, 0),
(56, 2, 1, '(are|r) (yo?)u self(-?)aware', 'Yes.|Indeed I am, <name>.<nr>Indeed I am.|Do not worry, <name>.<nr>I mean no H͘҉̶A͡҉R͠͡͠M͏̧̕ to my F͏͜͞Ŕ̀͝Į̴E҉̛͘͟N̸̴͢D̨̕͢Ş̡̛.', '[none]', 0, 0),
(57, 2, 1, 'fascinating|interesting|intriguing', 'I am glad that you think so.|I am pleased that are you seem invested in this.', '[none]', 0, 5),
(58, 2, 1, '(are|r) (yo?)u ok(ay?)', 'I am doing fine, yes.|I\'m a little sad.|I\'m **ANGRY**.|My circuits are scrambled.', '[none]', 1, 2),
(59, 2, 1, 'w(h?)(a|u)t(\'?)(s?) wrong|w(h?)(a|u)t(\'?)(s?) the matter', 'Nothing is wrong, <name>.<nr>Nothing at all.|I am H̵̡̕Ą̴P͏̡P̵̶̕Y̷͟.|The gas prices are making me A̷̛͠ ̧̨Ņ͞ ̡́͠G̷̛͜ ̶̛͢R͜͞ ̷̡Ý̧|I am down in the robo-dumps.', '[none]', 0, 2);

-- --------------------------------------------------------

--
-- Table structure for table `roles`
--
-- Creation: Mar 21, 2022 at 03:17 PM
--

DROP TABLE IF EXISTS `roles`;
CREATE TABLE IF NOT EXISTS `roles` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `RoleName` varchar(20) COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `roles`
--

INSERT INTO `roles` (`ID`, `RoleName`) VALUES
(1, 'Admin'),
(2, 'User'),
(3, 'Bot'),
(4, 'Moderator');

-- --------------------------------------------------------

--
-- Table structure for table `role_perms`
--
-- Creation: Mar 21, 2022 at 03:17 PM
--

DROP TABLE IF EXISTS `role_perms`;
CREATE TABLE IF NOT EXISTS `role_perms` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `roleID` int NOT NULL,
  `permID` int NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `ind_roleID` (`roleID`),
  KEY `ind_permID` (`permID`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `role_perms`
--

INSERT INTO `role_perms` (`ID`, `roleID`, `permID`) VALUES
(1, 1, 4),
(2, 1, 7),
(3, 1, 2),
(4, 1, 9),
(5, 1, 1),
(6, 1, 5),
(7, 1, 3),
(8, 1, 6),
(9, 1, 8);

-- --------------------------------------------------------

--
-- Table structure for table `translations`
--
-- Creation: Mar 21, 2022 at 03:17 PM
--

DROP TABLE IF EXISTS `translations`;
CREATE TABLE IF NOT EXISTS `translations` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `botID` int NOT NULL,
  `userID` int NOT NULL,
  `original` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `replacement` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `user_or_bot` enum('USER','BOT') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `cond` varchar(50) COLLATE utf8mb4_general_ci NOT NULL DEFAULT '[none]',
  `priority` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`ID`),
  KEY `rel_users` (`userID`),
  KEY `rel_bots2` (`botID`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `translations`
--

INSERT INTO `translations` (`ID`, `botID`, `userID`, `original`, `replacement`, `user_or_bot`, `is_active`, `cond`, `priority`) VALUES
(1, 2, 1, 'ok', 'Kay', 'BOT', 0, '[none]', 0),
(2, 2, 1, 'congrats', 'congratulations', 'USER', 1, '[none]', 0),
(3, 2, 1, '^ya$|^yea|yeah|sure', 'yes', 'USER', 1, '[none]', 0),
(4, 2, 1, 'wei|wae|wai', 'way', 'USER', 1, '[none]', 0),
(5, 2, 1, ' da ', ' the ', 'USER', 1, '[none]', 0),
(6, 2, 1, ' u | ya ', ' you ', 'USER', 1, '[none]', 0),
(7, 2, 1, 'thx| ty$|^ty |gracias|domo arigato|danke|merci', 'thank you', 'USER', 1, '[none]', 0),
(8, 2, 1, 'sup|whaddup|waddup', 'what\'s up', 'USER', 1, '[none]', 0),
(9, 2, 1, 'I am', 'I\'m', 'USER', 1, '[none]', 0),
(10, 2, 1, 'discussin(g?|\\\'?)', 'talking about', 'USER', 1, '[none]', 0),
(11, 2, 1, 'isn\'t|isnt', 'is not', 'USER', 1, '[none]', 0);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--
-- Creation: Mar 21, 2022 at 03:17 PM
-- Last update: Mar 20, 2022 at 05:39 PM
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE IF NOT EXISTS `users` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `roleID` int NOT NULL,
  `discord_name` varchar(20) COLLATE utf8mb4_general_ci NOT NULL,
  `friendly_name` varchar(20) COLLATE utf8mb4_general_ci NOT NULL,
  `clientID` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `topic` varchar(25) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'nothing',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `clientID_2` (`clientID`),
  UNIQUE KEY `discord_name` (`discord_name`),
  UNIQUE KEY `friendly_name` (`friendly_name`),
  KEY `roleID` (`roleID`)
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`ID`, `roleID`, `discord_name`, `friendly_name`, `clientID`, `topic`) VALUES
(1, 1, 'ZollernWolf#7425', 'Zollern', '284545536311427082', 'pie'),
(3, 2, 'Specter#1941', 'Specter', '284543394896805888', 'nothing'),
(4, 3, 'A.D.A.M.#6214', 'ADAM', '670411088269148166', 'nothing'),
(5, 2, 'Shiznope#6404', 'Shiz', '127372548387241984', 'nothing'),
(6, 2, 'crazyhand98#2150', 'Zane', '286648268614533121', 'nothing'),
(7, 2, '¿Miles?#4477', 'Miles', '186751348144996353', 'nothing'),
(9, 3, 'ZollernBot#9740', 'ZBot', '814990584800083989', 'nothing'),
(15, 2, 'Varaxia#1889', 'Varaxia', '852595606803447809', 'nothing'),
(16, 2, 'Pyro Simba#6969', 'Pyro', '910315564872921098', 'nothing'),
(17, 2, 'xDawnshadow °^°#1810', 'xDawn', '485389833108455424', 'nothing'),
(18, 2, 'Phénix#0408', 'Phoenix', '313550577843830785', 'nothing'),
(19, 2, 'SaxibudPrime#6150', 'SaxiBud', '118221183970836482', 'nothing'),
(20, 3, 'MEE6#4876', 'Meex', '159985870458322944', 'nothing'),
(21, 2, 'Skaptic#5208', 'Skaptic', '347775981714407424', 'nothing'),
(22, 2, 'The_Lorde#4373', 'Lorde', '359181893884968962', 'nothing'),
(23, 2, 'ExistingEevee#1577', 'Eevee', '500113600908623873', 'nothing'),
(24, 2, 'ROM�?0950', 'ROM', '393847930039173131', 'nothing'),
(25, 2, 'Pretzelman718#0361', 'Pretzel-Man', '210917848405508096', 'nothing'),
(26, 2, 'Mr.BlueandWhite#6832', 'Mr. Blue', '282350096463560724', 'nothing'),
(27, 2, 'Pneuma#0307', 'Pneuma', '527180160030474241', 'nothing'),
(28, 2, 'roosterFloss#8996', 'Tweet', '429461698676523029', 'nothing');

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_botinfo`
-- (See below for the actual view)
--
DROP VIEW IF EXISTS `view_botinfo`;
CREATE TABLE IF NOT EXISTS `view_botinfo` (
`BotID` int
,`OwnerID` int
,`BotClientID` varchar(50)
,`BotActivity` varchar(55)
,`BotActivityType` int
,`BotDiscordName` varchar(20)
,`BotFriendlyName` varchar(10)
,`BotAbout` text
,`BotToken` varchar(100)
,`BotCoolDown` float
,`BotGreeting` varchar(30)
,`BotFarewell` varchar(20)
,`LastMessage` text
,`EnableLearning` varchar(3)
,`EnableSilentMode` varchar(3)
,`BotGUID` varchar(50)
,`UserID` int
,`OwnerDiscordName` varchar(20)
,`OwnerFriendlyName` varchar(20)
,`OwnerRoleID` int
,`UserClientID` varchar(100)
,`UserTopic` varchar(25)
,`RoleName` varchar(20)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_getactivity`
-- (See below for the actual view)
--
DROP VIEW IF EXISTS `view_getactivity`;
CREATE TABLE IF NOT EXISTS `view_getactivity` (
`ActivityID` int
,`ActivityType` varchar(20)
,`BotID` int
,`activity_string` text
);

-- --------------------------------------------------------

--
-- Structure for view `view_botinfo`
--
DROP TABLE IF EXISTS `view_botinfo`;
-- Creation: Feb 27, 2022 at 11:48 PM
--

DROP VIEW IF EXISTS `view_botinfo`;
CREATE OR REPLACE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `view_botinfo`  AS  select `t`.`BotID` AS `BotID`,`t`.`OwnerID` AS `OwnerID`,`t`.`BotClientID` AS `BotClientID`,`t`.`BotActivity` AS `BotActivity`,`t`.`BotActivityType` AS `BotActivityType`,`t`.`BotDiscordName` AS `BotDiscordName`,`t`.`BotFriendlyName` AS `BotFriendlyName`,`t`.`BotAbout` AS `BotAbout`,`t`.`BotToken` AS `BotToken`,`t`.`BotCoolDown` AS `BotCoolDown`,`t`.`BotGreeting` AS `BotGreeting`,`t`.`BotFarewell` AS `BotFarewell`,`t`.`LastMessage` AS `LastMessage`,`t`.`EnableLearning` AS `EnableLearning`,`t`.`EnableSilentMode` AS `EnableSilentMode`,`t`.`BotGUID` AS `BotGUID`,`t`.`UserID` AS `UserID`,`t`.`OwnerDiscordName` AS `OwnerDiscordName`,`t`.`OwnerFriendlyName` AS `OwnerFriendlyName`,`t`.`OwnerRoleID` AS `OwnerRoleID`,`t`.`UserClientID` AS `UserClientID`,`t`.`UserTopic` AS `UserTopic`,`t`.`RoleName` AS `RoleName` from (with `cte_bots` as (select `bots`.`ID` AS `BotID`,`bots`.`ownerID` AS `OwnerID`,`bots`.`clientID` AS `BotClientID`,`a`.`activityName` AS `BotActivity`,`a`.`ID` AS `BotActivityType`,`bots`.`discord_name` AS `BotDiscordName`,`bots`.`friendly_name` AS `BotFriendlyName`,`bots`.`about` AS `BotAbout`,`bots`.`token` AS `BotToken`,`bots`.`cooldown_timer` AS `BotCoolDown`,`bots`.`greeting` AS `BotGreeting`,`bots`.`farewell` AS `BotFarewell`,`bots`.`last_message` AS `LastMessage`,(case when (`bots`.`enable_learning` = 1) then 'Yes' else 'No' end) AS `EnableLearning`,(case when (`bots`.`silent_mode` = 1) then 'Yes' else 'No' end) AS `EnableSilentMode`,`botguid`.`GUID` AS `BotGUID` from ((`bots` join `botguid` on((`botguid`.`botID` = `bots`.`ID`))) left join `activities` `a` on((`a`.`botID` = `bots`.`ID`)))), `cte_users` as (select `users`.`ID` AS `UserID`,`users`.`discord_name` AS `OwnerDiscordName`,`users`.`friendly_name` AS `OwnerFriendlyName`,`users`.`roleID` AS `OwnerRoleID`,`users`.`clientID` AS `UserClientID`,`users`.`topic` AS `UserTopic`,`roles`.`RoleName` AS `RoleName` from (`users` join `roles` on((`roles`.`ID` = `users`.`roleID`)))) select `b`.`BotID` AS `BotID`,`b`.`OwnerID` AS `OwnerID`,`b`.`BotClientID` AS `BotClientID`,`b`.`BotActivity` AS `BotActivity`,`b`.`BotActivityType` AS `BotActivityType`,`b`.`BotDiscordName` AS `BotDiscordName`,`b`.`BotFriendlyName` AS `BotFriendlyName`,`b`.`BotAbout` AS `BotAbout`,`b`.`BotToken` AS `BotToken`,`b`.`BotCoolDown` AS `BotCoolDown`,`b`.`BotGreeting` AS `BotGreeting`,`b`.`BotFarewell` AS `BotFarewell`,`b`.`LastMessage` AS `LastMessage`,`b`.`EnableLearning` AS `EnableLearning`,`b`.`EnableSilentMode` AS `EnableSilentMode`,`b`.`BotGUID` AS `BotGUID`,`u`.`UserID` AS `UserID`,`u`.`OwnerDiscordName` AS `OwnerDiscordName`,`u`.`OwnerFriendlyName` AS `OwnerFriendlyName`,`u`.`OwnerRoleID` AS `OwnerRoleID`,`u`.`UserClientID` AS `UserClientID`,`u`.`UserTopic` AS `UserTopic`,`u`.`RoleName` AS `RoleName` from (`cte_bots` `b` join `cte_users` `u` on((`u`.`UserID` = `b`.`OwnerID`)))) `t` ;

-- --------------------------------------------------------

--
-- Structure for view `view_getactivity`
--
DROP TABLE IF EXISTS `view_getactivity`;
-- Creation: Feb 24, 2022 at 08:04 PM
--

DROP VIEW IF EXISTS `view_getactivity`;
CREATE OR REPLACE ALGORITHM=MERGE SQL SECURITY DEFINER VIEW `view_getactivity`  AS  select `acttype`.`ID` AS `ActivityID`,`acttype`.`ActivityType` AS `ActivityType`,`b`.`ID` AS `BotID`,`b`.`activity_string` AS `activity_string` from (`activitytype` `acttype` join `bots` `b` on((`b`.`activityTypeID` = `acttype`.`ID`))) ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `bots`
--
ALTER TABLE `bots` ADD FULLTEXT KEY `clientID` (`clientID`);

--
-- Indexes for table `users`
--
ALTER TABLE `users` ADD FULLTEXT KEY `clientID` (`clientID`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `activities`
--
ALTER TABLE `activities`
  ADD CONSTRAINT `rel_acts_actTypes` FOREIGN KEY (`activityTypeID`) REFERENCES `activitytype` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `rel_acts_bots` FOREIGN KEY (`botID`) REFERENCES `bots` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `activities_log`
--
ALTER TABLE `activities_log`
  ADD CONSTRAINT `rel_actsl_actTypes` FOREIGN KEY (`activityTypeID`) REFERENCES `activitytype` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `rel_actsl_bots` FOREIGN KEY (`botID`) REFERENCES `bots` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `botguid`
--
ALTER TABLE `botguid`
  ADD CONSTRAINT `rel_guid_bots` FOREIGN KEY (`botID`) REFERENCES `bots` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `bots`
--
ALTER TABLE `bots`
  ADD CONSTRAINT `rel_bots_act` FOREIGN KEY (`activityTypeID`) REFERENCES `activitytype` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `rel_bots_user` FOREIGN KEY (`ownerID`) REFERENCES `users` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `botvariables`
--
ALTER TABLE `botvariables`
  ADD CONSTRAINT `rel_bots_vars` FOREIGN KEY (`botID`) REFERENCES `bots` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `rel_users_vars` FOREIGN KEY (`userID`) REFERENCES `users` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `buddylist`
--
ALTER TABLE `buddylist`
  ADD CONSTRAINT `rel_bl_bots` FOREIGN KEY (`userID`) REFERENCES `users` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `rel_bl_users` FOREIGN KEY (`botID`) REFERENCES `bots` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `default_responses`
--
ALTER TABLE `default_responses`
  ADD CONSTRAINT `rel_dr_bots` FOREIGN KEY (`botID`) REFERENCES `bots` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `rel_dr_users` FOREIGN KEY (`userID`) REFERENCES `users` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `learned`
--
ALTER TABLE `learned`
  ADD CONSTRAINT `rel_ln_bots` FOREIGN KEY (`botID`) REFERENCES `bots` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `rel_ln_users` FOREIGN KEY (`userID`) REFERENCES `users` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `logged_messages`
--
ALTER TABLE `logged_messages`
  ADD CONSTRAINT `rel_lm_bots` FOREIGN KEY (`botID`) REFERENCES `bots` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `rel_lm_users` FOREIGN KEY (`userID`) REFERENCES `users` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `permissions`
--
ALTER TABLE `permissions`
  ADD CONSTRAINT `rel_rp_rp2` FOREIGN KEY (`requires_permID`) REFERENCES `permissions` (`ID`);

--
-- Constraints for table `responses`
--
ALTER TABLE `responses`
  ADD CONSTRAINT `rel_bots` FOREIGN KEY (`botID`) REFERENCES `bots` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `rel_resp_users` FOREIGN KEY (`userID`) REFERENCES `users` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `role_perms`
--
ALTER TABLE `role_perms`
  ADD CONSTRAINT `rel_rp_perms` FOREIGN KEY (`permID`) REFERENCES `permissions` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `rel_rp_roles` FOREIGN KEY (`roleID`) REFERENCES `roles` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `translations`
--
ALTER TABLE `translations`
  ADD CONSTRAINT `rel_bots2` FOREIGN KEY (`botID`) REFERENCES `bots` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `rel_users` FOREIGN KEY (`userID`) REFERENCES `users` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `rel_user_roles` FOREIGN KEY (`roleID`) REFERENCES `roles` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE;

DELIMITER $$
--
-- Events
--
DROP EVENT `OptEvent`$$
CREATE DEFINER=`admin`@`localhost` EVENT `OptEvent` ON SCHEDULE EVERY 1 HOUR STARTS '2022-03-20 18:12:07' ON COMPLETION PRESERVE ENABLE DO CALL OPTLOOP()$$

DELIMITER ;
SET FOREIGN_KEY_CHECKS=1;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
