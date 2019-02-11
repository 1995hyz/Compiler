#ifndef _ASTNODE_H
#define _ASTNODE_H

struct astnode;
struct astnode_binop{
	int node_type;
	int operator;
	union astnode *left, *right;
};
struct astnode_unaop{
	int node_type;
	int operator;
	union astnode *left, *right;
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

struct astnode *astptr astnode_alloc(int node_type);

#endif //_ASTNODE_H
