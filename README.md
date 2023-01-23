# network-server-asm
This is just a random project to prove the insane superiority of low-level programming languages over high-level garbage (especially JavaScript).
> This is just a simple http web server, do whatever the fuck you want with it, I don't care.
Not suitable for production

Thanks to that project I have been able to elevate, and join the elite supremacy of low-level networking sigma along with jdh, low level learning and countless others.<br>
> May the force of assembly be with you, and never dare use high-level shitty language ever again.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# How the hell can I use it ?
Well, first you need an assembler, here I used the Netwide Assembler on linux also known as NASM.
You assemble it using this command : <br>
    nasm -f elf64 -o object_file.o network.asm
And then you link it : <br>
    ld -o network object_file.o
 
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# How does it work ?
By default it supplies the client with what it wrote in the URL, e.g if the url is (whatever the fuck your ip is):8001/bollocks.gay it will gently send back the file bollocks.gay and if does not exists, it will just send a 2048 null-bytes blank packet with the http header corresponding to the 404 status code. It only supports basic http requests. Don't try to send weirdass requests, it will probably just bug out, and if not just trigger a segmentation fault. When a blank HTTP request is sent (with the path "/"), it supplies the client with a file named index.html. If there aren't no file named like that, it will just send back a blank packet of 2048 bytes with the http header corresponding to the status code 404. It has no way of excluding folders and file at the moment therefore making it unsuitable for any kind of use other than flexing over virgin JavaScript/PHP users.

Why a blank packet of 2048 bytes, you may ask ? Well it's beacause I'm planning for support of 404 html pages but for the moment it's just null-bytes. If you're not happy with it, as I said earlier, I don't give a fuck. 

If you share my point of you and also hate new-age "programmer" then you and I will be friend.

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

