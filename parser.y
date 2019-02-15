%{
#include <stdio.h>
#include <stdlib.h>
#include "astnode.h"

//#define YYDEBUG 1
%}


%left ','
%right '='
%right '?' ':'
%left '+' '-'
%left '*' '/' '%'
%left '(' ')'
%left '[' ']'
%nonassoc '|'

%union {
	struct astnode* astnode_p;
	char *s;
	long long int i;
}

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

%type <astnode_p> additive_expr;
%type <astnode_p> multipli_expr;
%type <astnode_p> cast_expr;
%type <astnode_p> prime_expr;
%type <astnode_p> unary_expr;
%type <astnode_p> assignment_expr;
%type <astnode_p> argu_expr_list;
%type <astnode_p> postfix_expr;

%%
expr:	//Nothing
	| expr additive_expr EOL {
		print_tree($2, 0);
		tree_free($2);
	}
	;

prime_expr:	
	IDENT {
		$$ = astnode_alloc(AST_ident);
		$$->u.ident.name = $1;
	}
	| NUMBER {
		$$ = astnode_alloc(AST_num);
		struct astnode_num *n = &($$->u.num);
		n->value = $1;
	}
	| '(' prime_expr ')' {
		$$ = $2;
	}
	;

unary_expr:
	postfix_expr {

	}
	;

argu_expr_list:
	assignment_expr
	| argu_expr_list ',' assignment_expr {

	}
	;

assignment_expr:
	unary_expr '=' assignment_expr {;}
	;

postfix_expr:
	prime_expr {;}
	| postfix_expr '[' expr ']' {;}
	| postfix_expr '(' argu_expr_list ')' {

	}
	;

additive_expr:
	multipli_expr {;}
	| additive_expr '+' multipli_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = '+';
		n->left = $1;
		n->right = $3;
	}
	;

multipli_expr: cast_expr {}
	| multipli_expr '*' cast_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = '*';
		n->left = $1;
		n->right = $3;
	}
	;

cast_expr:
	unary_expr{}
	;

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
