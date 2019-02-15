%{
#include <stdio.h>
#include <stdlib.h>
#include "astnode.h"

//#define YYDEBUG 1
%}

%left '+'
%left '-'
%nonassoc '|'

%union {
	struct astnode* astnode_p;
	char *s;
	long long int i;
}

%type <astnode_p> binary_expr
%token <i> NUMBER
%token <s> IDENT
%token 	CHARLIT
%token 	STRING
%token 	INDSEL
%token 	PLUSPLUS
%token 	MINUSMINUS
%token 	SHL
%token 	SHR
%token 	LTEQ
%token 	GTEQ
%token 	EQEQ
%token 	NOTEQ
%token 	LOGAND
%token 	LOGOR
%token 	ELLIPSIS
%token 	TIMESEQ
%token 	DIVEQ
%token 	MODEQ
%token 	PLUSEQ
%token 	MINUSEQ
%token 	SHLEQ
%token 	SHREQ
%token 	ANDEQ
%token 	OREQ
%token 	XOREQ
%token 	AUTO
%token 	BREAK
%token 	CASE
%token 	CHAR
%token 	CONST
%token 	CONTINUE
%token 	DEFAULT
%token 	DO
%token 	DOUBLE
%token 	ELSE
%token 	ENUM
%token 	EXTERN
%token 	FLOAT
%token 	FOR
%token 	GOTO
%token 	IF
%token 	INLINE
%token 	INT
%token 	LONG
%token 	REGISTER
%token 	RESTRICT
%token 	RETURN
%token 	SHORT
%token 	SIGNED
%token 	SIZEOF
%token 	STATIC
%token 	STRUCT
%token 	SWITCH
%token 	TYPEDEF
%token 	UNION
%token 	UNSIGNED
%token 	VOID
%token 	VOLATILE
%token 	WHILE
%token 	_BOOL
%token 	_COMPLEX
%token 	_IMAGINARY
%token EOL

%type <astnode_p> prime_expr;

%%
expr:	//Nothing
	| expr binary_expr EOL {
		print_tree($2, 0);
		tree_free($2);
	}
prime_expr:	
	IDENT {
		$$ = astnode_alloc(AST_ident);
		$$->u.name = $1;
	}
	| NUMBER {
		$$ = astnode_alloc(AST_num);
		struct astnode_num *n = &($$->u.num);
		n->value = $1;
	}
	| '(' prime_expr ')' {
		$$ = $2;
	}
	

binary_expr: 	binary_expr '+' binary_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = '+';
		n->left = $1;
		n->right = $3;
	}
	| NUMBER {
		$$ = astnode_alloc(AST_num);
		struct astnode_num *n = &($$->u.num);
		n->value = $1;
	};
%%

yyerror(char *s){
	fprintf(stderr, " %d\terror: %s\n", yylineno, s);
	exit(1);
}

int main(){
	printf("> ");
	//yydebug=1;
	return yyparse();
}
