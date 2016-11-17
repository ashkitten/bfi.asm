.SILENT:

bf-interpreter: bf-interpreter.s
	nasm -f elf -F dwarf -g bf-interpreter.s
	ld -m elf_i386 -o bf-interpreter bf-interpreter.o --whole-archive

run: bf-interpreter
	./bf-interpreter

stripped: bf-interpreter.s
	nasm -f elf -F dwarf bf-interpreter.s
	ld -m elf_i386 -s -o bf-interpreter bf-interpreter.o
