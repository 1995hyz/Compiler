#include <symTable.h>

struct sym_table* sym_table_alloc(int scope_type) {
	struct sym_table* new_table = malloc(sizeof(struct sym_table));
	if(!new_table){
		fprintf(stderr, "out of space for sym table\n");
		exit(1);
	}
	new_table -> scope_type = scope_type;
	return new_table;
}
