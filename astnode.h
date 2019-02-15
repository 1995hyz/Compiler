#ifndef _ASTNODE_H
#define _ASTNODE_H

#define AST_binop 1
#define AST_unary 2
#define AST_num 3
#define AST_ident 4

extern int yylineno;
struct astnode;

struct astnode_binop{
	int node_type;
	int operator;
	struct astnode *left, *right;
};
struct astnode_unaop{
	int node_type;
	int operator;
	struct astnode *left, *right;
};

struct astnode_num{
	int node_type;
	long long int value;
};

struct astnode_ident{
	char *name;
};

struct astnode {
	int node_type;
	union astnodes{
		struct astnode_binop binop;
		struct astnode_unaop unaop;
		struct astnode_num num;
		struct astnode_ident ident;
	} u;
};

struct astnode* astnode_alloc(int node_type);
void print_tree(struct astnode*, int indent);
void tree_free(struct astnode*);

#endif //_ASTNODE_H
