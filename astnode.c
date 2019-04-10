#include "astnode.h"
#include "parser.tab.h"
#include "symTable.h"
#include <stdio.h>
#include <stdlib.h>

struct astnode* astnode_alloc(int type){
	struct astnode* new_node = malloc(sizeof(struct astnode));
	if(!new_node){
		fprintf(stderr, "out of space");
		exit(1);
	}
	new_node -> node_type = type;
	new_node -> next_node = NULL;
	return new_node;
}

void astnode_link(struct astnode** head, struct astnode** tail, struct astnode* new_insert) {
	if(*head == NULL) {
		*head = new_insert;
	}
	if(*tail == NULL) {
		*tail = new_insert;
	}
	else {
		(*tail)->next_node = new_insert;
		*tail = new_insert;
	}
	while((*tail)->next_node != NULL) {
		*tail = (*tail)->next_node;	//Pay attention to potential infinite loop here.
	}
}

void print_tree(struct astnode *node, int indent){
	indent++;
	print_indent(indent);
	switch(node->node_type){
		case AST_ident:
		{
			//printf("IDENT %s\n", node->u.ident.name);
			print_sym_entry(node->u.ident.entry);
			break;
		}
		case AST_binop:
		{	
			switch(node->u.binop.operator){
				case '+': printf("BINARY OP +\n"); break;
				case '-': printf("BINARY OP -\n"); break;
				case '*': printf("BINARY OP *\n"); break;
				case '/': printf("BINARY OP /\n"); break;
				case '%': printf("BINARY OP %\n"); break;
				case SHR: printf("BINARY OP >>\n"); break;
				case SHL: printf("BINARY OP <<\n"); break;
				case '>': printf("COMPARISON OP >\n"); break;
				case '<': printf("COMPARISON OP <\n"); break;
				case LTEQ: printf("COMPARISON OP <=\n"); break;
				case GTEQ: printf("COMPARISON OP >=\n"); break;
				case EQEQ: printf("COMPARISON OP ==\n"); break;
				case NOTEQ: printf("COMPARISON OP !=\n"); break;
				case '&': printf("BINARY OP &\n"); break;
				case '^': printf("BINARY OP ^\n"); break;
				case '|': printf("BINARY OP |\n"); break;
				case LOGAND: printf("LOGICAL OP &&\n"); break;
				case LOGOR: printf("LOGICAL OP ||\n"); break;
				case '=': printf("ASSIGNMENT\n"); break;
				case ',': printf("BINARY OP ,\n"); break;
				case '.': printf("SELECT\n"); break;
				default: printf("internal error: not finding the binary oprator %d\n", node->u.binop.operator);
			}
			//printf("BINARY OP %c\n", node->u.binop.operator);
			print_tree(node->u.binop.left, indent);
			print_tree(node->u.binop.right, indent);
			break;
		}
		case AST_unary:
		{	
			switch(node->u.unaop.operator){
				case PLUSPLUS: printf("UNARY OP POSTINC\n"); break;
				case MINUSMINUS: printf("UNARY OP NEGTNIC"); break;
				case SIZEOF: printf("SIZEOF\n"); break;
				default: printf("UNARY OP %c\n", node->u.unaop.operator);
			}
			if(node->u.unaop.left != NULL){
				print_tree(node->u.unaop.left, indent);
			}
			if(node->u.unaop.right != NULL){
				print_tree(node->u.unaop.right, indent);
			}
			break;
		}
		case AST_num:
		{	printf("NUM %lld\n", node->u.num.value);	
			break;
		}
		case AST_string:
		{	printf("STRING %s\n", node->u.string.value);
			break;
		}
		case AST_func:
		{	printf("FUNC\n");
			print_tree(node->u.func.name, indent);
			print_tree(node->u.func.next, indent);
			break;
		}
		case AST_argu:
		{	printf("argu #%d=\n", node->u.argu.num);
			print_tree(node->u.argu.value, indent);
			if(node->u.argu.next != NULL){
				indent--;
				print_tree(node->u.argu.next, indent);
			}
			break;
		}
		case AST_ternary:
		{	printf("TERNARY OP, IF:\n");
			print_tree(node->u.tern.first, indent);
			print_indent(indent);
			printf("THEN:\n");
			print_tree(node->u.tern.second, indent);
			print_indent(indent);
			printf("ELSE:\n");
			print_tree(node->u.tern.third, indent);
			break;
		}
		case AST_compound: 
		{	printf("LIST {\n");
			print_tree(node->u.comp.list, indent);
			print_indent(indent);
			printf("}\n");
			break;
		}
		case AST_block:
		{	print_tree(node->u.blo.item, indent);
			if(node->u.blo.next_block != NULL) {
				print_tree(node->u.blo.next_block, indent);
			}
			break;
		}
		case AST_if:
		{	printf("IF, EXPR:\n");
			print_tree(node->u.if_node.expr, indent);
			print_indent(indent);
			printf("BODY:\n");
			print_tree(node->u.if_node.if_body, indent);
			if(node->u.if_node.else_body != NULL) {
				print_tree(node->u.if_node.else_body, indent);
			}
			break;
		}
		case AST_while:
		{	printf("WHILE, EXPR\n");
			print_tree(node->u.while_node.expr, indent);
			print_indent(indent);
			printf("BODY\n");
			print_tree(node->u.while_node.body, indent);
			break;
		}
		case AST_do:
		{	printf("DO, STMT\n");
			print_tree(node->u.do_node.body, indent);
			print_indent(indent);
			printf("EXPR\n");
			print_tree(node->u.do_node.expr, indent);
			break;
		}
		case AST_case:
		{	printf("CASE\n");
			print_indent(indent+1);
			printf("EXPR\n");
			print_tree(node->u.case_node.expr, indent+1);
			print_indent(indent+1);
			printf("STMT\n");
			print_tree(node->u.case_node.body, indent+1);
			break;
		}
		case AST_default:
		{	printf("DEFAULT\n");
			print_tree(node->u.default_node.body, indent);
			break;
		}
		case AST_switch:
		{	printf("SWITCH\n");
			print_indent(indent+1);
			printf("EXPR\n");
			print_tree(node->u.switch_node.expr, indent+1);
			print_indent(indent+1);
			printf("BODY\n");
			print_tree(node->u.switch_node.body, indent+1);
			break;
		}
		case AST_goto:
		{	printf("GOTO ");
			print_tree(node->u.goto_node.ident, 0);
			break;
		}
		case AST_continue:
		{	printf("CONTINUE\n");
			break;
		}
		case AST_break:
		{	printf("BREAK\n");
			break;
		}
		case AST_return:
		{	printf("RETURN\n");
			if(node->u.return_node.expr != NULL) {
				print_tree(node->u.return_node.expr, indent);
			}
			else {
				printf("RETURN VOID\n");
			}
			break;
		}
		case AST_for:
		{	printf("FOR\n");
			if(node->u.for_node.init != NULL) {
				print_indent(indent);
				printf("INIT:\n");
				print_tree(node->u.for_node.init, indent+1);
			}
			if(node->u.for_node.cond != NULL) {
				print_indent(indent);
				printf("COND:\n");
				print_tree(node->u.for_node.cond, indent+1);
			}
			print_indent(indent);
			printf("BODY:\n");
			print_tree(node->u.for_node.body, indent+1);
			if(node->u.for_node.incr != NULL) {
				print_indent(indent);
				printf("INCR:\n");
				print_tree(node->u.for_node.incr, indent+1);
			}
			break;
		}
		default: printf("internal error: free bad node %d\n", node->node_type);
	}
}

void tree_free(struct astnode *node){
	switch(node->node_type) {
		case AST_ident:
		case AST_num:
		case AST_string: {
			free(node);
			break;
		}
		case AST_binop: {
			tree_free(node->u.binop.left);
			tree_free(node->u.binop.right);
			break;
		}
		case AST_unary: {
			if(node->u.unaop.left != NULL){
				tree_free(node->u.unaop.left);
			}
			if(node->u.unaop.right != NULL){
				tree_free(node->u.unaop.right);
			}
			break;
		}
		case AST_func: {
			tree_free(node->u.func.name);
			tree_free(node->u.func.next);
			break;
		}
		case AST_argu: {
			if(node->u.argu.next != NULL){
				tree_free(node->u.argu.next);
			}
			tree_free(node->u.argu.value);
			break;
		}
		case AST_ternary: {
			tree_free(node->u.tern.first);
			tree_free(node->u.tern.second);
			tree_free(node->u.tern.third);
		}	
	}
;


}

void print_sym_entry(struct sym_entry *entry) {
	switch(entry->entry_type) {
		case VAR_TYPE: {
			printf("stab_var name=%s def @%s:%d\n", entry->name, entry->def_file, entry->def_num);
			break;
		}
		case FUNC_TYPE: {
			printf("stab_fn name=%s def @%s:%d\n", entry->name, entry->def_file, entry->def_num);
			break;
		}
		default: {
			printf("Error: Unknown entry type when print ast-tree sym-entry.\n");
		}
	}
}

void print_indent(int indent) {
	while(indent > 1) {
		printf("%c", ' ');
		indent--;
	}
}
