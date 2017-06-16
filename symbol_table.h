#include <stdio.h>
#include <stdlib.h>

#define MAX_TABLE_SIZE 2048

typedef struct {
	char name[32];
	int scope;
	int type;
	int mode;
	int offset;
} symbol_entry;

extern symbol_entry table[MAX_TABLE_SIZE];

#define T_VOID 0
#define T_INT 1
#define T_DOUBLE 2
#define T_CHAR 3
#define T_BOOL 4

#define M_FUNC 0
#define M_VAR 1
#define M_ARGU 2

extern int cur_scope;
extern int cur_counter;