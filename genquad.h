#ifndef _GENQUAD_H
#define _GENQUAD_H

#include "astnode.h"
#include "symTable.h"

#define LOAD 256
#define STORE 257
#define BR 258
#define BRGT 259
#define BRLT 260
#define MOV 261
#define MUL 262
#define RET 263
#define LEA 264
#define CMP 265
#define CALL 266
#define ARG 267
#define ARGBEGIN 268
#define BREQ 269
#define BRNEQ 270
#define DIV 271

#define DIRECT 1
#define INDIRECT 2

struct quad {
	int opcode;
	struct astnode *result, *src1, *src2;
	struct quad *next;
};

struct bblock {
	int index[2];
	struct quad *first;
	struct quad *last;
	struct bblock *next;
	struct astnode *node;
};

struct astnode* gen_rvalue(struct astnode *node, struct astnode *target, struct bblock *bb);
struct astnode* gen_lvalue(struct astnode *node, int *mode, struct bblock *bb);
struct astnode* new_temporary(int index);
struct quad* quad_alloc();
struct bblock* bblock_alloc();
struct quad* emit(int opcode, struct astnode *src1, struct astnode *src2, struct astnode *result, struct bblock *curr_bb);
struct bblock* gen_quad(struct astnode *node, struct bblock *bb);
struct astnode* gen_assign(struct astnode *node, struct bblock *bb);
struct astnode* gen_condexp(struct astnode *node, struct bblock *bb);
struct astnode* gen_addressof(struct astnode *node, struct bblock *bb);
struct quad* gen_if(struct astnode *node, struct bblock *prev_bb);
struct quad* gen_while(struct astnode *node, struct bblock *prev_bb, struct bblock *next_bb);
struct quad* gen_func(struct astnode *node, struct bblock* curr_bb, struct bblock* new_bb);
struct bblock* bblock_append(struct bblock **new_bb, struct bblock **old_bb);
void add_return(struct bblock *bb);
void link_block(struct bblock *branch_to, struct bblock *branch_in);
void dump_bb (struct bblock* bb);
void dump_quad (struct quad* q); 
void print_target(struct astnode *node); 
void print_opcode(int opcode);
void print_source(struct astnode *src1, struct astnode *src2);
void print_name(struct astnode *src);

#endif //_GENQUAD_H
