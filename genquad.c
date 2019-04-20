#include "genquad.h"
#include "astnode.h"
#include <stdio.h>
#include <stdlib.h>

struct bblock *curr_bb;

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
		struct quad *new_quad = emit(node->u.binop.operator, left, right, target);
		return target;
	}
	if (node->node_type == AST_pointer) {
		struct astnode* addr = gen_rvalue(node->next_node, NULL);
		if (!target) {
			target = new_temporary();
		}
		struct quad *new_quad = emit(LOAD, addr, NULL, target);
		return target;
	}
	return NULL;
}

struct astnode* gen_lvalue(struct astnode *node, int *mode) {
	if (node->node_type == AST_scaler) {
		*mode = DIRECT;
		return node;
	}
	if (node->node_type == AST_num) {
		return NULL;
	}
	if (node->node_type == AST_pointer) {
		*mode = INDIRECT;
		return gen_rvalue(node->next_node, NULL);
	}
	return NULL;
}

struct astnode* gen_assign(struct astnode *node) {
	int dstmode;
	struct astnode *dst = gen_lvalue(node->u.binop.left, &dstmode);
	if (dstmode == DIRECT) {
		gen_rvalue(node->u.binop.right, dst);
	}
	else {
		struct astnode* t1 = gen_rvalue(node->u.binop.right, NULL);
		emit(STORE, t1, dst, NULL);
	}
	return NULL;
}

void gen_init(struct astnode *node) {
	curr_bb = bblock_alloc();
	switch (node->node_type) {
		case AST_binop: {
			switch(node->u.binop.operator) {
				case '=': {
					gen_assign(node);
				}
			}
		}
	}
}

struct astnode* new_temporary() {
	return astnode_alloc(AST_temp);
}

struct quad* emit(int opcode, struct astnode *src1, struct astnode *src2, struct astnode *result) {
	struct quad *new_quad = quad_alloc();
	new_quad->opcode = opcode;
	new_quad->result = result;
	new_quad->src1 = src1;
	new_quad->src2 = src2;
	if(curr_bb == NULL) {
		curr_bb->first = new_quad;
	}
	else {
		curr_bb->last->next = new_quad;
		curr_bb->last = new_quad;
	}
	return new_quad;
}

struct quad* quad_alloc() {
	struct quad *new_quad = malloc(sizeof(struct quad));
	if( !new_quad ) {
		fprintf(stderr, "out of space for quads\n");
		exit(1);
	}
	return new_quad;
}

struct bblock* bblock_alloc() {
	struct bblock *new_bblock = malloc(sizeof(struct bblock));
	if( !new_bblock ) {
		fprintf(stderr, "out of space for basic block\n");
		exit(1);
	}
	return new_bblock;
}

void dump_bb (struct bblock* bb){
	while( 1 ) {
		printf(".BB%d.%d :\n", bb->index[0], bb->index[1]);
		printf("\t");
		dump_quad(bb->first);
		if( bb->next != NULL ) {
			bb = bb->next;
		}
		else {
			break;
		}
	}
}

void dump_quad (struct quad* q) {
	while( 1 ) {
		print_target(q->result);
		print_opcode(q->opcode);
		if( q->next != NULL ) {
			q = q->next;
		}
		else {
			break;
		}
	}
}

void print_target(struct astnode *node) {

}

void print_opcode(int opcode) {

}
