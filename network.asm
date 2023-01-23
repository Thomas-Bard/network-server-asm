; 64-BITs  because I don't want to get limited by the really small number of registers in 32-BITs

%define SYS_READ 0x00
%define SYS_WRITE 0x01
%define SYS_OPEN 0x02
%define SYS_CLOSE 0x03
%define SYS_SOCKET 0x29
%define SYS_EXIT 0x3C
%define SYS_BIND 0x31
%define SYS_LISTEN 0x32
%define SYS_ACCEPT 0x2B

%define AF_INET 0x02
%define PORT 0x411f
%define SOCK_STREAM 0x01
%define STDOUT 0x01
%define STDERR 0x02

%define URL_MAX_LENGTH 0xFF
%define MAX_DATA_LENGTH 0xFFFFF

section .data
http_header: times 30 db 0
header_len: equ $ - http_header
file_data: times MAX_DATA_LENGTH db 0

request_data: times 2048 db 0

message_error: db "An error occured !", 0xa
message_error_len: equ $ - message_error

http_filename: times 256 db 0x00

socket_addr:
		dw 2 ; AF_INET
		dw 0x411f ; Port 8001 in host byte order
		dd 0x00 ; INADDR_ANY
		dd 0, 0
socket_addri_len: equ $ - socket_addr

socket_fd: dd 0
client_socket_fd: dd 0
errno: dq 0
end_of_request_msg: db 0xa,"========== END OF REQUEST ==========",0xa
end_of_request_msg_len: equ $ - end_of_request_msg
ok_header: db "HTTP/1.1 200 OK", 0xd, 0xa, 0xa
ok_header_len: equ $ - ok_header
not_found_header: db "HTTP/1.1 404 NOT FOUND", 0xd, 0xa, 0xa
not_found_header_len: equ $ - not_found_header
http_default_name: db "/index.html"
http_default_name_len: equ $ - http_default_name

section .text
global _start

_start:
	mov rax, SYS_SOCKET
	mov rdi, AF_INET
	mov rsi, SOCK_STREAM
	mov rdx, 0x00
	syscall

	cmp rax, 0
	jl error

	mov [socket_fd], rax

	mov rax, SYS_BIND
	mov rdi, [socket_fd]
	mov rsi, socket_addr
	mov rdx, socket_addri_len
	syscall

	cmp rax, 0
	jl error

	mov rax, SYS_LISTEN
	mov rdi, [socket_fd]
	mov rsi, 0x05
	syscall

	cmp rax, 0
	jl error

accept_connection:
	mov rax, SYS_ACCEPT
	mov rdi, [socket_fd]
	mov rsi, 0x00
	mov rdx, 0x00
	syscall

	cmp rax, 0
	jl error

	mov [client_socket_fd], rax

	; Let's print out what the socket has

	mov rdi, rax
	mov rax, SYS_READ
	mov rsi, request_data
	mov rdx, 2048
	syscall

	cmp rax, 0x00
	jl error
	
	;mov rdx, rax
	;mov rax, SYS_WRITE
	;mov rdi, STDOUT
	;mov rsi, request_data 
	;syscall

	;mov rax, SYS_WRITE
	;mov rdi, STDOUT
	;mov rsi, end_of_request_msg
	;mov rdx, end_of_request_msg_len
	;syscall

	call erase_http_header
	call erase_file_data_buffer
	call erase_http_filename
	mov rdi, request_data
	add rdi, 4
	mov rbx, 0x00
	mov rsi, http_filename
	copy_filename_loop:
		cmp [rdi], byte 0x00
		je error
		cmp [rdi], byte " "
		je continue_read_procedure
		mov al, [rdi]
		mov [rsi], al
		inc rdi
		inc rbx
		inc rsi
		cmp rbx, URL_MAX_LENGTH
		jg error
		jmp copy_filename_loop
	continue_read_procedure:
	mov [rsi], byte 0x00

	mov rax, SYS_WRITE
	mov rdi, STDOUT
	mov rsi, http_filename
	mov rdx, URL_MAX_LENGTH
	syscall

	call check_filename_root_replace_index
	; Open and reads http_filename

	mov rax, SYS_OPEN
	mov rdi, http_filename
	inc rdi
	mov rsi, 0x00
	mov rdx, 0x00
	syscall

	cmp rax, 0
	jl file_error
	jmp read_file_data
	file_error:
		cmp rax, -2
		je enoent_http
		jmp error
		enoent_http:
			mov rax, 404
			call load_http_status
			; Send a blank 2048 byte page with 404 status code
			mov rax, SYS_WRITE
			mov rdi, [client_socket_fd]
			mov rsi, http_header
			mov rdx, 2048
			syscall
			; Close socket connection
			mov rax, SYS_CLOSE
			mov rdi, [client_socket_fd]
			syscall
			jmp accept_connection

	read_file_data:
	mov rdi, rax
	mov rax, SYS_READ
	mov rsi, file_data
	sub rsi, header_len
	add rsi, ok_header_len
	mov rdx, MAX_DATA_LENGTH
	syscall

	cmp rax, 0
	jl error

	mov r10, rax
	mov rax, 200
	call load_http_status
	mov rax, r10
	; Send back the web page

	mov rdi, [client_socket_fd]
	mov rsi, http_header
	mov rdx, rax
	add rdx, ok_header_len
	mov rax, SYS_WRITE
	syscall

	mov rax, SYS_CLOSE
	mov rdi, [client_socket_fd]
	syscall

jmp accept_connection

	mov rax, SYS_EXIT
	mov rdi, 0x00
	syscall

	; ERREUR

	error:
	mov [errno], rax
	mov rax, SYS_WRITE
	mov rdi, STDERR
	mov rsi, message_error
	mov rdx, message_error_len
	syscall

	mov rax, SYS_EXIT
	mov rdi, [errno]
	syscall

erase_http_filename:
	mov rax, http_filename
	mov rbx, 0x00
	e_hfn_loop:
		mov [rax], byte 0x00
		inc rbx
		inc rax
		cmp rbx, URL_MAX_LENGTH
		jle e_hfn_loop
	ret

erase_file_data_buffer:
	mov rbx, 0
	mov rax, file_data
	e_fdata_loop:
		mov [rax], byte 0x00
		inc rax
		inc rbx
		cmp rbx, 2048
		jne e_fdata_loop
	ret
erase_http_header:
	; http_header_length = 30
	mov rax, http_header
	xor rbx, rbx
	ehttp_header_loop:
		mov [rax], byte 0x00
		inc rax
		inc rbx
		cmp rbx, header_len
		jg ehttp_header_end
		jmp ehttp_header_loop
	ehttp_header_end:
		ret
load_http_status:
	; RAX => Status code [200 for OK header, 404 for not found header] Other values will do nothing
	cmp rax, 200
	je lhs_ok
	cmp rax, 404
	je lhs_nf
	jmp lhs_end
	lhs_ok:
		mov rax, ok_header
		mov rcx, ok_header_len
		mov rbx, 0
		mov r8, http_header
		lhs_ok_loop:
			xor r9, r9
			mov r9b, byte [rax]
			mov [r8], r9b
			inc rax
			inc r8
			inc rbx
			cmp rbx, rcx
			je lhs_end
			jmp lhs_ok_loop
	lhs_nf:
		mov rax, not_found_header
		mov rcx, not_found_header_len
		mov rbx, 0
		mov r8, http_header
		lhs_nf_loop:
			xor r9, r9
			mov r9b, byte [rax]
			mov [r8], r9b
			inc rax
			inc r8
			inc rbx
			cmp rbx, rcx
			jg lhs_end
			jmp lhs_nf_loop
	lhs_end:
		ret

check_filename_root_replace_index:
	mov rax, http_filename
	mov bl, byte [rax]
	mov rcx, 0x00 ; 0 if needs replacement 1 otherwise
	mov rsi, 0x01 ; Pointer
	cfrri_loop:
		add rax, rsi
		mov bl, byte [rax]
		cmp bl, 0x00
		je cfrri_continue
		cmp bl, byte "/"
		jne cfrri_end_ok
		inc rsi
	cfrri_continue:
		mov rax, http_filename
		xor rsi, rsi ; Pointer <= http_default_name_len
		xor rbx, rbx
		mov rcx, http_default_name
		cfrri_copy_loop:
			mov bl, byte [rcx]
			mov [rax], bl
			inc rsi
			inc rax
			inc rcx
			cmp rsi, http_default_name_len
			jg cfrri_end_not_ok
			jmp cfrri_copy_loop
	cfrri_end_ok:
		ret
	cfrri_end_not_ok:
		mov [rax], byte 0x00	; Add the null byte to terminate filename
		ret
