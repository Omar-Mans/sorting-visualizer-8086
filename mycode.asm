org 100h

jmp start

; ---- Data ----
msgMenu         db 'Choose sorting algorithm:', 0Dh, 0Ah
                db '1. Insertion Sort', 0Dh, 0Ah
                db '2. Bubble Sort', 0Dh, 0Ah
                db '3. Selection Sort', 0Dh, 0Ah
                db 'Enter your choice (1-3): $'
msgInvalidChoice db 'Invalid choice! Enter 1-3.', 0Dh, 0Ah, '$'
msgEnterSize    db 'Enter array size (1-10): $'
msgInvalidSize  db 'Invalid size, must be 1-10!', 0Dh, 0Ah, '$'
msgEnterElem    db 'Enter element ', '$'
msgColonSpace   db ': ', '$'
msgInvalidNum   db 'Invalid number! Try again.', 0Dh, 0Ah, '$'
msgInitial      db 'Initial array:', 0Dh, 0Ah, '$'
msgSorted       db 'Sorted array:', 0Dh, 0Ah, '$'
msgPressKey     db 'Press any key$'

; Box drawing characters
boxTopLeft      db 0DAh, '$'      ; +
boxTopRight     db 0BFh, '$'      ; +
boxBottomLeft   db 0C0h, '$'      ; +
boxBottomRight  db 0D9h, '$'      ; +
boxHorizontal   db 0C4h, '$'      ; -
boxVertical     db 0B3h, '$'      ; ¦

inputBufferLen  db 4
inputCount      db 0
inputBuffer     db 4 dup(?)

digitsBuf       db 5 dup(?)

algorithmChoice db ?
NVal            db ?
iVar            db ?
jVar            db ?
keyVar          db ?
minIndex        db ?
tempVar         db ?
array           db 10 dup(?)

; ---- Code ----
start:
    mov ax, cs
    mov ds, ax

    ; Display menu and get algorithm choice
show_menu:
    mov dx, offset msgMenu
    mov ah, 09h
    int 21h
    
    mov ah, 01h
    int 21h
    call newline
    
    cmp al, '1'
    jb invalid_choice
    cmp al, '3'
    ja invalid_choice
    sub al, '0'
    mov [algorithmChoice], al
    jmp get_array_size

invalid_choice:
    mov dx, offset msgInvalidChoice
    mov ah, 09h
    int 21h
    jmp show_menu

get_array_size:
    mov dx, offset msgEnterSize
    mov ah, 09h
    int 21h
    
    mov byte ptr [inputCount], 0
    mov ah, 0Ah
    mov dx, offset inputBufferLen
    int 21h
    call newline
    
    xor ax, ax
    xor bx, bx
    mov cl, [inputCount]
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
    ; Print prompt in new line
    call newline
    mov dx, offset msgEnterElem
    mov ah, 09h
    int 21h
    
    push cx
    mov al, cl
    call print_num
    pop cx
    
    mov dx, offset msgColonSpace
    mov ah, 09h
    int 21h
    
    ; Read element input
    mov byte ptr [inputCount], 0
    mov ah, 0Ah
    mov dx, offset inputBufferLen
    int 21h
    
    ; Convert to number
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
    inc si
    dec ch
    jnz convert_elem

    ; Check if number is within byte range (0-99)
    cmp ah, 0
    jne elem_invalid
    
    ; Store element in array
    mov [di], al
    inc di
    
    ; Check if all elements read
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

    ; Call selected sorting algorithm
    mov al, [algorithmChoice]
    cmp al, 1
    je insertion_sort
    cmp al, 2
    je bubble_sort
    cmp al, 3
    je selection_sort

insertion_sort:
    mov byte ptr [iVar], 1
insertion_outer_loop:
    mov al, [iVar]
    cmp al, [NVal]
    jae sorting_done
    mov bl, [iVar]
    dec bl
    mov [jVar], bl
    mov si, offset array
    mov al, [iVar]
    mov ah, 0
    add si, ax
    mov al, [si]
    mov [keyVar], al

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

    call print_array_box
    call print_ij
    call wait_key

    mov si, offset array
    mov al, [jVar]
    mov ah, 0
    add si, ax
    mov al, [si]
    mov di, si
    inc di
    mov [di], al

    call print_array_box
    call print_ij
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

    call print_array_box
    call print_ij
    call wait_key

    inc byte ptr [iVar]
    jmp insertion_outer_loop

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
    
    call print_array_box
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
    
    mov [si], bl
    mov [si+1], al
    
bubble_no_swap:
    inc byte ptr [jVar]
    jmp bubble_inner_loop
    
bubble_end_inner_loop:
    inc byte ptr [iVar]
    jmp bubble_outer_loop

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
    
    call print_array_box
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
    
selection_no_new_min:
    inc byte ptr [jVar]
    jmp selection_inner_loop
    
selection_end_inner_loop:
    mov al, [minIndex]
    cmp al, [iVar]
    je selection_no_swap_needed
    
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
    
selection_no_swap_needed:
    inc byte ptr [iVar]
    jmp selection_outer_loop

sorting_done:
    mov dx, offset msgSorted
    mov ah, 09h
    int 21h
    call print_array_box
    call newline
    
    mov ah, 4Ch
    mov al, 0
    int 21h

; ---- Subroutines ----
print_array_box:
    push ax
    push bx
    push cx
    push dx
    push si
    
    ; Calculate total width: (N * 5) - 1
    mov al, [NVal]
    mov bl, 5
    mul bl
    dec al
    mov cl, al  ; cl = total width
    
    ; Print top border
    mov dx, offset boxTopLeft
    mov ah, 09h
    int 21h
    
    mov ch, 0
top_border:
    cmp ch, cl
    jae top_done
    mov dx, offset boxHorizontal
    mov ah, 09h
    int 21h
    inc ch
    jmp top_border
top_done:
    mov dx, offset boxTopRight
    mov ah, 09h
    int 21h
    call newline
    
    ; Print middle line with array elements
    mov dx, offset boxVertical
    mov ah, 09h
    int 21h
    
    mov cl, [NVal]
    mov ch, 0
    mov si, offset array
middle_loop:
    mov dl, ' '
    mov ah, 02h
    int 21h
    
    mov al, [si]
    call print_num
    
    mov dl, ' '
    mov ah, 02h
    int 21h
    
    dec cl
    jz middle_done
    
    mov dx, offset boxVertical
    mov ah, 09h
    int 21h
    
    inc si
    jmp middle_loop
    
middle_done:
    mov dx, offset boxVertical
    mov ah, 09h
    int 21h
    call newline
    
    ; Print bottom border
    mov dx, offset boxBottomLeft
    mov ah, 09h
    int 21h
    
    mov al, [NVal]
    mov bl, 5
    mul bl
    dec al
    mov cl, al
    mov ch, 0
bottom_border:
    cmp ch, cl
    jae bottom_done
    mov dx, offset boxHorizontal
    mov ah, 09h
    int 21h
    inc ch
    jmp bottom_border
bottom_done:
    mov dx, offset boxBottomRight
    mov ah, 09h
    int 21h
    call newline
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

print_num:
    push ax
    push bx
    push cx
    push dx
    
    mov ah, 0
    mov bl, 10
    div bl
    mov cl, ah
    mov dl, al
    add dl, '0'
    mov ah, 02h
    int 21h
    mov dl, cl
    add dl, '0'
    mov ah, 02h
    int 21h
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

print_ij:
    push ax
    push dx
    
    mov dl, ' '
    mov ah, 02h
    int 21h
    mov dl, 'i'
    int 21h
    mov dl, '='
    int 21h
    mov al, [iVar]
    call print_num
    mov dl, ' '
    int 21h
    mov dl, 'j'
    int 21h
    mov dl, '='
    int 21h
    mov al, [jVar]
    cmp al, 0
    jge print_j_pos
    mov dl, '-'
    int 21h
    mov dl, '1'
    int 21h
    jmp print_ij_done
print_j_pos:
    call print_num
print_ij_done:
    call newline
    pop dx
    pop ax
    ret

print_ij_min:
    push ax
    push dx
    
    mov dl, ' '
    mov ah, 02h
    int 21h
    mov dl, 'i'
    int 21h
    mov dl, '='
    int 21h
    mov al, [iVar]
    call print_num
    mov dl, ' '
    int 21h
    mov dl, 'j'
    int 21h
    mov dl, '='
    int 21h
    mov al, [jVar]
    call print_num
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
    call print_num
    
    call newline
    pop dx
    pop ax
    ret

newline:
    push dx
    push ax
    mov dl, 0Dh
    mov ah, 02h
    int 21h
    mov dl, 0Ah
    mov ah, 02h
    int 21h
    pop ax
    pop dx
    ret

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