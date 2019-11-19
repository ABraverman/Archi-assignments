section .data
    

section .rodata
    i_am_winner_string: db "Drone id %d: I am a winner" ,10 , 0
    


section .bss

    
    drone_struct_size: equ 46    ; size of drone struct
    CODEP: equ 0
    SPP: equ 4
    drone_x_coordinate: equ 8
    drone_y_coordinate: equ 18
    alpha: equ 28
    targets_destroyed: equ 38

    USHRT_MAX: equ 65535
    board_size: equ 100      ; size of board

section .text                           ; following - c code
    align 16                            
    global drone                         
    
    extern printf
    extern LFSR
    extern CURR
    extern mayDestroy
    extern scheduler_co
    extern targets_to_win
    extern curr_drone_index
    extern end_co
    extern resume
    extern target_co
    extern one_eighty


drone:
    push ebp
    mov ebp, esp
    sub esp, 24


    call LFSR                               ; produce number for delta(alpha)   
    mov dword [ebp-24], eax
    fild dword [ebp-24]
    mov dword [ebp-24], USHRT_MAX
    fidiv dword [ebp-24]          
                                       ; dividing the number by maxshort *3
    mov dword [ebp-24], 120                                            
    fimul dword [ebp-24]                    ; finishing scaling                 
    mov dword [ebp-24], 60
    fisub dword [ebp-24]                    ; getting the scale [-60,60] by substituting 60 degrees
    fidiv dword [one_eighty]
    fldpi
    fmulp
    fstp tword [ebp-20]                     ; moving scaled delta(alpha) to [ebp-20]

    call LFSR                               ; produce number for delta(d)
    mov dword [ebp-24], eax
    fild dword [ebp-24]
    mov dword [ebp-24], USHRT_MAX
    fild dword [ebp-24]
    fdivp
    mov eax, board_size
    shr eax, 1
    mov dword [ebp-24], eax
    fild dword [ebp-24]
    fmulp                                   ; scaling: number\maxshort * 50
    fstp tword [ebp-10]                     ; storing the scaled delta(d) in [ebp-10]
    
    
    fld tword [ebp-20]                     ; moving scaled delta(alpha) to ST(0) from [ebp-20] 
    mov edi, [CURR]
    fld tword [edi+alpha]
    faddp                                   ; alpha + delta(alpha) -> alpha'
    fldpi
    fldpi
    faddp                                   ; now checking 3 cases of alpha angle compared to pi*2 : (alpha'> 360), (360 > alpha' > 0), ( alpha' < 0 )
    fcomi st0, st1
    jae .test_neg_ang                        ; need to check if  ( alpha' < 0 )

    fsubp                                   ; (alpha' > 360)

    jmp .good_angle

    .test_neg_ang:
    fstp st0 
    mov ebx, 0
    mov dword [ebp-24], ebx
    fild dword [ebp-24]
    fcomip st0, st1
    jbe .good_angle

    fldpi
    fldpi
    faddp                                   ; getting pi*2 on x87 stack

    faddp                                   ; ( alpha' < 0 ) -> alpha' + pi*2
    
    .good_angle:
    
    mov edi, [CURR]
    fstp tword [edi+alpha]                  ; alpha' inserted to the drone struct
    fld tword [edi+alpha]                  ; alpha' inserted to the drone struct
                                            
    fsincos                                 ; computes both sin and cosine of the source operand in register st0), stores sine in st0) and pushes cosine to top of x87 stack
    fld tword [ebp-10]                      ; loading delta(d) to FPU register stack
    fmulp
    mov edi, [CURR]                                   ; delta(d)*cosine
    fld tword [edi+drone_x_coordinate]     
    faddp                                   ; x+ delta(x) -> x' on FPU register stack

    mov dword [ebp-24], board_size
    fild dword [ebp-24]
    fcomi st0, st1
    jae .test_neg_x

    fsubp

    jmp .good_x

    .test_neg_x:
    fstp st0
    mov dword [ebp-24], 0
    fild dword [ebp-24]
    fcomip st0, st1
    jbe .good_x

    mov dword [ebp-24], board_size
    fild dword [ebp-24]
    faddp
    
    .good_x:
    
    mov edi, [CURR]
    fstp tword [edi+drone_x_coordinate]        ; x' after putting it on the right place on the board

    fld tword [ebp-10]                          ; loading delta(y to FPU register stack
    fmulp                                       ; we have sine in st1 
    mov edi, [CURR]
    fld tword [edi+drone_y_coordinate]
    faddp                                       ; y+ delta(y -> y' on FPU register stack

    mov dword [ebp-24], board_size
    fild dword [ebp-24]
    fcomi st0, st1
    jae .test_neg_y

    fsubp

    jmp .good_y

    .test_neg_y:
    fstp st0
    mov dword [ebp-24], 0
    fild dword [ebp-24]
    fcomip st0, st1
    jbe .good_y

    mov dword [ebp-24], board_size
    fild dword [ebp-24]
    faddp
    
    .good_y:

    mov edi, [CURR]
    fstp tword [edi+drone_y_coordinate]    ; y' after putting it on the right place on the board

    
    call mayDestroy
    cmp eax, 0
    je .not_destroyed

    mov edi, [CURR]
    inc dword [edi + targets_destroyed]

    mov edi, [CURR]
    mov ebx, [edi + targets_destroyed]
    cmp ebx, [targets_to_win]
    jne .no_win

    push dword [curr_drone_index]
    push i_am_winner_string
    call printf
    add esp, 8


    
    mov ebp, esp
    pop ebp
    mov ebx, [CURR]
    call end_co

    .no_win:

    mov ebx, target_co
    call resume

    jmp drone

    .not_destroyed:
    mov ebx, scheduler_co
    call resume

    jmp drone



    

