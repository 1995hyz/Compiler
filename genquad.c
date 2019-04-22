#include "genquad.h"
#include "astnode.h"
#include <stdio.h>
#include <stdlib.h>

struct bblock *curr_bb;

struct astnode* gen_rvalue(struct astnode *node, struct astnode *target) {
	if (node->node_type == AST_ident) {
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
	if (node->node_type == AST_ident) {
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
	//curr_bb = bblock_alloc();
	struct bblock *new_bb = bblock_alloc();
	bblock_append(&new_bb, &curr_bb);
	struct bblock **first = &curr_bb;
	gen_quad(node);
	dump_bb(*first);
}

void gen_quad(struct astnode *node) {
	switch (node->node_type) {
		case AST_binop: {
			switch(node->u.binop.operator) {
				case '=': {
					gen_assign(node);
				}
			}
			break;
		}
		case AST_block:
		{	//struct bblock *new_bb = bblock_alloc();
			//bblock_append(&new_bb, &curr_bb);
			gen_quad(node->u.blo.item);
			if(node->u.blo.next_block != NULL) {
				gen_quad(node->u.blo.next_block);
			}
			break;
		}
		case AST_compound:
		{	struct bblock *new_bb = bblock_alloc();
			bblock_append(&new_bb, &curr_bb);
			if(node->u.comp.list != NULL) {
				gen_quad(node->u.comp.list);
			}
			break;
		}
		default:
		{	printf("****Error: Unknown astnode during generating quad.****\n");
		}
	}
}

struct bblock* bblock_append(struct bblock **new_block, struct bblock **old_block) {
	if(*old_block == NULL) {
		*old_block = *new_block;
	}
	else {
		(*old_block)->next = *new_block;
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
	if(curr_bb->first == NULL) {
		curr_bb->first = new_quad;
		curr_bb->last = new_quad;
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
	if(q == NULL) {
		printf("\n");
	}
	else {
		while( 1 ) {
			print_target(q->result);
			print_opcode(q->opcode);
			print_source(q->src1, q->src2);
			if( q->next != NULL ) {
				q = q->next;
			}
			else {
				break;
			}
		}
	}
}

void print_target(struct astnode *node) {
	printf("\t");
	if( node->node_type == AST_temp ) {
		printf("%T");
	}
	else {
		printf("%s=", node->u.ident.name);
	}
}

void print_opcode(int opcode) {
	printf("\t");
	switch(opcode) {
		case '+': printf("ADD"); break;
		case LOAD: printf("LOAD"); break;
		case STORE: printf("STORE"); break;
		default: printf("****Error: Unknown opcode\n");
	}
}

void print_source(struct astnode *src1, struct astnode *src2) {
	printf("\t");
	print_name(src1);
	if(src2 != NULL) {
		printf(",");
		print_name(src2);
	}
	printf("\n");
}

void print_name(struct astnode *src) {
	switch(src->node_type) {
		case AST_temp: {
			printf("%T");
			break;
		}
		case AST_ident: {
			printf("%s", src->u.ident.name);
			break;
		}
		case AST_num: {
			printf("%d", src->u.num.value);
			break;
		}
		default: {
			printf("****Error: Unknown astnode to print BB\n");
		}
	}
}
