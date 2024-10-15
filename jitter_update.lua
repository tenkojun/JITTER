local obs = obslua
local bit = require("bit")
local ffi = require("ffi")
local obsffi = ffi.load("obs")
local u32 = ffi.load("user32.dll")
local game_window = nil
local toggle_direction = 1
local shake_intensity = 6
local refresh_rate = 170
local shake_enabled = false
local sensitivity_scale = 1.0 -- 감도 비율 추가
local logo_path = "./LOGO.jpg"

-- FFI C 정의
ffi.cdef[[
    typedef void *HANDLE;
    typedef HANDLE HWND;
    typedef HANDLE HICON;
    typedef HICON HCURSOR;
    typedef char CHAR;
    typedef const CHAR *LPCCH,*PCSTR,*LPCSTR;
    typedef int WINBOOL,*PWINBOOL,*LPWINBOOL;
    typedef WINBOOL BOOL;
    typedef long LONG;
    typedef unsigned short WORD, SHORT;
    typedef unsigned long DWORD;
    typedef unsigned long ULONG_PTR;

    typedef struct tagPOINT {
        LONG x;
        LONG y;
    } POINT, *PPOINT, *NPPOINT, *LPPOINT;

    typedef struct tagCURSORINFO {
        DWORD   cbSize;
        DWORD   flags;
        HCURSOR hCursor;
        POINT   ptScreenPos;
    } CURSORINFO, *PCURSORINFO, *LPCURSORINFO;

    HWND FindWindowA(LPCSTR lpClassName, LPCSTR lpWindowName);
    HWND GetForegroundWindow();
    BOOL IsWindow(HWND hWnd);
    BOOL GetCursorInfo(PCURSORINFO pci);
    SHORT GetAsyncKeyState(int vKey);
    void mouse_event(DWORD dwFlags, DWORD dx, DWORD dy, DWORD dwData, ULONG_PTR dwExtraInfo);
    int MessageBoxA(HWND hWnd, LPCSTR lpText, LPCSTR lpCaption, unsigned int uType);
]]

-- 게임 창 활성화 확인
function IsGameWindowActive(game_window)
    return ffi.C.GetForegroundWindow() == game_window
end

-- 마우스 커서 표시 여부 확인
function IsMouseCursorVisible()
    local cursor_info = ffi.new("CURSORINFO")
    cursor_info.cbSize = ffi.sizeof("CURSORINFO")
    return ffi.C.GetCursorInfo(cursor_info) ~= 0 and cursor_info.flags ~= 0
end

-- 지터 동작 함수
function shake_function()
    game_window = ffi.C.FindWindowA(nil, "Apex Legends")
    if shake_enabled and game_window and IsGameWindowActive(game_window) and not IsMouseCursorVisible() then
        if bit.band(ffi.C.GetAsyncKeyState(0x01), 0x8000) > 0 and bit.band(ffi.C.GetAsyncKeyState(0x02), 0x8000) > 0 then
            local adjusted_intensity = toggle_direction * shake_intensity * sensitivity_scale -- 감도 비율 적용
            ffi.C.mouse_event(0x0001, adjusted_intensity, adjusted_intensity, 0, 0)
            toggle_direction = toggle_direction * -1
        end
    end
end

-- OBS 스크립트 설명
function script_description()
    return [[
    <div>
        <h1 style="font-family:Segoe Script; text-align: center">hollow_obs</h1>
        <center><img src=']] .. logo_path .. [['/></center>
    </div>
    <br>
    <div>에이펙스 지터</div>
    <div><a href="https://github.com/tenkojun" style="float: right">github</a></div>
    <hr>]]
end

-- OBS 속성 생성
function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_int_slider(props, "게임 FPS", "Game FPS", 1, 299, 1)
    obs.obs_properties_add_int_slider(props, "지터 거리설정", "Range", 1, 100, 1)
    obs.obs_properties_add_float_slider(props, "감도 비율", "Sensitivity Scale", 0.1, 5.0, 0.1) -- 감도 비율 추가
    obs.obs_properties_add_bool(props, "지터 활성화", "Enabled")
    return props
end

-- OBS 기본값 설정
function script_defaults(settings)
    obs.obs_data_set_default_double(settings, "게임 FPS", refresh_rate)
    obs.obs_data_set_default_int(settings, "지터 거리설정", shake_intensity)
    obs.obs_data_set_default_double(settings, "감도 비율", sensitivity_scale) -- 기본 감도 비율 설정
    obs.obs_data_set_default_bool(settings, "지터 활성화", shake_enabled)
end

-- OBS 설정 업데이트
function script_update(settings)
    refresh_rate = obs.obs_data_get_double(settings, "게임 FPS")
    shake_intensity = obs.obs_data_get_int(settings, "지터 거리설정")
    sensitivity_scale = obs.obs_data_get_double(settings, "감도 비율") -- 감도 비율 값 가져오기
    shake_enabled = obs.obs_data_get_bool(settings, "지터 활성화")

    obs.timer_remove(shake_function)

    if shake_enabled then
        obs.timer_add(shake_function, math.ceil(1000 / refresh_rate))
    else
        obs.timer_remove(shake_function)
    end
end
