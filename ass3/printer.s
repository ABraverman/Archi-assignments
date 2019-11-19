section .data
    
    global printer_co

    printer_struct_size: equ 8
    target_foramt: db "%.2f,%.2f", 10, 0
    drone_foramt: db "%d,%.2f,%.2f,%.2f,%d", 10, 0
    
    CODEP: equ 0
    SPP: equ 4
    
    STKSIZE:  equ 16*1024 ;16 KbSTKi:resb STKSIZE
    
    
    printer_co: dd printer
                dd PRNTSTK+STKSIZE

    drone_struct_size: equ 46    ; size of drone struct

    
    target_x_coordinate: equ 8
    target_y_coordinate: equ 18
        
    drone_x_coordinate: equ 8
    drone_y_coordinate: equ 18
    alpha: equ 28
    targets_destroyed: equ 38
    

section .rodata
    
    



section .bss
    
PRNTSTK: resb STKSIZE    


section .text                           ; following - c code
    align 16                            

    
    extern printf
    extern drones_array
    extern target_co   
    extern num_of_drones   
    extern scheduler_co
    extern resume
    extern one_eighty


printer:
    push ebp
    mov ebp, esp
    

    mov eax, target_co
    fld tword [eax+target_y_coordinate]
    sub esp, 8
    fstp qword [esp]
    mov eax, target_co
    fld tword [eax+target_x_coordinate]
    sub esp, 8
    fstp qword [esp]
    push target_foramt
    call printf
    add esp, 20

    mov ecx, [num_of_drones]
    mov esi, dword [drones_array]
    mov ebx, 1

    .print_drones_loop:
        
        
        
        mov eax, [esi]
        pushad

        push dword [eax + targets_destroyed]

        fld tword [eax + alpha]                     ; TODO convert to degrees
        fldpi
        fdivp st1, st0
        fild dword [one_eighty]
        fmulp
        sub esp, 8
        fstp qword [esp]

        fld tword [eax + drone_y_coordinate]
        sub esp, 8
        fstp qword [esp]

        fld tword [eax + drone_x_coordinate]
        sub esp, 8
        fstp qword [esp]

        push ebx                                    ; drone index
                
        push drone_foramt
        call printf
        add esp, 36

        popad
        add esi, 4
        inc ebx
    
    loop .print_drones_loop
T:
    

    mov esp, ebp
    pop ebp

    mov ebx, scheduler_co
    call resume
    jmp printer

