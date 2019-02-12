%{
#define YYSTYPE double
#include <stdio.h>
#include "astnode.h"
%}

%union {
	struct astnode *astnode_p
}

%type <astnode_p> binary_expr

%%
binary_expr:
	binary '+' binary_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = '+';
		n->left = $1;
		n->right = $3;
	}
%%
