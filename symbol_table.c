#include "symbol_table.h"
#include <string.h>

symbol_entry table[MAX_TABLE_SIZE];
int cur_counter;
int cur_scope;


void init_table() {
	cur_scope = 0;
	cur_counter = 0;
	memset(table, 0, sizeof(symbol_entry));
}


char* install_symbol (char *s, int stack_counter) {
	
	if(cur_counter > MAX_TABLE_SIZE) {
		printf("Symbol Table is full.\n");
	} else {
		strcpy(table[cur_counter].name, s);
		table[cur_counter].scope = cur_scope;
		table[cur_counter].offset = stack_counter;
		cur_counter++;
	}
	
	return s;
}

/**************Type******************/
void set_symbol_type_void (int idx) {
	table[idx].type = T_VOID;
}

void set_symbol_type_int (int idx) {
	table[idx].type = T_INT;
}

void set_symbol_type_double (int idx) {
	table[idx].type = T_DOUBLE;
}

void set_symbol_type_char (int idx) {
	table[idx].type = T_CHAR;
}

void set_symbol_type_bool (int idx) {
	table[idx].type = T_BOOL;
}

/***************Mode****************/
void set_symbol_mode_func(int idx) {
	table[idx].mode = M_FUNC;
}

void set_symbol_mode_var(int idx) {
	table[idx].mode = M_VAR;
}

void set_symbol_mode_argu(int idx) {
	table[idx].mode = M_ARGU;
}


int look_up_symbol(char *s) {
	
	int i;
	
	if(cur_counter == 0) return -1; 
	for(i = cur_counter ; i >= 0 ; i--){
		if(table[i].scope <= cur_scope) {
			if(!strcmp(s, table[i].name)){
				return i;
			}
		}
	}
	
	return -1;
}

void pop_up_symbol(char *s) {
	
	int i;
	
	if(cur_counter == 0) return; 
	for(i = cur_counter ; i >= 0 ; i--){
		if(table[i].scope < cur_scope) {
			cur_counter = i+1;
			break;
		}
	}
}



