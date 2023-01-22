# network-server-asm
This is just a random project to prove the insane superiority of low-level programming languages over high-level garbage (especially JavaScript).
> This is just a simple http web server, do whatever the fuck you want with it, I don't care.
Not suitable for production

Thanks to that project I have been able to elevate, and join the elite supremacy of low-level networking sigma along with jdh, low level learning and countless others.<br>
> May the force of assembly be with you, and never dare use high-level shitty language ever again.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# How the hell can I use it ?
Well, first you need an assembler, here I used the Netwide Assembler on linux also known as NASM.
You assemble it using this command :
    nasm -f elf64 -o object_file.o network.asm
And then you link it
    ld -o network object_file.o

Note :
I know about the warnings that say "register size blah blah blah", I don't care, I just wrote somewhere something like
    mov [smth], byte al
I did it for readability purpose. You don't like it, I don't care
