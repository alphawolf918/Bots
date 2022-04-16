if cond != "[none]":
    rx = "\[var:(?P<variable>[A-z0-9_-]{1,25})\]"
    tp = "\[topic:(?P<topic>[A-z0-9_-]{1,25})\]"
    uid = "\[userid:(?P<user>[0-9]{1,25})\]"
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