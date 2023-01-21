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

struc sockaddr_in
	.sin_family resw 1
	.sin_port resw 1
	.sin_addr resd 1
	.sin_zero resb 8
endstruc

section .data
http_header: db "HTTP/1.1 200 OK", 0xd, 0xa, 0xa
header_len: equ $ - http_header
file_data: times 2048 db 0

request_data: times 2048 db 0

message_error: db "An error occured !", 0xa
message_error_len: equ $ - message_error

http_filename: db "index.html", 0x00

socket_addr:
		dw 2 ; AF_INET
		dw 0x411f ; Port 8001 in host byte order
		dd 0x00 ; INADDR_ANY
		dd 0, 0
socket_addri_len: equ $ - socket_addr

socket_fd: dd 0
client_socket_fd: dd 0
errno: dq 0


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

	mov [socket_fd], dword rax

	mov rax, SYS_BIND
	mov dword rdi, [socket_fd]
	mov rsi, socket_addr
	mov rdx, socket_addri_len
	syscall

	cmp rax, 0
	jl error

	mov rax, SYS_LISTEN
	mov dword rdi, [socket_fd]
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

	mov [client_socket_fd], dword rax

	; Let's print out what the socket has

	mov rdi, rax
	mov rax, SYS_READ
	mov rsi, request_data
	mov rdx, 2048
	syscall

	cmp rax, 0x00
	jl error
	
	mov rdx, rax
	mov rax, SYS_WRITE
	mov rdi, STDOUT
	mov rsi, request_data 
	syscall

	; Open and reads index.html

	mov rax, SYS_OPEN
	mov rdi, http_filename
	; inc rdi
	mov rsi, 0x00
	mov rdx, 0x00
	syscall

	cmp rax, 0
	jl error


	mov rdi, rax
	mov rax, SYS_READ
	mov rsi, file_data
	mov rdx, 2048
	syscall

	cmp rax, 0
	jl error

	; Send back the web page

	mov rdi, [client_socket_fd]
	mov rsi, http_header
	mov rdx, header_len
	add rdx, rax
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

print:
	pusha
	mov rax, SYS_WRITE
	mov rdi, STDOUT
	syscall
	popa
	ret
is_in:
	; rax : buffer
	; rdi : substring
	; rsi : substring length
	; rdx : buffer_length
	; Returns rax => position in buffer or -1 if doesn't exist
	
