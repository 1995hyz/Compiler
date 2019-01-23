%option noyywrap
%{
#include "tokens-manual.h"
#include <stdlib.h>
#include <string.h>
#define NOVAL 4040
#define OCTNUMBER 4041
#define HEXNUMBER 4042

char* yylval;

%}
ILEN ([Uu](L|l|LL|ll)?|(L|l|LL|ll)[Uu]?)
EXP ([Ee][-+]?[0-9]+)
%%
0[0-7]*{ILEN}?	{
		yylval = yytext;
		return OCTNUMBER;
		}
[1-9][0-9]*{ILEN}?	{
		yylval = yytext;
		return NUMBER;
		}
0[Xx][0-9a-fA-F]+{ILEN}?	{
		yylval = yytext;
		return HEXNUMBER;
		}
[\+-]	{yylval=yytext;return NOVAL;}
 .	{fprintf(stderr, "Error: unknown token %s\n", yytext);}

%%

to_upper(char* dest, char* src){
	char* addr = NULL;
	while(*src != '\0'){
		char upper;
		if(*src > 96){
			upper = (char) *src - 32;
		}
		else{
			upper = *src;
		}
		*dest = upper;
		dest++;
		src++;
	}
}

my_atoi(char* string_value, int base){
	char* endptr;
	long long int i = strtoll(string_value, &endptr, base);
	char num_type[4] = {'\0', '\0', '\0', '\0'};
	to_upper(num_type, endptr);
	if(num_type[0] == '\0'){
		printf("number\tinteger\t%lld\tint\n", i);
	}
	else if(strcmp(&num_type[0], "L") == 0){
		printf("NUMBER\tINTEGER\t%lld\tLONG\n", i);
	}	
	else if(strcmp(&num_type[0], "U") == 0){
		printf("NUMBER\tINTEGER\t%lld\tUNSIGNED INT\n", i);
	}
	else if(strcmp(&num_type[0], "LL") == 0){
		printf("NUMBER\tINTEGER\t%lld\tLONGLONG\n", i);
	}
	else if(strcmp(&num_type[0], "LU") == 0 || strcmp(&num_type[0], "UL") == 0){
		printf("NUMBER\tINTEGER\t%lld\tUNSIGNED LONG\n", i); 
	}
	else if(strcmp(&num_type[0], "LLU") == 0 || strcmp(&num_type[0], "ULL") == 0){
		printf("NUMBER\tINTEGER\t%lld\tUNSIGNED LONGLONG\n", i); 
	}
	else{
		printf("number\tinteger\t%lld\tint\n", i);
	}
}

main()
{
int t;
	while (t=yylex())
	{
		switch(t)
		{
			case NUMBER: my_atoi(yylval, 10);
					break;
			case OCTNUMBER: my_atoi(yylval, 8);
					break;
			case HEXNUMBER: my_atoi(yylval, 16);
					break;
			case NOVAL: printf("%s\n", yylval);
					break;
		}
	}
	printf("EOF\n");
}
