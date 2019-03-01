#ifndef _SYMTABLE_H
#define _SYMTABLE_H
#include "astnode.h"

#define FILE_SCOPE 1
#define FUNC_SCOPE 2
#define BLOCK_SCOPE 3
#define PROTO_SCOPE 4

struct sym_table {
	int scope_type;
	struct astnode *first;
}

struct sym_table* sym_table_alloc(int scope_type);
