#include "astnode.h"
#include <stdio.h>
#include <stdlib.h>

astptr astnode_alloc(int node_type){
	switch (node_type){
		case 1: {
			u *new_node = malloc(9);
			return &(new_node->astnode_binop);
		} 

	}

}
