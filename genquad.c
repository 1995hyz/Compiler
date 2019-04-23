#include "genquad.h"
#include "astnode.h"
#include <stdio.h>
#include <stdlib.h>

//struct bblock *curr_bb;
int block_index;
int func_index;

struct astnode* gen_rvalue(struct astnode *node, struct astnode *target, struct bblock *bb) {
	if (node->node_type == AST_ident) {
		return node;
	}
	if (node->node_type == AST_num) {
		return node;
	}
	if (node->node_type == AST_binop) {
		struct astnode* left = gen_rvalue(node->u.binop.left, NULL, bb);
		struct astnode* right = gen_rvalue(node->u.binop.right, NULL, bb);
		if (!target) {
			target = new_temporary();
		}
		struct quad *new_quad = emit(node->u.binop.operator, left, right, target, bb);
		return target;
	}
	if (node->node_type == AST_pointer) {
		struct astnode* addr = gen_rvalue(node->next_node, NULL, bb);
		if (!target) {
			target = new_temporary();
		}
		struct quad *new_quad = emit(LOAD, addr, NULL, target, bb);
		return target;
	}
	return NULL;
}

struct astnode* gen_lvalue(struct astnode *node, int *mode, struct bblock *bb) {
	if (node->node_type == AST_ident) {
		*mode = DIRECT;
		return node;
	}
	if (node->node_type == AST_num) {
		return NULL;
	}
	if (node->node_type == AST_pointer) {
		*mode = INDIRECT;
		return gen_rvalue(node->next_node, NULL, bb);
	}
	return NULL;
}

struct astnode* gen_assign(struct astnode *node, struct bblock *bb) {
	int dstmode;
	struct astnode *dst = gen_lvalue(node->u.binop.left, &dstmode, bb);
	if (dstmode == DIRECT) {
		gen_rvalue(node->u.binop.right, dst, bb);
	}
	else {
		struct astnode* t1 = gen_rvalue(node->u.binop.right, NULL, bb);
		emit(STORE, t1, dst, NULL, bb);
	}
	return NULL;
}

struct quad* gen_if(struct astnode *node, struct bblock *prev_bb) {
	struct bblock *bexpr = bblock_alloc();
	struct bblock *bt = bblock_alloc();
	struct bblock *bf = bblock_alloc();
	struct bblock *bn;
	struct quad *branch;
	if (node->u.if_node.else_body != NULL) {
		//bn = bblock_alloc();
		gen_quad(node->u.if_node.else_body, bf);
	}
	gen_quad(node->u.if_node.expr, bexpr);
	switch(node->u.if_node.expr->u.binop.operator) {
		case '>': branch = emit(BRGE, bt->node, bf->node, NULL, bexpr); break;
		default: printf("****Error: Unknown binop during if stmt quad generation****\n");
	}
	link_block(bexpr, prev_bb);
	bblock_append(&bexpr, &prev_bb);
	gen_quad(node->u.if_node.if_body, bt);
	bblock_append(&bt, &bexpr);
	bblock_append(&bf, &bt);
	return branch;
}

void link_block(struct bblock *branch_to, struct bblock *branch_in) {
	emit(BR, branch_to->node, NULL, NULL, branch_in);
}

void gen_init(struct astnode *node) {
	//curr_bb = bblock_alloc();
	struct bblock *new_bb = bblock_alloc();
	//bblock_append(&new_bb, &curr_bb);
	//struct bblock **first = &curr_bb;
	gen_quad(node, new_bb);
	//dump_bb(*first);
	dump_bb(new_bb);
}

struct bblock* gen_quad(struct astnode *node, struct bblock *bb) {
	struct bblock *new_bb;
	switch (node->node_type) {
		case AST_binop: {
			switch(node->u.binop.operator) {
				case '=': {
					gen_assign(node, bb);
				}
			}
			break;
		}
		case AST_block:
		{	//struct bblock *new_bb = bblock_alloc();
			//bblock_append(&new_bb, &curr_bb);
			new_bb = gen_quad(node->u.blo.item, bb);
			if(node->u.blo.next_block != NULL) {
				new_bb = gen_quad(node->u.blo.next_block, new_bb);
			}
			break;
		}
		case AST_compound:
		{	//struct bblock *new_bb = bblock_alloc();
			//bblock_append(&new_bb, &curr_bb);
			if(node->u.comp.list != NULL) {
				gen_quad(node->u.comp.list, bb);
			}
			break;
		}
		case AST_if:
		{	struct quad *branch = gen_if(node, bb);
			new_bb = bblock_alloc();	//Generating a new basic block for statements after the if statement
			link_block(new_bb, branch->src1->u.basic_block.bb);
			link_block(new_bb, branch->src2->u.basic_block.bb);
			bblock_append(&new_bb, &(branch->src2->u.basic_block.bb));
			break;
		}
		default:
		{	printf("****Error: Unknown astnode during generating quad.****\n");
		}
	}
	return new_bb;
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

struct quad* emit(int opcode, struct astnode *src1, struct astnode *src2, struct astnode *result, struct bblock *curr_bb) {
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
	new_bblock->index[0] = func_index;
	new_bblock->index[1] = block_index;
	new_bblock->node = astnode_alloc(AST_bb);
	new_bblock->node->u.basic_block.bb = new_bblock;
	block_index = block_index + 1;
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
	if(node != NULL) {
		if( node->node_type == AST_temp ) {
			printf("%T");
		}
		else {
			printf("%s=", node->u.ident.name);
		}
	}
}

void print_opcode(int opcode) {
	printf("\t");
	switch(opcode) {
		case '+': printf("ADD"); break;
		case '>': printf("CMP"); break;
		case '<': printf("CMP"); break;
		case LOAD: printf("LOAD"); break;
		case STORE: printf("STORE"); break;
		case BR: printf("BR"); break;
		case BRGE: printf("BRGE"); break;
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
		case AST_bb: {
			printf(".BB%d.%d", src->u.basic_block.bb->index[0], src->u.basic_block.bb->index[1]);
			break;
		}
		default: {
			printf("****Error: Unknown astnode to print BB\n");
		}
	}
}
