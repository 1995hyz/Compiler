#include "astnode.h"
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
