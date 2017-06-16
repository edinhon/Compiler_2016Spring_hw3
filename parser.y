%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include "symbol_table.h"
extern int num_line;
extern char srcBuf[2048];
extern char* yytext;

extern int cur_counter;
extern int cur_scope;
extern symbol_entry table[2048];
int stack_counter = 0;

FILE *fp;

bool global_flag = false;
%}

%start program
%union{
	int intVal;
	char ident[32];
}

%token KEY_FOR KEY_WHILE KEY_DO KEY_IF KEY_ELSE KEY_SWTICH KEY_RETURN KEY_BREAK KEY_CONTINUE KEY_STRUCT KEY_CASE KEY_DEFAULT
%token KEY_NULL KEY_TRUE KEY_FALSE
%token KEY_CONST
%token TYPE_INT TYPE_DOUBLE TYPE_CHAR TYPE_BOOL TYPE_VOID
%token OPER_PP OPER_SS OPER_AA OPER_OO OPER_CMP
%token SCI DOUBLE CHAR STR
%token <intVal> INT
%token <ident> ID
%type <ident> var scalar_id


%left OPER_OO
%left OPER_AA
%right '!'
%left OPER_CMP
%left '+' '-'
%left '*' '/' '%'
%nonassoc UMINUS
%left OPER_PP OPER_SS
%left '[' ']'


%%

program:	statement
		|	statement program
		;
		
program_in_func:
			statement_in_func
		|	statement_in_func program_in_func
		;
		
program_in_case:
			statement_in_case
		|	statement_in_case program_in_case
		;

statement:	declare
		|	func_invocation ';'
		|	simple_statement
		;

statement_in_func:	
			declare_in_func
		|	simple_statement
		|	compound_statement
		|	if_else_statement
		|	switch_statement
		|	while_statement
		|	for_statement
		|	KEY_BREAK ';'
		|	KEY_CONTINUE ';'
		|	return_statement
		|	expr ';'
		;
		
statement_in_case:	
			simple_statement
		|	compound_statement
		|	if_else_statement
		|	switch_statement
		|	while_statement
		|	for_statement
		|	KEY_BREAK ';'
		|	KEY_CONTINUE ';'
		|	return_statement
		|	expr ';'
		;

declare:	type declare_ID ';'
		|	KEY_CONST type declare_const ';'
		|	type declare_function
		|	type_void declare_function
		;

declare_in_func:	
			type declare_ID ';'
		|	KEY_CONST type declare_const ';'
		;

declare_ID:	scalar
		|	array
		|	scalar ',' declare_ID
		|	array ',' declare_ID
		;

declare_const:
			ID '=' expr									{	}
		|	ID '=' expr ',' declare_const				{	}
		;

declare_function:
			ID '(' ')' ';'								{	int idx = cur_counter;
															install_symbol($1, stack_counter);
															set_symbol_mode_func(idx);
															stack_counter += 4;}
		|	ID '(' paras ')' ';'						{	int idx = cur_counter;
															install_symbol($1, stack_counter);
															set_symbol_mode_func(idx);
															stack_counter += 4;}
		|	ID '(' ')' '{' '}'							{	global_flag = true;
															int idx = cur_counter;
															install_symbol($1, stack_counter);
															set_symbol_mode_func(idx);
															stack_counter += 4;} 
		|	ID '(' paras ')' '{' '}'					{	global_flag = true;
															int idx = cur_counter;
															install_symbol($1, stack_counter);
															set_symbol_mode_func(idx);
															stack_counter += 4;} 
		|	ID '(' ')' '{' program_in_func '}'			{	global_flag = true;
															int idx = cur_counter;
															install_symbol($1, stack_counter);
															set_symbol_mode_func(idx);
															stack_counter += 4;} 
		|	ID '(' paras ')' '{' program_in_func '}'	{	global_flag = true;
															int idx = cur_counter;
															install_symbol($1, stack_counter);
															set_symbol_mode_func(idx);
															stack_counter += 4;} 
		;
		
type:		TYPE_INT									{set_symbol_type_int(cur_counter);}
		|	TYPE_DOUBLE									{set_symbol_type_double(cur_counter);}
		|	TYPE_CHAR									{set_symbol_type_char(cur_counter);}
		|	TYPE_BOOL									{set_symbol_type_bool(cur_counter);}
		;
		
type_void:	TYPE_VOID									{set_symbol_type_void(cur_counter);}
		
scalar:		scalar_id									{	}
		|	scalar_id '=' expr							{	int idx = look_up_symbol($1);
															if(idx != -1){
																fprintf(fp, "lwi	$r0, [$sp+%d]\n", stack_counter-4);
																fprintf(fp, "swi	$ro, [$sp+%d\n", table[idx].offset);
																stack_counter -= 4;
															}
														}
		;
		
scalar_id:	ID											{	if(look_up_symbol($1) == -1){
																int idx = cur_counter;
																install_symbol($1, stack_counter);
																set_symbol_mode_var(idx);
																stack_counter += 4;
																strcpy($$, $1);
															} else {
																int idx = look_up_symbol($1);
																if(table[idx].scope == cur_scope){
																	fprintf(stderr, "Error at line %d: Duplicate declaration: %s.\n", num_line, $1);
																	exit(1);
																}
															}
														}
		
array:		ID arr_state_index
		|	ID arr_state_index '=' '{' arr_content '}'
		|	ID arr_state_index '=' '{' '}'
		;

arr_state_index:	
			'[' INT ']'
		|	'[' INT ']' arr_state_index
		;

arr_content:
			exprs
		;

paras:		para
		|	para ',' paras
		;

para:		type ID										{	set_symbol_mode_argu(cur_counter);
															install_symbol($2, stack_counter);
															stack_counter += 4;}
		|	type ID arr_state_index
		;

var:		ID											{	strcpy($$, $1);}
		|	ID arr_expr_index
		;

simple_statement:
			var '=' expr ';'							{	int idx = look_up_symbol($1);
															fprintf(fp, "lwi	$r0, [$sp+%d]\n", stack_counter-4);
															fprintf(fp, "swi	$r0, [$sp+%d]\n", table[idx].offset);
															stack_counter -= 4;}
		;

compound_statement:
			'{' program_in_func '}'
		|	'{' '}'
		;
		
if_else_statement:
			KEY_IF '(' expr ')' '{' program_in_func '}' 
		KEY_ELSE '{' program_in_func '}'
		|	KEY_IF '(' expr ')' '{' '}' 
		KEY_ELSE '{' program_in_func '}'
		|	KEY_IF '(' expr ')' '{' program_in_func '}' 
		KEY_ELSE '{' '}'
		|	KEY_IF '(' expr ')' '{' '}' 
		KEY_ELSE '{' '}'
		
		|	KEY_IF '(' expr ')' '{' program_in_func '}'
		|	KEY_IF '(' expr ')' '{' '}'
		;

switch_statement:
			KEY_SWTICH '(' ID ')' '{' case_statements '}'
		|	KEY_SWTICH '(' ID ')' '{' case_statements default_statement '}'
		|	KEY_SWTICH '(' ID ')' '{' program_in_func case_statements '}'
		|	KEY_SWTICH '(' ID ')' '{' program_in_func case_statements default_statement '}'
		;
		
case_const:	INT
		|	CHAR
		;
		
case_statements:
			KEY_CASE case_const ':' program_in_case
		|	KEY_CASE case_const ':' program_in_case case_statements
		|	KEY_CASE case_const ':'
		|	KEY_CASE case_const ':' case_statements
		;

default_statement:
			KEY_DEFAULT ':' program_in_case
		|	KEY_DEFAULT ':'
		;
		
while_statement:
			KEY_WHILE '(' expr ')' '{' program_in_func '}'
		|	KEY_WHILE '(' expr ')' '{' '}'
		|	KEY_DO '{' program_in_func '}' KEY_WHILE '(' expr ')' ';'
		|	KEY_DO '{' '}' KEY_WHILE '(' expr ')' ';'
		;
		
for_statement:
			KEY_FOR '(' for_paras ';' expr ';' for_paras ')' '{' program_in_func '}'
		|	KEY_FOR '(' for_paras ';' expr ';' for_paras ')' '{' '}'
		
		|	KEY_FOR '(' for_paras ';' ';' for_paras ')' '{' program_in_func '}'
		|	KEY_FOR '(' for_paras ';' ';' for_paras ')' '{' '}'
		
		|	KEY_FOR '(' for_paras ';' expr ';' ')' '{' program_in_func '}'
		|	KEY_FOR '(' for_paras ';' expr ';' ')' '{' '}'
		
		|	KEY_FOR '(' for_paras ';' ';' ')' '{' program_in_func '}'
		|	KEY_FOR '(' for_paras ';' ';' ')' '{' '}'
		
		|	KEY_FOR '(' ';' expr ';' for_paras ')' '{' program_in_func '}'
		|	KEY_FOR '(' ';' expr ';' for_paras ')' '{' '}'
		
		|	KEY_FOR '(' ';' ';' for_paras ')' '{' program_in_func '}'
		|	KEY_FOR '(' ';' ';' for_paras ')' '{' '}'
		
		|	KEY_FOR '(' ';' expr ';' ')' '{' program_in_func '}'
		|	KEY_FOR '(' ';' expr ';' ')' '{' '}'
		
		|	KEY_FOR '(' ';' ';' ')' '{' program_in_func '}'
		|	KEY_FOR '(' ';' ';' ')' '{' '}'
		;
		
for_paras:	expr
		|	var '=' expr
		|	expr ',' for_paras
		|	var '=' expr ',' for_paras
		;
		
return_statement:
			KEY_RETURN expr ';'
		;
		
exprs:		expr
		|	expr ',' exprs
		;

expr: 		var											{	int idx = look_up_symbol($1);
															fprintf(fp, "lwi	$r0, [$sp+%d]\n", table[idx].offset);
															fprintf(fp, "swi	$r0, [$sp+%d]\n", stack_counter);
															stack_counter += 4;}
		|	ID OPER_PP									{	int idx = look_up_symbol($1);
															fprintf(fp, "lwi	$r0, [$sp+%d]\n", table[idx].offset);
															fprintf(fp, "addi	$r0, 1\n");
															fprintf(fp, "swi	$r0, [$sp+%d]\n", table[idx].offset);
															fprintf(fp, "swi	$r0, [$sp+%d]\n", stack_counter);
															stack_counter += 4;}
		|	ID OPER_SS									{	int idx = look_up_symbol($1);
															fprintf(fp, "lwi	$r0, [$sp+%d]\n", table[idx].offset);
															fprintf(fp, "addi	$r0, -1\n");
															fprintf(fp, "swi	$r0, [$sp+%d]\n", table[idx].offset);
															fprintf(fp, "swi	$r0, [$sp+%d]\n", stack_counter);
															stack_counter += 4;}
		|	'-' expr %prec UMINUS
		|	expr '*' expr
		|	expr '/' expr
		|	expr '%' expr
		|	expr '+' expr								{	fprintf(fp, "lwi	$r0, [$sp+%d]\n", stack_counter-8);
															fprintf(fp, "lwi	$r1, [$sp+%d]\n", stack_counter-4);
															stack_counter -= 8;
															fprintf(fp, "add	$r0, $r0, $r1\n");
															fprintf(fp, "swi	$r0, [$sp+%d]\n", stack_counter);
															stack_counter += 4;}
		|	expr '-' expr								{	fprintf(fp, "lwi	$r0, [$sp+%d]\n", stack_counter-8);
															fprintf(fp, "lwi	$r1, [$sp+%d]\n", stack_counter-4);
															stack_counter -= 8;
															fprintf(fp, "sub	$r0, $r0, $r1\n");
															fprintf(fp, "swi	$r0, [$sp+%d]\n", stack_counter);
															stack_counter += 4;}
		|	expr OPER_CMP expr
		|	'!' expr
		|	expr OPER_AA expr
		|	expr OPER_OO expr
		|	'(' expr ')'
		|	val
		|	ID '(' ')'
		|	ID '(' exprs ')'
		;

val:		SCI
		|	INT											{	fprintf(fp, "movi	$r0, %d\n", $1);
															fprintf(fp, "swi	$r0, [$sp+%d]\n", stack_counter);
															stack_counter += 4;}
		|	DOUBLE
		|	CHAR
		|	STR
		|	KEY_NULL
		|	KEY_TRUE
		|	KEY_FALSE
		;

arr_expr_index: 
			'[' expr ']'
		| 	'[' expr ']' arr_expr_index
		;

func_invocation:
			ID '(' ')'
		|	ID '(' exprs ')'
		;


%%

int main(void){
	fp = fopen("assembly", "w");
	init_table();
	yyparse();
	if(!global_flag) yyerror("");
	fprintf(stdout, "%s\n", "No syntax error!");
	return 0;
}

int yyerror(char *msg){
	fprintf( stderr, "*** Error at line %d: %s\n", num_line, srcBuf );
	fprintf( stderr, "\n" );
	fprintf( stderr, "Unmatched token: %s\n", yytext );
	fprintf( stderr, "*** syntax error\n");
	exit(-1);
}

