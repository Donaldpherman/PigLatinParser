%{
int yylex();
%}

%{
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "parser.tab.h"
#include <stdbool.h>
#include <string.h>
 
#define TABSIZE 1000
#define true 1
#define false 0
 
extern char* var_names[TABSIZE];
extern int var_def[TABSIZE];
extern int n_of_names;
extern int install(char *txt);
extern void reset();
 
/* variables for the grammar file */
int invalid = false;            // just added for error checking
char* var_values[TABSIZE];     // array where all the values are stored
 
int yyerror(const char *p) 
{
    fprintf(stderr, "%s\n", p); // print the error message
    invalid = true;
    return true;
}
 
char* getLineFromPosition(const char* s, int* pos, char *line)
{
	for(int i = 0; ;++i)
	{
        line[i] = s[*pos];
		++(*pos);
        if(line[i] == '\0')
            return line;
        if(line[i] == '\n')
		{
            line[i+1]='\0';
            return line;
        }	
    }
}

bool match(char comparator, int colNumToCompare, int numberToCompare)
{

			switch(comparator)
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
%token <str> COMPARATOR;
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
			char newString[256];
            newString[0] = '\0';
			do{
                char line[256] = "";
				getLineFromPosition(variable, &pos, line);
				int colNumToCompare = atoi(&line[colID * 2]);
				
				if (match(*comparator, colNumToCompare, numberToCompare))
				{
					strcat_s(newString, 256, line);
				}
			}while(variable[pos] != '\0');
			
			$$ = newString;
		}
	
assignment : VARIABLE '=' command	
		{ 
			var_values[$1] = $3; 
			var_def[$1] = 1;  
			$$ = var_values[$1];
		}
;

%%
 
int main(void)
{
    /* reset all the definition flags first */
    reset();
     
    yyparse();
     
    return 0;
}