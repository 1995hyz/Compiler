#ifndef _ASTNODE_H
#define _ASTNODE_H

#define AST_binop 1
#define AST_unary 2
#define AST_num 3
#define AST_ident 4
#define AST_string 5
#define AST_func 6
#define AST_argu 7
#define AST_ternary 8

#define TAG 9
#define LABEL 10
#define MEMBER 11
#define ELSE 12

extern int yylineno;
struct astnode;

struct astnode_binop {
	int node_type;
	int operator;
	struct astnode *left, *right;
};
struct astnode_unaop {
	int node_type;
	int operator;
	struct astnode *left, *right;
};

struct astnode_num {
	int node_type;
	long long int value;
};

struct astnode_ident {
	int node_type;
	char name[1024];
};

struct astnode_string {
	int node_type;
	char value[1024];
};

struct astnode_func {
	int node_type;
	struct astnode *name;
	struct astnode *next;
	int num;
};

struct astnode_argu {
	int node_type;
	struct astnode *next;
	struct astnode *start;
	struct astnode *value;
	int num;
};

struct astnode_ternary {
	int node_type;
	struct astnode *first;
	struct astnode *second;
	struct astnode *third;
};

struct astnode_var {
	int name_space;
	int storage_class;
	char name[1024];
	int offset;
	struct astnode *next;
};

struct astnode {
	int node_type;
	union astnodes{
		struct astnode_binop binop;
		struct astnode_unaop unaop;
		struct astnode_num num;
		struct astnode_ident ident;
		struct astnode_string string;
		struct astnode_func func;
		struct astnode_argu argu;
		struct astnode_ternary tern;

		struct astnode_var var;
	} u;
};

struct astnode* astnode_alloc(int node_type);
void print_tree(struct astnode*, int indent);
void tree_free(struct astnode*);

#endif //_ASTNODE_H
