%{
#define YYSTYPE double
#include <stdio.h>
#include "astnode.h"
%}

%union {
	struct astnode* astnode_p
}

%type <astnode_p> binary_expr
%token <astnode_p> NUM

%%
binary_expr: NUM {
		$$ = astnode_alloc(AST_num);
		struct astnode_num *n = &($$->u.num);	
	}
	|binary_expr '+' NUM {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = '+';
		n->left = $1;
		n->right = $3;
	}
%%

int main(){
	printf(">");
	return yyparse();
}
