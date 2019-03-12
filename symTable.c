#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symTable.h"
#include "parser.tab.h"

struct sym_table* sym_table_alloc(int scope_type) {
	struct sym_table *new_table = malloc(sizeof(struct sym_table));
	if(!new_table){
		fprintf(stderr, "out of space for sym table\n");
		exit(1);
	}
	new_table -> scope_type = scope_type;
	return new_table;
}

int search_entry(struct sym_table* curr_table, char *ident) {
	if(curr_table->first != NULL) {
		struct sym_entry *curr_entry = curr_table->first;
		int i = 1;
		while((i=strcmp(curr_entry->name, ident)) != 0){
			curr_entry = curr_entry->next;
			if(curr_entry == NULL){
				break;
			}
		}
		if(i == 0) {
			return 0; // Find the ident.
		}
		else {
			if(curr_table->parent_table != NULL) {
				int j = search_entry(curr_table->parent_table, ident);
				return j;
			}
			return 1;
		}
	}
	return 1;
}

struct sym_entry* sym_entry_alloc(int entry_type, char* name, struct sym_table* curr_table, struct sym_entry* next_entry) {
	struct sym_entry *new_entry = malloc(sizeof(struct sym_entry));
	if(!new_entry) {
		fprintf(stderr, "out of space for sym entry\n");
		exit(1);
	}
	new_entry->entry_type = entry_type;
	strncpy(new_entry->name, name, 1024);
	new_entry->curr_table = curr_table;
	new_entry->next = next_entry;
	return new_entry;
}

int insert_entry(struct sym_table* curr_table, struct sym_entry* new_entry) {
	int finding = search_entry(curr_table, new_entry->name);
	if(finding == 0) {
		return 1; //Entry already exist.
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
	return 0; //Succesfully added the entry
}

int print_entry(struct sym_entry* entry) {
	int indent = 0;
	struct astnode *node = entry->first_node;
	while(node != NULL){
		int curr_indent = indent;
		printf(" ", indent);
		int node_type = node->node_type;
		switch(node_type){
			case AST_scaler: {
				switch(node->u.scaler.scaler_type) {
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
				printf("struct %s\n", node->u.stru.name);
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
			printf("[in global scope starting at ***]");
			break;
		}
		default: {
			printf("****Error: Current scope undefined.****");
			return 1;
		}
	}
	return 0;
}

int print_result(char* file, int lineno, struct sym_entry* entry) {
	switch(entry->entry_type) {
		case VAR_TYPE: {
			printf("%s is defined at %s:%d ", entry->name, file, lineno);
			print_scope(entry);
			printf("as a variable with stgclass *** of type:\n");
			print_entry(entry);
			break;
		}
		case STRUCT_TYPE: {

		}
		default: {
			printf("****Error: Current entry type undefined.****\n");
		}
	}
	return 0;
}

struct sym_entry* add_entry(struct astnode* node, struct sym_table *curr_scope){
	switch(node->u.ident.ident_type) {
		case VAR_TYPE: {
			struct sym_entry *n = sym_entry_alloc(VAR_TYPE, node->u.ident.name, curr_scope, NULL);
			int i = insert_entry(curr_scope, n);
			n->first_node = node->next_node;
			free(node);
			return n;
		}
		case STRUCT_TYPE: {
			struct sym_entry *n = sym_entry_alloc(STRUCT_TYPE, node->u.stru.name, curr_scope, NULL);
			int i = insert_entry(curr_scope, n);
			n->first_node = node->next_node;
			free(node);
			return n;
		}
	}
	return NULL;
}
