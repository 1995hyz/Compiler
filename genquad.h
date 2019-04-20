#include "astnode.h"

#define LOAD 256
#define STORE 257

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
};

struct astnode* gen_rvalue(struct astnode *node, struct astnode *target);
struct astnode* new_temporary();
struct quad* quad_alloc();
struct quad* emit(int opcode, struct astnode *src1, struct astnode *src2, struct astnode *result);
struct bblock* bblock_alloc();
void dump_bb (struct bblock* bb);
void dump_quad (struct quad* q); 
void print_target(struct astnode *node); 
void print_opcode(int opcode);
