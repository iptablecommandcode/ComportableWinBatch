@echo off
setlocal enabledelayedexpansion

echo 라우팅 설정용 윈도우 배치

@REM 메뉴
cls
:menu
echo 메뉴 :
echo 1. 라우팅 추가
echo 0. 종료
set /p menunumber=원하는 옵션을 선택하세요 : 

@REM 사용자의 선택에 따라 다른 작업 수행
cls
if %menunumber%==0 goto quit
if %menunumber%==1 goto add

@REM route add 220.86.29.33 172.30.0.1 if 5 metric 100 -p
:add
echo 라우팅을 시작합니다.
echo 라우팅 옵션을 선택해 주세요
echo 0. 종료
echo 1. 라우팅 테이블 일시적 경로 추가 (재부팅시 초기화)
echo 2. 라우팅 테이블 영구 경로 추가 (삭제 처리 해야됨)
set /p routingmenu=원하는 옵션을 선택하세요 : 

@REM 사용자의 선택에 따라 다른 작업 수행
if %routingmenu%==1 (
    set "userchoice=1"
)
if %routingmenu%==2 (
    set "userchoice=2"
)
if %routingmenu%==0 (
    goto quit
)
cls
goto ipChk

@REM IP 정상 기입 확인용
:ipChk
route print
set /p routingIpAddress=라우팅 아이피를 입력해 주세요 (ex.xxx.xxx.xxx.xxx) : 
goto setIP

@REM IP설정을 위한 로직
@REM 라우팅 값을 보고 netmask 사용 하는지 확인 없을경우 단일 아이피 적용
:setIP
set "check_ip=1"

for /f "tokens=1-4 delims=." %%a in ("%routingIpAddress%") do (
    if "%%d"=="" set "check_ip=0"
    for %%i in (%%a %%b %%c %%d) do (
        rem 각 옥텟이 숫자인지 확인하고 0-255 범위 내에 있는지 확인
        if not "%%i"=="" (
            for /f "tokens=*" %%x in ('echo %%i^|findstr /r "^[0-9][0-9]*$"') do (
                @REM ip의 경우 0의 값이 없는 상태 있어야 한다
                if %%i lss 0 set "check_ip=0"
                if %%i gtr 255 set "check_ip=0"
            )
        ) else (
            set "check_ip=0"
        )
    )
)
if "%check_ip%"=="0" (
    cls
    echo 정확한 ip 주소 값을 입력해 주시기 바랍니다.
    goto ipChk
) else (
    cls
    goto netmask
)

@REM netmask 설정
:netmask
route print
set /p netmaskaddress = netmask를 입력해 주세요(ex.255.255.255.0) : 

set "check_netmask=1"

for /f "tokens=1-4 delims=." %%a in ("%netmaskaddress%") do (
    if "%%d"=="" set "check_netmask=0"
    for %%i in (%%a %%b %%c %%d) do (
        rem 아이피 숫자인지 확인 0~255
        if not "%%i"=="" (
            for /f "tokens=*" %%x in ('echo %%i^|findstr /r "^[0-9][0-9]*$"') do (
                @REM netmask의 경우 0의 값이 있는 상태라 지워야 된다
                @REM if %%i lss 0 set "check_netmask=0"
                if %%i gtr 255 set "check_netmask=0"
            )
        ) else (
            set "check_netmask=0"
        )
    )
)

if "%check_netmask%"=="0" (
    cls
    echo 정확한 netmask 값을 입력해 주시기 바랍니다.
    goto netmask
) else (
    cls
    goto interface
)

@REM interface 값 입력
:interface
route print
set /p interface=interface값을 입력해 주세요 : 

if "!interface!" == "" (
    if %errorlevel% == 0 (
        cls
        goto metric
    ) else (
        cls
        echo 정확한 interface값을 입력해 주세요.
        goto interface
    )
)

@REM metric 값 입력
:metric
route print
set /p metric=metric값을 입력해 주세요 : 

if %metric% == "" (
    pause
    cls
    echo 정확한 metric값을 입력해 주시기 바랍니다.
    goto metric
) else (
    if %userchoice% == "1" (
        cls
        goto temporary
    ) else (
        cls
        goto permanent
    )
)

@REM gateway 설정을 위한 로직
:gateway
set /p gateway=gateway 주소(을)를 입력해 주세요 : 

set "check_gateway=1"

for /f "tokens=1-4 delims=." %%a in ("%gateway%") do (
    if "%%d"=="" set "check_gateway=0"
    for %%i in (%%a %%b %%c %%d) do (
        rem gateway 숫자인지 확인 0~255
        if not "%%i"=="" (
            for /f "tokens=*" %%x in ('echo %%i^|findstr /r "^[0-9][0-9]*$"') do (
                @REM gateway의 경우 0의 값이 없는 상태라 적용 하여야  된다
                if %%i lss 0 set "check_gateway=0"
                if %%i gtr 255 set "check_gateway=0"
            )
        ) else (
            set "check_gateway=0"
        )
    )
)

if "%check_gateway%"=="0" (
    cls
    echo 정확한 gateway 주소 값을 입력해 주시기 바랍니다.
    goto gateway
) else (
    cls
    goto metric
)

@REM route add 220.86.29.33 172.30.0.1 if 5 metric 100
@REM 일시적 경로 추가
:temporary
route add %routingIpAddress% %netmaskaddress% %gateway% if %interface% metric %metric%

@REM route add 220.86.29.33 172.30.0.1 if 5 metric 100 -p
@REM 영구적 경로 추가
:permanent
route add %routingIpAddress% %netmaskaddress% %gateway% if %interface% metric %metric% -p

:quit
echo 프로그램을 종료합니다.
exit /b