#ifndef _ASTNODE_H
#define _ASTNODE_H

#include "symTable.h"

#define AST_binop 1
#define AST_unary 2
#define AST_num 3
#define AST_ident 4
#define AST_string 5
#define AST_func 6
#define AST_argu 7
#define AST_ternary 8

#define AST_scaler 9
#define AST_pointer 10
#define AST_struct 11
#define AST_union 12
#define AST_array 13

#define AST_compound 14
#define AST_block 15
#define AST_if 16
#define AST_while 17
#define AST_do 18
#define AST_case 19
#define AST_default 20

#define TAG 9
#define LABEL 10
#define MEMBER 11
#define ANYELSE 12

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
	struct astnode* next;
	int ident_type;
	struct sym_entry *entry;
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

struct astnode_scaler {
	int scaler_type;
};

struct astnode_pointer {
	;
};

struct astnode_struct {
	char name[1024];
	//struct sym_table *table;
	struct sym_entry *entry;
};

struct astnode_union {
	char name[1024];
};

struct astnode_array {
	int num;
};

struct astnode_compound {
	struct astnode *list;
};

struct astnode_block {
	struct astnode *item;
	struct astnode *next_block;
	struct astnode *start;
};

struct astnode_if {
	struct astnode *expr;
	struct astnode *if_body;
	struct astnode *else_body;
};

struct astnode_while {
	struct astnode *expr;
	struct astnode *body;	
};

struct astnode_do {
	struct astnode *expr;
	struct astnode *body;
};

struct astnode_case {
	struct astnode *expr;
	struct astnode *body;
};

struct astnode_default {
	struct astnode *body;
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

		struct astnode_scaler scaler;
		struct astnode_pointer pointer;
		struct astnode_struct stru;
		struct astnode_union uni;
		struct astnode_array arr;
		
		struct astnode_compound comp;
		struct astnode_block blo;
		struct astnode_if if_node;
		struct astnode_while while_node;
		struct astnode_do do_node;
		struct astnode_case case_node;
		struct astnode_default default_node;
	} u;
	struct astnode *next_node;
};

struct astnode_list {
	struct astnode *node;
	struct astnode_list *next;
};

struct astnode* astnode_alloc(int node_type);
void print_tree(struct astnode*, int indent);
void tree_free(struct astnode*);
void print_sym_entry(struct sym_entry *entry);
void print_indent(int indent);
void astnode_link(struct astnode **head, struct astnode **tail, struct astnode *new_insert);

#endif //_ASTNODE_H
