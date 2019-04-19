#include <astnode.h>

#define ADD 1

struct quad {
	int opcode;
	struct astnode *result, *src1, *src2;
	struct quad *next;
}

struct astnode* gen_rvalue(struct astnode *node, struct astnode *target);
struct astnode* new_temporary();
