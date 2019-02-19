%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "astnode.h"

#define YYDEBUG 1
%}

%union {
	struct astnode* astnode_p;
	char *s;
	long long int i;
}

%token <i> NUMBER
%token <s> IDENT
%token <i> CHARLIT
%token <s> STRING
%token 	INDSEL
%token 	PLUSPLUS
%token 	MINUSMINUS
%token <s> SHL
%token <s> SHR
%token <s> LTEQ
%token <s> GTEQ
%token <s> EQEQ
%token <s> NOTEQ
%token <s> LOGAND
%token <s> LOGOR
%token 	ELLIPSIS
%token <s> TIMESEQ
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

%left ','
%right TIMESEQ
%right '='
%right '?' ':'
%left LOGOR
%left LOGAND
%left '|'
%left '^'
%left '&'
%left EQEQ NOTEQ
%left '>' '<' LTEQ GTEQ
%left SHL SHR
%left '+' '-'
%left '*' '/' '%'
%left '(' ')'
%left '[' ']'

/*%type <astnode_p> expr;*/
%type <astnode_p> additive_expr;
%type <astnode_p> multipli_expr;
%type <astnode_p> cast_expr;
%type <astnode_p> prime_expr;
%type <astnode_p> unary_expr;
%type <astnode_p> argu_expr_list;
%type <astnode_p> postfix_expr;
%type <astnode_p> shift_expr;
%type <astnode_p> relational_expr;
%type <astnode_p> equality_expr;
%type <astnode_p> and_expr;
%type <astnode_p> excl_or_expr;
%type <astnode_p> incl_or_expr;
%type <astnode_p> log_and_expr;
%type <astnode_p> log_or_expr;
%type <astnode_p> conditional_expr;
%type <astnode_p> assignment_expr;

%%
expr:	//Nothing	
	| expr assignment_expr EOL {
		//$$ = $1;
		print_tree($2, 0);
		tree_free($2);
	}
	/*| expr ',' assignment_expr EOL {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = ',';
		n->left = $1;
		n->right = $3;
	}*/
	;

prime_expr:	
	IDENT {
		$$ = astnode_alloc(AST_ident);
		strncpy($$->u.ident.name, $1, 1024);
	}
	| NUMBER {
		$$ = astnode_alloc(AST_num);
		struct astnode_num *n = &($$->u.num);
		n->value = $1;
	}
	| CHARLIT {
		$$ = astnode_alloc(AST_num);
		struct astnode_num *n = &($$->u.num);
		n->value = $1;
	}
	| STRING {
		$$ = astnode_alloc(AST_string);
		struct astnode_string *n = &($$->u.string);
		strncpy(n->value, $1, 1024);
	}
	| '(' prime_expr ')' {
		$$ = $2;
	}
	;

unary_expr:
	postfix_expr { $$ = $1; }
	| '&' cast_expr {
		$$ = astnode_alloc(AST_unary);
		struct astnode_unaop *n = &($$->u.unaop);
		n->operator = '&';
		n->left = NULL;
		n->right = $2;
	}
	| '*' cast_expr {
		$$ = astnode_alloc(AST_unary);
		struct astnode_unaop *n = &($$->u.unaop);
		n->operator = '*';
		n->left = NULL;
		n->right = $2;
	}
	| '+' cast_expr {
		$$ = astnode_alloc(AST_unary);
		struct astnode_unaop *n = &($$->u.unaop);
		n->operator = '+';
		n->left = NULL;
		n->right = $2;
	}
	| '-' cast_expr {
		$$ = astnode_alloc(AST_unary);
        	struct astnode_unaop *n = &($$->u.unaop);
		n->operator = '-';
		n->left = NULL;
		n->right = $2;
	}
	| '~' cast_expr {
		$$ = astnode_alloc(AST_unary);
                struct astnode_unaop *n = &($$->u.unaop);
		n->operator = '~';
		n->left = NULL;
		n->right = $2;
	}
	| '!' cast_expr {
		$$ = astnode_alloc(AST_unary);
		struct astnode_unaop *n = &($$->u.unaop);
		n->operator = '~';
		n->left = NULL;
		n->right = $2;
	}
	;

argu_expr_list:
	assignment_expr
	| argu_expr_list ',' assignment_expr {

	}
	;

postfix_expr:
	prime_expr {$$ = $1;}
	| postfix_expr '[' expr ']' {;}
	| postfix_expr '(' argu_expr_list ')' {

	}
	;

additive_expr:
	multipli_expr { $$ = $1;}
	| additive_expr '+' multipli_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = '+';
		n->left = $1;
		n->right = $3;
	}
	| additive_expr '-' multipli_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = '-';
		n->left = $1;
		n->right = $3;
	}
	;

multipli_expr: 
	cast_expr { $$ = $1;}
	| multipli_expr '*' cast_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = '*';
		n->left = $1;
		n->right = $3;
	}
	| multipli_expr '/' cast_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = '/';
		n->left = $1;
		n->right = $3;
	}
	| multipli_expr '%' cast_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = '%';
		n->left = $1;
		n->right = $3;
	}
	;

cast_expr: 
	unary_expr{ $$ = $1;}
	;

shift_expr: 
	additive_expr	{ $$ = $1; }
	| shift_expr SHL additive_expr
	{	$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = SHL;
		n->left = $1;
		n->right = $3;
	}
	| shift_expr SHR additive_expr
	{	$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = SHR;
		n->left = $1;
		n->right = $3;
	};

relational_expr:
	shift_expr { $$ = $1; }
	| relational_expr '>' shift_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = '>';
		n->left = $1;
                n->right = $3;
	}
	| relational_expr '<' shift_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = '<';
		n->left = $1;
		n->right = $3;
	}
	| relational_expr LTEQ shift_expr{
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = LTEQ;
		n->left = $1;
		n->right = $3;
	}
	| relational_expr GTEQ shift_expr{
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = GTEQ;
		n->left = $1;
		n->right = $3;
	}
	;

equality_expr:
	relational_expr { $$ = $1; }
	| equality_expr EQEQ relational_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop); 	
		n->operator = EQEQ;
		n->left = $1;
		n->right = $3;
	}
	| equality_expr NOTEQ relational_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop); 
		n->operator = NOTEQ;
		n->left = $1;
		n->right = $3;
	}
	;

and_expr:
	equality_expr { $$ = $1; }
	| and_expr '&' equality_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop); 
		n->operator = '&';
		n->left = $1;
		n->right = $3; 	
	}
	;

excl_or_expr:
	and_expr { $$ = $1; }
	| excl_or_expr '^' and_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop); 
		n->operator = '^';
		n->left = $1;
		n->right = $3; 
	}
	;

incl_or_expr:
	excl_or_expr { $$ = $1; }
	| incl_or_expr '|' excl_or_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = '|';
		n->left = $1;
		n->right = $3;
	}
	;

log_and_expr:
	incl_or_expr { $$ = $1; }
	| log_and_expr LOGAND incl_or_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = LOGAND;
		n->left = $1;
		n->right = $3;
	}
	;

log_or_expr:
	log_and_expr { $$ = $1; }
	| log_or_expr LOGOR log_and_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = LOGOR;
		n->left = $1;
		n->right = $3;
	}
	;

conditional_expr:
	log_or_expr { $$ = $1; }
	;

assignment_expr:
	conditional_expr { $$ = $1; }
	| unary_expr '=' assignment_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = '=';
		n->left = $1;
		n->right = $3;
	}
	| unary_expr TIMESEQ assignment_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = '*';
		n->left = $1;
		n->right = $3;
		$3 = $$;
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *m = &($$->u.binop);
		m->operator = '=';
		m->left = $1;
		m->right = $3;
	}
	| unary_expr DIVEQ assignment_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = '/';
		n->left = $1;
		n->right = $3;
		$3 = $$;
		$$ = astnode_alloc(AST_binop);
                struct astnode_binop *m = &($$->u.binop);
		m->operator = '=';
		m->left = $1;
		m->right = $3;
	}
	| unary_expr MODEQ assignment_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = '%';
		n->left = $1;
		n->right = $3;
		$3 = $$;
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *m = &($$->u.binop);
		m->operator = '=';
		m->left = $1;
		m->right = $3;
	}
	| unary_expr PLUSEQ assignment_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = '+';
		n->left = $1;
		n->right = $3; 	
		$3 = $$;
	        $$ = astnode_alloc(AST_binop);
                struct astnode_binop *m = &($$->u.binop);
		m->operator = '=';
		m->left = $1;
		m->right = $3;
	}
	| unary_expr MINUSEQ assignment_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = '-';
		n->left = $1;
		n->right = $3; 	
		$3 = $$;
	        $$ = astnode_alloc(AST_binop);
                struct astnode_binop *m = &($$->u.binop);
		m->operator = '=';
		m->left = $1;
		m->right = $3;
	}	
	;

%%

yyerror(char *s){
	fprintf(stderr, " %d\terror: %s\n", yylineno, s);
	exit(1);
}

int main(){
	printf("> ");
	yydebug=1;
	return yyparse();
}
