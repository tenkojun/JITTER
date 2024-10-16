local a = obslua
local b = require("bit")
local c = require("ffi")
local d = c.load("obs")
local e = c.load("user32.dll")

local f = nil
local g = 1
local h = 6
local i = 170
local j = false
local k = 1000
local v = 5

local l = debug.getinfo(1).source:match("@?(.*/)") or ""
local m = l .. "LOGO.jpg"

c.cdef[[
typedef void* HANDLE;
typedef HANDLE HWND;
typedef HANDLE HICON;
typedef HICON HCURSOR;
typedef char CHAR;
typedef const CHAR* LPCCH, *PCSTR, *LPCSTR;
typedef int WINBOOL, *PWINBOOL, *LPWINBOOL;
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
    DWORD cbSize;
    DWORD flags;
    HCURSOR hCursor;
    POINT ptScreenPos;
} CURSORINFO, *PCURSORINFO, *LPCURSORINFO;
HWND FindWindowA(LPCSTR lpClassName, LPCSTR lpWindowName);
HWND GetForegroundWindow();
BOOL IsWindow(HWND hWnd);
BOOL GetCursorInfo(PCURSORINFO pci);
SHORT GetAsyncKeyState(int vKey);
void mouse_event(DWORD dwFlags, DWORD dx, DWORD dy, DWORD dwData, ULONG_PTR dwExtraInfo);
int MessageBoxA(HWND hWnd, LPCSTR lpText, LPCSTR lpCaption, unsigned int uType);
]]

local function n(window)
    return c.C.GetForegroundWindow() == window
end

local function p()
    local cursorInfo = c.new("CURSORINFO")
    cursorInfo.cbSize = c.sizeof("CURSORINFO")
    if c.C.GetCursorInfo(cursorInfo) ~= 0 then
        return cursorInfo.flags ~= 0
    end
end

local function r()
    f = c.C.FindWindowA(nil, "Apex Legends")
    if j and f and n(f) and not p() then
        if b.band(c.C.GetAsyncKeyState(0x01), 0x8000) > 0 and b.band(c.C.GetAsyncKeyState(0x02), 0x8000) > 0 then
            c.C.mouse_event(0x0001, g * h, v, 0, 0)
            g = g * -1
        end
    end
end

function script_description()
    return [[
    <div><center><img src="]] .. m .. [[" alt="Logo" width="200" height="200"/></center></div>
    <br>
    <div>에이펙스 지터</div>
    <div><a href="https://github.com/tenkojun/JITTER" style="float: right">개발자 양반 깃헙</a></div>
    <hr>
    ]]
end

function script_properties()
    local props = a.obs_properties_create()
    a.obs_properties_add_int_slider(props, "게임 FPS", "게임 FPS", 1, 299, 1)
    a.obs_properties_add_int_slider(props, "지터 좌우반동", "지터 좌우반동 (0-50)", 0, 1000, 1)
    a.obs_properties_add_int_slider(props, "지터 세로반동", "지터 세로반동 (0-50)", 0, 1000, 1)
    a.obs_properties_add_int_slider(props, "커서 체크 빈도", "초당 커서 체크 횟수", 1, 1000, 1)
    a.obs_properties_add_bool(props, "지터 활성화", "지터 활성화")
    return props
end

function script_defaults(settings)
    a.obs_data_set_default_double(settings, "게임 FPS", i)
    a.obs_data_set_default_int(settings, "지터 좌우반동", h)
    a.obs_data_set_default_int(settings, "지터 세로반동", v)
    a.obs_data_set_default_int(settings, "커서 체크 빈도", k)
    a.obs_data_set_default_bool(settings, "지터 활성화", j)
end

function script_update(settings)
    i = a.obs_data_get_double(settings, "게임 FPS")
    h = a.obs_data_get_int(settings, "지터 좌우반동") / 20 
    v = a.obs_data_get_int(settings, "지터 세로반동") / 20 

    k = a.obs_data_get_int(settings, "커서 체크 빈도")
    j = a.obs_data_get_bool(settings, "지터 활성화")

    a.timer_remove(r)
    if j then
        a.timer_add(r, math.ceil(1000 / k))
    else
        a.timer_remove(r)
    end
end
