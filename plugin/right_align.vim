" File: right_align.vim
" Author: Alexey Radkov
" Version: 0.7
" Description: A function to set right indentation, it can be useful in insert
"              mode in addition to ^T, ^D and ^F
" Usage:
"   Command :RightAlign to align current line to a right border, the optional
"   argument indicates that position of the cursor must be kept.
"   Global variable g:RightAlign_RightBorder will be used as the right border
"   value, if not set then value of option 'textwidth' will be used instead.
"   If global variable g:RightAlign_ShiftRound is set then start position of
"   the line after motion will be shiftwidth-fold, otherwise the start
"   position will depend on whether option 'shiftround' is set or not. Default
"   value of g:RightAlign_ShiftRound is 1.
"   Recommended mappings are
"       imap <silent> <C-b>  <Plug>RightAlign
"       nmap <silent> <C-k>b :RightAlign<CR>
"       vmap <silent> <C-k>b :RightAlign<CR>


if exists('g:loaded_RightAlignPlugin') && g:loaded_RightAlignPlugin
    finish
endif

let g:loaded_RightAlignPlugin = 1

if !exists('g:RightAlign_RightBorder')
    let g:RightAlign_RightBorder = &textwidth
endif

if !exists('g:RightAlign_ShiftRound')
    let g:RightAlign_ShiftRound = 1
endif

function! <SID>do_right_align(right_border, keep_cursor)
    let save_lbr = &lbr
    let save_sbr = &sbr
    let line_length = virtcol('$') - 1
    let narrow_win = winwidth(0) < a:right_border || winwidth(0) < line_length
    " unset temporarily 'lbr' and 'sbr' if line is or will be wrapped
    if narrow_win
        setlocal nolbr
        setlocal sbr=
        let line_length = virtcol('$') - 1
    endif
    let indent_cmd = ''
    let move_left = 0
    let tab_width = &et ? &sw : 1
    let save_cursor = getpos('.')
    let move_cursor = 0
    let line_diff = a:right_border - line_length
    let move_count = line_diff / &sw
    let restore_noshiftround = 0
    if g:RightAlign_ShiftRound && ! &shiftround
        set shiftround
        let restore_noshiftround = 1
    endif
    normal ^
    let start_pos = virtcol('.') - 1
    let start_shift = start_pos % &sw
    let end_shift = line_diff % &sw
    call setpos('.', save_cursor)
    " restore cursor position after undo (see Tip 1595 in vim.wikia.com)
    if a:keep_cursor
        normal ix
        normal x
    endif
    if g:RightAlign_ShiftRound && start_shift > 0
        if line_diff >= 0
            if &sw - start_shift <= line_diff % &sw
                let move_count += 1
                let move_cursor = start_shift - tab_width
            else
                if line_diff < &sw
                    let move_left = 1
                    let move_count = 1
                    let move_cursor = -start_shift - tab_width
                else
                    let move_cursor = -start_shift
                endif
            endif
        else
            if start_shift < abs(end_shift)
                let move_count -= 1
            endif
        endif
    else
        let start_shift = 0
    endif
    if line_diff < 0 && (start_shift != 0 || end_shift != 0)
        let move_count -= 1
        let move_cursor -= start_shift
        if start_shift != 0
            let move_cursor += tab_width
        endif
    endif
    let move_cursor += move_count * tab_width
    if move_cursor < 0 && start_pos < -move_cursor
        let move_cursor = -start_pos
    endif
    let save_cursor[2] += move_cursor
    if line_diff < 0
        let move_left = 1
        let move_count = -move_count
    endif
    for i in range(1, move_count)
        let indent_cmd .= move_left ? '<' : '>'
    endfor
    if !empty(indent_cmd)
        exe indent_cmd
    endif
    if a:keep_cursor
        call setpos('.', save_cursor)
    endif
    if restore_noshiftround
        set noshiftround
    endif
    if narrow_win
        let &lbr = save_lbr
        let &sbr = save_sbr
    endif
    return ''
endfunction

function! <SID>right_align(right_border, ...)
    if getline('.') =~ '^[[:blank:]]*$'
        return ''
    endif
    let keep_cursor = a:0 > 0 && a:1 == 'kc'
    return s:do_right_align(a:right_border, keep_cursor)
endfunction

command! -range -nargs=* RightAlign     <line1>,<line2>
            \ call s:right_align(g:RightAlign_RightBorder, <f-args>)

imap <silent> <Plug>RightAlign
            \ <C-r>=<SID>right_align(g:RightAlign_RightBorder, 'kc')<CR>

