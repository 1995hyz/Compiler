test:	scanner.l parser.y astnode.h
	bison -d -v parser.y
	flex -o lex.yy.c scanner.l
	gcc -o $@ parser.tab.c lex.yy.c astnode.c
