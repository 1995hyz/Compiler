#ifndef _SYMTABLE_H
#define _SYMTABLE_H
#include "astnode.h"

#define FILE_SCOPE 1
#define FUNC_SCOPE 2
#define BLOCK_SCOPE 3
#define PROTO_SCOPE 4

#define VAR_TYPE 5
#define FUNC_TYPE 6

struct sym_table {
	int scope_type;
	struct sym_table* parent_table;
	struct sym_entry *first;
	struct sym_entry *last;
};

struct var_entry {
	int storage_class;
	int offset;
};

struct func_entry {
	int storage_class;
	int complete;
};

struct sym_entry {
	int entry_type;
	char name[1024];
	struct sym_table* curr_table;
	struct sym_entry *next;
	union sym_entries {
		struct var_entry var;
		struct func_entry func;
	} e;
	struct astnode *first_node;
};

struct sym_table* sym_table_alloc(int scope_type);
struct sym_entry* sym_entry_alloc(int entry_type, char* name, struct sym_table *curr_table, struct sym_entry *next);
int search_ident(struct sym_table *curr_table, char *ident);

#endif //_SYMTABLE_H