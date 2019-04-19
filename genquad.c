#include "genquad.h"
#include "astnode.h"

struct astnode* gen_rvalue(struct astnode *node, struct astnode *target) {
	if (node->node_type == AST_scaler) {
		return node;
	}
	if (node->node_type == AST_num) {
		return node;
	}
	if (node->node_type == AST_binop) {
		struct astnode* left = gen_rvalue(node->u.binop.left, NULL);
		struct astnode* right = gen_rvalue(node->u.binop.right, NULL);
		if (!target) {
			target = new_temporary();
		}
		emit(node->u.binop.operator, left, right, target);
	}
	if (node->node_type == AST_pointer) {
		
	}
}

struct astnode* new_temporary() {
	return astnode_alloc(AST_temp);
}

struct quad* emit(int opcode, struct astnode *src1, struct astnode *src2, struct astnode *result) {
	
}

struct quad* quad_alloc(); {

}
