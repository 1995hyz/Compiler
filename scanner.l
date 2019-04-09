%option noyywrap
%{
#include "parser.tab.h"
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#define SKIP 4040
#define REAL 4043

#if 0
union YYLVAL{

	char* s;
	long long int i;
} yylval;
#endif

char buf[1024];
int counter;
long long int line_num;
char file_name[1024] = "<stdin>";
char* num_type;

%}
ILEN ([Uu](L|l|LL|ll)?|(L|l|LL|ll)[Uu]?)
EXP ([Ee][-+]?[0-9]+)
BEXP ([Pp][-+]?[0-9]+)
FLOATING_PREFIX ([fFlL])
DIGIT_SEQ ([0-9]+)
HEX_DIGIT_SEQ ([0-9a-fA-F]+)

%x CHAR_ESCAPE
%x STRING_ESCAPE
%x WAIT_END
%x STRING_WAIT_END

%%
(->)	{yylval.s = yytext; return INDSEL;}
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
auto	{yylval.j = AUTO; return AUTO;}
break	{yylval.j = BREAK; return BREAK;}	
case	{yylval.j = CASE; return CASE;}
char	{yylval.j = CHAR; return CHAR;}
const	{yylval.j = CONST; return CONST;}
continue	{yylval.s = yytext; return CONTINUE;}
default	{yylval.s = yytext; return DEFAULT;}
do	{yylval.j = DO; return DO;}
double	{yylval.j = DOUBLE; return DOUBLE;}
else	{yylval.j = ELSE; return ELSE;}
enum	{yylval.s = yytext; return ENUM;}
extern	{yylval.j = EXTERN; return EXTERN;}
float	{yylval.j = FLOAT; return FLOAT;}
for	{yylval.s = yytext; return FOR;}
goto	{yylval.s = yytext; return GOTO;}
if	{yylval.j = IF; return IF;}
inline	{yylval.s = yytext; return INLINE;}
int	{yylval.j = INT; return INT;}
long	{yylval.j = LONG; return LONG;}
register	{yylval.j = REGISTER; return REGISTER;}
restrict	{yylval.j = RESTRICT; return RESTRICT;}
return	{yylval.s = yytext; return RETURN;}
short	{yylval.j = SHORT; return SHORT;}
signed	{yylval.j = SIGNED; return SIGNED;}
sizeof	{yylval.s = yytext; return SIZEOF;}
static	{yylval.j = STATIC; return STATIC;}
struct	{yylval.j = STRUCT; return STRUCT;}
switch	{yylval.s = yytext; return SWITCH;}
typedef	{yylval.s = yytext; return TYPEDEF;}
union	{yylval.j = UNION; return UNION;}
unsigned	{yylval.j = UNSIGNED; return UNSIGNED;}
void	{yylval.j = VOID; return VOID;}
volatile	{yylval.j = VOLATILE; return VOLATILE;}
while	{yylval.j = WHILE; return WHILE;}
_Bool	{yylval.j = _BOOL; return _BOOL;}
_Complex	{yylval.j = _COMPLEX; return _COMPLEX;}
_Imaginary	{yylval.s = yytext; return _IMAGINARY;}


0[0-7]*{ILEN}?	{
		yylval.i = strtoll(yytext, &num_type, 8);
		return NUMBER;
		}
[1-9][0-9]*{ILEN}?	{
		yylval.i = strtoll(yytext, &num_type, 10);
		return NUMBER;
		}
0[Xx][0-9a-fA-F]+{ILEN}?	{
		yylval.i = strtoll(yytext, &num_type, 16);
		return NUMBER;
		}
({DIGIT_SEQ}?\.{DIGIT_SEQ})|({DIGIT_SEQ}\.){EXP}?{FLOATING_PREFIX}?	{
		//Decimal Floating Constant 1
		yylval.s = yytext;
		return REAL;
	}
{DIGIT_SEQ}{EXP}{FLOATING_PREFIX}?	{
		//Decimal Floating Constant 2
		yylval.s = yytext;
		return REAL;
}
0[Xx]((({HEX_DIGIT_SEQ}?\.{HEX_DIGIT_SEQ})|({HEX_DIGIT_SEQ}\.))|({HEX_DIGIT_SEQ})){BEXP}{FLOATING_PREFIX}?	{
		//Hexdecimal Floating Constant
		yylval.s = yytext;
		return REAL;
	}
~	{yylval.i='~'; return '~';}
!	{yylval.i='!'; return '!';}
%	{yylval.i='%'; return '%';}
\^	{yylval.i='^'; return '^';}
&	{yylval.i='&'; return '&';}
\*	{yylval.i='*'; return '*';}
\(	{yylval.i='('; return '(';}
\)	{yylval.i=')'; return ')';}
\-	{yylval.i='-'; return '-';}
\+	{yylval.i='+'; return '+';}
\{	{yylval.i='{'; return '{';}
\}	{yylval.i='}'; return '}';}
\[	{yylval.i='['; return '[';}
\]	{yylval.i=']'; return ']';}
:	{yylval.i=':'; return ':';}
;	{yylval.i=';'; return ';';}
\<	{yylval.i='<'; return '<';}
,	{yylval.i=','; return ',';}
\>	{yylval.i='>'; return '>';}
\.	{yylval.i='.'; return '.';}
\?	{yylval.i='?'; return '?';}
\/	{yylval.i='/'; return '/';}
\|	{yylval.i='|'; return '|';}
=	{yylval.i='='; return '=';}

([_a-zA-Z])([_a-zA-Z0-9])*	{
		strncpy(yylval.arr, yytext, 1024);
		return IDENT;
		}

'	BEGIN(CHAR_ESCAPE);
\"		{
		int i = 0;
		while(i <= counter){	//Cleaning Global Virables
			buf[i] = '\0';
			i++;
		}
		counter = 0;
		yylval.s = &buf[0];
		BEGIN(STRING_ESCAPE);
		}

#\ [0-9]+\ \"[\ -~]+\".*$	{
		char *token;
		token = strtok(yytext, " ");
		token = strtok(NULL, " ");
		yylineno = strtoll(token, NULL, 10) - 1;
		token = strtok(NULL, " ");
		strcpy(file_name, token);
		}
<CHAR_ESCAPE>\\[0-7]{1,3}	{
			long int num = strtol(yytext+1, NULL, 8);
			yylval.i = num;
			BEGIN(WAIT_END);
			}
<CHAR_ESCAPE>\\[abfnrtv\\'"\?]	{
			int num = *(yytext+1);
			switch(num){
				case 'a': yylval.i = '\a';
					break;
				case 'b': yylval.i = '\b';
					break;
				case 'f': yylval.i = '\f';
					break;
				case 'n': yylval.i = '\n';
					break;
				case 'r': yylval.i = '\r';
					break;
				case 't': yylval.i = '\t';
					break;
				case 'v': yylval.i = '\v';
					break;
				default: yylval.i = num;
			}
			BEGIN(WAIT_END);
			}
<CHAR_ESCAPE>\\x[0-9a-fA-F]{1,2}	{
			long int num = strtol(yytext+2, NULL, 16);
			yylval.i = num;
			BEGIN(WAIT_END);
			}
<CHAR_ESCAPE>[#-&\(->@-\[\]-~]	{
			yylval.i = *yytext;
			BEGIN(WAIT_END);
			}
<STRING_ESCAPE>[#-&\(->@-\[\]-~]	{
		if(counter < 1024){
			buf[counter] = *yytext;
			counter++;
		}
		else{
			fprintf(stderr, "ERROR: String length is greater than buffer.\n");
			BEGIN(STRING_WAIT_END);
		}	
		}
<STRING_ESCAPE>\\x[0-9a-fA-F]+	{
		if(counter<1024){
			long long int num = strtoll(yytext+2, NULL, 16);
			if(num > 255){
				fprintf(stderr, "%s:%lld:Warning: Hex escape sequence out of range\n", &file_name[0], yylineno);
				num = 255;
			}
			buf[counter] = num;
			counter++;
		}
		else{
			fprintf(stderr, "ERROR: String length is greater than buffer.\n");
			BEGIN(STRING_WAIT_END);
		}
		}
<STRING_ESCAPE>\\[abfnrtv\\'"\?]	{
		if(counter < 1024){
			int num = *(yytext+1);
			switch(num){
				case 'a': buf[counter] = '\a';
					break;
				case 'b': buf[counter] = '\b';
					break;
				case 'f': buf[counter] = '\f';
					break;
				case 'n': buf[counter] = '\n';
					break;
				case 'r': buf[counter] = '\r';
					break;
				case 't': buf[counter] = '\t';
					break;
				case 'v': buf[counter] = '\v';
					break;
				default: buf[counter] = num;
 			}
			counter++;
			yylval.s = &buf[0];
		}
		else{
			fprintf(stderr, "ERROR: String length is greater than buffer.\n");
			BEGIN(STRING_WAIT_END);
		}
		}
<STRING_ESCAPE>\\[0-7]{1,3}	{
		if(counter<1024){
			//yylval.s = &buf[0]
			long int num = strtol(yytext+1, NULL, 8);
			buf[counter] = num;
			counter++;
		}
		else{
			fprintf(stderr, "ERROR: String length is greater than buffer.\n");
			BEGIN(STRING_WAIT_END);
		}
		}

<STRING_ESCAPE>\"	{
			BEGIN(INITIAL);
			return STRING;
		}	
<WAIT_END>'	{
		BEGIN(INITIAL);
		return CHARLIT;
		}
<WAIT_END>.	{
		if(counter == 0){
			fprintf(stderr, "%s:%lld:Warning:Unsupported multibyte character literal truncated to first byte\n", &file_name[0], yylineno);
			counter++;
		}
		}
<STRING_WAIT_END>\"	{
		BEGIN(INITIAL);
		counter = 0;
		return STRING;
	}
<STRING_WAIT_END>.	{
		;
	}

[ ]+	{}

\n	{yylineno++;}

 .	{fprintf(stderr, "Error: unknown token %s\n", yytext);}

%%

void to_upper(char* dest, char* src){
	char* addr = NULL;
	while(*src != '\0'){
		char upper;
		/*if(*src > 96){
			upper = (char) *src - 32;
		}
		else{
			upper = *src;
		}*/
		upper = toupper(*src);
		*dest = upper;
		dest++;
		src++;
	}
}

void my_atoi(char* endptr){
	char num_type[4] = {'\0', '\0', '\0', '\0'};
	to_upper(num_type, endptr);
	if(num_type[0] == '\0'){
		printf("INT");
	}
	else if(strcmp(&num_type[0], "L") == 0){
		printf("LONG");
	}	
	else if(strcmp(&num_type[0], "U") == 0){
		printf("UNSIGNED INT");
	}
	else if(strcmp(&num_type[0], "LL") == 0){
		printf("LONGLONG");
	}
	else if(strcmp(&num_type[0], "LU") == 0 || strcmp(&num_type[0], "UL") == 0){
		printf("UNSIGNED LONG"); 
	}
	else if(strcmp(&num_type[0], "LLU") == 0 || strcmp(&num_type[0], "ULL") == 0){
		printf("UNSIGNED LONGLONG"); 
	}
	else{
		printf("INT");
	}
}

void realnum_parser(char* string_value){
	/*char* endptr;
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
	}*/
	printf("NUMBER\tREAL\t%s", yylval.s);
}

void char_printer(char current_char){
	if(current_char > 32 && current_char < 127 && current_char != 34 && current_char != 39 &&
	current_char != 63 && current_char != 92){
		printf("%c", current_char);
	}
	else{
		switch(current_char){
			case 0: printf("\\0");
				break;
			case '\a': printf("\\a");
				break;
			case '\b': printf("\\b");
				break;
			case '\f': printf("\\f");
				break;
			case '\n': printf("\\n");
				break;
			case '\r': printf("\\r");
				break;
			case '\t': printf("\\t");
				break;
			case '\v': printf("\\v");
				break;
			case '\\': printf("\\\\");
				break;
			case '\'': printf("\\\'");
				break;
			case '\"': printf("\\\"");
				break;
			case '\?': printf("\?");
				break;
			default: {
				if(current_char >= 0){
					printf("\\%03o", current_char);
				}
				else{
					int i = current_char;
					i += 256;
					printf("\\%03o", i);
				}
			}
		}
	}
}

/*void main()
{
int t;
	while (t=yylex())
	{
		if(t != SKIP){
			printf("%s\t%lld\t", &file_name[0], line_num);
		}
		switch(t)
		{
			case '~': printf("%c", yylval.i);
					break;
			case '!': printf("%c", yylval.i);
					break;
			case '%': printf("%c", yylval.i);
					break;
			case '^': printf("%c", yylval.i);
					break;
			case '&': printf("%c", yylval.i);
					break;
			case '*': printf("%c", yylval.i);
					break;
			case '(': printf("%c", yylval.i);
					break;
			case ')': printf("%c", yylval.i);
					break;
			case '-': printf("%c", yylval.i);
					break;
			case '+': printf("%c", yylval.i);
					break;
			case '{': printf("%c", yylval.i);
					break;
			case '}': printf("%c", yylval.i);
					break;
			case '[': printf("%c", yylval.i);
					break;
			case ']': printf("%c", yylval.i);
					break;
			case ':': printf("%c", yylval.i);
					break;
			case ';': printf("%c", yylval.i);
					break;
			case '<': printf("%c", yylval.i);
					break;
			case ',': printf("%c", yylval.i);
					break;
			case '>': printf("%c", yylval.i);
					break;
			case '.': printf("%c", yylval.i);
					break;
			case '?': printf("%c", yylval.i);
					break;
			case '/': printf("%c", yylval.i);
					break;
			case '|': printf("%c", yylval.i);
					break;
			case NUMBER: {	
					printf("NUMBER\tINTEGER\t%lld\t", yylval.i);
					my_atoi(num_type);
					break;
			}
			case IDENT: printf("IDENT\t%s", yylval.s);
					break;
			case REAL: realnum_parser(yylval.s);
					break;
			case CHARLIT: {
					char current_char = yylval.i;
					printf("CHARLIT\t");
					char_printer(current_char);
					break;
			}
			case INDSEL: printf("INDSEL");
					break;
			case PLUSPLUS: printf("PLUSPLUS");
					break;
			case MINUSMINUS: printf("MINUSMINUS");
					break;
			case SHL: printf("SHL");
					break;
			case SHR: printf("SHR");
					break;
			case LTEQ: printf("LTEQ");	
					break;
			case GTEQ: printf("GTEQ");
					break;
			case EQEQ: printf("EQEQ");
					break;
			case NOTEQ: printf("NOTEQ");
					break;
			case LOGAND: printf("LOGAND");
					break;
			case LOGOR: printf("LOGOR");
					break;
			case ELLIPSIS: printf("ELLIPSIS");
					break;
			case TIMESEQ: printf("TIMESEQ");
					break;
			case DIVEQ: printf("DIVEQ");
					break;
			case MODEQ: printf("MODEQ");
					break;
			case PLUSEQ: printf("PLUSEQ");
					break;
			case MINUSEQ: printf("MINUSEQ");
					break;
			case SHLEQ: printf("SHLEQ");
					break;
			case SHREQ: printf("SHREQ");
					break;
			case ANDEQ: printf("ANDEQ");
					break;
			case OREQ: printf("OREQ");
					break;
			case XOREQ: printf("XOREQ");
					break;
			case AUTO: printf("AUTO");
					break;
			case BREAK: printf("BREAK");
					break;
			case CASE: printf("CASE");
					break;
			case CHAR: printf("CHAR");
					break;
			case CONST: printf("CONST");
					break;
			case CONTINUE: printf("CONTINUE");
					break;
			case DEFAULT: printf("DEFAULT");
					break;
			case DO: printf("DO");
					break;
			case DOUBLE: printf("DOUBLE");
					break;
			case ELSE: printf("ELSE");
					break;
			case ENUM: printf("ENUM");
					break;
			case EXTERN: printf("EXTERN");
					break;
			case FLOAT: printf("FLOAT");
					break;
			case FOR: printf("FOR");
					break;
			case GOTO: printf("GOTO");
					break;
			case IF: printf("IF");
					break;
			case INLINE: printf("INLINE");
					break;
			case INT: printf("INT");
					break;
			case LONG: printf("LONG");
					break;
			case REGISTER: printf("REGISTER");
					break;
			case RESTRICT: printf("RESTRICT");
					break;
			case RETURN: printf("RETURN");
					break;
			case SHORT: printf("SHORT");
					break;
			case SIGNED: printf("SIGNED");
					break;
			case SIZEOF: printf("SIZEOF");
					break;
			case STATIC: printf("STATIC");
					break;
			case STRUCT: printf("STRUCT");
					break;
			case SWITCH: printf("SWITCH");
					break;
			case TYPEDEF: printf("TYPEDEF");
					break;
			case UNION: printf("UNION");
					break;
			case UNSIGNED: printf("UNSIGNED");
					break;
			case VOID: printf("VOID");
					break;
			case VOLATILE: printf("VOLATILE");
					break;
			case WHILE: printf("WHILE");
					break;
			case _BOOL: printf("_BOOL");
					break;
			case _COMPLEX: printf("_COMPLEX");
					break;
			case _IMAGINARY: printf("_IMAGINARY");
					break;
			case STRING: { 	printf("STRING\t");
					int i = 0;
					while(i<counter){
						char_printer(*(yylval.s+i));
						i++;
					}
					break;
			}
			case SKIP: 	continue;
			default:
				;
		}
		printf("\n");
		counter = 0;
	}
	printf("EOF\n");
}*/
