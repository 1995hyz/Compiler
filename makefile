test:	scanner.l parser.y astnode.h
	bison -d -v parser.y
	flex -o lex.yy.c scanner.l
	gcc -o $@ parser.tab.c lex.yy.c astnode.c symTable.c

debug:	scanner.l parser.y astnode.h
	bison -d -v parser.y
	flex -o lex.yy.c scanner.l
	gcc -g -o $@ parser.tab.c lex.yy.c astnode.c symTable.c

clean:
	rm -f test lex.yy.c parser.tab.h parser.tab.c parser.output debug
