
@echo ============±‡“Îtexas”Œœ∑Ω≈±æ============
@set OutPutDir=..\..\..\..\product\win32d\server\games\tex
@if not exist %OutPutDir%\ md %OutPutDir%\
@if not exist %OutPutDir%\logic\ md %OutPutDir%\logic
@if not exist %OutPutDir%\lanpack\ md %OutPutDir%\lanpack
@if not exist .\release\logic\ md .\release\logic\

..\..\bin\luac.exe -o %OutPutDir%\tex.declare.drd %cd%\tex.declare.lua
..\..\bin\luac.exe -o %OutPutDir%\tex.main.drd %cd%\tex.main.lua
..\..\bin\luac.exe -o %OutPutDir%\tex.net.drd %cd%\tex.net.lua
..\..\bin\luac.exe -o %OutPutDir%\tex.gift.drd %cd%\tex.gift.lua
..\..\bin\luac.exe -o %OutPutDir%\tex.safebox.drd %cd%\tex.safebox.lua
..\..\bin\luac.exe -o %OutPutDir%\tex.achievement.drd %cd%\tex.achievement.lua
..\..\bin\luac.exe -o %OutPutDir%\tex.buff.drd %cd%\tex.buff.lua
..\..\bin\luac.exe -o %OutPutDir%\tex.filter.drd %cd%\tex.filter.lua

..\..\bin\luac.exe -o %OutPutDir%\tex.net.drd tex.net.lua
..\..\bin\luac.exe -o %OutPutDir%\tex.gift.drd tex.gift.lua
..\..\bin\luac.exe -o %OutPutDir%\tex.safebox.drd tex.safebox.lua
..\..\bin\luac.exe -o %OutPutDir%\tex.achievement.drd tex.achievement.lua
..\..\bin\luac.exe -o %OutPutDir%\tex.buff.drd tex.buff.lua
..\..\bin\luac.exe -o %OutPutDir%\huodong.drd huodong.lua


copy logic\*.lua %OutPutDir%\logic\ /y
copy lanpack\*.lua %OutPutDir%\lanpack\ /y
copy tex.net.lua %OutPutDir%\ /y
copy tex.gift.lua %OutPutDir%\ /y
copy tex.safebox.lua %OutPutDir%\ /y
copy tex.achievement.lua %OutPutDir%\ /y
copy tex.buff.lua %OutPutDir%\ /y
copy huodong.lua %OutPutDir%\ /y
copy tex.suanpaiqi.lua %OutPutDir%\ /y
copy tex.quest.lua %OutPutDir%\ /y
copy tex.filter.lua %OutPutDir%\ /y
copy tex.speaker.lua %OutPutDir%\ /y
copy tex.userdiy.lua %OutPutDir%\ /y
copy tex.gameprops.lua %OutPutDir%\ /y
copy tex.ipprotect.lua %OutPutDir%\ /y
copy tex.channelyw.lua %OutPutDir%\ /y
copy tex.dhome.lua %OutPutDir%\ /y
copy tex.match.lua %OutPutDir%\ /y
copy tex.language_package.lua %OutPutDir%\ /y
copy tex.files_load.lua %OutPutDir%\ /y
copy tex.viproom.lua %OutPutDir%\ /y

