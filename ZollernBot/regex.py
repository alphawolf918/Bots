import re

async def RegExp_Like(line, pattern):
    matchObj = re.search(pattern, line, re.M|re.I)
    return matchObj

async def RegExp_Replace(line, pattern, repl):
    matchObj = await RegExp_Like(line, pattern)
    if matchObj:
        result = re.sub(pattern, repl, line)
        return result

async def RegExp_Set(line, pattern, groupNm):
    v = re.search(pattern, line).group(groupNm)
    return v