#include "astnode.h"
//#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>

struct astnode* astnode_alloc(int type){
	struct astnode* new_node = malloc(sizeof(struct astnode));
	if(!new_node){
		fprintf(stderr, "out of space");
		exit(1);
	}
	new_node -> node_type = type;
	return new_node;
}

void print_tree(struct astnode *node, int indent){
	char space = ' ';
	indent++;
	while (indent > 1){
		printf("%c", space);
		indent--;
	}
	switch(node->node_type){
		case AST_binop:
		{	printf("BINARY OP %c\n", node->u.binop.operator);
			print_tree(node->u.binop.right, indent);
			print_tree(node->u.binop.left, indent);
			break;
		}
		case AST_num:
			printf("NUM: %lld\n", node->u.num.value);	
			break;
		default: printf("internal error: free bad node %d\n", node->node_type);
	}
}

void tree_free(struct astnode *node){
;


}
