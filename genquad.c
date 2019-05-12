#include "genquad.h"
#include "astnode.h"
#include "symTable.h"
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>

int block_index;
int func_index;
int reg_counter;
int array_flag;
int array_type_length = 1;
struct sym_table *curr_table;

int get_type(struct sym_entry *entry) {
	struct astnode *node = entry->first_node;
	while(node != NULL) {
		if(node->node_type == AST_scaler) {
			switch(node->u.scaler.scaler_type) {
				case CHAR: return 1;
				case SHORT: return 2;
				case INT: return 4;
				case LONG: return 8;
				default: return 4;
			}
		}
		else if(node->node_type == AST_pointer) {
			return 1;
		}
		else {
			node = node->next_node;
		}
	}
	return -1;
}

int get_offset(struct sym_table *table, char *name) {
	int offset = 0;
	int type_length = 4;
	struct sym_entry *entry = table->first;
	while(entry != NULL) {
		if(strncmp(entry->name, name, 1024) != 0) {
			type_length = get_type(entry);
			while(1) {
				if( offset % type_length == 0) {
					break;
				}
				else {
					offset++;
				}
			}
			offset = offset + get_type(entry);
			entry = entry->next;
		}
		else {
			return offset;
		}
	}
	return -1;
} 

struct astnode* gen_rvalue(struct astnode *node, struct astnode *target, struct bblock *bb) {
	if (node->node_type == AST_ident) {
		switch(node->u.ident.entry->first_node->node_type) {
			case AST_array: {
				target = new_temporary(reg_counter);
				reg_counter++;
				struct quad *new_quad = emit(LEA, node, NULL, target, bb);
				array_flag = 1;
				array_type_length = get_type(node->u.ident.entry);
				return target;
			}
			case AST_pointer: {
				if (!target) {
					target = new_temporary(reg_counter);
					reg_counter++;
				}
				emit(LEA, node, NULL, target, bb);
				return target;
			}
		}
		return node;
	}
	if (node->node_type == AST_num) {
		return node;
	}
	if (node->node_type == AST_binop) {
		if (node->u.binop.operator == '.') {
			return gen_struct(node, bb);
		}
		struct astnode* left = gen_rvalue(node->u.binop.left, NULL, bb);
		struct astnode* right = gen_rvalue(node->u.binop.right, NULL, bb);
		if (!target) {
			target = new_temporary(reg_counter);
			reg_counter++;
		}
		// The following two if stmt handle pointer +/- integer
		if (left->node_type == AST_ident && right->node_type == AST_num) {
			int type_length = 1;
			switch(left->u.ident.entry->first_node->node_type) {
				case AST_array:
				case AST_pointer: {
					type_length = get_type(left->u.ident.entry);
					struct astnode *type_size = astnode_alloc(AST_num);
					type_size->u.num.value = type_length;
					struct astnode *temp = new_temporary(reg_counter);
					reg_counter++;
					struct astnode *temp_2 = new_temporary(reg_counter);
					reg_counter++;
					emit(MUL, type_size, right, temp, bb);
					emit(LEA, left, NULL, temp_2, bb);
					emit(node->u.binop.operator, temp_2, temp, target, bb);
					break;
				}
				default: {
					struct quad *new_quad = emit(node->u.binop.operator, left, right, target, bb);
				}
			}
		}
		else if (right->node_type == AST_ident && left->node_type == AST_num) {
			int type_length = 1;
			switch(right->u.ident.entry->first_node->node_type) {
				case AST_array:
				case AST_pointer: {
					type_length = get_type(right->u.ident.entry);
					struct astnode *type_size = astnode_alloc(AST_num);
					type_size->u.num.value = type_length;
					struct astnode *temp = new_temporary(reg_counter);
					reg_counter++;
					struct astnode *temp_2 = new_temporary(reg_counter);
					reg_counter++;
					emit(MUL, type_size, left, temp, bb);
					emit(LEA, right, NULL, temp_2, bb);
					emit(node->u.binop.operator, temp_2, temp, target, bb);
					break;
				}
				default: {
					struct quad *new_quad = emit(node->u.binop.operator, left, right, target, bb);
				}
			}
		}
		// The following conditional stmt handles Pointer +/- Pointer
		else if (right->node_type == AST_ident && left->node_type == AST_ident) {
			if (right->u.ident.entry->first_node->node_type == AST_pointer
				&&  left->u.ident.entry->first_node->node_type == AST_pointer) {
				struct astnode *temp = new_temporary(reg_counter);
				reg_counter++;
				struct astnode *temp_2 = new_temporary(reg_counter);
				reg_counter++;
				emit(LEA, left, NULL, temp, bb);
				emit(LEA, right, NULL, temp_2, bb);
				emit(node->u.binop.operator, temp, temp_2, target, bb);
			}
			else {
				emit(node->u.binop.operator, left, right, target, bb);
			}
		}
		else if (array_flag && (right->node_type == AST_num)) {
			struct astnode *type_size = astnode_alloc(AST_num);
			type_size->u.num.value = array_type_length;
			struct astnode *temp = new_temporary(reg_counter);
			reg_counter++;
			emit(MUL, type_size, right, temp, bb);
			emit(node->u.binop.operator, left, temp, target, bb);
		}
		else {
			struct quad *new_quad = emit(node->u.binop.operator, left, right, target, bb);
		}
		return target;
	}
	if (node->node_type == AST_array) {
		target = new_temporary(reg_counter);
		reg_counter++;
		struct quad *new_quad = emit(LEA, node, NULL, target, bb);
		return target;
	}
	if (node->node_type == AST_unary) {
		switch(node->u.unaop.operator) {
			case '*': {
				struct astnode *addr = gen_rvalue(node->u.unaop.right, NULL, bb);
				struct astnode *temp = new_temporary(reg_counter);
				reg_counter++;
				if (!target) {
					target = new_temporary(reg_counter);
					reg_counter++;
				}
				struct quad *new_quad = emit(MOV, addr, NULL, temp, bb); // Must load addr into a temp reg instead of a variable
				return temp;
			}
			case PLUSPLUS: {
				struct astnode *temp = gen_post(node->u.unaop.right, bb, '+');
				return temp;
			}
			case MINUSMINUS: {
				struct astnode *temp = gen_post(node->u.unaop.right, bb, '-');
				return temp;
			}
			case SIZEOF: {
				int type_size = get_type(node->u.unaop.right->u.ident.entry); // Assume sizeof only follows an ident
				struct astnode *var_size = astnode_alloc(AST_num);
				var_size->u.num.value = type_size;
				return var_size;
			}	
		}
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
	if (node->node_type == AST_unary) {
		switch(node->u.unaop.operator) {
			case '*': {
				struct astnode *addr = gen_rvalue(node->u.unaop.right, NULL, bb);
				return addr;
			}
			default: {
				fprintf(stderr, "****Error: Invalid unary op at lvalue during quad gen****\n");
			}
		} 
	}
	if (node->node_type == AST_binop) {
		switch(node->u.binop.operator) {
			case '.': {
				return gen_struct(node, bb);
			}
		}
	}
	return NULL;
}

struct astnode* gen_struct(struct astnode *node, struct bblock *bb) {
	struct astnode *base = gen_addressof(node->u.binop.left, bb);
	struct sym_entry *test = search_entry(curr_table, node->u.binop.left->u.ident.entry->first_node->u.stru.name, STRUCT_TYPE);
	if (test == NULL) {
		fprintf(stderr, "****Error: Cannot find struct %d while generating quad****", node->u.binop.left->u.ident.entry->first_node->u.stru.name);
		exit(1);
	}
	int offset = get_offset(test->e.stru.table, node->u.binop.right->u.ident.name);
	struct astnode *temp_target = new_temporary(reg_counter);
	reg_counter++;
	struct astnode *temp = astnode_alloc(AST_num);
	temp->u.num.value = offset;
	emit('+', base, temp, temp_target, bb);
	return temp_target;
}

struct astnode* gen_assign(struct astnode *node, struct bblock *bb) {
	int dstmode;
	struct astnode *dst = gen_lvalue(node->u.binop.left, &dstmode, bb);
	if (dstmode == DIRECT) {
		struct astnode *node_rval = gen_rvalue(node->u.binop.right, dst, bb);
		if (node_rval->node_type == AST_ident) {
			//emit(LOAD, node_rval, NULL, dst, bb);
		}
		else if (node_rval->node_type == AST_num) {
			emit(MOV, node_rval, NULL, dst, bb);
		}
		else if (node_rval->node_type == AST_temp) {
			emit(LOAD, node_rval, NULL, dst, bb);
		}
	}
	else {
		struct astnode* t1 = gen_rvalue(node->u.binop.right, NULL, bb);
		emit(STORE, t1, dst, NULL, bb);
	}
	return NULL;
}

struct astnode* gen_addressof(struct astnode *node, struct bblock *bb) {
	switch(node->node_type) {
		case AST_ident: {
			struct astnode *temp = new_temporary(reg_counter);
			reg_counter++;
			emit(LEA, node, NULL, temp, bb);
			return temp;
		}
		default: {
			fprintf(stderr, "****Error: Invalid astnode during address generation of quad generation****\n");
		}
	}
	return node;
}

struct astnode* gen_condexp(struct astnode *node, struct bblock *bb) {
	//struct astnode *left = gen_rvalue(node->u.binop.left, NULL, bb);
	switch(node->node_type) {
		case AST_num: {
			struct astnode *temp = astnode_alloc(AST_num);
			temp->u.num.value = 1;
			emit(CMP, node, temp, NULL, bb);
			break;
		}
		case AST_binop: {
			struct astnode *left = gen_rvalue(node->u.binop.left, NULL, bb);
			struct astnode *right = gen_rvalue(node->u.binop.right, NULL, bb);
			emit(CMP, left, right, NULL, bb);
			break;
		}
		default: {
			fprintf(stderr, "****Error: Unknown astnode type during condexp quad generation****\n");
		}
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
	gen_condexp(node->u.if_node.expr, bexpr);
	switch(node->u.if_node.expr->u.binop.operator) {
		// This if conditional statement can only handle comparision and logic
		case '>': branch = emit(BRGT, bt->node, bf->node, NULL, bexpr); break;
		case '<': branch = emit(BRLT, bt->node, bf->node, NULL, bexpr); break;
		case NOTEQ: branch = emit(BRNEQ, bt->node, bf->node, NULL, bexpr); break;
		case EQEQ: branch = emit(BRNEQ, bt->node, bf->node, NULL, bexpr); break;
		default: printf("****Error: Unknown binop during if stmt quad generation****\n");
	}
	link_block(bexpr, prev_bb);
	bblock_append(&bexpr, &prev_bb);
	gen_quad(node->u.if_node.if_body, bt);
	bblock_append(&bt, &bexpr);
	bblock_append(&bf, &bt);
	return branch;
}

struct quad* gen_while(struct astnode *node, struct bblock *prev_bb, struct bblock *next_bb) {
	struct bblock *bexpr = bblock_alloc();
	struct bblock *body = bblock_alloc();
	struct quad *branch;
	gen_condexp(node->u.while_node.expr, bexpr);
	switch(node->u.while_node.expr->u.binop.operator) {
		// This while conditional statement can only handle comparision and logic
		case '>': branch = emit(BRGT, body->node, next_bb->node, NULL, bexpr); break;
		case '<': branch = emit(BRLT, body->node, next_bb->node, NULL, bexpr); break;
		default: printf("****Error: Unknown binop during if stmt quad generation****\n");
	}
	link_block(bexpr, prev_bb);
	bblock_append(&bexpr, &prev_bb);
	gen_quad(node->u.while_node.body, body);
	link_block(bexpr, body);
	bblock_append(&body, &bexpr);
	bblock_append(&next_bb, &body);
	return branch;
}

struct quad* gen_func(struct astnode *node, struct bblock* curr_bb, struct bblock* new_bb) {
	struct astnode *temp = astnode_alloc(AST_num);
	struct quad *branch;
	int argu_num = argu_counter(node->u.func.next);
	temp->u.num.value = argu_num;
	emit(ARGBEGIN, temp, NULL, NULL, curr_bb);
	struct astnode *argu = node->u.func.next;
	while(argu_num>0) {
		struct astnode *argu_index = astnode_alloc(AST_num);
		argu_index->u.num.value = argu->u.argu.num;
		switch(argu->u.argu.value->node_type) {
			case AST_num:
			case AST_ident: {
				emit(ARG, argu_index, argu->u.argu.value, NULL, curr_bb);
				break;
			}
			case AST_binop: {
				struct astnode *target = gen_rvalue(argu->u.argu.value, NULL, curr_bb);
				emit(ARG, argu_index, target, NULL, curr_bb);
				break;
			}
			default: {
				fprintf(stderr, "****Error: Invalid astnode type when generating quad for func argu****\n");
			}
		}
		argu_num--;
		argu = argu->u.argu.next;
	}
	branch = emit(CALL, node, NULL, NULL, curr_bb);
	link_block(new_bb, curr_bb);
	bblock_append(&new_bb, &curr_bb);
	return branch;
}

struct astnode* gen_post(struct astnode *node, struct bblock *bb, int post_op) {
	struct astnode *temp = new_temporary(reg_counter);
	reg_counter++;
	emit(MOV, node, NULL, temp, bb);
	struct astnode *change = astnode_alloc(AST_num);
	change->u.num.value = 1;
	emit(post_op, node, change, node, bb);
	return temp;
}

int argu_counter(struct astnode *node) {
	int counter = 0;
	struct astnode *temp = node->u.func.next;
	while(temp != NULL) {
		if (temp->node_type == AST_argu) {
			counter++;
		}
		temp = temp->u.argu.next;
	}
	return counter;
}

void link_block(struct bblock *branch_to, struct bblock *branch_in) {
	emit(BR, branch_to->node, NULL, NULL, branch_in);
}

void gen_init(struct astnode *node, struct sym_table *table, int func_counter) {
	curr_table = table;
	func_index = func_counter;
	reg_counter = 0;
	struct bblock *new_bb = bblock_alloc();
	gen_quad(node, new_bb);
	add_return(new_bb);
	dump_bb(new_bb);
}

struct bblock* gen_quad(struct astnode *node, struct bblock *bb) {
	struct bblock *new_bb = bb;
	switch (node->node_type) {
		case AST_binop: {
			switch(node->u.binop.operator) {
				case '=': {
					gen_assign(node, bb);
					break;
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
		case AST_while:
		{	new_bb = bblock_alloc();
			struct quad *branch = gen_while(node, bb, new_bb);
			//new_bb = bblock_alloc();
			//link_block(new_bb, branch->src1->u.basic_block.bb);
			//link_block(new_bb, branch->src2->u.basic_block.bb);
			//bblock_append(&new_bb, &(branch->src2->u.basic_block.bb));
			break;
		}
		case AST_func:
		{	new_bb = bblock_alloc();
			struct quad *branch = gen_func(node, bb, new_bb);
			break;
		}
		case AST_unary:
		{	switch(node->u.unaop.operator) {
				case PLUSPLUS: {
					gen_post(node->u.unaop.right, bb, '+');
					break;
				}
				case MINUSMINUS: {
					gen_post(node->u.unaop.right, bb, '-');
					break;
				}
				default: {
					fprintf(stderr, "****Error: Invalid unary operator during generating quad****\n");
				}
			}
		}
		default:
		{	printf("****Error: Invalid astnode during generating quad.****\n");
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

void add_return(struct bblock *bb) {
	while(bb->next != NULL) {
		bb = bb->next;
	}
	emit(RET, NULL, NULL, NULL, bb);
}

struct astnode* new_temporary(int counter) {
	struct astnode *ast_temp = astnode_alloc(AST_temp);
	ast_temp->u.temp_node.index = counter;
	return ast_temp;
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
			printf("%T%d", node->u.temp_node.index);
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
		case '-': printf("SUB"); break;
		case '>': printf("CMP"); break;
		case '<': printf("CMP"); break;
		case '*': printf("MUL"); break;
		case '/': printf("DIV"); break;
		case LOAD: printf("LOAD"); break;
		case STORE: printf("STORE"); break;
		case BR: printf("BR"); break;
		case BRGT: printf("BRGT"); break;
		case BRLT: printf("BRLT"); break;
		case BREQ: printf("BREQ"); break;
		case BRNEQ: printf("BRNEQ"); break;
		case MOV: printf("MOV"); break;
		case MUL: printf("MUL"); break;
		case RET: printf("RET"); break;
		case LEA: printf("LEA"); break;
		case CMP: printf("CMP"); break;
		case CALL: printf("CALL"); break;
		case ARGBEGIN: printf("ARGBEGIN"); break;
		case ARG: printf("ARG"); break;
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
	if( src != NULL ) {
		switch(src->node_type) {
			case AST_temp: {
				printf("%T%d", src->u.temp_node.index);
				break;
			}
			case AST_ident: {
				printf("%s", src->u.ident.name);
				if(src->u.ident.entry->curr_table->scope_type == FILE_SCOPE) {
					printf("{global}");
				}
				else {
					printf("{lvar}");
				}
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
			case AST_func: {
				printf("$%s", src->u.func.name->u.ident.name);
				break;
			}
			default: {
				printf("****Error: Unknown astnode to print BB\n");
			}
		}
	}
}
