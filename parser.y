%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "astnode.h"
#include "symTable.h"
#include "genquad.h"

//#define YYDEBUG 1

struct astnode* front;
struct astnode* end;
struct sym_table *curr_scope;
extern char file_name[1024];
int storage_class;
int func_counter;

%}

%union {
	struct astnode* astnode_p;
	char *s;
	char arr[1024];
	long long int i;
	int j;
}

%left IF
%left ELSE

%token <i> NUMBER
%token <arr> IDENT
%token <i> CHARLIT
%token <s> STRING
%token 	INDSEL
%token <s> PLUSPLUS
%token <s> MINUSMINUS
%token <s> SHL
%token <s> SHR
%token <s> LTEQ
%token <s> GTEQ
%token <j> EQEQ
%token <j> NOTEQ
%token <s> LOGAND
%token <s> LOGOR
%token 	ELLIPSIS
%token <s> TIMESEQ
%token <s> DIVEQ
%token <s> MODEQ
%token <s> PLUSEQ
%token <s> MINUSEQ
%token <s> SHLEQ
%token <s> SHREQ
%token <s> ANDEQ
%token <s> OREQ
%token <s> XOREQ
%token <j> AUTO
%token <j> BREAK
%token <j> CASE
%token <j> CHAR
%token <j> CONST
%token <j> CONTINUE
%token <j> DEFAULT
%token <j> DO
%token <j> DOUBLE
%token <j> ELSE
%token 	ENUM
%token <j> EXTERN
%token <j> FLOAT
%token 	FOR
%token <j> GOTO
%token <j> IF
%token 	INLINE
%token <j> INT
%token <j> LONG
%token 	REGISTER
%token <j> RESTRICT
%token <j> RETURN
%token <j> SHORT
%token <j> SIGNED
%token <j> SIZEOF
%token <j> STATIC
%token <j> STRUCT
%token <j> SWITCH
%token 	TYPEDEF
%token <j> UNION
%token <j> UNSIGNED
%token <j> VOID
%token <j> VOLATILE
%token <j> WHILE
%token <j> _BOOL
%token <j> _COMPLEX
%token 	_IMAGINARY
%token EOL

/*%start decl_or_stmt*/
%start decl_or_fndef_list;
%type <astnode_p> expr;
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
%type <astnode_p> constant_expr
%type <astnode_p> assignment_expr;
%type <astnode_p> declaration;
%type <astnode_p> type_specifier;
%type <astnode_p> type_qualifier;
%type <astnode_p> init_declarator_list;
%type <astnode_p> declaration_specifiers;
%type <astnode_p> declarator;
%type <astnode_p> direct_declarator;
%type <astnode_p> compound_statement;
%type <astnode_p> statement;
%type <astnode_p> pointer;
%type <astnode_p> type_qualifier_list;
%type <astnode_p> struct_or_union_specifier;
%type <astnode_p> struct_or_union;
%type <astnode_p> struct_declaration_list;
%type <astnode_p> struct_declaration;
%type <astnode_p> specifier_qualifier_list;
%type <astnode_p> struct_declarator_list;
%type <astnode_p> struct_declarator;
%type <astnode_p> decl_or_stmt;
%type <astnode_p> decl_or_stmt_list;
%type <astnode_p> expression_statement;
%type <astnode_p> selection_statement;
%type <astnode_p> iteration_statement;
%type <astnode_p> labeled_statement;
%type <astnode_p> jump_statement;
%type <astnode_p> init_for_expr;

%%

decl_or_fndef_list: 
	declaration_or_fndef {}
	| decl_or_fndef_list declaration_or_fndef {} 
	;
 
declaration_or_fndef: 
	declaration {
		//printf("*********\n");
		//print_table(curr_scope);
	}
	| function_definition {}
	;

function_definition:
	declaration_specifiers declarator '{' {
		struct sym_entry *finding = search_all(curr_scope, front->u.ident.name, FUNC_TYPE);
		if(finding == NULL) {
			astnode_link(&front, &end, $1);
			struct sym_entry *n = add_entry(front, curr_scope, file_name, yylineno);
			add_storage_class(n);
			//n->e.func.complete = 1;
			//print_entry(n, 0);
			front = NULL;
			end = NULL;
		}
		else if (finding->e.func.complete == 1) {
			yyerror("Function has already been defined");
		}
		else {
			front = NULL;
			end = NULL;
			finding->def_num = yylineno;
			strncpy(finding->def_file, file_name , 1024);
		}
		enter_scope(FUNC_SCOPE);
		strncpy(curr_scope->name, $2->u.ident.name, 1024); 
	}
	decl_or_stmt_list '}' {
		struct sym_table *temp = curr_scope;
		exit_scope();
		curr_scope->last->e.func.complete = 1;
		print_entry(curr_scope->last);
		
		if($5 != NULL) {
			printf("AST Dump for function\n");
			printf("LIST {\n");
			print_tree($5->u.blo.start, 0);
			printf(" }\n");
			printf("************************\n");
			gen_init($5->u.blo.start, temp, func_counter);
			func_counter++;
			printf("************************\n");
		}
	}
	;

compound_statement:
	'{' { enter_scope(BLOCK_SCOPE); } decl_or_stmt_list '}' {
		exit_scope();
		$$ = astnode_alloc(AST_compound);
		$$->u.comp.list = $3->u.blo.start;
	}
	;

decl_or_stmt_list:
	decl_or_stmt {
		if($1 != NULL) {
			$1->u.blo.start = $1;
			$$ = $1;
		}
		else {
			$$ = NULL;
		}
	}
	| decl_or_stmt_list decl_or_stmt {
		if($1 != NULL && $2 != NULL) {
			$1->u.blo.next_block = $2;
			$2->u.blo.start = $1->u.blo.start;
			$$ = $2;
		}
		else if ($1 != NULL) {
			$$ = $1;
		}
		else if ($2 != NULL){
			$2->u.blo.start = $2;
			$$ = $2;
		}
		else {
			$$ = NULL;
		}
	}
	;

decl_or_stmt:
	declaration { $$ = NULL; }
	| statement {
		//print_tree($1, 0);
		$$ = astnode_alloc(AST_block);
		struct astnode_block *n = &($$->u.blo);
		n->item = $1;
	}
	;

statement:
	labeled_statement { $$ = $1; }
	| compound_statement { $$ = $1; }
	| expression_statement { $$ = $1; }
	| selection_statement { $$ = $1; }
	| iteration_statement { $$ = $1; }
	| jump_statement { $$ = $1; }
	;

labeled_statement:
	IDENT ':' statement {
		struct astnode *temp = astnode_alloc(AST_ident);
		struct astnode_ident *n = &(temp->u.ident);
		strncpy(temp->u.ident.name, $1, 1024);
		n->ident_type = LABEL_TYPE;
		struct sym_entry *finding = search_all(curr_scope, $1, LABEL_TYPE);
		if( finding == NULL ){
			struct sym_entry *i = add_entry(temp, curr_scope, file_name, yylineno);
			n->entry = i;
		}
		else {
			strncpy(finding->def_file, file_name, 1024);
			finding->def_num = yylineno;
			n->entry = finding;
		}
		$$ = astnode_alloc(AST_label);
		struct astnode_label *t = &($$->u.label_node);
		t->ident = temp;
		t->body = $3;
	}
	| CASE constant_expr ':' statement {
		$$ = astnode_alloc(AST_case);
		struct astnode_case *n = &($$->u.case_node);
		n->expr = $2;
		n->body = $4;
	}
	| DEFAULT ':' statement {
		$$ = astnode_alloc(AST_default);
		struct astnode_default *n = &($$->u.default_node);
		n->body = $3;
	}
	;

expression_statement:
	';' { $$ = NULL; }
	| expr ';' { $$ = $1; }
	;

selection_statement:
	IF '(' expr ')' statement %prec IF {
		$$ = astnode_alloc(AST_if);
		struct astnode_if *n = &($$->u.if_node);
		n->expr = $3;
		n->if_body = $5;
	}
	| IF '(' expr ')' statement ELSE statement %prec ELSE {
		$$ = astnode_alloc(AST_if);
		struct astnode_if *n = &($$->u.if_node);
		n->expr = $3;
		n->if_body = $5;
		n->else_body = $7;
	}
	| SWITCH '(' expr ')' statement {
		$$ = astnode_alloc(AST_switch);
		struct astnode_switch *n = &($$->u.switch_node);
		n->expr = $3;
		n->body = $5;
	}
	;

iteration_statement:
	WHILE '(' expr ')' statement {
		$$ = astnode_alloc(AST_while);
		struct astnode_while *n = &($$->u.while_node);
		n->expr = $3;
		n->body = $5;
	}
	| DO statement WHILE '(' expr ')' ';' {
		$$ = astnode_alloc(AST_do);
		struct astnode_do *n = &($$->u.do_node);
		n->expr = $5;
		n->body = $2;
	}
	| FOR '(' init_for_expr ';' init_for_expr ';' init_for_expr ')' statement {
		$$ = astnode_alloc(AST_for);
		struct astnode_for *n = &($$->u.for_node);
		n->init = $3;
		n->cond = $5;
		n->incr = $7;
		n->body = $9;
	}
	;

init_for_expr:
	| expr { }
	;

jump_statement:
	GOTO IDENT ';' {
		$$ = astnode_alloc(AST_goto);
		$$->u.goto_node.ident = astnode_alloc(AST_ident);
		strncpy($$->u.goto_node.ident->u.ident.name, $2, 1024);
		struct sym_entry *finding = search_all(curr_scope, $2, LABEL_TYPE);
		if( finding == NULL ) {
			struct astnode *temp = astnode_alloc(AST_ident);
			struct astnode_ident *n = &(temp->u.ident);
			strncpy(temp->u.ident.name, $2, 1024);
			n->ident_type = LABEL_TYPE;
			struct sym_entry *i = add_entry(temp, curr_scope, file_name, yylineno);
			$$->u.goto_node.ident->u.ident.entry = i;
		}
		else {
			$$->u.goto_node.ident->u.ident.entry = finding;
		}
	}
	| CONTINUE ';' {
		$$ = astnode_alloc(AST_continue);
	}
	| BREAK ';' {
		$$ = astnode_alloc(AST_break);
	}
	| RETURN ';' {
		$$ = astnode_alloc(AST_return);
		$$->u.return_node.expr = NULL;
	}
	| RETURN expr ';' {
		$$ = astnode_alloc(AST_return);
		$$->u.return_node.expr = $2;
	}
	;

expr:	
	assignment_expr {
		$$ = $1;
		//print_tree($2, 0);
		//tree_free($2);
	}
	| expr ',' assignment_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = ',';
		n->left = $1;
		n->right = $3;
	}
	;

prime_expr:	
	IDENT {
		$$ = astnode_alloc(AST_ident);
		strncpy($$->u.ident.name, $1, 1024);
		$$->u.ident.entry = search_all(curr_scope, $1, VAR_TYPE);
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
	| '(' expr ')' {
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
	| PLUSPLUS unary_expr {
		struct astnode *temp1 = astnode_alloc(AST_num);
		temp1->u.num.value = 1;
		struct astnode *temp2 = astnode_alloc(AST_binop);
		struct astnode_binop *n = &(temp2->u.binop);
		n->operator = '+';
		n->left = $2;
		n->right = temp1; 	
	        $$ = astnode_alloc(AST_binop);
                struct astnode_binop *m = &($$->u.binop);
		m->operator = '=';
		m->left = $2;
		m->right = temp2;
	}
	| MINUSMINUS unary_expr {
		struct astnode *temp1 = astnode_alloc(AST_num);
		temp1->u.num.value = 1;
		struct astnode *temp2 = astnode_alloc(AST_binop);
		struct astnode_binop *n = &(temp2->u.binop);
		n->operator = '-';
		n->left = $2;
		n->right = temp1; 	
	        $$ = astnode_alloc(AST_binop);
                struct astnode_binop *m = &($$->u.binop);
		m->operator = '=';
		m->left = $2;
		m->right = temp2;
	}
	| SIZEOF unary_expr {
		$$ = astnode_alloc(AST_unary);
		struct astnode_unaop *n = &($$->u.unaop);
		n->operator = SIZEOF;
		n->left = NULL;
		n->right = $2;
	}
	;

argu_expr_list:
	assignment_expr { 
		$$ = astnode_alloc(AST_argu);
		$$->u.argu.next = NULL;
		$$->u.argu.num = 1;
		$$->u.argu.start = $$;
		$$->u.argu.value = $1;
		//($0->u.func->num)++;
	}
	| argu_expr_list ',' assignment_expr {
		$$ = astnode_alloc(AST_argu);
		struct astnode_argu *n = &($$->u.argu);
		n->next = NULL;
		n->value = $3;
		n->num = ($1->u.argu.num)+1;
		n->start = ($1->u.argu.start);
		$1->u.argu.next = $$;
		//($0->u.func->num)++;
	}
	;

postfix_expr:
	prime_expr {$$ = $1;}
	| postfix_expr '[' expr ']' {
		struct astnode *temp = astnode_alloc(AST_binop);
		struct astnode_binop *n = &(temp->u.binop);
		n->operator = '+';
		n->left = $1;
		n->right = $3;
		$$ = astnode_alloc(AST_unary);
		struct astnode_unaop *m = &($$->u.unaop);
		m->operator = '*';
		m->left = NULL;
		m->right = temp;
	}
	| postfix_expr '(' argu_expr_list ')' {
		$$ = astnode_alloc(AST_func);
		struct astnode_func *n = &($$->u.func);
		n->name = $1;
		n->next = $3->u.argu.start;
		n->num = 0;
		;
	}
	| postfix_expr PLUSPLUS {
		$$ = astnode_alloc(AST_unary);
		struct astnode_unaop *n = &($$->u.unaop);
		n->operator = PLUSPLUS;
		n->left = NULL;
		n->right = $1;
	}
	| postfix_expr MINUSMINUS {
		$$ = astnode_alloc(AST_unary);
		struct astnode_unaop *n = &($$->u.unaop);
		n->operator = MINUSMINUS;
		n->left = NULL;
		n->right = $1;
	}
	| postfix_expr '.' IDENT {
		$$ = astnode_alloc(AST_ident);
		strncpy($$->u.ident.name, $3, 1024);
		struct astnode* temp = $$;
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = '.';
		n->left = $1;
		n->right = temp;
	}
	| postfix_expr INDSEL IDENT {
		struct astnode *temp = astnode_alloc(AST_unary);
		struct astnode_unaop *m = &(temp->u.unaop);
		m->operator = '*';
		m->left = NULL;
		m->right = $1;
		struct astnode *temp_ident = astnode_alloc(AST_ident);
		strncpy(temp_ident->u.ident.name, $3, 1024);
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = '.';
		n->left = temp;
		n->right = temp_ident;
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
	| log_or_expr '?' expr ':' conditional_expr {
		$$ = astnode_alloc(AST_ternary);
		struct astnode_ternary *n = &($$->u.tern);
		n->first = $1;
		n->second = $3;
		n->third = $5;
	}
	;

constant_expr:
	conditional_expr { $$ = $1; }
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
	| unary_expr SHLEQ assignment_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = SHL;
		n->left = $1;
		n->right = $3; 	
		$3 = $$;
	        $$ = astnode_alloc(AST_binop);
                struct astnode_binop *m = &($$->u.binop);
		m->operator = '=';
		m->left = $1;
		m->right = $3;
	}
	| unary_expr SHREQ assignment_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = SHR;
		n->left = $1;
		n->right = $3; 	
		$3 = $$;
	        $$ = astnode_alloc(AST_binop);
                struct astnode_binop *m = &($$->u.binop);
		m->operator = '=';
		m->left = $1;
		m->right = $3;
	}
	| unary_expr ANDEQ assignment_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = '&';
		n->left = $1;
		n->right = $3; 	
		$3 = $$;
	        $$ = astnode_alloc(AST_binop);
                struct astnode_binop *m = &($$->u.binop);
		m->operator = '=';
		m->left = $1;
		m->right = $3;
	}
	| unary_expr XOREQ assignment_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = '^';
		n->left = $1;
		n->right = $3; 	
		$3 = $$;
	        $$ = astnode_alloc(AST_binop);
                struct astnode_binop *m = &($$->u.binop);
		m->operator = '=';
		m->left = $1;
		m->right = $3;
	}
	| unary_expr OREQ assignment_expr {
		$$ = astnode_alloc(AST_binop);
		struct astnode_binop *n = &($$->u.binop);
		n->operator = '|';
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

declaration:
	declaration_specifiers ';' {}
	| declaration_specifiers init_declarator_list ';' {
	}
	;

declaration_specifiers: 
	type_specifier {
		$$ = $1;
	}
	| type_specifier declaration_specifiers {
		$1->next_node = $2;
		$$ = $1;
	}
	| type_qualifier {
		$$ = $1;
	}
	| type_qualifier declaration_specifiers {
		$1->next_node = $2;
		$$ = $1;
	}
	| storage_class_specifier {
		
	}
	| storage_class_specifier declaration_specifiers {
		$$ = $2;
	}
	;

storage_class_specifier: 
	EXTERN {
		storage_class = EXTERN_STORE;
	}
	| STATIC {
		storage_class = STATIC_STORE;
	}
	| AUTO {
		storage_class = AUTO_STORE;
	}
	| REGISTER {
		storage_class = REGISTER_STORE;
	}
	;

init_declarator_list:
	declarator {
		astnode_link(&front, &end, $<astnode_p>0);
		struct sym_entry *n = add_entry(front, curr_scope, file_name, yylineno);
		add_storage_class(n);
		print_entry(n);
		front = NULL;
		end = NULL;
	}
	| init_declarator_list ',' declarator {
		astnode_link(&front, &end, $<astnode_p>0);
		struct sym_entry *n = add_entry(front, curr_scope, file_name, yylineno);
		add_storage_class(n);
		print_entry(n);
		front = NULL;
		end = NULL;
	}
	;

type_specifier:
	VOID {
		struct astnode *n = astnode_alloc(AST_scaler);
		n->u.scaler.scaler_type = $1;
		$$ = n;
	}
	| CHAR {
		struct astnode *n = astnode_alloc(AST_scaler);
		n->u.scaler.scaler_type = $1;
		$$ = n;

	}
	| SHORT {
		struct astnode *n = astnode_alloc(AST_scaler);
		n->u.scaler.scaler_type = $1;
		$$ = n;
	}
	| INT {
		struct astnode *n = astnode_alloc(AST_scaler);
		n->u.scaler.scaler_type = $1;
		$$ = n;
	}
	| LONG {
		struct astnode *n = astnode_alloc(AST_scaler);
		n->u.scaler.scaler_type = $1;
		$$ = n;
	}
	| FLOAT {
		struct astnode *n = astnode_alloc(AST_scaler);
		n->u.scaler.scaler_type = $1;
		$$ = n;
	}
	| DOUBLE {
		struct astnode *n = astnode_alloc(AST_scaler);
		n->u.scaler.scaler_type = $1;
		$$ = n;
	}
	| SIGNED {
		struct astnode *n = astnode_alloc(AST_scaler);
		n->u.scaler.scaler_type = $1;
		$$ = n;
	}
	| UNSIGNED {
		struct astnode *n = astnode_alloc(AST_scaler);
		n->u.scaler.scaler_type = $1;
		$$ = n;
	}
	| _BOOL {
		struct astnode *n = astnode_alloc(AST_scaler);
		n->u.scaler.scaler_type = $1;
		$$ = n;
	}
	| _COMPLEX {
		struct astnode *n = astnode_alloc(AST_scaler);
		n->u.scaler.scaler_type = $1;
		$$ = n;
	}
	| struct_or_union_specifier {
		$$ = $1;
	}
	;

type_qualifier:
	CONST {
		/*struct astnode *n = astnode_alloc(AST_scaler);
		n->u.scaler.scaler_type = $1;
		$$ = n;*/
	}
	| RESTRICT {
		/*struct astnode *n = astnode_alloc(AST_scaler);
		n->u.scaler.scaler_type = $1;
		$$ = n;*/
	}
	| VOLATILE {
		/*struct astnode *n = astnode_alloc(AST_scaler);
		n->u.scaler.scaler_type = $1;
		$$ = n;*/
	}
	;

declarator:
	direct_declarator {
		$$ = $1;
	}
	| pointer direct_declarator {
		//struct astnode *n = astnode_alloc(AST_pointer);
		astnode_link(&front, &end, $1);
		$$ = front;
	}
	;

direct_declarator:
	IDENT {
		struct astnode *n = astnode_alloc(AST_ident);
		strncpy(n->u.ident.name, $1, 1024);
		n->u.ident.ident_type = VAR_TYPE;
		astnode_link(&front, &end, n);
		$$ = front;
	}
	| '(' IDENT ')' {
		struct astnode *n = astnode_alloc(AST_ident);
		strncpy(n->u.ident.name, $2, 1024);
		n->u.ident.ident_type = VAR_TYPE;
		astnode_link(&front, &end, n);
		$$ = front;
	}
	| direct_declarator '[' ']' {
		struct astnode *n = astnode_alloc(AST_array);
		n->u.arr.num = 0;
		astnode_link(&front, &end, n);
		$$ = front;
	}
	| direct_declarator '[' NUMBER ']' {
		struct astnode *n = astnode_alloc(AST_array);
		n->u.arr.num = $3;
		astnode_link(&front, &end, n);
		$$ = front;
	}
	| direct_declarator '(' ')' {
		$1->u.ident.ident_type = FUNC_TYPE;
		$$ = front;
	}
	;

pointer:
	'*' {
		struct astnode *n = astnode_alloc(AST_pointer);
		$$ = n;
	}
	| '*' type_qualifier_list {
		struct astnode *n = astnode_alloc(AST_pointer);
		$$ = n;
	}
	| '*' pointer {
		struct astnode *n = astnode_alloc(AST_pointer);
		n->next_node = $2;
		$$ = n;
	}
	| '*' type_qualifier_list pointer {
		struct astnode *n = astnode_alloc(AST_pointer);
		n->next_node = $3;
		$$ = n;
	}
	;

type_qualifier_list:
	type_qualifier {
		//astnode_link(&front, &end, $1);
		$$ = $1;
	}
	| type_qualifier_list type_qualifier {

	}
	;

struct_or_union_specifier:
	struct_or_union IDENT {
		strncpy($1->u.stru.name, $2, 1024);
		struct astnode *n = astnode_alloc(AST_ident);
		strncpy(n->u.ident.name, $2, 1024);
		if ($1->node_type == AST_struct) {
			n->u.ident.ident_type = STRUCT_TYPE;
		}
		else {
			n->u.ident.ident_type = UNION_TYPE;
		}
		struct sym_entry *finding = search_all(curr_scope, $2, STRUCT_TYPE);
		if(finding != NULL) {
			//yyerror("Variable has already been defined");
			$$ = $1;
		}
		else {
			struct sym_entry *new_entry = add_entry(n, curr_scope, file_name, yylineno);
			new_entry->e.stru.complete = 0;
			print_entry(new_entry);
			$$ = $1;
		}
	}
	| struct_or_union {enter_scope(STRUCT_SCOPE);} '{' struct_declaration_list '}' {
		struct sym_table *temp = curr_scope;
		exit_scope();
		strncpy($1->u.stru.name, "", 1024);
		struct astnode *n = astnode_alloc(AST_ident);
		strncpy(n->u.ident.name, "", 1024);
		if ($1->node_type == AST_struct) {
			n->u.ident.ident_type = STRUCT_TYPE;
		}
		else {
			n->u.ident.ident_type = UNION_TYPE;
		}
		//struct sym_entry *new_entry = add_entry(n, curr_scope, file_name, yylineno);
		struct sym_entry *new_entry = sym_entry_alloc(n->u.ident.ident_type, n->u.ident.name, NULL, NULL, file_name, yylineno);
		new_entry->e.stru.complete = 1;
		new_entry->e.stru.table = temp;
		$1->u.stru.entry = new_entry;
		print_entry(new_entry);
		$$ = $1;
	}
	| struct_or_union IDENT { enter_scope(STRUCT_SCOPE); strncpy(curr_scope->name, $2, 1024);} '{' struct_declaration_list '}' {
		struct sym_table *temp = curr_scope;
		exit_scope();
		strncpy($1->u.stru.name, $2, 1024);
		struct astnode *n = astnode_alloc(AST_ident);
		strncpy(n->u.ident.name, $2, 1024);
		if ($1->node_type == AST_struct) {
			n->u.ident.ident_type = STRUCT_TYPE;
		}
		else {
			n->u.ident.ident_type = UNION_TYPE;
		}
		//struct sym_entry *new_entry = add_entry(n, curr_scope, file_name, yylineno);
		struct sym_entry *finding = search_all(curr_scope, $2, STRUCT_TYPE);
		if(finding != NULL) {
			if(finding->e.stru.complete == 1) {
				yyerror("Variable has already been defined");
			}
			else {
				finding->e.stru.complete = 1;
				finding->e.stru.table = temp;
				finding->def_num = yylineno;
				strncpy(finding->def_file, file_name, 1024);
				print_entry(finding);
			}
		}
		else {
			/*struct sym_entry *new_entry = sym_entry_alloc(n->u.ident.ident_type, n->u.ident.name, NULL, NULL, file_name, yylineno);
			new_entry->e.stru.complete = 1;
			new_entry->e.stru.table = temp;
			//$1->u.stru.entry = new_entry;
			print_entry(new_entry, 0);*/
			struct sym_entry *new_entry = add_entry(n, curr_scope, file_name, yylineno);
			new_entry->e.stru.complete = 1;
			new_entry->e.stru.table = temp;
			add_storage_class(new_entry);
			print_entry(new_entry);
		}
		$$ = $1;
	} 
	;

struct_declaration_list:
	struct_declaration {
		$$ = $1;
	}
	| struct_declaration_list struct_declaration {
		$$ = $1;
	}
	;

struct_declaration:
	specifier_qualifier_list struct_declarator_list ';' {
		$$ = $1;
	}
	;

specifier_qualifier_list:
	type_specifier {
		$$ = $1;
	}
	| type_specifier specifier_qualifier_list {
		$1->next_node = $2;
		$$ = $1;
	}
	;

struct_declarator_list:
	struct_declarator {
		astnode_link(&front, &end, $<astnode_p>0);
		struct sym_entry *n = add_entry(front, curr_scope, file_name, yylineno);
		front = NULL;
		end = NULL;
		$$ = $1;
	}
	| struct_declarator_list ',' struct_declarator {
		astnode_link(&front, &end, $<astnode_p>0);
		struct sym_entry *n = add_entry(front, curr_scope, file_name, yylineno);
		front = NULL;
		end = NULL;
		$$ = $1;
	}
	;

struct_declarator:
	declarator {
		front->u.ident.ident_type = MEMBER_TYPE;
	}
	;

struct_or_union:
	STRUCT {
		struct astnode *n = astnode_alloc(AST_struct);
		//struct sym_table *temp = curr_scope;
		//curr_scope = sym_table_alloc(STRUCT_SCOPE, yylineno);
		//n->u.stru.table = curr_scope;
		//curr_scope->parent_table = temp;
		$$ = n;
	}
	| UNION {
		struct astnode *n = astnode_alloc(AST_union);
		$$ = n;
	}
	;

%%

yyerror(char *s) {
	fprintf(stderr, "%s:%d\terror: %s\n", file_name, yylineno, s);
	exit(1);
}

enter_scope(int scope_type) {
	struct sym_table *new_table = sym_table_alloc(scope_type, yylineno);
	new_table->parent_table = curr_scope;
	curr_scope = new_table;
}

exit_scope() {
	curr_scope = curr_scope->parent_table;
}

add_storage_class(struct sym_entry *entry) {
	if(storage_class ==0){
		if(entry->curr_table->scope_type == FILE_SCOPE) {
			storage_class = EXTERN_STORE;
		}
		else if(entry->curr_table->scope_type == BLOCK_SCOPE || entry->curr_table->scope_type == FUNC_SCOPE){
			storage_class = AUTO_STORE;
		}
		else {
			yyerror("Eligible storage class declaration");
		}
	}
	if(entry->entry_type == VAR_TYPE) {
		entry->e.var.storage_class = storage_class;
	}
	else if (entry->entry_type == FUNC_TYPE) {
		entry->e.func.storage_class = storage_class;
	}
	storage_class = 0;
}

int main() {
	printf(">>>>>>>>>>>>\n");
	//yydebug=1;
	curr_scope = sym_table_alloc(FILE_SCOPE, yylineno);
	return yyparse();
}
