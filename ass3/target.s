section .data
    
    global target_co          

    target_struct_size: equ 28
    
    target_co:  dd target
                dd TRGSTK+STKSIZE
                dt 0.0
                dt 0.0

    
    

section .rodata
    
    



section .bss
    
    CODEP: equ 0
    SPP: equ 4
    target_x_coordinate: equ 8
    target_y_coordinate: equ 18

    STKSIZE:  equ 16*1024 ;16 KbSTKi:resb STKSIZE
    
    TRGSTK: resb STKSIZE


    drone_struct_size: equ 46    ; size of drone struct
    
    drone_x_coordinate: equ 8
    drone_y_coordinate: equ 18
    alpha: equ 28
    targets_destroyed: equ 38

    USHRT_MAX: equ 65535

    board_size: equ 100      ; size of board


section .text                           ; following - c code
    align 16                            
    
    global create_target
    global mayDestroy
    
    extern LFSR
    extern beta
    extern max_distance
    extern CURR
    extern scheduler_co
    extern resume


target:
   
   call create_target
   mov ebx, scheduler_co
   call resume

jmp target



mayDestroy:                                          ;  (abs(alpha-gamma < beta and sqrt((y2-y1^2+(x2-x1^2 < d
    push ebp
    mov ebp,esp
    sub esp, 34
    mov eax, 0
    
    ;calculatioing
    mov esi, target_co
    fld tword [esi + target_y_coordinate]     ; value of target_y held in st(1 (was st(0
    mov esi, [CURR]
    fld tword [esi + drone_y_coordinate]           ; value of drone_y held in st(0
    fsubp                                           ; calcualting y_target - y_drone (we may have mixed them up
    fstp tword [ebp-20]                              ; [ebp-20] holds [y2-y1]
    fld tword [ebp-20]                              ; [ebp-20] holds [y2-y1]
    
    mov esi, target_co
    fld tword [esi + target_x_coordinate]     ; value of target_x held in st(1 (was st(0
    mov esi, [CURR]
    fld tword [esi + drone_x_coordinate]           ; value of drone_x held in st(0
    fsubp                                           ; calcualting x_target - x_drone (we may have mixed them up
    fstp tword [ebp-10]                              ; now [ebp-20] holds [y2-y1], and [ebp-10] holds [x2-x1]
    fld tword [ebp-10]                              ; now [ebp-20] holds [y2-y1], and [ebp-10] holds [x2-x1]
    
    fpatan                                          ; calculating <gamma> using arctan
    fstp tword [ebp-30]                              ; now [ebp-30] stores gamma
    fld tword [ebp-30]                              ; now [ebp-30] stores gamma

    mov esi, [CURR]
    fld tword [esi + alpha]
    fsubp
    fabs
    fldpi
    fcomip st0, st1
    jae good_angle

    fstp st0

    fld tword [ebp-30]
    mov esi, [CURR]
    fld tword [esi + alpha]
    fcomi st0, st1                             ; if alpha > gamma -> cf = 0, else cf =1
    jb alpha_is_lower                              ; if (alpha > gamma -> swap the two values on the x87 (so that we get gamma +pi*2. if( alpha < gamma -> keep them both in the stack and add pi*2 to alpha

    fxch st1                                     ; exchange alpha with gamma           
    
    alpha_is_lower:                                ; alpha is lower -> add pi*2 to alpha
    mov dword [ebp-34], 2                                     
    fldpi
    fimul dword [ebp-34]                                ; getting the 2*pi on stack
    faddp
    fsubp
    fabs                                           ; after adding pi*2 to alpha/ gamma calculate abs(alpha - gamma

    good_angle:
    fstp tword [ebp-30]                              ; now [ebp-30] stores <abs(gamma-alpha>
    fld tword [ebp-30]                              ; now [ebp-30] stores <abs(gamma-alpha>

    fld dword [beta]
    fcomip st0, st1                              
    fstp st0                                      ; pop the head of the stack -> x87 stack is empty
    jbe end                                         ; jump if beta <= abs(gamma-alpha

    

    ; sqrt((y2-y1^2+(x2-x1^2 < d calculation:

    fld tword [ebp-20]
    fmul st0
    
    fld tword [ebp-10]
    fmul st0
    faddp                                            ; stack holds the value of -> (y2-y1^2+(x2-x1^2
    fsqrt                                            ; stack holds the value of -> sqrt((y2-y1^2+(x2-x1^2
    
    fild dword [max_distance]                        ; storing max_distance in the x87 stack
    fcomip st0, st1                              ; if  d <= sqrt((y2-y1^2+(x2-x1^2
    fstp st0                                      ; pop the head of the stack -> x87 stack is empty
    jbe end

    
    mov eax, 1                                      ; both conditions are met -> return value changhed to 1
    
   
    end:

    mov esp, ebp
    pop ebp
    ret




create_target:

    push ebp
    mov ebp,esp
    sub esp, 4

    pushad
    call LFSR
    mov dword [ebp-4], eax
    fild dword [ebp-4]
    mov dword [ebp-4], USHRT_MAX
    fidiv dword [ebp-4]
    mov dword [ebp-4], board_size
    fimul dword [ebp-4]
    fstp tword [target_co+target_x_coordinate]
    popad

    pushad
    call LFSR
    mov dword [ebp-4], eax
    fild dword [ebp-4]
    mov dword [ebp-4], USHRT_MAX
    fidiv dword [ebp-4]
    mov dword [ebp-4], board_size
    fimul dword [ebp-4]
    fstp tword [target_co+target_y_coordinate]
    popad

    mov esp, ebp
    pop ebp
    ret
    
