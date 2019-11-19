section .data
    

section .rodata
    
    



section .bss

section .text                           ; following - c code
    align 16                            
    global scheduler

    extern num_of_steps
    extern drones_array
    extern printer_co
    extern num_of_drones
    extern resume
    extern curr_drone_index

scheduler:
    
    mov ecx, 0
    mov esi, 0
    

.thread_loop:

    mov [curr_drone_index], ecx             ; storing the current drone
    inc dword [curr_drone_index]
    mov ebx, [drones_array]
    shl ecx, 2
    add ebx, ecx
    shr ecx, 2
    mov ebx, [ebx]
    call resume

    inc esi
    cmp esi, [num_of_steps]
    jb .no_print
    
    mov ebx, printer_co
    call resume

    .no_print:

    inc ecx
    mov eax, ecx
    mov edx, 0     
    mov ebx, [num_of_drones]
    div ebx
    mov ecx, edx

    
    mov eax, esi
    mov edx, 0     
    mov ebx, [num_of_steps]
    div ebx
    mov esi, edx


jmp .thread_loop


