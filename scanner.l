%option noyywrap
%{
#include "tokens-manual.h"
#include <stdlib.h>
#include <string.h>
#define NOVAL 4040
#define OCTNUMBER 4041
#define HEXNUMBER 4042
#define REAL 4043

union YYLVAL{
	char* s;
	long long int i;
} yylval;
char buf[1024];

%}
ILEN ([Uu](L|l|LL|ll)?|(L|l|LL|ll)[Uu]?)
EXP ([Ee][-+]?[0-9]+)

%x char_escape
%x WAIT_END

%%
(\+\+)	{yylval.s = yytext; return PLUSPLUS;}
(--)	{yylval.s = yytext; return MINUSMINUS;}
(<<)	{yylval.s = yytext; return SHL;}
(>>)	{yylval.s = yytext; return SHR;}
(<=)	{yylval.s = yytext; return LTEQ;}
(>=)	{yylval.s = yytext; return GTEQ;}
(==)	{yylval.s = yytext; return EQEQ;}
(!=)	{yylval.s = yytext; return NOTEQ;}
(&&)	{yylval.s = yytext; return LOGAND;}
(\|\|)	{yylval.s = yytext; return LOGOR;}
(\.\.\.)	{yylval.s = yytext; return ELLIPSIS;}
(\*=)	{yylval.s = yytext; return TIMESEQ;}
(\/=)	{yylval.s = yytext; return DIVEQ;}
(%=)	{yylval.s = yytext; return MODEQ;}
(\+=)	{yylval.s = yytext; return PLUSEQ;}
(-=)	{yylval.s = yytext; return MINUSEQ;}
(<<=)	{yylval.s = yytext; return SHLEQ;}
(>>=)	{yylval.s = yytext; return SHREQ;}
(&=)	{yylval.s = yytext; return ANDEQ;}
(\|=)	{yylval.s = yytext; return OREQ;}
(^=)	{yylval.s = yytext; return XOREQ;}
auto	{yylval.s = yytext; return AUTO;}
break	{yylval.s = yytext; return BREAK;}	
case	{yylval.s = yytext; return CASE;}
char	{yylval.s = yytext; return CHAR;}
const	{yylval.s = yytext; return CONST;}
continue	{yylval.s = yytext; return CONTINUE;}
default	{yylval.s = yytext; return DEFAULT;}
do	{yylval.s = yytext; return DO;}
double	{yylval.s = yytext; return DOUBLE;}
else	{yylval.s = yytext; return ELSE;}
enum	{yylval.s = yytext; return ENUM;}
extern	{yylval.s = yytext; return EXTERN;}
float	{yylval.s = yytext; return FLOAT;}
for	{yylval.s = yytext; return FOR;}
goto	{yylval.s = yytext; return GOTO;}
if	{yylval.s = yytext; return IF;}
inline	{yylval.s = yytext; return INLINE;}
int	{yylval.s = yytext; return INT;}
long	{yylval.s = yytext; return LONG;}
register	{yylval.s = yytext; return REGISTER;}
restrict	{yylval.s = yytext; return RESTRICT;}
return	{yylval.s = yytext; return RETURN;}
short	{yylval.s = yytext; return SHORT;}


0[0-7]*{ILEN}?	{
		yylval.s = yytext;
		return OCTNUMBER;
		}
[1-9][0-9]*{ILEN}?	{
		yylval.s = yytext;
		return NUMBER;
		}
0[Xx][0-9a-fA-F]+{ILEN}?	{
		yylval.s = yytext;
		return HEXNUMBER;
		}
[0-9]+{EXP}[flFL]?	{
		yylval.s = yytext;
		return REAL;
		}
[~!%^&\*\(\)-\+\{\}\[\]:;<,>\.\?/]	{yylval.s=yytext;return *yytext;}
([_a-zA-Z])([_a-zA-Z0-9])*	{
		yylval.s = yytext;
		return IDENT;
		}

'	BEGIN(char_escape);
	
<char_escape>\\([0-7]{1,4})	{
			long int num = strtol(yytext+1, NULL, 8);
			yylval.i = num;
			BEGIN(WAIT_END);
			}
<char_escape>\\[abfnrtv]	{
			int num = *(yytext+1);
			switch(num){
				case 97: yylval.i = 7;
				case 98: yylval.i = 8;
				case 102: yylval.i = 12;
				case 110: yylval.i = 10;
				case 114: yylval.i = 13;
				case 116: yylval.i = 9;
				case 118: yylval.i = 11;
			}
			BEGIN(WAIT_END);
			}
<char_escape>[a-zA-Z0-9]	{
			yylval.i = *yytext;
			BEGIN(WAIT_END);
			}
<WAIT_END>'	{
		BEGIN(INITIAL);
		return CHARLIT;
		}
<WAIT_END>.	{
		//fprintf(stderr, "Warning: Unsupported multibyte character literal truncated to first byte\n");
		;
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
			case NUMBER: my_atoi(yylval.s, 10);
					break;
			case OCTNUMBER: my_atoi(yylval.s, 8);
					break;
			case HEXNUMBER: my_atoi(yylval.s, 16);
					break;
			case IDENT: printf("IDENT\t%s\n", yylval.s);
					break;
			case REAL: realnum_parser(yylval.s);
					break;
			case CHARLIT:	if(yylval.i > 32 && yylval.i < 127){
						printf("%c\n", yylval.i);
					}
					else{
						printf("\\%o", yylval.i);
					}
					break;
			case PLUSPLUS: printf("PLUSPLUS\n");
					break;
			case MINUSMINUS: printf("MINUSMINUS\n");
					break;
			case NOVAL: printf("%s\n", yylval.s);
					break;
			default:
				printf("%s\n", yylval.s);
		}
	}
	printf("EOF\n");
}
