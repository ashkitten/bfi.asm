.SILENT:

bf-interpreter: bf-interpreter.s
	nasm -f bin -o bf-interpreter -l bf-interpreter.list bf-interpreter.s
	chmod +x bf-interpreter

run: bf-interpreter
	./bf-interpreter

.PHONY: clean

clean:
	rm bf-interpreter
