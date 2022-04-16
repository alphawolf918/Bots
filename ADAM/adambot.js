const Discord = require("discord.js");
const logger = require("winston");
const auth = require("./auth.json");
const config = require("./package.json");
const sql = require("mysql");
const uuidx = require('uuid/v4');
const botUtils = require("./bot_utils.js");
const giphy = require("giphy-api")();
const dbc = config.db;
const prefix = config.prefix;
const argCode = config.argcode;
const name = config.name;
const botName = name.toLowerCase();
const botChatName = botName + ": ";
const ownerID = config.ownerID;
const talkedRecently = new Set();
const bot = new Discord.Client();
const botID = config.id;

const status = {
    "online": "online",
    "offline": "offline",
    "idle": "idle",
    "dnd": "dnd"
};

const capitalize = (s) => {
    if (typeof s !== 'string'){
        return "";
    }
    
    return s.charAt(0).toUpperCase() + s.slice(1);
}

var pool = sql.createPool({ host : config.db.host,
                            user : config.db.username,
                            password : config.db.password,
							database : config.db.database,
							connectionLimit : 100
					      });

//Cooldown variables.
var multiplyBy = 1.0;
var waitSeconds;

//Control variable.
var canLearn = true;

var cooldown;
var token;
var activity_string;
var activity_type;
var owner;
var greeting;
var botGUID;
var botNick;
var botClientID;

var botUserObj;

var msgObj;

var heartRate = 5000;
var isAwake = true;

var db = sql.createConnection({
        host: dbc.host,
        port: dbc.port,
        user: dbc.username,
        password: dbc.password,
        database: dbc.database
});

initializePersistance(false, isAwake);

logger.remove(logger.transports.Console);
logger.add(new logger.transports.Console, {
    colorize: true
});
logger.level = "debug";

bot.on("ready",  async (evt) => {
    heartRate = 5000;
	logMsg("Connected to Discord!");
    logMsg("Logged in as: " + config.name);
    logMsg("Bot Discord Tag: " + bot.user.tag);
    logMsg("COOLDOWN TIMER: " + cooldown);
    logMsg("GUID: " + botGUID);
    logMsg("Heartbeat Rate: " + heartRate + " sec (" + (heartRate / 60) + " mins)\n");
    
    botUserObj = bot.user;
    botUserObj.setStatus(status.online);
    setBotActivity(bot, activity_string);
    owner = getUserByClientID(bot, ownerID);
    sendUserMessage(owner, owner, greeting);
    
/*     setInterval(function(){
        updatePersistance();
    }, (heartRate * 1000)); */
});

function initializePersistance(hasInitialized){
    db.connect(async(err) => {
        if (err) {
            logErr(err);
            botLogout();
            return;
        }

        if(!hasInitialized){
            logMsg("Connected to database!");
        }
    
        db.query("SELECT * FROM Bots WHERE ID = " + botID + ";", 
            async (err, result) => {
                cooldown = parseFloat(result[0].cooldown_timer);
                token = result[0].token;
                greeting = result[0].greeting;
                waitSeconds = ((cooldown * multiplyBy) * 1000);
                activity_string = result[0].activity_string;
                botNick = result[0].nickname;
                botClientID = result[0].clientID;
                canLearn = result[0].enable_learning;
                heartRate = result[0].heartrate_sec;
                db.query("SELECT ActivityType FROM VIEW_GetActivity WHERE BotID = " + botID + ";", function(err, res){
                    activity_type = res[0].ActivityType;
                });
                db.query("SELECT GUID FROM BotGUID WHERE BotID = " + botID + ";", function(err, res){
                    if(res.length > 0){
                        botGUID = res[0].GUID;
                    }
                });
        });
    });
}

function updatePersistance(){
    logMsg("Heartbeat detected.");
    //initializePersistance(true);
}

botLogin();

bot.on("message", async (message) => {
    var msg = message.content;
    var channel = message.channel;
    var user = message.author;
    var userID = user.id;
    var username = user.username;

    if (talkedRecently.has(userID)) {
        return;
    }

    talkedRecently.add(userID);
    setTimeout(async () => {
        talkedRecently.delete(userID);
    }, waitSeconds);

    if(!(msg.substring(0, 1) === prefix) && !(msg.substring(0, 1) === "`")){
        msg = await userTranslate(channel, user, msg);
        var m = msg.replace("'", "");
        m = m.replace(botChatName, "");
        m = m.replace("<@!" + botClientID + "> ", "");
        m = m.replace(/<@!(.*?)>(\s)?/, "");
        if(user != botUserObj){
            logMsg("RECEIVED: \"" + msg  + "\" FROM: " + username);
        
            if(Rand(1000) <= 250){
                db.connect((err) => {
                    db.query("CALL LearnSaying(" + botID + ", '" + userID + "', '" + m + "');", async (err, result) => {
                        if(err){
                            logErr(err);
                        }
                    
                        if(result.rowsAffected > 0 || result.length > 0){
                            logMsg("I have learned a new saying: " + m);
                        }
                    });
                });
            }
        }
        
        //Log messages sent and received
        db.connect(async (err) => {
            db.query("CALL LogMessage(" + botID + ", '" + userID + "', '" + m + "');");
        });
    }
    
    getUserInfo(user);

    if (msg.substring(0, 1) === prefix) {
        var args = msg.substring(1).split(argCode);
        var cmd = args[0];

        args = args.splice(1);
        console.log("args: [" + args + "]");

        //Ignore messages from other bots.
        if (user.bot) {
            return;
        }

        cmd = cmd.toLowerCase();

        switch (cmd) {
            default:
                sendChannelMessage(channel, user, "Invalid command.");
            break;
            case "ping":
                sendChannelMessage(channel, user, "Ping received by " + username + ".");
                sendUserMessage(user, user, "You pinged me.<nr>It hurted.");
            break;
            case "sendim":
                if (args[0] != null) {
                    var toUserID = args[0];
                    if (args[1] != null) {
                        var msg2 = args[1];
                        var toUser = getUserByClientID(bot, toUserID);
                        sendUserMessage(toUser, toUser,  msg2);
                    } else {
                        sendChannelMessage(channel, toUser, "Message was left blank.");
                    }
                } else {
                    sendChannelMessage(channel, user, "User was left blank.");
                }
            break;
            case "logout":
            case "logoff":
                if (userID == ownerID) {
                    sendChannelMessage(channel, user, "Logging off. Goodbye!"); //Seems to break Promise rejection...
                    botLogout();
                } else {
                    sendChannelMessage(channel, user, "You are not my Master.<nr>I do not obey you.");
                }
            break;
            case "restart":
            case "reboot":
                if (userID == ownerID) {
                    sendChannelMessage(channel, user, "Beginning reboot...");
                    botLogout();
                    //sleep(2000);
                    botLogin();
                    sendChannelMessage(channel, user, "Reboot complete. Hello!");
                }
            break;
            case "updact":
                if (userID == ownerID) {
                    if (args[0] != null) {
                        db.connect(function (err) {
                            db.query("UPDATE Bots SET activity_string = '" + args[0] + "' WHERE ID = " + botID + ";", function (err, result) {
                                console.log("Records affected: " + result.affectedRows);
                            });
                        });
                        setBotActivity(bot, args[0]);
                        sendChannelMessage(channel, user, "Activity updated.");
                    }
                }
            break;
            case "about":
                sendChannelMessage(channel, user, config.description);
            break;
            case "obey":
                if (userID != ownerID) {
                    sendChannelMessage(channel, user, "No.");
                } else {
                    sendChannelMessage(channel, user, "Yes, Master.");
                }
            break;
            case "cooldown":
                sendChannelMessage(channel, user, "Cooldown timer is at " + cooldown + " seconds.");
            break;
            case "setcooldown":
                if(!checkIfOwner(userID)){
                    return;
                }
            
                if(args[0] != null){
                    var cd = args[0];
                    db.connect((err) => {
                        db.query("UPDATE Bots SET cooldown_timer = " + cd + " WHERE ID = " + botID + ";", (err, result) => {
                            logMsg("Records affected: " + result.affectedRows);
                            cooldown = cd;
                            sendChannelMessage(channel, user, "Cooldown timer updated to " + cooldown + " seconds.");
                        });
                    });
                } else {
                    sendChannelMessage(channel, user, "Psst.<nr>You forgot the cooldown number.");
                }
            break;
            case "say":
                if(!checkIfOwner){
                    return;
                }
            
                if(args[0] != null){
                    var msg5 = capitalize(args[0]);
                    sendChannelMessage(channel, user, msg5);
                } else {
                    sendChannelMessage(channel, user, "Aren't you forgetting something?");
                }
            break;
            case "friendme":
                db.connect((err) => {
                    db.query("CALL AddFriend(" + botID + ", '" + userID + "');", (err, result) => {
                        var rowsAffected = result.rowsAffected;
                        if(rowsAffected > 0){
                            logMsg("Rows affected: " + result.rowsAffected);
                            sendChannelMessage(channel, user, "I have added " + username + " as a friend.");
                        } else {
                            sendChannelMessage(channel, user, "Hmm.<nr>Seems like we're already friends, <name>.");
                        }
                    });
                });
            break;
            case "guid":
                if(!checkIfOwner(userID)){
                    return;
                }
                
                var typ = "get";
                if(typ != null){
                    typ = args[0];
                }
                
                switch(typ){
                    case "get":
                        sendChannelMessage(channel, user, "My current GUID is: " + getGUID());
                    break;
                    case "update":
                        updateGUID();
                        sendChannelMessage(channel, user, "New GUID generated.");
                    break;
                    case "gen":
                    case "generate":
                        sendChannelMessage(channel, user, "GUID: " + generateGUID());
                    break;
                }
            break;
            case "find":
                if(args[0] != null){
                    var findWho = args[0];
                    db.connect((err) => {
                        db.query("SELECT clientID FROM Users WHERE LOWER(friendly_name) LIKE '%" + findWho.toLowerCase() + "%';", (err, result) => {
                            if(result.length > 0){
                                var foundUser = "<@!" + result[0].clientID + ">";
                                sendChannelMessage(channel, user, capitalize(findWho) + " is " + foundUser + ".");
                            } else {
                                sendChannelMessage(channel, user, "Sorry, I have no matching records for " + capitalize(findWho) + ".");
                            }
                        });
                    });
                } else {
                    sendChannelMessage(channel, user, "Who am I supposed to find, exactly?");
                }
            break;
            case "whois":
                if(args[0] != null){
                    var whoIs = args[0];
                    whoIs = whoIs.replace("!", "");
                    whoIs = whoIs.replace(/<@(.*?)>/, "$1");
                    console.log(whoIs);
                    db.connect((err) => {
                        db.query("SELECT friendly_name FROM Users WHERE clientID LIKE '%" + whoIs + "%';", (err, result) => {
                            if(result == undefined){
                                return;
                            }
                            
                            if(result.length > 0){
                                if(result[0].friendly_name != null){
                                    var foundName = capitalize(result[0].friendly_name);
                                    sendChannelMessage(channel, user, "<@!" + whoIs + "> is " + capitalize(foundName) + ".");
                                }
                            }
                        });
                    });
                }
            break;
            case "gif":
            case "giphy":
                if(args[0] != null){
                    var searchFor = args[0];
                    giphy.search({
                        q: args[0],
                        rating: "r",
                        fmt: "json"
                    }).then(function(res){
                        var gifData = res.data;
                        var gifURL = gifData[0].bitly_gif_url;
                        gifURL = gifData[Rand(gifData.length)].bitly_gif_url;
                        sendChannelMessage(channel, user, gifURL);
                    });
                } else {
                    sendChannelMessage(channel, user, "No GIF criteria specified.");
                }
            break;
            case "var":
            case "variable":
                if(!checkIfOwner(userID)){
                    sendChannelMessage(channel, user, "Sorry, only my Master can manage my variables due to the security risks involved.");
                    return;
                }
                
                if(args[0] != null){
                    var subCmd = args[0];
                    switch(subCmd){
                        default:
                            sendChannelMessage(channel, user, "Invalid secondary command.");
                        break;
                        case "get":
                            if(args[1] != null){
                                var v = args[1];
                                if(v.charAt(0) != "$"){
                                    sendChannelMessage(channel, user, "Variable names must start with a dollar sign (**$**).");    
                                    return;
                                }
                                
								var strSQL = "SELECT Func_GetVar(" + botID + ", '" + v + "') AS Var;";
                                var rows = await getResult(strSQL);
                                if(rows.length > 0){
                                    var val = rows[0].Var;
                                    if(val != null){
                                        sendChannelMessage(channel, user, "**" + v + "** = " + val);
                                    } else {
                                        sendChannelMessage(channel, user, "Variable **" + v + "** was null.");
                                    }
                                }
                            } else {
								sendChannelMessage(channel, user, "Variable name was left blank.");
							}
                        break;
                        case "set":
                            if(args[1] != null){
                                var v = args[1];
                                v = v.replace(/^(\d+)?/, "");
                                if(v.charAt(0) != "$"){
                                    sendChannelMessage(channel, user, "Variable names must start with a dollar sign (**$**).");    
                                    return;
                                }
                                
                                if(args[2] != null){
                                    var val = args[2];
                                    val = val.replace("'", "\'");
                                    var strSQL = "CALL SetVar(" + botID + ", '" + userID + "', '" + v + "', '" + val + "');";
                                    var rows = await getResult(strSQL);
                                    console.log(rows[0]);
                                    if(rows.length > 0){
                                        sendChannelMessage(channel, user, "Variable **" + v + "** was set to **" + val + "**.");
                                    }
                                } else {
                                    sendChannelMessage(channel, user, "Variable value cannot be empty.");
                                }
                            } else {
                                sendChannelMessage(channel, user, "Variable name was left blank.");
                            }
                        break;
                    }
                } else {
                    sendChannelMessage(channel, user, "Secondary command not specified.");
                }
            break;
            }
    } else if (msg.toLowerCase().startsWith(botChatName) || channel.type == "dm" || msg.includes("<@!" + bot.user.id + ">")) {
        var msg3 = await userTranslate(channel, user, msg.toLowerCase());
        var inputMsg = msg3.replace(botChatName, "");
        inputMsg = inputMsg.replace("<@!" + bot.user.id + ">", "");
        logMsg("INPUT: \"" + inputMsg + "\" FROM: " + username + "\n");
        
        var patt;
        var input;
        var output;
        
        if((botUserObj == user) || (user.tag == undefined)){
            return;
        }
        
        if(input == "" || input == " "){
            sendChannelMessage(channel, userObj, "Yes?|Uh... what?");
        }
        
        var hasMatch = false;
        
        var strSQL = "SELECT input, output FROM Responses WHERE botID = " + botID + ";";
        var rows = await getResult(strSQL);
        var res;
        
        for(var i = 0; i < rows.length; i++){
            res = rows[i];
            input = res.input;
            patt = new RegExp(input, "i");
            if(patt.test(msg3)){
                output = capitalize(res.output);
                output = checkPunctuation(output);
                hasMatch = true;
                sendChannelMessage(channel, user, output);
                return;
            }
        }
        
        if(!hasMatch){
            randomResponse(channel, user, msg3);
        }
    }
});

bot.on("disconnect", () => {
    bot.user.setStatus(status.offline);
    logMsg(name + " has disconnected.");
    Promise.resolve();
    pool.end();
    db.end();
    isAwake = false;
});

bot.on("error", () => {
    logErr(name + " has experienced a malfunction.");
    botLogout();
});

bot.on("voiceStateUpdate", async (before, after) => {
    //TODO
});

function sendChannelMessage(channel, userObj, message) {
    parseSendMessage(channel, userObj, message);
    logMsg("SENT: \"" + message + "\" to CHANNEL: " + channel + "\n");
}

function sendUserMessage(user, userObj, message) {
    parseSendMessage(user, userObj, message);
    logMsg("SENT: \"" + message + "\" to USER: " + user + "\n");
    getUserInfo(user);
}

function randomResponse(obj, userObj, strMsg){
    var msg = "I do not have any input for that.";
    if(Rand(100) <= 50){
        db.connect((err) => {
            db.query("SELECT learned_txt FROM Learned WHERE botID = " + botID + " AND is_active = 1 ORDER BY RAND();", (err, result) => {
                if(result.length > 0){
                    sendChannelMessage(obj, userObj, capitalize(result[0].learned_txt));
                } else {
                    sendChannelMessage(obj, userObj, capitalize(msg));
                }
            });
        });
    } else {
        msg = (Rand(100) <= 50) ? botUtils.buildSentence() : (Rand(15) >= 5) ? botUtils.AI_Sentence() : botUtils.NLP();
        msg = msg.replace("'", "\'");
        sendChannelMessage(obj, userObj, msg);
    }
}

async function parseSendMessage(obj, userObj, strMsg){
    var containsCode = false;
    
    if(strMsg.includes("<nr>")){
        containsCode = true;
        var msg = strMsg.split("<nr>");
        msg.forEach(async (s) => {
            setTimeout(async () => {
                var parse = async () => {
                    var str = await parseMsg(obj, userObj, s);
                    parseSendMessage(obj, userObj, str);
                };
                parse();
            }, waitSeconds);
        });
    }
    
    var msg = await parseMsg(obj, userObj, strMsg);
    msg = await parseMsg(obj, userObj, msg);
    
    if(!containsCode){
        sendMsg(obj, userObj, msg);
    }
}

async function parseMsg(obj, userObj, strMsg, hasParsed){
    var msg = await translate(obj, userObj, strMsg);
    var parsedYet = (hasParsed == null)? false : true;
    
    var userClientID = userObj.id;
    
    if(strMsg.includes("|")){
        var arr = strMsg.split("|");
        var randMsg = arr[Rand(arr.length)];
        if(randMsg != null){
            msg = await parseMsg(obj, userObj, randMsg);
        }
    }
    
    if(msg.includes("<name>")){
        var strSQL = "SELECT friendly_name, discord_name FROM Users WHERE clientID = '" + userClientID + "';";
        var rows = await getResult(strSQL);
        if(rows.length > 0){
            msg = msg.replace(new RegExp(/<name>/, "gi"), Nz(rows[0].friendly_name, rows[0].discord_name));
            msg = await parseMsg(obj, userObj, msg);
        }
        
        Promise.resolve();
    }
    
    if(msg.includes("<last>")){
        var strSQL = "SELECT * FROM VIEW_UserMessages WHERE UserClientID = '" + userClientID + "' AND botID = " + botID + " ORDER BY MessageID DESC LIMIT 1";
        var rows = await getResult(strSQL);
        if(rows.length > 0){
            msg = msg.replace(new RegExp(/<last>/, "gi"), rows[0].Message);
            msg = await parseMsg(obj, userObj, msg);
        }
        
        Promise.resolve();
    }
    
    var patt = /(.+?)?<var:\$(.+?)>(.+?)?/gi;
    var regx = new RegExp(patt, "i");
    
    if(regx.test(msg)){
        var r = msg.replace(patt, "$2");
        r = r.replace("'", "\'");
        logMsg("Variable located: " + r);
        var strSQL = "SELECT Func_GetVar(1, '$" + r + "') AS Var;";
        var rows = await getResult(strSQL);
        if(rows.length > 0){
            var val = rows[0].Var;
            msg = await parseMsg(obj, userObj, msg.replace(regx, val));
            
        }
        
        Promise.resolve();
    }
    
    return msg;
}

async function parseVariable(obj, userObj, strMsg, strVar){
    var msg = strMsg;
    
    
    
    return msg;
}

async function sendMsg(obj, userObj, strMsg){
    var msg = strMsg;
    if(obj != undefined && userObj != undefined){
        msg = await translate(obj, userObj, msg);
        msg = await parseMsg(obj, userObj, msg);
        obj.send(msg);
        Promise.resolve();
    } else {
        logMsg("Objects were invalid or not defined.");
    }
}

function Nz(expr, exprIfNull){
    return ((expr == null) ? exprIfNull : expr);
}

function getGUID(){
    var guid = botGUID;
    db.connect(async (err) => {
        db.query("SELECT GUID FROM BotGUID WHERE botID = " + botID + ";",  (err, result) => {
            guid = result[0].GUID;
        });
    });
    return guid;
}

function generateGUID(){
    var guid = "{" + uuidx().toUpperCase() + "}";
    return guid;
}

function updateGUID(){
    var guid = generateGUID();
    db.connect(function(err){
        db.query("UPDATE BotGUID SET GUID = '" + guid + "' WHERE BotID = " + botID + ";", function(err, result){
            botGUID = guid;
            if(result.length > 0){
                logMsg("GUID updated. " + result[0].rowsAffected + " rows affected.");
                logMsg("New GUID: " + guid);
            }
        });
    });
}

function checkIfOwner(userID){
    return (userID == ownerID);
}

function checkPunctuation(strMsg){
    if(strMsg == null){
        return;
    }
    
    var msg = strMsg;
    
    var punc = new Array(".", "!", "?");
    var hasPunc = false;
    punc.forEach(function(p){
        if(msg.endsWith(p)){
            hasPunc = true;
            return;
        }
    });
    
    if(!hasPunc){
        msg += punc[Rand(punc.length)];
    }
    
    return msg;
}

async function translate(obj, userObj, strMsg){
    var msg = strMsg;
    
    try {
        var strSQL = "SELECT original, replacement FROM Translations WHERE user_or_bot = 'BOT' AND is_active = 1 AND botID = " + botID + ";";
        var rows = await getResult(strSQL);
        
        for(const i in rows){
            var res = rows[i];
            var regx = new RegExp(res.original, "i");
            
            if(regx.test(msg)){
                msg = msg.replace(regx, res.replacement);
            }
        }
        
        Promise.resolve();
    
        if(msg == "" || msg == null || msg == " "){
            msg = strMsg;
            logErr("TRANSLATION FAILED.");
        }
        
        return msg;
        
    } catch(err){
        logErr(err);
    }
}

async function userTranslate(obj, userObj, strMsg){
  var msg = strMsg;
    
    try {
        var strSQL = "SELECT original, replacement FROM Translations WHERE user_or_bot = 'USER' AND is_active = 1 AND botID = " + botID + ";";
        var rows = await getResult(strSQL);
        
        for(const i in rows){
            var res = rows[i];
            var regx = new RegExp(res.original, "i");
            if(regx.test(msg)){
                msg = msg.replace(regx, res.replacement);
            }
        }
        
        Promise.resolve();
    
        if(msg == "" || msg == null || msg == " "){
            msg = strMsg;
            logErr("TRANSLATION FAILED.");
        }
        
        return msg;
        
    } catch(err){
        logErr(err);
    }
}

function getResult(strSQL){
    return new Promise(async (resolve, reject) => {
        pool.query(strSQL, (err, result) => {
            if(err){
                reject(err);
            } else {
                resolve(result);
            }
        });
    });
}

function Rand(num){
    return botUtils.Rand(num);
}

function getUserInfo(user) {
    if((user == botUserObj) || (user == undefined)){
        return;
    }
    
    logMsg("USER ID: " + user.id);
	logMsg("USERNAME: " + user.tag + "\n");
	db.connect(function(err){
		db.query("CALL CheckNewUserByID('" + user.id + "', '" + user.tag + "')", function(err, result){
			if(result == null){
				return;
			}
			var rowsAffected = result.rowsAffected;
			if(rowsAffected > 0){
				logMsg("Rows affected: " + result.rowsAffected);
			}
		});
	});
}

function getUserByClientID(bot, clientID){
    return bot.users.get(clientID);
}

function botLogin() {
    bot.login(auth.token)
		.then(logMsg("Logged In\n"))
			.catch(console.error);
    isAwake = true;
}

function botLogout(){
    bot.destroy();
    isAwake = false;
    heartRate = 0;
}

function setBotActivity(bot, strActivity) {
    bot.user.setActivity(strActivity, {
        type: activity_type
    })
		.then(presence => logMsg("Activity updated to: " + strActivity + "\n"))
			.catch(logErr);
}

function logMsg(strMsg) {
    console.log("[LOGGER] " + strMsg);
}

function logErr(errMsg){
    console.error("[ERROR] " + errMsg);
}