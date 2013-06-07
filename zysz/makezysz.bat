
@echo ============编译智勇三张游戏脚本============
@set OutPutDir=..\..\..\..\product\win32d\server\games\zysz
@if not exist %OutPutDir%\ md %OutPutDir%\
@if not exist %OutPutDir%\logic\ md %OutPutDir%\logic
@if not exist .\release\logic\ md .\release\logic\

..\..\bin\luac.exe -o %OutPutDir%\zysz.declare.drd zysz.declare.lua
..\..\bin\luac.exe -o %OutPutDir%\zysz.main.drd zysz.main.lua
