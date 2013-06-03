
@echo ============±‡“Îtexas”Œœ∑Ω≈±æ============
@set OutPutDir=..\..\..\..\..\product\win32d\server\games\modules\daxiao
@if not exist %OutPutDir%\ md %OutPutDir%\

..\..\..\bin\luac.exe -o %OutPutDir%\daxiao.declare.drd %cd%\daxiao.declare.lua
..\..\..\bin\luac.exe -o %OutPutDir%\daxiao.main.drd %cd%\daxiao.main.lua