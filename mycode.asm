org 100h

jmp start

; ============================================
; DATA SECTION
; ============================================

; Menu messages
msgMenu         db '------------------------------------', 0Dh, 0Ah
                db '8086 Sorting Algorithms Visualizer', 0Dh, 0Ah
                db '------------------------------------', 0Dh, 0Ah
                db '1) Insertion Sort', 0Dh, 0Ah
                db '2) Bubble Sort', 0Dh, 0Ah
                db '3) Selection Sort', 0Dh, 0Ah
                db '4) Exit', 0Dh, 0Ah
                db '------------------------------------', 0Dh, 0Ah
                db 'Enter your choice: $'

msgInvalidChoice db 0Dh, 0Ah, 'Invalid choice! Enter 1-4.', 0Dh, 0Ah, '$'

; Input messages
msgEnterSize    db 0Dh, 0Ah, 'Enter array size (1-10): $'
msgInvalidSize  db 0Dh, 0Ah, 'Invalid size! Must be between 1 and 10.', 0Dh, 0Ah, '$'
msgEnterElem    db 'Enter element $'
msgColonSpace   db ': $'
msgInvalidNum   db 0Dh, 0Ah, 'Invalid number! Enter a value between 0-255.', 0Dh, 0Ah, '$'

; Display messages
msgInitial      db 0Dh, 0Ah, 'Initial Array:', 0Dh, 0Ah, '$'
msgSorted       db 0Dh, 0Ah, 'Sorted Array:', 0Dh, 0Ah, '$'
msgComparing    db 'Comparing...', 0Dh, 0Ah, '$'
msgSwapping     db 'Swapping...', 0Dh, 0Ah, '$'
msgShifting     db 'Shifting...', 0Dh, 0Ah, '$'
msgInserting    db 'Inserting key...', 0Dh, 0Ah, '$'
msgPressKey     db 0Dh, 0Ah, 'Press any key to continue...$'

; Input buffer for reading strings
inputBufferLen  db 4
inputCount      db 0
inputBuffer     db 4 dup(?)

; Variables
algorithmChoice db ?
NVal            db ?
iVar            db ?
jVar            db ?
keyVar          db ?
minIndex        db ?
tempVar         db ?

; Array storage (BYTE array, max 10 elements)
array           db 10 dup(?)

; Highlight flags (which indices to highlight)
highlightIdx1   db ?
highlightIdx2   db ?
highlightIdx3   db ?

; ============================================
; MAIN CODE SECTION
; ============================================

start:
    mov ax, cs
    mov ds, ax

show_menu:
    mov dx, offset msgMenu
    mov ah, 09h
    int 21h
    
    mov ah, 01h
    int 21h
    call newline
    
    cmp al, '1'
    jb invalid_choice
    cmp al, '4'
    ja invalid_choice
    
    sub al, '0'
    mov [algorithmChoice], al
    
    cmp al, 4
    je exit_program
    
    jmp get_array_size

invalid_choice:
    mov dx, offset msgInvalidChoice
    mov ah, 09h
    int 21h
    jmp show_menu

; ============================================
; INPUT SECTION
; ============================================

get_array_size:
    mov dx, offset msgEnterSize
    mov ah, 09h
    int 21h
    
    mov byte ptr [inputCount], 0
    mov byte ptr [inputBuffer], 0
    mov byte ptr [inputBuffer+1], 0
    mov byte ptr [inputBuffer+2], 0
    
    mov ah, 0Ah
    mov dx, offset inputBufferLen
    int 21h
    call newline
    
    xor ax, ax
    xor bx, bx
    mov cl, [inputCount]
    cmp cl, 0
    je size_invalid
    mov si, offset inputBuffer
    
convert_size:
    cmp cl, 0
    je conv_done_size
    
    mov bl, [si]
    cmp bl, '0'
    jb size_invalid
    cmp bl, '9'
    ja size_invalid
    
    sub bl, '0'
    
    mov dx, ax
    shl ax, 1
    shl dx, 3
    add ax, dx
    xor bh, bh
    add ax, bx
    
    inc si
    dec cl
    jmp convert_size
    
conv_done_size:
    cmp ax, 1
    jb size_invalid
    cmp ax, 10
    ja size_invalid
    
    mov [NVal], al
    jmp got_size
    
size_invalid:
    mov dx, offset msgInvalidSize
    mov ah, 09h
    int 21h
    jmp get_array_size

got_size:
    mov di, offset array
    mov cl, 1
    
read_element:
    call newline
    mov dx, offset msgEnterElem
    mov ah, 09h
    int 21h
    
    push cx
    mov al, cl
    call print_num_no_leading_zero
    pop cx
    
    mov dx, offset msgColonSpace
    mov ah, 09h
    int 21h
    
    mov byte ptr [inputCount], 0
    mov byte ptr [inputBuffer], 0
    mov byte ptr [inputBuffer+1], 0
    mov byte ptr [inputBuffer+2], 0
    
    mov ah, 0Ah
    mov dx, offset inputBufferLen
    int 21h
    
    mov si, offset inputBuffer
    xor ax, ax
    mov ch, [inputCount]
    cmp ch, 0
    je elem_invalid
    
convert_elem:
    mov bl, [si]
    cmp bl, '0'
    jb elem_invalid
    cmp bl, '9'
    ja elem_invalid
    
    sub bl, '0'
    
    mov dx, ax
    shl ax, 1
    shl dx, 3
    add ax, dx
    xor bh, bh
    add ax, bx
    
    cmp ax, 255
    ja elem_invalid
    
    inc si
    dec ch
    jnz convert_elem
    
    cmp ah, 0
    jne elem_invalid
    
    mov [di], al
    inc di
    
    mov al, cl
    cmp al, [NVal]
    je all_elements_done
    inc cl
    jmp read_element
    
elem_invalid:
    call newline
    mov dx, offset msgInvalidNum
    mov ah, 09h
    int 21h
    jmp read_element

all_elements_done:
    call newline
    mov dx, offset msgInitial
    mov ah, 09h
    int 21h
    call print_array_box
    call wait_key
    
    mov al, [algorithmChoice]
    cmp al, 1
    je insertion_sort
    cmp al, 2
    je bubble_sort
    cmp al, 3
    je selection_sort

; ============================================
; INSERTION SORT
; ============================================

insertion_sort:
    mov byte ptr [iVar], 1
    
insertion_outer_loop:
    mov al, [iVar]
    cmp al, [NVal]
    jae sorting_done
    
    mov si, offset array
    mov al, [iVar]
    mov ah, 0
    add si, ax
    mov al, [si]
    mov [keyVar], al
    
    mov bl, [iVar]
    dec bl
    mov [jVar], bl
    
    mov dx, offset msgInserting
    mov ah, 09h
    int 21h
    mov al, [iVar]
    mov [highlightIdx1], al
    mov al, [jVar]
    inc al
    mov [highlightIdx2], al
    mov byte ptr [highlightIdx3], 255
    call print_array_box_highlight
    call print_ij_key
    call wait_key
    
insertion_inner_loop:
    mov al, [jVar]
    cmp al, 0
    jl insertion_insert_key
    
    mov si, offset array
    mov al, [jVar]
    mov ah, 0
    add si, ax
    mov al, [si]
    mov bl, [keyVar]
    cmp al, bl
    jle insertion_insert_key
    
    mov dx, offset msgShifting
    mov ah, 09h
    int 21h
    mov al, [jVar]
    mov [highlightIdx1], al
    mov al, [jVar]
    inc al
    mov [highlightIdx2], al
    mov byte ptr [highlightIdx3], 255
    call print_array_box_highlight
    call print_ij_key
    call wait_key
    
    mov si, offset array
    mov al, [jVar]
    mov ah, 0
    add si, ax
    mov al, [si]
    mov di, si
    inc di
    mov [di], al
    
    call print_array_box_highlight
    call print_ij_key
    call wait_key
    
    dec byte ptr [jVar]
    jmp insertion_inner_loop
    
insertion_insert_key:
    mov si, offset array
    mov al, [jVar]
    inc al
    mov ah, 0
    add si, ax
    mov al, [keyVar]
    mov [si], al
    
    call print_array_box_highlight
    call print_ij_key
    call wait_key
    
    inc byte ptr [iVar]
    jmp insertion_outer_loop

; ============================================
; BUBBLE SORT
; ============================================

bubble_sort:
    mov byte ptr [iVar], 0
    
bubble_outer_loop:
    mov al, [iVar]
    mov bl, [NVal]
    dec bl
    cmp al, bl
    jae sorting_done
    
    mov byte ptr [jVar], 0
    
    mov al, [NVal]
    sub al, [iVar]
    dec al
    mov [tempVar], al
    
bubble_inner_loop:
    mov al, [jVar]
    cmp al, [tempVar]
    jae bubble_end_inner_loop
    
    mov dx, offset msgComparing
    mov ah, 09h
    int 21h
    mov al, [jVar]
    mov [highlightIdx1], al
    mov al, [jVar]
    inc al
    mov [highlightIdx2], al
    mov byte ptr [highlightIdx3], 255
    call print_array_box_highlight
    call print_ij
    call wait_key
    
    mov si, offset array
    mov al, [jVar]
    mov ah, 0
    add si, ax
    mov al, [si]
    mov bl, [si+1]
    
    cmp al, bl
    jle bubble_no_swap
    
    ; Save values and si before printing (print functions may modify registers)
    push ax
    push bx
    push si
    
    mov dx, offset msgSwapping
    mov ah, 09h
    int 21h
    call print_array_box_highlight
    call print_ij
    call wait_key
    
    ; Restore si and values for swap
    pop si
    pop bx
    pop ax
    
    mov [si], bl
    mov [si+1], al
    
    call print_array_box_highlight
    call print_ij
    call wait_key
    
bubble_no_swap:
    inc byte ptr [jVar]
    jmp bubble_inner_loop
    
bubble_end_inner_loop:
    inc byte ptr [iVar]
    jmp bubble_outer_loop

; ============================================
; SELECTION SORT
; ============================================

selection_sort:
    mov byte ptr [iVar], 0
    
selection_outer_loop:
    mov al, [iVar]
    mov bl, [NVal]
    dec bl
    cmp al, bl
    jae sorting_done
    
    mov al, [iVar]
    mov [minIndex], al
    
    mov al, [iVar]
    inc al
    mov [jVar], al
    
selection_inner_loop:
    mov al, [jVar]
    cmp al, [NVal]
    jae selection_end_inner_loop
    
    mov dx, offset msgComparing
    mov ah, 09h
    int 21h
    mov al, [iVar]
    mov [highlightIdx1], al
    mov al, [jVar]
    mov [highlightIdx2], al
    mov al, [minIndex]
    mov [highlightIdx3], al
    call print_array_box_highlight
    call print_ij_min
    call wait_key
    
    mov si, offset array
    mov al, [jVar]
    mov ah, 0
    add si, ax
    mov al, [si]
    
    mov di, offset array
    mov bl, [minIndex]
    mov bh, 0
    add di, bx
    mov bl, [di]
    
    cmp al, bl
    jae selection_no_new_min
    
    mov al, [jVar]
    mov [minIndex], al
    
    call print_array_box_highlight
    call print_ij_min
    call wait_key
    
selection_no_new_min:
    inc byte ptr [jVar]
    jmp selection_inner_loop
    
selection_end_inner_loop:
    mov al, [minIndex]
    cmp al, [iVar]
    je selection_no_swap_needed
    
    mov dx, offset msgSwapping
    mov ah, 09h
    int 21h
    mov al, [iVar]
    mov [highlightIdx1], al
    mov al, [minIndex]
    mov [highlightIdx2], al
    mov byte ptr [highlightIdx3], 255
    call print_array_box_highlight
    call print_ij_min
    call wait_key
    
    mov si, offset array
    mov al, [iVar]
    mov ah, 0
    add si, ax
    mov al, [si]
    mov [tempVar], al
    
    mov di, offset array
    mov bl, [minIndex]
    mov bh, 0
    add di, bx
    mov bl, [di]
    
    mov [si], bl
    mov [di], al
    
    call print_array_box_highlight
    call print_ij_min
    call wait_key
    
selection_no_swap_needed:
    inc byte ptr [iVar]
    jmp selection_outer_loop

; ============================================
; SORTING COMPLETE
; ============================================

sorting_done:
    call newline
    mov dx, offset msgSorted
    mov ah, 09h
    int 21h
    call print_array_box
    call newline
    
    jmp show_menu

exit_program:
    mov ah, 4Ch
    mov al, 0
    int 21h

; ============================================
; SUBROUTINES
; ============================================

; Print array in format: [ 1 , 5 , 3 , 7 , 2 ]
print_array_box:
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov dl, '['
    mov ah, 02h
    int 21h
    
    mov dl, ' '
    int 21h
    
    mov cl, [NVal]
    mov ch, 0
    mov si, offset array
    
print_array_loop:
    mov al, [si]
    call print_num_no_leading_zero
    
    dec cl
    jz print_array_done
    
    mov dl, ' '
    mov ah, 02h
    int 21h
    
    mov dl, ','
    int 21h
    
    mov dl, ' '
    int 21h
    
    inc si
    jmp print_array_loop
    
print_array_done:
    mov dl, ' '
    mov ah, 02h
    int 21h
    
    mov dl, ']'
    int 21h
    call newline
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Print array with highlighting: [ 1 , <<5>> , <<3>> , 7 , 2 ]
print_array_box_highlight:
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov dl, '['
    mov ah, 02h
    int 21h
    
    mov dl, ' '
    int 21h
    
    mov cl, [NVal]
    mov ch, 0
    mov si, offset array
    xor bh, bh
    
print_array_loop_hl:
    mov al, bh
    cmp al, [highlightIdx1]
    je do_highlight_hl
    cmp al, [highlightIdx2]
    je do_highlight_hl
    cmp al, [highlightIdx3]
    je do_highlight_hl
    jmp no_highlight_hl
    
do_highlight_hl:
    mov dl, '<'
    mov ah, 02h
    int 21h
    mov dl, '<'
    int 21h
    mov al, [si]
    call print_num_no_leading_zero
    mov dl, '>'
    int 21h
    mov dl, '>'
    int 21h
    jmp after_element_hl
    
no_highlight_hl:
    mov al, [si]
    call print_num_no_leading_zero
    
after_element_hl:
    dec cl
    jz print_array_done_hl
    
    mov dl, ' '
    mov ah, 02h
    int 21h
    
    mov dl, ','
    int 21h
    
    mov dl, ' '
    mov ah, 02h
    int 21h
    
    inc si
    inc bh
    jmp print_array_loop_hl
    
print_array_done_hl:
    mov dl, ' '
    mov ah, 02h
    int 21h
    
    mov dl, ']'
    int 21h
    call newline
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Print number without leading zeros (0-255)
print_num_no_leading_zero:
    push ax
    push bx
    push cx
    push dx
    
    mov ah, 0
    mov bl, 10
    div bl
    mov cl, ah
    mov ch, al
    
    cmp ch, 0
    je print_ones_only
    
    mov dl, ch
    add dl, '0'
    mov ah, 02h
    int 21h
    
print_ones_only:
    mov dl, cl
    add dl, '0'
    mov ah, 02h
    int 21h
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Print i, j values
print_ij:
    push ax
    push dx
    
    call newline
    mov dl, 'i'
    mov ah, 02h
    int 21h
    mov dl, '='
    int 21h
    mov al, [iVar]
    call print_num_no_leading_zero
    
    mov dl, ' '
    int 21h
    mov dl, 'j'
    int 21h
    mov dl, '='
    int 21h
    mov al, [jVar]
    call print_num_no_leading_zero
    call newline
    
    pop dx
    pop ax
    ret

; Print i, j, min values
print_ij_min:
    push ax
    push dx
    
    call newline
    mov dl, 'i'
    mov ah, 02h
    int 21h
    mov dl, '='
    int 21h
    mov al, [iVar]
    call print_num_no_leading_zero
    
    mov dl, ' '
    int 21h
    mov dl, 'j'
    int 21h
    mov dl, '='
    int 21h
    mov al, [jVar]
    call print_num_no_leading_zero
    
    mov dl, ' '
    int 21h
    mov dl, 'm'
    int 21h
    mov dl, 'i'
    int 21h
    mov dl, 'n'
    int 21h
    mov dl, '='
    int 21h
    mov al, [minIndex]
    call print_num_no_leading_zero
    call newline
    
    pop dx
    pop ax
    ret

; Print i, j, key values
print_ij_key:
    push ax
    push dx
    
    call newline
    mov dl, 'i'
    mov ah, 02h
    int 21h
    mov dl, '='
    int 21h
    mov al, [iVar]
    call print_num_no_leading_zero
    
    mov dl, ' '
    int 21h
    mov dl, 'j'
    int 21h
    mov dl, '='
    int 21h
    mov al, [jVar]
    cmp al, 0
    jge print_j_pos_key
    mov dl, '-'
    int 21h
    mov dl, '1'
    int 21h
    jmp print_key
print_j_pos_key:
    call print_num_no_leading_zero
    
print_key:
    mov dl, ' '
    int 21h
    mov dl, 'k'
    int 21h
    mov dl, 'e'
    int 21h
    mov dl, 'y'
    int 21h
    mov dl, '='
    int 21h
    mov al, [keyVar]
    call print_num_no_leading_zero
    call newline
    
    pop dx
    pop ax
    ret

; Print newline
newline:
    push dx
    push ax
    mov dl, 0Dh
    mov ah, 02h
    int 21h
    mov dl, 0Ah
    int 21h
    pop ax
    pop dx
    ret

; Wait for keypress
wait_key:
    push dx
    push ax
    mov dx, offset msgPressKey
    mov ah, 09h
    int 21h
    mov ah, 00h
    int 16h
    call newline
    pop ax
    pop dx
    ret
