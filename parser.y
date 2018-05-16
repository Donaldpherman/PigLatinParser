%{
int yylex();
%}

%{
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdbool.h>
#include <string.h>

#include "parser.tab.h"
 
#define TABSIZE 1000
#define true 1
#define false 0
 
extern char* var_names[TABSIZE];
extern int var_def[TABSIZE];
extern int n_of_names;
extern int install(char* txtParameter);
extern void reset();
 
// variables for the grammar file
int invalid = false;            // just added for error checking
char* var_values[TABSIZE];     // array where all the values are stored

struct ForEach
{
    int columnIndex;
    char* operator;
    int number;
};

struct ForEach for_each_values[TABSIZE];
int forEachValuesIndex;
 
int yyerror(const char *p) 
{
    fprintf(stderr, "%s\n", p); // print the error message
    invalid = true;
    return true;
}

void getLineFromPosition(const char* s, int* pos, char *line)
{
	for(int i = 0; ;++i)
	{
        line[i] = s[*pos];
		++(*pos);
        if(line[i] == '\0')
            return;
        if(line[i] == '\n')
		{
            line[i+1]='\0';
            return;
        }	
    }
}

bool match(char* comparator, int colNumToCompare, int numberToCompare)
{

			switch(*comparator)
			{
				case '>'  :
					return colNumToCompare > numberToCompare;
					break;
				case '>=' :
					return colNumToCompare >= numberToCompare;
					break;
				case '==' :
					return colNumToCompare == numberToCompare;
					break;
				case '<=' :
					return colNumToCompare <= numberToCompare;
					break;
				case '<'  :
					return colNumToCompare < numberToCompare;
					break;
				default :
					printf("error in match()");
			}
            return false;
}

int mathOperation(char* operator, int colNumToOperate, int numToOperate)
{
    if (operator == '\0')
        return colNumToOperate;
	switch(*operator)
	{
		case '+'  :
			return colNumToOperate + numToOperate;
			break;
		case '-' :
			return colNumToOperate - numToOperate;
			break;
		case '*' :
			return colNumToOperate * numToOperate;
			break;
		case '/' :
            if (numToOperate == 0)
            {
                printf("Divide by Zero Error");
                return 0;
            }
            return colNumToOperate / numToOperate;
			break;
		case '^'  :
			return (int)pow(colNumToOperate, numToOperate);
			break;
        case '\0' :
            return colNumToOperate;
            break;
		default :
			printf("error in mathOperation()");
	}
    return false;
}

%}
 
%union {
    /* this will be used for the yylval. */
    /* it is a union since three data types will be used */
    int num;     // the number provided by the user
    int index;      // index of the variable name inside the array
	char* str;
};
 
%start commands
%token <index> VARIABLE
%token <str> FILENAME
%token <num> NUMBER
%token <str> COMPARATOR
%token <str> OPERATOR
%token LOAD
%token DUMP
%token FILTER
%token BY
%token <num> COLUMNID
%token FOREACH
%token GENERATE
%token EOL
%type <str> load_filename
%type <str> dump_variable
%type <str> filter_by
%type <str> command
%type <str> assignment
%type <str> foreach_generate
%type <str> expression
%type <str> expressions
%type <str> math_expression
%type <str> columnid_math_expression

%%
 
commands: 						{ }
        | commands command EOL	{ }
        ;
 
command :
		load_filename
		|
		dump_variable
		|
		assignment
		|
		filter_by
        |
        foreach_generate
		;
 
load_filename:                           	
		LOAD FILENAME
		{
            FILE * f;
			fopen_s(&f, $2, "rb");
			fseek (f, 0, SEEK_END);
			long length = ftell (f);
			fseek (f, 0, SEEK_SET);
			char * buffer = malloc (length + 1);
			fread (buffer, 1, length, f);
			buffer[length] = '\0';
			fclose (f);
			$$ = buffer;
		}
		;
 
dump_variable:                           	
		DUMP VARIABLE
		{
			printf(var_values[$2]);
		}
		;
		
filter_by:
		FILTER VARIABLE BY COLUMNID NUMBER COMPARATOR NUMBER
		{
			char* variable = {var_values[$2]};
			int colID = $5;
			char* comparator = $6;
			int numberToCompare = $7;
			
			// get a line
			int pos = 0;
			char newString[256] = "";
			do{
                char line[256] = "";
				getLineFromPosition(variable, &pos, line);
				int colNumToCompare = atoi(&line[colID * 2]);
				
				if (match(comparator, colNumToCompare, numberToCompare))
				{
					strcat_s(newString, 256, line);
				}
			}while(variable[pos] != '\0');
			
			$$ = newString;
		}
	    ;

foreach_generate:
    FOREACH VARIABLE GENERATE expressions
    {
        char* variable = {var_values[$2]};
    	// get a line
		int pos = 0;
		char newString[100000] = "";
		do{
            char lineFromVariable[256] = "";
	        getLineFromPosition(variable, &pos, lineFromVariable);
            for (int i = 0; i < forEachValuesIndex; ++i)
            {
                struct ForEach foreach = for_each_values[i];
                int columnIndex = foreach.columnIndex;
                int colNumToOperate = atoi(&lineFromVariable[columnIndex * 2]);
                int result = mathOperation(foreach.operator, colNumToOperate, foreach.number);
                char buffer[100000] = "";
                _itoa_s(result, buffer, 100000, 10);
                strcat_s(newString, 100000, buffer);
                if (i != forEachValuesIndex - 1)
                    strcat_s(newString, 100000, ",");
            }
            strcat_s(newString, 100000, "\n");

        }while(variable[pos] != '\0');

        $$ = newString;

        forEachValuesIndex = 0;
    }

expressions:
    expression
    |
    expressions',' expression
    ;

expression:
    math_expression
    |
    columnid_math_expression
    ;
math_expression:
    COLUMNID NUMBER
    {
        struct ForEach forEach;
        forEach.columnIndex = $2;
        forEach.operator = '\0';
        forEach.number = 0;
        for_each_values[forEachValuesIndex] = forEach;
        forEachValuesIndex++;
    }
    ;
columnid_math_expression:
    COLUMNID NUMBER OPERATOR NUMBER
		{
            struct ForEach forEach;
            forEach.columnIndex = $2;
            forEach.operator = $3;
            forEach.number = $4;

            for_each_values[forEachValuesIndex] = forEach;
            forEachValuesIndex++;

		}
        ;
assignment : VARIABLE '=' command	
		{ ;
			var_values[$1] = $3; 
			var_def[$1] = 1;  
			$$ = var_values[$1];
		}
;

%%
 
int main(void)
{
    /* reset all the definition flags first */
    forEachValuesIndex = 0;
    reset();
     
    yyparse();
     
    return 0;
}
