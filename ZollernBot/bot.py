# bot.py
import os
import discord
import datetime as DtTm
import json
import mysql.connector as SqlDB
import uuid
import pyttsx3 as pySpeak
import random
from discord.ext import tasks, commands
from discord.ext.commands import Bot
from discord.voice_client import VoiceClient
from dotenv import load_dotenv
from mysql.connector import Error
from regex import *

load_dotenv()
TOKEN = os.getenv('DISCORD_TOKEN')
MAIN_GUILD = os.getenv('MAIN_GUILD')
ALT_GUILD = os.getenv('ALT_GUILD')
ADMIN_ID = int(os.getenv('ADMIN_ID'))
ADMIN = os.getenv('ADMIN')
SYS_CHANNEL = os.getenv('SYSTEM_CHANNEL')
DB_HOST = os.getenv('DB_HOST')
DB_USER = os.getenv('DB_USER')
DB_PASS = os.getenv('DB_PASS')
DB_DATABASE = os.getenv('DB_DATABASE')
GUID = os.getenv('GUID')

client = discord.Client()
bot = commands.Bot(command_prefix='!')
engine = pySpeak.init()

async def DbConnect():
    sqlCon = SqlDB.connect(host=DB_HOST,
                           database=DB_DATABASE,
                           user=DB_USER,
                           password=DB_PASS)
    return sqlCon

async def getBotField(strField):
    sqlCon = await DbConnect()
    sqlCurs = sqlCon.cursor(prepared=True)
    q = "SELECT `" + strField + "` FROM VIEW_BotInfo WHERE `BotToken` = %s"
    params = (TOKEN,)
    sqlCurs.execute(q, params)
    result = sqlCurs.fetchone()
    sqlCurs.close()
    if sqlCon.is_connected():
        sqlCon.close()
    return result[0]


async def getUserField(strField, authorID, strAnd="1"):
    sqlCon = await DbConnect()
    sqlCurs = sqlCon.cursor(prepared=True)
    sqlCurs.execute("SELECT `" + strField + "` FROM VIEW_BotInfo WHERE `BotToken` = %s AND `UserClientID` = %s AND " + strAnd + ";", (TOKEN, authorID))
    result = sqlCurs.fetchone()
    sqlCurs.close()
    if sqlCon.is_connected():
        sqlCon.close()
    return result[0]

async def setUserField(authorID, strField, value, strAnd="1=1"):
    sqlCon = await DbConnect()
    v = value.replace("'", "''")
    sqlCurs = sqlCon.cursor(prepared=True)
    sqlCurs.execute("UPDATE `Users` SET `" + strField + "` = %s WHERE `clientID` = %s AND " + strAnd + ";", (v, authorid))
    sqlCurs.close()
    if sqlCon.is_connected():
        sqlCon.commit()
        sqlCon.close()

async def setBotField(strField, value, strAnd="1=1"):
    sqlCon = await DbConnect()
    v = value.replace("'", "''")
    sqlCurs = sqlCon.cursor()
    sqlCurs.execute("UPDATE `bots` SET `" + strField + "` = %s WHERE `token` = %s AND " + strAnd + ";", (v, TOKEN))
    sqlCurs.close()
    if sqlCon.is_connected():
        sqlCon.commit()
        sqlCon.close()

async def getField(strTable, strField, strWhere="1=1"):
    sqlCon = await DbConnect()
    sqlCurs = sqlCon.cursor(dictionary=True)
    sqlCurs.execute("SELECT `" + strField + "` FROM `" + strTable + "` WHERE " + strWhere + ";")
    result = sqlCurs.fetchone()
    sqlCurs.close()
    if sqlCon.is_connected():
        sqlCon.close()
    return result[strField]

async def setField(strTable, strField, strValue, strWhere="1=1"):
    sqlCon = await DbConnect()
    sqlCurs = sqlCon.cursor(prepared=True)
    sqlCurs.execute("UPDATE `" + strTable + "` SET `" + strField + "` = %s WHERE " + strWhere + ";", (strValue,))
    sqlCurs.close()
    if sqlCon.is_connected():
        sqlCon.commit()
        sqlCon.close()

async def senddm(USER_ID, msg):
    user = await bot.fetch_user(USER_ID)
    m = await botTranslate(msg, USER_ID)
    await user.send(m)
    ct = DtTm.datetime.now()
    print(f'[{bot.user} @ {ct}]: {m}')

async def getVar(botID, msg, authorID):
    sqlCon = await DbConnect()
    sqlCurs = sqlCon.cursor(prepared=True)
    pattern = "<var get=\$(.+?)>"
    varName = await RegExp_Set(msg, pattern, 1)
    userID = str(authorID)
    sqlCurs.execute("SELECT Func_GetVar(" + str(botID) + ", %s, %s) AS Var FROM DUAL;", (userID, varName))
    result = sqlCurs.fetchone()
    msg = await RegExp_Replace(msg, pattern, result[0])
    sqlCurs.close()
    if sqlCon.is_connected():
        sqlCon.commit()
        sqlCon.close()
    return msg

async def setVar(botID, msg, authorID, outFinal, input, n):
    sqlCon = await DbConnect()
    sqlCurs = sqlCon.cursor()
    varValue = await RegExp_Set(msg, input, n)
    pattern = "<var set\[(.+?)=\$(.+?)\]>"
    varName = await RegExp_Set(outFinal, pattern, 1)
    outFinal = await RegExp_Replace(outFinal, pattern, varValue)
    try:
        params = (str(botID), str(authorID), varName, varValue)
        args = sqlCurs.callproc("SetVar", params)
        for results in sqlCurs.stored_results():
            print(results.fetchall())
    except SqlDB.Error as E:
        print("Failed to execute stored procedure: SetVar {}".format(E))
    print(f'Set {varName} to {varValue}')
    sqlCurs.close()
    if sqlCon.is_connected():
        sqlCon.commit()
        sqlCon.close()
    return outFinal

async def getTopic(botID, authorID):
    sqlCon = await DbConnect()
    sqlCurs = sqlCon.cursor(prepared=True)
    userID = str(authorID)
    sqlCurs.execute("SELECT Func_GetVar(" + str(botID) + ", %s, 'topic') AS Topic FROM DUAL;",(userID,))
    result = sqlCurs.fetchone()
    currentTopic = result[0]
    sqlCurs.close()
    if sqlCon.is_connected():
        sqlCon.close()
    return currentTopic

async def getRandLearned(botID, authorID):
    sqlCon = await DbConnect()
    sqlCurs = sqlCon.cursor(dictionary=True)
    sqlCurs.execute("SELECT Func_GetRandLearned(" + str(botID) + ") AS Learned FROM DUAL;")
    result = sqlCurs.fetchone()
    randLearned = await capFirst(result["Learned"])
    randLearned = await botTranslate(randLearned, authorID)
    sqlCurs.close()
    if sqlCon.is_connected:
        sqlCon.close()
    return randLearned

async def getRandResponse(botID, authorID):
    sqlCon = await DbConnect()
    sqlCurs = sqlCon.cursor(dictionary=True)
    sqlCurs.execute("SELECT Func_GetDefaultResponse(" + str(botID) + ") AS Response FROM DUAL;")
    result = sqlCurs.fetchone()
    randResponse = await capFirst(result["Response"])
    r = await botTranslate(randResponse, authorID)
    sqlCurs.close()
    if sqlCon.is_connected():
        sqlCon.close()
    return r

async def capFirst(msg):
    str = "%s%s" % (msg[0].upper(), msg[1:])
    return str

@tasks.loop(minutes=15)
async def updateActivityRandomly():
    await bot.wait_until_ready()
    sqlCon = await DbConnect()
    botID = await getBotField("BotID")
    try:
        sqlCurs = sqlCon.cursor()
        params = (str(botID),)
        args = sqlCurs.callproc("UpdateActivity", params)
        for results in sqlCurs.stored_results():
            print(results.fetchall())
        sqlCurs.close()
        await readyActivity(botID)
    except SqlDB.Error as E:
        print("Failed to execute stored procedure: UpdateActivity {}".format(E))
    if sqlCon.is_connected():
        sqlCon.commit()
        sqlCon.close()

async def LogMessage(authorID, msg):
    sqlCon = await DbConnect()
    botID = await getBotField("BotID")
    try:
        sqlCurs = sqlCon.cursor()
        params = (botID, str(authorID), msg)
        args = sqlCurs.callproc("LogMessage", params)
        for results in sqlCurs.stored_results():
            print(results.fetchall())
        sqlCurs.close()
    except SqlDB.Error as E:
        print("Failed to execute stored procedure: LogMessage {}".format(E))
    if sqlCon.is_connected():
        sqlCon.commit()
        sqlCon.close()

async def LearnSaying(authorID, msg):
    sqlCon = await DbConnect()
    botID = await getBotField("BotID")
    botClientID = await getBotField("BotClientID")
    canLearn = await getBotField("EnableLearning")
    if authorID == botClientID or canLearn.lower() == "no":
        if sqlCon.is_connected():
            sqlCon.close()
        return
    try:
        sqlCurs = sqlCon.cursor()
        params = (str(botID), str(authorID), msg)
        args = sqlCurs.callproc("LearnSaying", params)
        for results in sqlCurs.stored_results():
            print(results.fetchall())
        sqlCurs.close()
        print("I have learned a new saying:\n\t" + msg)
    except SqlDB.Error as E:
        print("Failed to execute stored procedure: LearnSaying {}".format(E))
    if sqlCon.is_connected():
        sqlCon.commit()
        sqlCon.close()

async def CheckNewUserByID(author, authorID):
    sqlCon = await DbConnect()
    try:
        sqlCurs = sqlCon.cursor()
        params = (str(authorID), author)
        args = sqlCurs.callproc("CheckNewUserByID", params)
        for result in sqlCurs.stored_results():
            print(result.fetchall())
        sqlCurs.close()
    except SqlDB.Error as E:
        print("Failed to execute stored procedure: CheckNewUserByID {}".format(E))
    if sqlCon.is_connected():
        sqlCon.commit()
        sqlCon.close()

async def CheckResponses(authorID, message):
    if message.author == bot.user or message.author.bot:
        return
    sqlCon = await DbConnect()
    msg = message.content
    msg = await userTranslate(msg, authorID)
    if msg != "" and msg != " " and msg != None:
        botID = await getBotField("BotID")
        hasMatch = False
        sqlCurs = sqlCon.cursor(dictionary=True)
        sqlCurs.execute("SELECT `input`, `output`, `cond`, `friendship_modifier` FROM `responses` WHERE `botID` = " + str(botID) + " ORDER BY `ID` ASC, `priority` DESC;")
        results = sqlCurs.fetchall()
        for row in results:
            input = row["input"]
            output = row["output"]
            cond = row["cond"].lower()
            friendMod = row["friendship_modifier"]
            if await RegExp_Like(msg, input):
                hasMatch = True
                out = output
                choices = out.split("|")
                secureRandom = random.SystemRandom()
                out = secureRandom.choice(choices)
                outFinal = await botTranslate(out, authorID)
                if cond != "[none]":
                    rx = "\[var:(?P<variable>[A-z0-9_-]{1,25})\]"
                    tp = "\[topic:(?P<topic>[A-z0-9_-]{1,25})\]"
                    uid = "\[userid:(?P<user>[0-9]{1,25})\]"
                    fl = "\[friendship:(?P<friendship>[-255-9]{1,4})\]"
                    if await RegExp_Like(cond, rx):
                        n = await RegExp_Set(cond, rx, 'variable')
                        outFinal = await setVar(botID, msg, authorID, outFinal, input, n)
                    elif await RegExp_Like(cond, tp):
                        requiredTopic = await RegExp_Set(cond, tp, 'topic')
                        currentTopic = await getTopic(botID, authorID)
                        if currentTopic.lower() != requiredTopic.lower():
                            outFinal = ""
                            hasMatch = False
                    elif await RegExp_Like(cond, uid):
                        userID = await RegExp_Set(cond, uid, 'user')
                        currentUserID = await getBotField("UserID")
                        if int(currentUserID) != int(userID):
                            outFinal = ""
                            hasMatch = False
                if not outFinal == "":
                    if "<nr>" not in outFinal:
                        await message.channel.send(outFinal)
                        await setBotField("last_message", outFinal)
                    else:
                        outN = outFinal.split("<nr>")
                        for n in outN:
                            await message.channel.send(n)
                            await setBotField("last_message", n)
                    if not friendMod == 0 and await checkIfFriends(authorID):
                       try:
                           sqlCurs2 = sqlCon.cursor()
                           userID = await getField("Users", "ID", "clientID = '" + str(authorID) + "'")
                           sBotID = str(botID)
                           sUserID = str(userID)
                           sFM = str(friendMod)
                           q = "UPDATE `BuddyList` SET `friendship_level` = (`friendship_level` + " + sFM + ") WHERE `botID` = " + sBotID + " AND `userID` = " + sUserID + ";"
                           sqlCurs2.execute(q)
                           sqlCurs2.close()
                       except SqlDB.Error as E:
                           print("Unable to run UPDATE query: {}".format(E))
        if(not(hasMatch)):
            if random.randint(0, 100) < 50:
                randLearned = await getRandLearned(botID, authorID)
                await message.channel.send(randLearned)
                await setBotField("last_message", randLearned)
            else:
                randResponse = await getRandResponse(botID, authorID)
                if "<nr>" not in randResponse:
                    await message.channel.send(randResponse)
                    await setBotField("last_message", randResponse)
                else:
                    outFinal = randResponse.split("<nr>")
                    for n in outFinal:
                        await message.channel.send(n)
                        await setBotField("last_message", n)
        sqlCurs.close()
    if sqlCon.is_connected():
        sqlCon.commit()
        sqlCon.close()

async def botTranslate(msg, authorID):
    sqlCon = await DbConnect()
    botID = await getBotField("BotID")
    out = msg
    sqlCurs = sqlCon.cursor(dictionary=True)
    sqlCurs.execute("SELECT original, replacement, cond FROM translations WHERE user_or_bot = 'BOT' AND is_active = 1 AND botID = " + str(botID) + " ORDER BY ID ASC, priority DESC;")
    results = sqlCurs.fetchall()
    for row in results:
        original = row["original"]
        replacement = row["replacement"]
        if await RegExp_Like(out, original):
            out = await RegExp_Replace(out, original, replacement)
    outFinal = out
    sqlCurs.close()
    if "<name>" in outFinal:
        sqlCurs = sqlCon.cursor(dictionary=True)
        sqlCurs.execute("SELECT IFNULL(Users.friendly_name, Users.discord_name) AS Name FROM Users WHERE clientID = '" + str(authorID) + "';")
        result = sqlCurs.fetchone()
        outFinal = outFinal.replace("<name>", result["Name"])
        sqlCurs.close()
    if "<last>" in outFinal:
        lastMessage = await getBotField("LastMessage")
        outFinal = outFinal.replace("<last>", lastMessage)
    if "<activity>" in outFinal:
        activity = await getBotField("BotActivity")
        outFinal = outFinal.replace("<activity>", activity)
    if "<act_type>" in outFinal:
        sqlCurs = sqlCon.cursor(dictionary=True)
        sqlCurs.execute("SELECT Func_GetActivityType(" + str(botID) + ") AS ActType FROM DUAL;")
        result = sqlCurs.fetchone()
        actType = result["ActType"].lower() + 'ing'
        if actType == "listening":
            actType += " to"
        outFinal = outFinal.replace("<act_type>", actType)
        sqlCurs.close()
    if "<topic>" in outFinal:
        topic = await getTopic(botID, authorID)
        outFinal = outFinal.replace("<topic>", topic)
    if "<learned>" in outFinal:
        randLearned = await getRandLearned(botID, authorID)
        outFinal = outFinal.replace("<learned>", randLearned)
    if "<botname>" in outFinal:
        botName = await getBotField("BotFriendlyName")
        outFinal = outFinal.replace("<botname>", await capFirst(botName))
    if await RegExp_Like(outFinal, "<var get=\$(.+?)>"):
        outFinal = await getVar(botID, outFinal, authorID)
    if await RegExp_Like(outFinal, "<silent=(?P<sil>1|0)>"):
        enableSilence = await RegExp_Set(outFinal, "<silent=(?P<sil>1|0)>", 'sil')
        await setField("bots", "silent_mode", str(enableSilence), "ID = " + str(botID))
        outFinal = await RegExp_Replace(outFinal, "<silent=(?P<sil>1|0)>", "")
    if sqlCon.is_connected():
        sqlCon.commit()
        sqlCon.close()
    outMsg = outFinal.replace("  ", " ")
    outMsg = await capFirst(outMsg)
    return outMsg

async def userTranslate(msg, authorID):
    sqlCon = await DbConnect()
    botID = await getBotField("BotID")
    botClientID = await getBotField("BotClientID")
    botFriendlyName = await getBotField("BotFriendlyName")
    botFriendlyName += ": "
    botFriendlyName = botFriendlyName.lower()
    out = msg
    sqlCurs = sqlCon.cursor(dictionary=True)
    sqlCurs.execute("SELECT original, replacement, cond FROM translations WHERE user_or_bot = 'USER' AND is_active = 1 AND botID = " + str(botID) + " ORDER BY ID ASC, priority DESC;")
    results = sqlCurs.fetchall()
    for row in results:
        original = row["original"]
        replacement = row["replacement"]
        if await RegExp_Like(out, original):
            out = await RegExp_Replace(out, original, replacement)
    outFinal = out.replace("<@!" + botClientID + ">", "")
    outFinal = outFinal.replace(botFriendlyName, "")
    outFinal = outFinal.replace("  ", " ")
    sqlCurs.close()
    if sqlCon.is_connected():
        sqlCon.commit()
        sqlCon.close()
    outFinal = outFinal.replace(botFriendlyName, "")
    return outFinal

async def checkIfFriends(authorID):
    botID = await getBotField("BotID")
    userID = await getField("Users", "ID", "clientID = '" + str(authorID) + "'")
    sqlCon = await DbConnect()
    sqlCurs = sqlCon.cursor(buffered=True)
    sqlCurs.execute("SELECT userID FROM BuddyList WHERE botID = " + str(botID) + " AND userID = " + str(userID) + ";")
    rowCount = sqlCurs.rowcount
    sqlCurs.close()
    if sqlCon.is_connected():
        sqlCon.close()
    return (rowCount > 0)

async def readyActivity(botID):
    sqlCon = await DbConnect()
    try:
        sqlCurs = sqlCon.cursor(dictionary=True)
        sqlCurs.execute("SELECT Func_GetActivityType(" + str(botID) + ") AS ActType, Func_GetActivityName(" + str(botID) + ") AS ActName FROM DUAL")
        results = sqlCurs.fetchone()
        actType = results["ActType"].lower()
        actName = results["ActName"]
        act = None
        match actType:
            case 'play':
                act = discord.Game(actName)
            case 'listen':
                act = discord.Activity(type=discord.ActivityType.listening, name=actName)
            case 'watch':
                act = discord.Activity(type=discord.ActivityType.watching, name=actName)
            case _: #Default
                act = None
        if act != None:
            await bot.change_presence(status=discord.Status.online, activity=act)
        sqlCurs.close()
    except SqlDB.Error as E:
        print("Failed to execute stored function: Func_GetActivityType {}".format(E))
    if sqlCon.is_connected():
        sqlCon.close()

@bot.command(name="friendme")
async def friendme(ctx):
    botID = await getBotField("BotID")
    authorID = ctx.author.id
    alreadyFriends = await checkIfFriends(authorID)
    if alreadyFriends:
        m = "We are already friends, <name>!"
        m = await botTranslate(m, authorID)
        await ctx.channel.send(m)
    else:
        sqlCon = await DbConnect()
        try:
            sqlCurs = sqlCon.cursor()
            params = (botID, str(authorID))
            args = sqlCurs.callproc("AddFriend", params)
            for results in sqlCurs.stored_results():
                print(results.fetchall())
            m = "We are now friends, <name>!"
            m = await botTranslate(m, authorID)
            await ctx.channel.send(m)
            sqlCurs.close()
        except SqlDB.Error as E:
            print("Failed to execute stored procedure: AddFriend {}".format(E))
        if sqlCon.is_connected():
            sqlCon.commit()
            sqlCon.close()

@bot.command(name="unfriendme")
async def unfriendme(ctx):
    botID = await getBotField("BotID")
    authorID = ctx.author.id
    alreadyFriends = await checkIfFriends(authorID)
    if not alreadyFriends:
        m = "But we're not even friends, <name>..."
        m = await botTranslate(m, authorID)
        await ctx.channel.send(m)
    else:
        sqlCon = await DbConnect()
        try:
            sqlCurs = sqlCon.cursor()
            params = (botID, str(authorID))
            args = sqlCurs.callproc("RemoveFriend", params)
            for results in sqlCurs.stored_results():
                print(results.fetchall())
            m = "Okay, I have removed you from my friends list, <name>. :disappointed:"
            m = await botTranslate(m, authorID)
            await ctx.channel.send(m)
            sqlCurs.close()
        except SqlDB.Error as E:
            print("Failed to execute stored procedure: RemoveFriend {}".format(E))
        if sqlCon.is_connected():
            sqlCon.commit()
            sqlCon.close()

@bot.command(name="speak")
async def speak(ctx, *args):
    msg = ""
    for a in args:
        msg += " " + a
    msg = msg.replace("  ", " ")
    engine.say(msg)
    engine.runAndWait()

@bot.command(name="sendchannelmessage")
async def sendchannelmessage(ctx, CHANNEL_ID, *args):
   msg = ""
   for a in args:
       msg += " " + a
   msg = msg.replace("  ", " ")
   msg = await botTranslate(msg, ctx.author.id)
   print(f'{CHANNEL_ID} - {msg}')
   channel = bot.get_channel(int(CHANNEL_ID))
   await channel.send(msg)
   await setBotField("last_message", msg)

@bot.command(name="sendusermessage")
async def sendusermessage(ctx, USER_ID, *args):
    user = await bot.fetch_user(USER_ID)
    msg = ""
    for a in args:
        msg += " " + a
    msg = msg.replace("  ", " ")
    m = await botTranslate(msg, USER_ID)
    await setBotField("last_message", m)
    await user.send(m)

@bot.command(name="join")
async def join(ctx):
    connected = ctx.author.voice
    if connected:
        voiceChannel = bot.get_channel(ctx.author.voice.channel.id)
        await voiceChannel.connect()
    else:
        await ctx.channel.send("Cannot detect your voice channel.")

@bot.command(name="leave")
async def leave(ctx):
    for vc in bot.voice_clients:
        await vc.disconnect()

@bot.command(name="check")
async def check(ctx, arg):
    if ctx.guild is False:
        await ctx.channel.send(arg)

@bot.command(name="logout")
async def logout(ctx):
    if ctx.author.id == ADMIN_ID:
        farewell = await getBotField("BotFarewell")
        f = await botTranslate(farewell, ADMIN_ID)
        await ctx.channel.send(f)
        await bot.change_presence(status=discord.Status.invisible)
        await bot.close()
    else:
        msg = "I only listen to my Master."
        m = await botTranslate(msg, ctx.author.id)
        await ctx.channel.send(m)
        await setBotField("last_message", m)

@bot.command(name="activity")
async def activity(ctx, actType, *actName):
    botID = await getBotField("BotID")
    authorID = ctx.author.id
    if authorID != ADMIN_ID:
        return
    actType = actType.lower()
    activity = ""
    for g in actName:
        activity += " " + g
    activity = activity.replace("  ", " ")
    act = None
    match actType:
        case ('game'|'play'):
            act = discord.Game(activity)
        case 'listen':
            act = discord.Activity(type=discord.ActivityType.listening, name=activity)
        case 'watch':
            act = discord.Activity(type=discord.ActivityType.watching, name=activity)
        case _:
            act = None #Default
    if act != None:
        sqlCon = await DbConnect()
        try:
            sqlCurs = sqlCon.cursor()
            params = (botID, actType, activity)
            args = sqlCurs.callproc("SetActivity", params)
            for results in sqlCurs.stored_results():
                print(sqlCurs.fetchall())
            sqlCurs.close()
        except SqlDB.Error as E:
            print("Failed to execute stored procedure: SetActivity {}".format(E))
        await bot.change_presence(status=discord.Status.online, activity=act)
        m = "Activity updated."
        await ctx.channel.send(m)
        await setBotField("last_message", m)
        if sqlCon.is_connected():
            sqlCon.close()

@bot.command(name="guid")
async def guid(ctx):
    g = uuid.uuid4()
    await senddm(ADMIN_ID, "{" + str.upper(str(g)) + "}")

@bot.event
async def on_ready():
    await bot.wait_until_ready()
    botID = await getBotField("BotID")
    botGUID = await getBotField("BotGUID")
    if botGUID != GUID:
        print("GUIDs do not match! Signing off.")
        await bot.change_presence(status=discord.Status.invisible)
        await bot.close()
        return
    print(f'Connected as: {bot.user}')
    print(f'{bot.user} is connected to:')
    p_guild = discord.utils.find(lambda g: g.name == MAIN_GUILD, bot.guilds)
    s_guild = discord.utils.find(lambda g: g.name == ALT_GUILD, bot.guilds)
    print(f'{p_guild.name} (ID: {p_guild.id})')
    print(f'{s_guild.name} (ID: {s_guild.id})')
    print("Ready!")
    activity = await getBotField("BotActivity")
    greeting = await getBotField("BotGreeting")
    greeting = await botTranslate(greeting, ADMIN_ID)
    await readyActivity(botID)
    await senddm(ADMIN_ID, greeting)

@bot.event
async def on_connect():
    print(f'{bot.user} has connected to Discord!')

@bot.event
async def on_disconnect():
    print(f'{bot.user} has disconnected from Discord.')

@bot.event
async def on_resumed():
    print(f'{bot.user} has resumed connection on Discord.')

@bot.event
async def on_member_join(ctx, member):
    await ctx.channel.send(f'Welcome, <@!{member.name}>!')

@bot.event
async def on_message(message):
    await bot.process_commands(message)
    silentMode = await getBotField("EnableSilentMode")
    if silentMode.lower() == 'yes':
        return
    if message.content.startswith("!"):
        return
    ct = DtTm.datetime.now()
    author = message.author
    authorID = author.id
    msg = message.content
    isDM = isinstance(message.channel, discord.channel.DMChannel)
    botFriendlyName = await getBotField("BotFriendlyName")
    botFriendlyName = botFriendlyName.lower()
    if not msg.lower().startswith(botFriendlyName + ": ") and not isDM and not bot.user.mentioned_in(message):
        return
    botClientID = await getBotField("BotClientID")
    msg = await userTranslate(msg, authorID)
    print(f'{author} (ID: {authorID}) @ {ct}: {msg}')
    await CheckNewUserByID(f'{author}', f'{authorID}')
    await CheckResponses(authorID, message)
    await LogMessage(authorID, msg)
    if random.randint(0, 100) < 10:
        if authorID != botClientID and author != bot.user:
            await LearnSaying(authorID, msg)

updateActivityRandomly.start()
bot.run(TOKEN)