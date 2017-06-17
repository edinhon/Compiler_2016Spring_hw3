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
int label_counter = 1;
int if_label = 0;
int if_label_2 = 0;
int while_begin_label = 0;
int while_end_label = 0;

FILE *fp;

bool global_flag = false;
bool void_flag = false;
%}

%start program
%union{
	int intVal;
	char ident[32];
	char cmper[4];
}

%token KEY_FOR KEY_WHILE KEY_DO KEY_IF KEY_ELSE KEY_SWTICH KEY_RETURN KEY_BREAK KEY_CONTINUE KEY_STRUCT KEY_CASE KEY_DEFAULT
%token KEY_NULL KEY_TRUE KEY_FALSE
%token KEY_CONST
%token TYPE_INT TYPE_DOUBLE TYPE_CHAR TYPE_BOOL TYPE_VOID
%token OPER_PP OPER_SS OPER_AA OPER_OO
%token SCI DOUBLE CHAR STR
%token <intVal> INT
%token <ident> ID
%type <ident> var scalar_id const_id
%token <cmper> OPER_CMP

%token DIGITALWRITE DELAY HIGH LOW


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
		
program_in_compound:
			statement_in_compound
		|	statement_in_compound program_in_compound
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
		|	expr ';'
		;
		
statement_in_compound:
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
		|	return_void_statement
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
		|	return_void_statement
		|	expr ';'
		;

declare:	type declare_ID ';'
		|	KEY_CONST type declare_const ';'
		|	type declare_function
		|	type_void declare_void_function
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
			const_id '=' expr								{	int idx = look_up_symbol($1);
																if(idx != -1){
																	fprintf(fp, "lwi	$r0, [$sp+%d]\n", stack_counter-4);
																	fprintf(fp, "swi	$r0, [$sp+%d]\n", table[idx].offset);
																	stack_counter -= 4;
																}
															}
		|	const_id '=' expr ',' declare_const				{	int idx = look_up_symbol($1);
																if(idx != -1){
																	fprintf(fp, "lwi	$r0, [$sp+%d]\n", stack_counter-4);
																	fprintf(fp, "swi	$r0, [$sp+%d]\n", table[idx].offset);
																	stack_counter -= 4;
																}
															}
		;
		
const_id:	ID											{	int idx;
															if((idx = look_up_symbol($1)) != -1 && table[idx].scope == cur_scope){
																fprintf(stderr, "Error at line %d: Duplicate declaration: %s.\n", num_line, $1);
																exit(1);
															} else {
																set_symbol_mode_const(cur_counter);
																install_symbol($1, stack_counter);
																stack_counter += 4;
																strcpy($$, $1);
															}
														}

declare_function:
			func_id '(' ')' ';'								
		|	func_id '(' paras ')' ';'						
		|	func_id '(' ')' left_curly right_curly			{global_flag = true;} 
		|	func_id '(' paras ')' left_curly right_curly	{global_flag = true;} 
		|	func_id '(' ')' left_curly program_in_func return_statement right_curly			{global_flag = true;} 
		|	func_id '(' paras ')' left_curly program_in_func return_statement right_curly	{global_flag = true;} 
		;
		
declare_void_function:
			func_id '(' ')' ';'								
		|	func_id '(' paras ')' ';'						
		|	func_id '(' ')' left_curly right_curly			{	global_flag = true;
																void_flag = false;} 
		|	func_id '(' paras ')' left_curly right_curly	{	global_flag = true;
																void_flag = false;}
		|	func_id '(' ')' left_curly program_in_func return_void_statement right_curly			{	global_flag = true;
																										void_flag = false;}
		|	func_id '(' paras ')' left_curly program_in_func return_void_statement right_curly		{	global_flag = true;
																										void_flag = false;}
		;
		
func_id:	ID											{	int idx;
															if((idx = look_up_symbol($1)) != -1 && table[idx].scope == cur_scope){
																fprintf(stderr, "Error at line %d: Duplicate declaration: %s.\n", num_line, $1);
																exit(1);
															} else {
																set_symbol_mode_func(cur_counter);
																install_symbol($1, stack_counter);
																stack_counter += 4;
															}
														}										
		;
type:		TYPE_INT									{set_symbol_type_int(cur_counter);}
		|	TYPE_DOUBLE									{set_symbol_type_double(cur_counter);}
		|	TYPE_CHAR									{set_symbol_type_char(cur_counter);}
		|	TYPE_BOOL									{set_symbol_type_bool(cur_counter);}
		;
		
type_void:	TYPE_VOID									{	set_symbol_type_void(cur_counter);
															void_flag = true;}
		
scalar:		scalar_id									{	}
		|	scalar_id '=' expr							{	int idx = look_up_symbol($1);
															if(idx != -1){
																fprintf(fp, "lwi	$r0, [$sp+%d]\n", stack_counter-4);
																fprintf(fp, "swi	$r0, [$sp+%d]\n", table[idx].offset);
																stack_counter -= 4;
															} else {
																fprintf(stderr, "Error at line %d: Doesn't exist variable: %s.\n", num_line, $1);
																exit(1);
															}
														}
		;
		
scalar_id:	ID											{	int idx;
															if((idx = look_up_symbol($1)) != -1 && table[idx].scope == cur_scope){
																fprintf(stderr, "Error at line %d: Duplicate declaration: %s.\n", num_line, $1);
																exit(1);
															} else {
																set_symbol_mode_var(cur_counter);
																install_symbol($1, stack_counter);
																stack_counter += 4;
																strcpy($$, $1);
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
			left_curly program_in_compound right_curly
		|	left_curly right_curly
		;
		
if_else_statement:
			if_condition if_scope
		KEY_ELSE left_curly program_in_compound right_curly					{	fprintf(fp, ".L%d:\n", if_label_2);}
		
		|	if_condition if_scope
		KEY_ELSE left_curly right_curly										{	fprintf(fp, ".L%d:\n", if_label_2);}
		
		|	if_condition left_curly program_in_compound right_curly			{	fprintf(fp, ".L%d:\n", if_label);}
		|	if_condition left_curly right_curly								{	fprintf(fp, ".L%d:\n", if_label);}
		;
		
if_condition:
			KEY_IF '(' expr ')'							{	fprintf(fp, "lwi	$r0, [$sp+%d]\n", stack_counter-4);
															stack_counter -= 4;
															fprintf(fp, "beqz	$r0, .L%d\n", label_counter);
															if_label = label_counter;
															label_counter++;}
		;
		
if_scope:	left_curly program_in_compound right_curly	{	fprintf(fp, "j	.L%d\n", label_counter);
															if_label_2 = label_counter;
															label_counter++;
															fprintf(fp, ".L%d:\n", if_label);}
		|	left_curly right_curly						{	fprintf(fp, "j	.L%d\n", label_counter);
															if_label_2 = label_counter;
															label_counter++;
															fprintf(fp, ".L%d:\n", if_label);}
		;
		
switch_statement:
			KEY_SWTICH '(' ID ')' left_curly case_statements right_curly
		|	KEY_SWTICH '(' ID ')' left_curly case_statements default_statement right_curly
		|	KEY_SWTICH '(' ID ')' left_curly program_in_compound case_statements right_curly
		|	KEY_SWTICH '(' ID ')' left_curly program_in_compound case_statements default_statement right_curly
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
			while_condition left_curly program_in_compound right_curly	{	fprintf(fp, "j	.L%d\n", while_begin_label);
																			fprintf(fp, ".L%d:\n", while_end_label);}
		|	while_condition left_curly right_curly						{	fprintf(fp, "j	.L%d\n", while_begin_label);
																			fprintf(fp, ".L%d:\n", while_end_label);}
		|	KEY_DO left_curly program_in_compound right_curly KEY_WHILE '(' expr ')' ';'
		|	KEY_DO left_curly right_curly KEY_WHILE '(' expr ')' ';'
		;
		
while_condition:
			while_token '(' expr ')'					{	fprintf(fp, "lwi	$r0, [$sp+%d]\n", stack_counter-4);
															stack_counter -= 4;
															fprintf(fp, "beqz	$r0, .L%d\n", label_counter);
															while_end_label = label_counter;
															label_counter++;}
		
while_token:
			KEY_WHILE									{	fprintf(fp, ".L%d:\n", label_counter);
															while_begin_label = label_counter;
															label_counter++;}
		
for_statement:
			KEY_FOR '(' for_paras ';' expr ';' for_paras ')' left_curly program_in_compound right_curly
		|	KEY_FOR '(' for_paras ';' expr ';' for_paras ')' left_curly right_curly
		
		|	KEY_FOR '(' for_paras ';' ';' for_paras ')' left_curly program_in_compound right_curly
		|	KEY_FOR '(' for_paras ';' ';' for_paras ')' left_curly right_curly
		
		|	KEY_FOR '(' for_paras ';' expr ';' ')' left_curly program_in_compound right_curly
		|	KEY_FOR '(' for_paras ';' expr ';' ')' left_curly right_curly
		
		|	KEY_FOR '(' for_paras ';' ';' ')' left_curly program_in_compound right_curly
		|	KEY_FOR '(' for_paras ';' ';' ')' left_curly right_curly
		
		|	KEY_FOR '(' ';' expr ';' for_paras ')' left_curly program_in_compound right_curly
		|	KEY_FOR '(' ';' expr ';' for_paras ')' left_curly right_curly
		
		|	KEY_FOR '(' ';' ';' for_paras ')' left_curly program_in_compound right_curly
		|	KEY_FOR '(' ';' ';' for_paras ')' left_curly right_curly
		
		|	KEY_FOR '(' ';' expr ';' ')' left_curly program_in_compound right_curly
		|	KEY_FOR '(' ';' expr ';' ')' left_curly right_curly
		
		|	KEY_FOR '(' ';' ';' ')' left_curly program_in_compound right_curly
		|	KEY_FOR '(' ';' ';' ')' left_curly right_curly
		;
		
for_paras:	expr
		|	var '=' expr
		|	expr ',' for_paras
		|	var '=' expr ',' for_paras
		;
		
return_statement:
			KEY_RETURN expr ';'							{	if(void_flag){
																fprintf(stderr, "Error at line %d: Return value in void function.\n", num_line);
																exit(1);
															}}
		;
		
return_void_statement:
			KEY_RETURN ';'								{	if(!void_flag){
																fprintf(stderr, "Error at line %d: Return void in non-void function.\n", num_line);
																exit(1);
															}}
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
															fprintf(fp, "swi	$r0, [$sp+%d]\n", stack_counter);
															fprintf(fp, "addi	$r0, $r0, 1\n");
															fprintf(fp, "swi	$r0, [$sp+%d]\n", table[idx].offset);
															stack_counter += 4;}
		|	ID OPER_SS									{	int idx = look_up_symbol($1);
															fprintf(fp, "lwi	$r0, [$sp+%d]\n", table[idx].offset);
															fprintf(fp, "swi	$r0, [$sp+%d]\n", stack_counter);
															fprintf(fp, "addi	$r0, $r0, -1\n");
															fprintf(fp, "swi	$r0, [$sp+%d]\n", table[idx].offset);
															stack_counter += 4;}
		|	'-' expr %prec UMINUS						{	fprintf(fp, "movi	$r0, 0\n");
															fprintf(fp, "lwi	$r1, [$sp+%d]\n", stack_counter-4);
															stack_counter -= 4;
															fprintf(fp, "sub	$r0, $r0, $r1\n");
															fprintf(fp, "swi	$r0, [$sp+%d]\n", stack_counter);
															stack_counter += 4;}
		|	expr '*' expr								{	fprintf(fp, "lwi	$r0, [$sp+%d]\n", stack_counter-8);
															fprintf(fp, "lwi	$r1, [$sp+%d]\n", stack_counter-4);
															stack_counter -= 8;
															fprintf(fp, "mul	$r0, $r0, $r1\n");
															fprintf(fp, "swi	$r0, [$sp+%d]\n", stack_counter);
															stack_counter += 4;}
		|	expr '/' expr								{	fprintf(fp, "lwi	$r0, [$sp+%d]\n", stack_counter-8);
															fprintf(fp, "lwi	$r1, [$sp+%d]\n", stack_counter-4);
															stack_counter -= 8;
															fprintf(fp, "divsr	$r0, $r1, $r0, $r1\n");
															fprintf(fp, "swi	$r0, [$sp+%d]\n", stack_counter);
															stack_counter += 4;}
		|	expr '%' expr								{	fprintf(fp, "lwi	$r0, [$sp+%d]\n", stack_counter-8);
															fprintf(fp, "lwi	$r1, [$sp+%d]\n", stack_counter-4);
															stack_counter -= 8;
															fprintf(fp, "divsr	$r0, $r1, $r0, $r1\n");
															fprintf(fp, "swi	$r1, [$sp+%d]\n", stack_counter);
															stack_counter += 4;}
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
		|	expr OPER_CMP expr							{	fprintf(fp, "lwi	$r0, [$sp+%d]\n", stack_counter-8);
															fprintf(fp, "lwi	$r1, [$sp+%d]\n", stack_counter-4);
															stack_counter -= 8;
															if(!strcmp($2, "<")){
																fprintf(fp, "slts	$r0, $r0, $r1\n");
																fprintf(fp, "zeb	$r0, $r0\n");
																fprintf(fp, "swi	$r0, [$sp+%d]\n", stack_counter);
																stack_counter += 4;
															} else if (!strcmp($2, "<=")){
																fprintf(fp, "slts	$r0, $r0, $r1\n");
																fprintf(fp, "xori	$r0, $r0, 1\n");
																fprintf(fp, "zeb	$r0, $r0\n");
																fprintf(fp, "swi	$r0, [$sp+%d]\n", stack_counter);
																stack_counter += 4;
															} else if (!strcmp($2, ">")){
																fprintf(fp, "slts	$r0, $r1, $r0\n");
																fprintf(fp, "zeb	$r0, $r0\n");
																fprintf(fp, "swi	$r0, [$sp+%d]\n", stack_counter);
																stack_counter += 4;
															} else if (!strcmp($2, ">=")){
																fprintf(fp, "slts	$r0, $r1, $r0\n");
																fprintf(fp, "xori	$r0, $r0, 1\n");
																fprintf(fp, "zeb	$r0, $r0\n");
																fprintf(fp, "swi	$r0, [$sp+%d]\n", stack_counter);
																stack_counter += 4;
															} else if (!strcmp($2, "==")){
																fprintf(fp, "xor	$r0, $r0, $r1\n");
																fprintf(fp, "slti	$r0, $r0, 1\n");
																fprintf(fp, "zeb	$r0, $r0\n");
																fprintf(fp, "swi	$r0, [$sp+%d]\n", stack_counter);
																stack_counter += 4;
															} else if (!strcmp($2, "!=")){
																fprintf(fp, "xor	$r0, $r0, $r1\n");
																fprintf(fp, "movi	$r1, 0\n");
																fprintf(fp, "slt	$r0, $r1, $r0\n");
																fprintf(fp, "zeb	$r0, $r0\n");
																fprintf(fp, "swi	$r0, [$sp+%d]\n", stack_counter);
																stack_counter += 4;
															}
														}
		|	'!' expr									{	fprintf(fp, "lwi	$r0, [$sp+%d]\n", stack_counter-4);
															stack_counter -= 4;
															fprintf(fp, "addi	$r0, $r0, 0\n");
															fprintf(fp, "slti	$r0, $r0, 1\n");
															fprintf(fp, "zeb	$r0, $r0\n");
															fprintf(fp, "swi	$r0, [$sp+%d]\n", stack_counter);
															stack_counter += 4;}
		|	expr OPER_AA expr							{	fprintf(fp, "lwi	$r0, [$sp+%d]\n", stack_counter-8);
															fprintf(fp, "beqz	$r0, .L%d\n", label_counter);
															fprintf(fp, "lwi	$r0, [$sp+%d]\n", stack_counter-4);
															fprintf(fp, "beqz	$r0, .L%d\n", label_counter);
															fprintf(fp, "movi	$r0, 1\n");
															fprintf(fp, "j	.L%d\n", label_counter+1);
															stack_counter -= 8;
															
															fprintf(fp, ".L%d:\n", label_counter);
															fprintf(fp, "movi	$r0, 0\n");
															label_counter++;
															
															fprintf(fp, ".L%d:\n", label_counter);
															fprintf(fp, "swi	$r0, [$sp+%d]\n", stack_counter);
															label_counter++;
															stack_counter += 4;}
		|	expr OPER_OO expr							{	fprintf(fp, "lwi	$r0, [$sp+%d]\n", stack_counter-8);
															fprintf(fp, "bnez	$r0, .L%d\n", label_counter);
															fprintf(fp, "lwi	$r0, [$sp+%d]\n", stack_counter-4);
															fprintf(fp, "beqz	$r0, .L%d\n", label_counter+1);
															stack_counter -= 8;
															
															fprintf(fp, ".L%d:\n", label_counter);
															fprintf(fp, "movi	$r0, 1\n");
															fprintf(fp, "j	.L%d\n", label_counter+2);
															label_counter++;
															
															fprintf(fp, ".L%d:\n", label_counter);
															fprintf(fp, "movi	$r0, 0\n");
															label_counter++;
															
															fprintf(fp, ".L%d:\n", label_counter);
															fprintf(fp, "swi	$r0, [$sp+%d]\n", stack_counter);
															label_counter++;
															stack_counter += 4;}
		|	'(' expr ')'								{	}
		|	val
		|	ID '(' ')'
		|	ID '(' exprs ')'
		|	DIGITALWRITE '(' INT ',' HIGH ')'			{	fprintf(fp, "movi	$r0, %d\n", $3);
															fprintf(fp, "movi	$r1, 1\n");
															fprintf(fp, "bal	digitalWrite\n");}
		|	DIGITALWRITE '(' INT ',' LOW ')'			{	fprintf(fp, "movi	$r0, %d\n", $3);
															fprintf(fp, "movi	$r1, 0\n");
															fprintf(fp, "bal	digitalWrite\n");}
		|	DELAY '(' expr ')'							{	fprintf(fp, "lwi	$r0, [$sp+%d]\n", stack_counter-4);
															fprintf(fp, "bal	delay\n");
															stack_counter -= 4;}
		;

val:		SCI
		|	INT											{	fprintf(fp, "movi	$r0, %d\n", $1);
															fprintf(fp, "swi	$r0, [$sp+%d]\n", stack_counter);
															stack_counter += 4;}
		|	DOUBLE
		|	CHAR										{	}
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
		|	DIGITALWRITE '(' INT ',' HIGH ')'			{	fprintf(fp, "movi	$r0, %d\n", $3);
															fprintf(fp, "movi	$r1, 1\n");
															fprintf(fp, "bal	digitalWrite\n");}
		|	DIGITALWRITE '(' INT ',' LOW ')'			{	fprintf(fp, "movi	$r0, %d\n", $3);
															fprintf(fp, "movi	$r1, 0\n");
															fprintf(fp, "bal	digitalWrite\n");}
		|	DELAY '(' expr ')'							{	fprintf(fp, "lwi	$r0, [$sp+%d]\n", stack_counter-4);
															fprintf(fp, "bal	delay\n");
															stack_counter -= 4;}
		;
		

left_curly:	'{'											{	cur_scope++;}
		;
		
right_curly:
			'}'											{	cur_scope--;
															pop_up_symbol();}
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

