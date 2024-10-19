#Requires AutoHotkey v2.0


; SetTitleMatchMode(2)

SetKeyDelay 100

move_cursor_to(inp){
    ; MouseGetPos &xpos, &ypos
    ; cur_title := WinGetTitle("A")
    if WinExist(inp){
        WinGetPos &x, &y, &w, &h, inp
        center_x := x + (w // 2)
        center_y := y + (h // 2)
        ; MouseMove center_x, center_y
        WinActivate inp
        WinWaitActive inp
        return 'ok'
        ; for _, ele in inp_command{
        ;     ; MsgBox ele
        ;     Send ele
        ; }
    } else {
        MsgBox "not exists"
        return 'fail'
        ; ExitApp ; it will exit ahk, not just stop this execution
    }
}

; src_title := "WSL-Ubuntu"
src_title := 'Visual Studio Code'
; tgt_title := "10.20.14.4"
; tgt_title := "10.26.6.81"
tgt_title := 'PuTTY'
; tgt_title := '远程桌面连接'


; get_path(){
;     A_Clipboard := ""
;     Send "cp"
;     ClipWait
;     tmp_path := A_Clipboard
;     aa := StrSplit(tmp_path, 'project/', '')
;     new_path := aa[2]
;     A_Clipboard := ""
;     Send "sy"
;     ClipWait
;     tmp_content := A_Clipboard
;     tmp_pos := InStr(tmp_content, '|')-1
;     lines := SubStr(tmp_content, 1, tmp_pos)
;     new_content := SubStr(tmp_content, tmp_pos+2)
;     lines_sp := StrSplit(lines, ',')
;     start_line := lines_sp[1]
;     line_num := lines_sp[2]
;     A_Clipboard := SubStr(tmp_content, tmp_pos+2)
;     Sleep(1000)
;     return new_path
; }

get_path(inp){
    A_Clipboard := ""
    Send "+!c"
    ClipWait
    tmp_path := A_Clipboard
    aa := StrSplit(tmp_path, 'project\', '')
    new_path := StrReplace(aa[2], "\", "/")
    A_Clipboard := ""
    if (inp == 'a') {
        Send "^a"
    }
    Send '^c'
    ; send 'y'
    ClipWait
    ; Sleep(1000)
    return new_path
}

tgt_action(inp_path, inp_title){
    tmp := move_cursor_to(inp_title)
    if (tmp == 'fail') {
        return 'fail'
    }
    Send "{Esc}"
    Send ":Jwtabnew " inp_path
    Send "{Enter}"
    Sleep(200)
    Send "{Esc}"
    Sleep(500)
    SendText "gg"
    Sleep(200)
    SendText "v"
    Sleep(200)
    SendText 'G'
    Sleep(200)
    SendText 'd'
    SendText 'i'
    Sleep(200)
    Send '+{Insert}'
    Sleep(1000)
    Send '{Esc}'
    Sleep(200)
    return 'ok'
}

; $space::Space
Space & l::
{
    cur_title := WinGetTitle("A")
    if InStr(cur_title, src_title)
    {
        new_path := get_path('')
        tmp := tgt_action(new_path, tgt_title)
        if (tmp == 'fail' ){
            return 'fail'
        }
        Send 'v'
        Send 'gg'
        Sleep(200)
        SendText 'm'
        Sleep(500)
        Send '#1'
        Sleep(100)
        Send '{Esc}'
    }
}

^h::
{
    cur_title := WinGetTitle("A")
    if InStr(cur_title, src_title)
    {
        ; send 'gg'
        ; Sleep(200)
        ; send 'v'
        ; Sleep(200)
        ; send 'G'
        ; Sleep(300)
        new_path := get_path('a')
        tmp := tgt_action(new_path, tgt_title)
        if (tmp == 'fail'){
            return 'fail'
        }
        Sleep(200)
        Send 'gg'
        Sleep(200)
        Send '#1'
    }
}

space::space



; !k::
; {
;     Send "+{Insert}"
;     ; Sleep(1000)
;     Send "ggvG"
; }






Space & j::
{
    cur_title := WinGetTitle("A")
    if InStr(cur_title, tgt_title)
        {
            move_cursor_to(src_title)
        }
    if InStr(cur_title, src_title)
        {
            move_cursor_to(tgt_title)
        }
    ; else{
    ;     Send '{PgUp}'
    ; }
}

; !j::gt
; {
;     cur_title := WinGetTitle("A")
;     if InStr(cur_title, src_title)
;     {
;         move_cursor_to(tgt_title)
;     }
;     ; else{
;     ;     Send '{PgDn}'
;     ; }
; }
