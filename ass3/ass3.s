section .data
    
    global scheduler_co
    global one_eighty

    board_size: equ 100      ; size of board
    format_int: db '%d'     ; string to int format
    format_short: db '%hd'     ; string to int format
    LFSR_taps: db 45        ; mask for the LFSR
    
    
    STKSIZE:  equ 16*1024 ;16 KbSTKi:resb STKSIZE
    USHRT_MAX: equ 65535
    
    scheduler_co:   dd scheduler
                    dd SCHDSTK+STKSIZE

    one_eighty: dd 180
     
    
section .rodata

section .bss
    
    global num_of_drones
    global drones_array
    global seed
    global targets_to_win
    global num_of_steps
    global beta
    global max_distance
    global SPT
    global SPMAIN
    global curr_drone_index
    global CURR
    

    SCHDSTK:    resb STKSIZE

    num_of_drones: resd 1       ; number of drones
    drones_array: resd 1        ; drones coroutines array
    seed: resw 1                ; the seed for the lsfr
    targets_to_win: resd 1      ; number of targets
    num_of_steps: resd 1        ; number of steps to print
    beta: resd 1                ; angle of drone field of view
    max_distance: resd 1        ; distance needed to be able to destroy
    SPT: resd 1                 ; esp holder

    CODEP: equ 0                ; scheduler struct
    SPP: equ 4
    
    SPMAIN: resd 1
    curr_drone_index: resd 1

    CURR: resd 1    ; current running thread   

    drone_struct_size: equ 46    ; size of drone struct

    drone_x_coordinate: equ 8
    drone_y_coordinate: equ 18
    alpha: equ 28
    targets_destroyed: equ 38
    drone_stack: equ 42




section .text                           ; following - c code

    align 16                            
    global main
    global LFSR
    global resume
    global do_resume
    global start_co
    global end_co
    global init_target
    global init_printer

    extern malloc 
    extern calloc 
    extern sscanf
    extern free 
    extern scheduler
    extern drone
    extern target_co
    extern create_target
    extern printer_co

    

; _start:
;     pop    dword ecx    ; ecx = argc
;     mov    esi,esp      ; esi = argv
;     mov eax, esi
;     add eax, 4
;     pushad

    

    

;     ; After we have all the inputs <N> <T> <K> <b> <d> <seed>


;     ;; lea eax, [esi+4*ecx+4] ; eax = envp = (4*ecx)+esi+4
;     mov     eax,ecx     ; put the number of arguments into eax
;     shl     eax,2       ; compute the size of argv in bytes
;     add     eax,esi     ; add the size to the address of argv 
;     add     eax,4       ; skip NULL at the end of argv
;     push    dword eax   ; char *envp[]
;     push    dword esi   ; char* argv[]
;     push    dword ecx   ; int argc

;     call    main        ; int main( int argc, char *argv[], char *envp[] )

main:
    push ebp
    mov ebp, esp

    mov ecx, [ebp+8]                ; argc
    mov eax, [ebp+12]               ; argv
    add eax, 4

    finit

    pushad
    push num_of_drones          ; taking the num_of_drones from argv[0]
    push format_int
    push dword [eax]
    call sscanf
    add esp, 12
    popad

    add eax, 4
    pushad
    push targets_to_win         ; taking the targets_to_win from argv[1]
    push format_int
    push dword [eax]
    call sscanf
    add esp, 12
    popad

    add eax, 4
    pushad
    push num_of_steps           ; taking the targets_to_win from argv[2]
    push format_int
    push dword [eax]
    call sscanf
    add esp, 12
    popad

    add eax, 4
    pushad
    push beta                  ; taking the targets_to_win from argv[3]
    push format_int             
    push dword [eax]
    call sscanf
    add esp, 12
    popad

    fild dword [beta]
    fidiv dword [one_eighty]
    fldpi
    fmulp
    fstp dword [beta]

    add eax, 4
    pushad
    push max_distance           ; valid distance to destroy a target argv[4]
    push format_int
    push dword [eax]
    call sscanf
    add esp, 12
    popad

    add eax, 4
    pushad
    push seed                   ; taking the targets_to_win from argv[5]
    push format_short
    push dword [eax]
    call sscanf
    add esp, 12
    popad

    call init

    call start_co

    call free_drones

    mov     ebx,eax
    mov     eax,1
    int     0x80
    nop


LFSR:
    push ebp
    mov ebp, esp
    pushad
    mov edx, 0
    mov dx, [seed]                  ; seed
    mov ecx, 16
    .loop:
        mov ebx, edx                      ; save the value of seed in ebx
        shr dx, 1                       ; pop the lsb bit in the pseudo random cycle
        and bl, [LFSR_taps]               ; mask to get the odd/even number of 1 bits from the taps
        jp .even                         ; if the taps gave even result then 0 should be in the msb of LFSR
        
        mov ax, 1                       ; put 1 value in eax
        shl ax, 15                      ; make value of eax 2^15 to insert into LFSR
        add dx, ax                      ; insert msb 1 bit into LFSR -> now we have a new pseudo number
        
        .even:
                           ; move return result into eax
    loop .loop

    mov [seed], dx                  ; move return result into eax
    
    popad
    mov eax, 0
    mov ax, [seed]
    mov esp, ebp
    pop ebp
    ret

    

init:
    push ebp
    mov ebp, esp
    sub esp, 12
    mov ebx, [num_of_drones]
    shl ebx, 2
    push ebx
    push 1
    call calloc
    mov [drones_array], eax
    add esp, 8

    pushad
    call init_target

    call init_printer

    call init_scheduler
    popad

    mov ecx, [num_of_drones]
    mov esi, 0
    drone_init_loop:

        

        mov eax, dword [drones_array]
        add eax, esi
        mov [ebp-8], eax

        pushad
        push drone_struct_size
        push 1
        call calloc
        add esp, 8
        mov edi, [ebp-8]
        mov [edi], eax
        popad
        mov eax, [eax]
        mov [ebp-8], eax 

        mov dword [eax+CODEP], drone
        pushad
        push STKSIZE
        push 1
        call calloc
        add esp, 8
        mov [ebp-4], eax
        popad
        mov ebx, [ebp-4]
        mov dword [eax+drone_stack], ebx
        mov dword [eax+SPP], ebx
        add dword [eax+SPP], STKSIZE
        ; dec dword [eax+SPP]

        pushad
        call LFSR
        mov dword [ebp-12], eax
        fild dword [ebp-12]
        mov eax, [ebp-8]
        mov dword [ebp-12], USHRT_MAX
        fidiv dword [ebp-12]
        mov dword [ebp-12], board_size
        fimul dword [ebp-12]
        fstp tword [eax+drone_x_coordinate]
        popad

        pushad
        call LFSR
        mov dword [ebp-12], eax
        fild dword [ebp-12]
        mov eax, [ebp-8]
        mov dword [ebp-12], USHRT_MAX
        fidiv dword [ebp-12]
        mov dword [ebp-12], board_size
        fimul dword [ebp-12]
        fstp tword [eax+drone_y_coordinate]
        popad

        pushad
        call LFSR
        mov dword [ebp-12], eax
        fild dword [ebp-12]
        mov eax, [ebp-8]
        mov dword [ebp-12], USHRT_MAX
        fidiv dword [ebp-12]
        fldpi
        mov dword [ebp-12], 2                           ; in order to mul by 2 we need to save it in memory
        fimul dword [ebp-12]                            ; mul by 2
        fmulp
        fstp tword [eax+alpha]
        popad

        mov dword [eax+targets_destroyed], 0

        mov [SPT], esp
        mov esp, [eax+SPP]
        push dword [eax+CODEP]
        pushfd
        pushad
        mov [eax+SPP], esp
        mov esp, [SPT]

        add esi, 4
    dec ecx
    jnz drone_init_loop
    
    mov esp, ebp
    pop ebp
    ret
    


init_target:

    push ebp
    mov ebp,esp
    pushad

    call create_target

    mov eax, target_co
    mov [SPT], esp
    mov esp, [eax+SPP]
    push dword [eax+CODEP]
    pushfd
    pushad
    mov [eax+SPP], esp
    mov esp, [SPT]

    popad
    mov esp, ebp
    pop ebp
    ret


resume:
    pushfd
    pushad
    mov edx, [CURR]
    mov [edx+SPP], esp   ; save current ESP

do_resume: ; load ESP for resumed co-routine

    mov esp, [ebx+SPP]
    mov [CURR], ebx
    popad
    popfd
    ret

init_scheduler:

    push ebp
    mov ebp,esp
    pushad

    mov eax, scheduler_co
    mov [SPT], esp
    mov esp, [eax+SPP]
    push dword [eax+CODEP]
    pushfd
    pushad
    mov [eax+SPP], esp
    mov esp, [SPT]

    popad
    mov esp, ebp
    pop ebp
    ret

start_co:
    pushad
    mov [SPMAIN], esp
    mov dword [CURR], scheduler_co
    mov ebx, scheduler_co
    jmp do_resume

init_printer:

    push ebp
    mov ebp,esp
    pushad

    mov eax, printer_co
    mov [SPT], esp
    mov esp, [eax+SPP]
    push dword [eax+CODEP]
    pushfd
    pushad
    mov [eax+SPP], esp
    mov esp, [SPT]

    popad
    mov esp, ebp
    pop ebp
    ret



end_co:
    pushfd
    pushad
    mov [ebx+SPP], esp
    mov esp, [SPMAIN]              ; restore ESP of main()popad
    popad
    ret

free_drones:
    push ebp
    mov ebp,esp
    pushad

    mov ebx, 0
    mov ecx, dword [num_of_drones]
    .loop:
        mov eax, dword [drones_array]
        add eax, ebx
        pushad
        mov eax, [eax]
        mov eax, [eax+drone_stack]
        push eax
        call free
        add esp, 4
        popad
        pushad
        push dword [eax]
        call free
        add esp, 4
        popad
        
        add ebx, 4


    loop .loop

    push dword [drones_array]
    call free
    add esp, 4

    popad
    mov esp, ebp
    pop ebp
    ret












