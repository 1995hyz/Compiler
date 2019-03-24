#ifndef _SYMTABLE_H
#define _SYMTABLE_H
#include "astnode.h"

#define FILE_SCOPE 1
#define FUNC_SCOPE 2
#define BLOCK_SCOPE 3
#define PROTO_SCOPE 4
#define STRUCT_SCOPE 5

#define VAR_TYPE 6
#define FUNC_TYPE 7
#define STRUCT_TYPE 8
#define UNION_TYPE 9
#define MEMBER_TYPE 10

#define AUTO_STORE 11
#define EXTERN_STORE 12
#define STATIC_STORE 13
#define REGISTER_STORE 14

struct sym_table {
	int scope_type;
	struct sym_table* parent_table;
	struct sym_entry *first;
	struct sym_entry *last;
	int def_num;
};

struct var_entry {
	int storage_class;
	//int offset;
};

struct func_entry {
	int storage_class;
	int complete;
};

struct struct_entry {
	struct sym_table *table;
	int complete;
};

struct union_entry {
	struct sym_table *table;
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
		struct struct_entry stru;
		struct union_entry uni;
	} e;
	struct astnode *first_node;
	int def_num;
	char def_file[1024];
};

struct sym_table* sym_table_alloc(int scope_type, int def_num);
struct sym_entry* sym_entry_alloc(int entry_type, char* name, struct sym_table *curr_table, struct sym_entry *next, char *def_file, int def_num);
struct sym_entry* search_ident(struct sym_table *curr_table, char *ident, int entry_type);
int print_entry(struct sym_entry* entry, int step_in);
int print_table(struct sym_table* table);
struct sym_entry* add_entry(struct astnode* astnode, struct sym_table *curr_scope, char *def_file, int def_num);

#endif //_SYMTABLE_H
