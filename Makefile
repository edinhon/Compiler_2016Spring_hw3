all:
	flex scanner.l
	byacc -d -v parser.y
	gcc -c symbol_table.c
	gcc -o codegen lex.yy.c y.tab.c symbol_table.o
clean:
	rm -f lex.yy.c codegen y.tab.h y.tab.c y.output
