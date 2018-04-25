%{
/*  Written by: Yancy Vance M. Paredes. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"
 
#define TABSIZE 1000
#define true 1
#define false 0
 
char* var_names[TABSIZE];   // where the variable names will be stored
int var_def[TABSIZE];       // flag to determine whether a var is defined
int n_of_names = 0;         // counter of variables
 
void reset()
{
    /* this will just reset all the flags to false */
    int j;
    for(j = 0; j < TABSIZE; j++)
        var_def[j] = false;
}
 
int install(char *txt)
{
    int j; char *s;
     
    /* if the table of var_names is still empty */
    /* add the first record at 0 and return 0 */
    if(n_of_names == 0) {
        s = _strdup(txt);
        var_names[0] = s;
        ++n_of_names;
        return 0;
    }
     
    /* if the table has contents already, return the index */
    for(j = 0; j < n_of_names; ++j) {
        if(strcmp(txt, var_names[j]) == 0) {
            return j;
        }
    }
     
    /* if the table is not empty and the var name is not yet listed */
    /* list the new var name and return the index */
    s = _strdup(txt);
    var_names[j] = s;
    ++n_of_names;
    return j;
}
 
%}

RW      LOAD|DUMP|FILTER|BY|FOREACH|GENERATE
number	[0-9]+
id      [a-zA-Z][a-zA-Z0-9]*
file	{id}\.{id}
comparator ">"|">="|"=="|"<="|"<"


%%
 
[ \t]                 { }
 
LOAD 		{return LOAD;}
DUMP 		{return DUMP;}
FILTER 		{return FILTER;}
BY 			{return BY;}
FOREACH 	{return FOREACH;}
GENERATE 	{return GENERATE;}

{file}  {
    /* Save file names  */
    yylval.str = yytext;
    return FILENAME;
}

"$"  {
    /* Save file names  */
    return COLUMNID;
}

{id}	{
    /* install the variable found to the array and return the index */
    yylval.index = install(yytext);
    return VARIABLE;
}

{comparator} {
                yylval.str = yytext;
                return COMPARATOR;
}

{number}  {
    /* convert yytext to a double and return it  */
    yylval.num = atoi(yytext);
    return NUMBER;
}

[ \n]	return EOL;
 
.                       {
    return yytext[0];
}
 
%%
 
int yywrap(void)
{
    return 1;
}
