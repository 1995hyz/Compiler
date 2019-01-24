%option noyywrap
%{
#include "tokens-manual.h"
#include <stdlib.h>
#include <string.h>
#define NOVAL 4040
#define OCTNUMBER 4041
#define HEXNUMBER 4042
#define REAL 4043

char* yylval;

%}
ILEN ([Uu](L|l|LL|ll)?|(L|l|LL|ll)[Uu]?)
EXP ([Ee][-+]?[0-9]+)
%%
\+\+	{yylval = yytext; return PLUSPLUS;}
--	{yylval = yytext; return MINUSMINUS;}
<<	{yylval = yytext; return SHL;}
>>	{yylval = yytext; return SHR;}
<=	{yylval = yytext; return LTEQ;}
>=	{yylval = yytext; return GTEQ;}
==	{yylval = yytext; return EQEQ;}
!=	{yylval = yytext; return NOTEQ;}
&&	{yylval = yytext; return LOGAND;}
||	{yylval = yytext; return LOGOR;}
\.\.\.	{yylval = yytext; return ELLIPSIS;}
\*=	{yylval = yytext; return TIMESEQ;}
/=	{yylval = yytext; return DIVEQ;}
%=	{yylval = yytext; return MODEQ;}
\+=	{yylval = yytext; return PLUSEQ;}
-=	{yylval = yytext; return MINUSEQ;}
<<=	{yylval = yytext; return SHLEQ;}
>>=	{yylval = yytext; return SHREQ;}
&=	{yylval = yytext; return ANDEQ;}
|=	{yylval = yytext; return OREQ;}
^=	{yylval = yytext; return XOREQ;}
auto	{yylval = yytext; return AUTO;}
break	{yylval = yytext; return BREAK;}	
case	{yylval = yytext; return CASE;}
char	{yylval = yytext; return CHAR;}
const	{yylval = yytext; return CONST;}
continue	{yylval = yytext; return CONTINUE;}
default	{yylval = yytext; return DEFAULT;}
do	{yylval = yytext; return DO;}
double	{yylval = yytext; return DOUBLE;}
else	{yylval = yytext; return ELSE;}
enum	{yylval = yytext; return ENUM;}
extern	{yylval = yytext; return EXTERN;}
float	{yylval = yytext; return FLOAT;}
for	{yylval = yytext; return FOR;}
goto	{yylval = yytext; return GOTO;}
if	{yylval = yytext; return IF;}
inline	{yylval = yytext; return INLINE;}
int	{yylval = yytext; return INT;}
long	{yylval = yytext; return LONG;}
register	{yylval = yytext; return REGISTER;}
restrict	{yylval = yytext; return RESTRICT;}
return	{yylval = yytext; return RETURN;}
short	{yylval = yytext; return SHORT;}


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
[0-9]+{EXP}[flFL]?	{
		yylval = yytext;
		return REAL;
		}
[~!%^&\*\(\)-\+\{\}\[\]:;<,>\.\?/]	{yylval=yytext;return *yytext;}
([_a-zA-Z])([_a-zA-Z0-9])*	{
		yylval = yytext;
		return IDENT;
		}
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
		printf("NUMBER\tINTEGER\t%lld\tINT\n", i);
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

realnum_parser(char* string_value){
	char* endptr;
	long long int i = strtoll(string_value, &endptr, 10);
	int length = strlen(endptr);
	char last_char = *(endptr + length - 1);
	if(last_char == 'f' || last_char == 'F'){
		*(endptr + length - 1) = '\0'; 
		printf("NUMBER\tREAL\t%ld%s\tFLOAT\n", i, endptr);
	}
	else if(last_char == 'l' || last_char == 'L'){
		*(endptr + length - 1) = '\0';
		printf("NUMBER\tREAL\t%ld%s\tLONG DOUBLE\n", i, endptr);
	}
	else{
		printf("NUMBER\tREAL\t%ld%s\tDOUBLE\n", i, endptr);
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
			case IDENT: printf("IDENT\t%s\n", yylval);
					break;
			case REAL: realnum_parser(yylval);
					break;
			case PLUSPLUS: printf("PLUSPLUS\n");
					break;
			case MINUSMINUS: printf("MINUSMINUS\n")
					break;
			case NOVAL: printf("%s\n", yylval);
					break;
			default:
				printf("%s\n", yylval);
		}
	}
	printf("EOF\n");
}
