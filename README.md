A brainfuck interpreter written in pure x86 assembly. The assembled binary is a mere 208 bytes.

# About

Brainfuck is an [esoteric programming language](https://en.wikipedia.org/wiki/Esoteric_programming_language) designed
for extreme minimalism. Its programs consist of eight distinct characters which perform operations on an array in
memory. It was created by Urban Müller in 1992 for the Amiga family of personal computers with the goal of having the
smallest compiler possible. In fact, the compiler he wrote has an executable size of just 240 bytes!

This project was designed not with the goal of creating the smallest compiler possible, but to create the smallest
*interpreter* possible. While there are definitely optimizations I could still make, this is likely as small as it
will get without much work.

To execute a brainfuck program with this interpreter, first build it with `make`. You can then pass it a program along
with input via stdin. The interpreter reads two lines from stdin - the first is the program, and the second is the
input.

# Examples

To run these examples, write them to a file and then pipe it into the program: `cat hello.b | ./bf-interpreter`

Here is the classical example of a program that simply prints "Hello, World!" and a newline:
```brainfuck
++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.
```
Note that this example has no second line. The "Hello, World!" example does not read input, but there are certainly
programs that do. The simplest of these is a `cat` program, one that reads from input and prints it to stdout. The
simplest `cat` program is this:
```brainfuck
,[.,]
This input will appear on stdout!
```
The program above will print "This input will appear on stdout!" to the terminal.

# Limitations

- Programs **must** be on one line, with the second line being the input. This means that most `.b` files you find
online will need to be edited in order to work with this interpreter.

# Credits
- Me (duh)
- [Blackle Mori](https://github.com/blackle): helped messing with the ELF header
- My dad wanted to be mentioned in the credits so yeah

# Similar projects
- [C0dehero's brainfuck interpreter, written for the x86_64 platform](https://github.com/C0DEHERO/brainfuck.asm)
