%option noyywrap
%{
#include "tokens-manual.h"
#include <stdlib.h>
#include <string.h>
#define NOVAL 4040
#define OCTNUMBER 4041

char* yylval;

%}
%%
0+[0-7]*[LU]*(LLU)*	{
				yylval = yytext;
				return OCTNUMBER;
			}
[1-9]+[0-9]*[LU]*(LLU)*	{
		/*char* endptr;
		long int i = strtol(yytext, &endptr, 10);
		//yylval=atoi(yytext);
		if(i > 32767){
			fprintf(stderr, "Error: yylval exceeds.");
			yylval = 32767;
		}
		else{
			yylval = (int) i;
		}
		if(strcmp(endptr, "L") == 0){
			return LONG;
		}
		if(strcmp(endptr, "U") == 0){
			return UNSIGNED;
		}
		if(strcmp(endptr, "LLU" == 0)){
			return LONG;
		}*/
		yylval = yytext;
		return NUMBER;
		}
[\+-]	{yylval=yytext;return NOVAL;}
 .	{fprintf(stderr, "Error: unknown token %s\n", yytext);}

%%

my_atoi(char* string_value, int base){
	char* endptr;
	long int i = strtol(string_value, &endptr, base);
	if(strcmp(endptr, "L") == 0){
		printf("NUMBER\tINTEGER\t%lld\tLONG\n", i);
	}	
	else if(strcmp(endptr, "U") == 0){
		printf("NUMBER\tINTEGER\t%lld\tUNSIGNED INT\n", i);
	}
	else if(strcmp(endptr, "LLU") == 0){
		printf("NUMBER\tINTEGER\t%lld\tUNSIGNED LONGLONG\n", i); 
	}
	else{
		printf("NUMBER\tINTEGER\t%lld\tINT\n", i);
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
			case NOVAL: printf("%s\n", yylval);
					break;
		}
	}
	printf("EOF\n");
}
