#include "astnode.h"
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>

struct astnode* astnode_alloc(int type){
	struct astnode* new_node = malloc(sizeof(struct astnode));
	if(!new_node){
		fprintf(stderr, "out of space");
		exit(1);
	}
	new_node -> node_type = type;
	return new_node;
}

void astnode_link(struct astnode* head, struct astnode* tail, struct astnode* new_insert) {
	if(head == NULL) {
		head = new_insert;
	}
	if(tail == NULL) {
		tail = new_insert;
	}
	else {
		tail->next_node = new_insert;
		tail = new_insert;
	}
}

void print_tree(struct astnode *node, int indent){
	char space = ' ';
	indent++;
	int temp = indent;
	while (indent > 1){
		printf("%c", space);
		indent--;
	}
	indent = temp;
	switch(node->node_type){
		case AST_ident:
		{
			printf("IDENT %s\n", node->u.ident.name);
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
			printf("THEN:\n");
			print_tree(node->u.tern.second, indent);
			printf("ELSE:\n");
			print_tree(node->u.tern.third, indent);
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
