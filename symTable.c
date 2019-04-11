#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symTable.h"
#include "parser.tab.h"

struct sym_table* sym_table_alloc(int scope_type, int def_num) {
	struct sym_table *new_table = malloc(sizeof(struct sym_table));
	if(!new_table){
		fprintf(stderr, "out of space for sym table\n");
		exit(1);
	}
	new_table->scope_type = scope_type;
	new_table->def_num = def_num;
	return new_table;
}

struct sym_entry* search_entry(struct sym_table *curr_table, char *ident, int entry_type) {
	if(curr_table->first != NULL) {
		struct sym_entry *curr_entry = curr_table->first;
		struct sym_entry *i = NULL;
		while(1) {
			if (strcmp(curr_entry->name, ident) == 0){
				switch(entry_type) {
					case MEMBER_TYPE: {
						i = curr_entry;
						break;
					}
					case STRUCT_TYPE: {
						if(curr_entry->entry_type == STRUCT_TYPE || curr_entry->entry_type == UNION_TYPE) {
							i = curr_entry;
							break;
						}
					}
					case UNION_TYPE: {
						if(curr_entry->entry_type == STRUCT_TYPE || curr_entry->entry_type == UNION_TYPE) {
							i = curr_entry;
							break;
						}
					}
					case LABEL_TYPE: {
						if(curr_entry->entry_type == LABEL_TYPE) {
							i = curr_entry;
							break;
						}
					}
					default: {
						if(curr_entry->entry_type != STRUCT_TYPE && curr_entry->entry_type != UNION_TYPE && curr_entry->entry_type != MEMBER_TYPE) {
							i = curr_entry;
							break;
						}
					}
				}
				break;
			}
			curr_entry = curr_entry->next;
			if(curr_entry == NULL){
				break;
			}
		}
		if(i != NULL) {
			return i; // Find the ident.
		}
	}
	else {
		return NULL;
	}
}

struct sym_entry* search_all(struct sym_table *curr_table, char *ident, int entry_type) {
	struct sym_entry* i;
	i = search_entry(curr_table, ident, entry_type);
	if (i != NULL) {
		return i;
	}
	else {
		while(curr_table != NULL) {
			if(curr_table->parent_table != NULL) {
				i = search_entry(curr_table->parent_table, ident, entry_type);
				if (i != NULL) {
					return i;
				}
			}
			curr_table = curr_table->parent_table;
		}
	}
	return NULL;
}

struct sym_entry* sym_entry_alloc(int entry_type, char* name, struct sym_table* curr_table, struct sym_entry* next_entry, char *def_file, int def_num) {
	struct sym_entry *new_entry = malloc(sizeof(struct sym_entry));
	if(!new_entry) {
		fprintf(stderr, "out of space for sym entry\n");
		exit(1);
	}
	new_entry->entry_type = entry_type;
	strncpy(new_entry->name, name, 1024);
	new_entry->curr_table = curr_table;
	new_entry->next = next_entry;
	strncpy(new_entry->def_file, def_file, 1024);
	new_entry->def_num =  def_num;
	return new_entry;
}

struct sym_entry* insert_entry(struct sym_table* curr_table, struct sym_entry* new_entry) {
	struct sym_entry *finding = search_entry(curr_table, new_entry->name, new_entry->entry_type);
	if(finding != NULL) {
		return finding; //Entry already exist.
	}
	else {
		
		if(curr_table->first == NULL) {
			curr_table->first = new_entry;
			curr_table->last = new_entry;
		}
		else {
			curr_table->last->next = new_entry;
			curr_table->last = new_entry;
		}
	}
	return NULL; //Succesfully added the entry
}

int trace_entry(struct sym_entry* entry) {
	int indent = 0;
	struct astnode *node = entry->first_node;
	while(node != NULL){
		int curr_indent = indent;
		printf(" ", indent);
		int node_type = node->node_type;
		switch(node_type){
			case AST_scaler: {
				switch(node->u.scaler.scaler_type) {
					case CHAR: printf("CHAR\n"); break;
					case SHORT: printf("SHORT\n"); break;
					case INT: printf("INT\n"); break;
					case LONG: printf("LONG\n"); break;
					case UNSIGNED: printf("UNSIGNED\n"); break;
					case CONST: printf("CONST\n"); break;
					case RESTRICT: printf("RESTRICT\n"); break;
					case VOLATILE: printf("VOLATILE\n"); break;
					default: printf("Error: Unknown scaler type.\n");
				}
				break;
			}
			case AST_struct: {
				if((node->u.uni.name)[0] == '\0') {
					printf("struct (anonymous)\n");
				}
				else {
					printf("struct %s\n", node->u.uni.name);
				}
				break;
			}
			case AST_union: {
				if((node->u.stru.name)[0] == '\0') {
					printf("union (anonymous)\n");
				}
				else {
					printf("union %s\n", node->u.stru.name);
				}
				break;
			}
			case AST_pointer: {
				printf("pointer to\n");
				break;
			}
			case AST_array: {
				printf("array #%d\n", node->u.arr.num);
				break;
			}
			default: {
				printf("Error: Unknown astnode type.\n");
			}
		}
		node = node -> next_node;
		indent = indent + 1;	
	}
}

int print_scope(struct sym_entry* entry) {
	switch(entry->curr_table->scope_type) {
		case FILE_SCOPE: {
			printf("[in global scope starting at %d] ", entry->curr_table->def_num);
			break;
		}
		case STRUCT_SCOPE: {
			printf("[in struct/union scope starting at %d] ", entry->curr_table->def_num);
			break;
		}
		case FUNC_SCOPE: {
			printf("[in function scope starting at %d] ", entry->curr_table->def_num);
			break;
		}
		case BLOCK_SCOPE: {
			printf("[in block scope starting at %d] ", entry->curr_table->def_num);
			break;
		}
		default: {
			printf("****Error: Current scope undefined.****");
			return 1;
		}
	}
	return 0;
}

int print_entry(struct sym_entry* entry, int step_in) {
	switch(entry->entry_type) {
		case VAR_TYPE: {
			printf("%s is defined at %s:%d ", entry->name, entry->def_file, entry->def_num);
			print_scope(entry);
			printf("as a variable with stgclass ");
			print_storage_class(entry->e.var.storage_class);
			printf(" of type:\n");
			trace_entry(entry);
			break;
		}
		case STRUCT_TYPE: {
			if(step_in == 1) {
				break;
			}
			if(entry->e.stru.complete == 1) {
				if((entry->name)[0] == '\0') {
					printf("struct (anonymous) ");
				}
				else {
					printf("struct %s ", entry->name);
				}
				printf("definition at %s:%d {\n", entry->def_file, entry->def_num);
				print_table(entry->e.stru.table);
				printf("}\n");
			}
			else {
				printf("struct %s is declared but undefined at %s:%d\n", entry->name, entry->def_file, entry->def_num);
			}
			break;
		}
		case UNION_TYPE: {
			if(step_in == 1) {
				break;
			}
			if(entry->e.uni.complete == 1) {
				if((entry->name)[0] == '\0') {
					printf("union (anonymous) ");
				}
				else {
					printf("union %s ", entry->name);
				}
				printf("definition at %s:%d {\n", entry->def_file, entry->def_num);
				print_table(entry->e.uni.table);
				printf("}\n");
			}
			break;
		}
		case MEMBER_TYPE: {
			printf("%s is defined at %s:%d ", entry->name, entry->def_file, entry->def_num);
			print_scope(entry);
			if(entry->curr_table->name != NULL) {
				printf("as a field of struct/union %s of type:\n", entry->curr_table->name);
			}
			else {
				printf("as a field of struct/union anonymous of type:\n");
			}
			trace_entry(entry);
			break;
		}
		case FUNC_TYPE: {
			if(entry->e.func.complete == 0) {
				printf("%s is declared but not defined at %s:%d ", entry->name, entry->def_file, entry->def_num);
			}
			else {
				printf("%s is defined at %s:%d ", entry->name, entry->def_file, entry->def_num);
			}
			print_scope(entry);
			printf("as a/an ");
			print_storage_class(entry->e.func.storage_class);
			printf("function returning ");
			trace_entry(entry);
			break;
		}
		default: {
			fprintf(stderr, "****Error: Current entry type undefined.****\n");
		}
	}
	return 0;
}

int print_table(struct sym_table* table) {
	int counter;
	counter = 0;
	struct sym_entry *n = table->first;
	while(n != NULL) {
		print_entry(n, 1);
		counter = counter + 1;
		n = n->next;
	}
	return counter;
}

print_storage_class(int storage_class) {
	switch(storage_class) {
		case AUTO_STORE: printf("auto "); break;
		case EXTERN_STORE: printf("extern "); break;
		case STATIC_STORE: printf("static "); break;
		case REGISTER_STORE: printf("register "); break;
		default: fprintf(stderr, "****Error: Current storage class type undefined.****\n");
	}
}

struct sym_entry* add_entry(struct astnode* node, struct sym_table *curr_scope, char *def_file, int def_num){
	switch(node->u.ident.ident_type) {
		case VAR_TYPE: {
			struct sym_entry *n = sym_entry_alloc(VAR_TYPE, node->u.ident.name, curr_scope, NULL, def_file, def_num);
			struct sym_entry *i = insert_entry(curr_scope, n);
			if(i != NULL) {
				fprintf(stderr, "****Error: Current entry %s has been defined at %s:%d ****\n", i->name, i->def_file, i->def_num);
				exit(1);
			}
			n->first_node = node->next_node;
			free(node);
			return n;
		}
		case STRUCT_TYPE: {
			struct sym_entry *n = sym_entry_alloc(STRUCT_TYPE, node->u.ident.name, curr_scope, NULL, def_file, def_num);
			struct sym_entry *i = insert_entry(curr_scope, n);
			n->first_node = node->next_node;
			free(node);
			return n;
		}
		case UNION_TYPE: {
			struct sym_entry *n = sym_entry_alloc(UNION_TYPE, node->u.ident.name, curr_scope, NULL, def_file, def_num);
			struct sym_entry *i = insert_entry(curr_scope, n);
			n->first_node = node->next_node;
			free(node);
			return n;
		}
		case MEMBER_TYPE: {
			struct sym_entry *n = sym_entry_alloc(MEMBER_TYPE, node->u.ident.name, curr_scope, NULL, def_file, def_num);
			struct sym_entry *i = insert_entry(curr_scope, n);
			if(i != NULL) {
				fprintf(stderr, "****Error: Current entry %s has been defined at %s:%d ****\n", i->name, i->def_file, i->def_num);
				exit(1);
			}
			n->first_node = node->next_node;
			free(node);
			return n;
		}
		case FUNC_TYPE: {
			struct sym_entry *n = sym_entry_alloc(FUNC_TYPE, node->u.ident.name, curr_scope, NULL, def_file, def_num);
			n->e.func.complete = 0;
			struct sym_entry *i = insert_entry(curr_scope, n);
			n->first_node = node->next_node;
			free(node);
			return n;
		}
		case LABEL_TYPE: {
			struct sym_entry *n = sym_entry_alloc(LABEL_TYPE, node->u.ident.name, curr_scope, NULL, def_file, def_num);
			struct sym_entry *i = insert_entry(curr_scope, n);
			return n;
		}
	}
	return NULL;
}
