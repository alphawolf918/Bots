CREATE OR REPLACE VIEW VIEW_BotInfo AS
SELECT T.*
FROM (WITH CTE_Bots AS
		(SELECT bots.ID       		 AS BotID
			   ,bots.ownerID  		 AS OwnerID
			   ,bots.clientID        AS BotClientID
			   ,A.activityName		 AS BotActivity
			   ,A.ID                 AS BotActivityType
			   ,bots.discord_name    AS BotDiscordName
			   ,bots.friendly_name   AS BotFriendlyName
			   ,bots.about           AS BotAbout
			   ,bots.token           AS BotToken
			   ,bots.cooldown_timer  AS BotCoolDown
			   ,bots.greeting        AS BotGreeting
			   ,bots.farewell        AS BotFarewell
			   ,bots.last_message    AS LastMessage
			   ,(CASE
					WHEN (bots.enable_learning = 1) THEN 'Yes'
                    ELSE 'No'
                 END)				 AS EnableLearning
			   ,(CASE
					WHEN (bots.silent_mode = 1) THEN 'Yes'
					ELSE 'No'
				 END)				 AS EnableSilentMode
			   ,botguid.GUID         AS BotGUID
		 FROM Bots
		 JOIN BotGUID
			ON BotGUID.botID = bots.ID
		 LEFT JOIN Activities A
			ON A.botID = bots.ID),
		 CTE_Users AS
		 (SELECT users.id            AS UserID
		        ,users.discord_name  AS OwnerDiscordName
				,users.friendly_name AS OwnerFriendlyName
				,users.roleID        AS OwnerRoleID
				,users.clientID      AS UserClientID
				,users.topic         AS UserTopic
				,roles.RoleName      AS RoleName
		  FROM Users
		  JOIN Roles
			ON Roles.ID = Users.roleID)
	  SELECT *
	  FROM CTE_Bots  B
	  JOIN CTE_Users U
		ON U.UserID = B.OwnerID) T;