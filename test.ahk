#Requires AutoHotkey v2.0


; SetTitleMatchMode(2)



move_cursor_to(inp, inp_command){
    ; MouseGetPos &xpos, &ypos
    cur_title := WinGetTitle("A")
    if WinExist("ahk_class TMobaXtermForm"){
        WinGetPos &x, &y, &w, &h, inp
        center_x := x + (w // 2)
        center_y := y + (h // 2)
        ; MouseMove center_x, center_y
        WinActivate inp
        WinWaitActive inp
        for _, ele in inp_command{
            Send ele
        }
    } else {
        MsgBox "not exists"
        return
    }
    Sleep(2000)
    WinActivate cur_title
    ; Sleep(1000)
    ; MsgBox xpos " " ypos
    ; MouseMove xpos, ypos
    
}

^j::
{
    ; A_Clipboard := ""  ; 先让剪贴板为空, 这样可以使用 ClipWait 检测文本什么时候被复制到剪贴板中.
    ; Send "^c"
    ; ClipWait
    if WinActive("ahk_class TFormDetachedTab")
    { 
        move_cursor_to("ahk_class TMobaXtermForm", "+{Insert}")      
    }
    
}


^o::
{
    cur_title := WinGetTitle("A")
    if InStr(cur_title, "NVIM")
    {
        tmp_pos := InStr(cur_title, '(')
        filename := SubStr(cur_title, 1, tmp_pos-1)
        tmp_pos2 := InStr(cur_title, ')')
        filedir := SubStr(cur_title, tmp_pos+1, tmp_pos2-tmp_pos-1)
        aa := StrSplit(filedir, '\', '')
        new_path := "~/" aa[2] "/" aa[3] "/" filename
        ; A_Clipboard := ""
        ; Send "yp"
        ; ClipWait
        ; new_path := A_Clipboard
        A_Clipboard := ""
        Send "sy"
        ClipWait
        tmp_content := A_Clipboard
        tmp_pos := InStr(tmp_content, '|')-1
        lines := SubStr(tmp_content, 1, tmp_pos)
        new_content := SubStr(tmp_content, tmp_pos+2)
        lines_sp := StrSplit(lines, ',')
        start_line := lines_sp[1]
        line_num := lines_sp[2]
        tmp_command := []
        tmp_command.Push(":Jwtabnew " new_path)
        ; tmp_command.Push("{Enter}")
        ; tmp_command.Push(':lua goto_or_add_line(' line_num '){Enter}O' )
        ; tmp_command.Push("+{Insert}{Esc}")
        ; if line_num == 0{
        ;     tmp_command.Push(start_line "ggm")
        ; }else{
        ;     tmp_command.Push(start_line "ggv" line_num "jm")
        ; }
        move_cursor_to("ahk_class TMobaXtermForm", tmp_command)
    }
}
