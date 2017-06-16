%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "y.tab.h"

int num_line = 1;
bool isSrc = true;
bool isToken = true;
char srcBuf[2048];
char tokenBuf[2048];
%}

%x COMMENT
%x STRING
%%

"//"(.)* {
	/*Comment*/
	strcat(srcBuf, yytext);
}

"/*" {
	/*Start Comment*/
	strcat(srcBuf, yytext);
	BEGIN COMMENT;
}

<COMMENT>"*/" {
	/*End Comment*/
	strcat(srcBuf, yytext);
	BEGIN 0;
}
<COMMENT>\n {
	/*During Comment*/
	if(isToken){
		printf("%s", tokenBuf);
	}
	if(isSrc){
		printf("%d:%s\n", num_line, srcBuf);
	}
	
	strcpy(srcBuf, "\0");
	strcpy(tokenBuf, "\0");

	num_line++;
	BEGIN COMMENT;
}
<COMMENT>(.|\\n) {
	/*During Comment*/
	strcat(srcBuf, yytext);
	BEGIN COMMENT;
}

\n { 
	if(isToken){
		printf("%s", tokenBuf);
	}
	if(isSrc){
		printf("%d:%s\n", num_line, srcBuf);
	}
	
	//strcpy(srcBuf, "\0");
	//strcpy(tokenBuf, "\0");
	memset(srcBuf, 0, sizeof srcBuf);
	memset(tokenBuf, 0, sizeof tokenBuf);

	num_line++;
}

\t {
	strcat(srcBuf, yytext);
}

" " {
	strcat(srcBuf, yytext);
}

"#pragma source on" {
	isSrc = true;
	strcat(srcBuf, yytext);
}

"#pragma source off" {
	isSrc = false;
	strcat(srcBuf, yytext);
}

"#pragma token on" {
	isToken = true;
	strcat(srcBuf, yytext);
}

"#pragma token off" {
	isToken = false;
	strcat(srcBuf, yytext);
}

digitalWrite {
	strcat(tokenBuf, "#id:");
	strcat(tokenBuf, yytext);
	strcat(tokenBuf, "\n");
	strcat(srcBuf, yytext);
	
	return DIGITALWRITE;
}

delay {
	strcat(tokenBuf, "#id:");
	strcat(tokenBuf, yytext);
	strcat(tokenBuf, "\n");
	strcat(srcBuf, yytext);
	
	return DELAY;
}

HIGH {
	strcat(tokenBuf, "#integer:");
	strcat(tokenBuf, yytext);
	strcat(tokenBuf, "\n");
	strcat(srcBuf, yytext);
	
	return HIGH;
}

LOW {
	strcat(tokenBuf, "#integer:");
	strcat(tokenBuf, yytext);
	strcat(tokenBuf, "\n");
	strcat(srcBuf, yytext);
	
	return LOW;
}

for|while|do|if|else|switch|return|break|continue|struct|case|default {
	/*Keywords Function*/
	strcat(tokenBuf, "#key:");
	strcat(tokenBuf, yytext);
	strcat(tokenBuf, "\n");
	strcat(srcBuf, yytext);
	
	if (!strcmp(yytext, "for")){
		return KEY_FOR;
	} else if (!strcmp(yytext, "while")){
		return KEY_WHILE;
	} else if (!strcmp(yytext, "do")){
		return KEY_DO;
	} else if (!strcmp(yytext, "if")){
		return KEY_IF;
	} else if (!strcmp(yytext, "else")){
		return KEY_ELSE;
	} else if (!strcmp(yytext, "switch")){
		return KEY_SWTICH;
	} else if (!strcmp(yytext, "return")){
		return KEY_RETURN;
	} else if (!strcmp(yytext, "break")){
		return KEY_BREAK;
	} else if (!strcmp(yytext, "continue")){
		return KEY_CONTINUE;
	} else if (!strcmp(yytext, "struct")){
		return KEY_STRUCT;
	} else if (!strcmp(yytext, "case")){
		return KEY_CASE;
	} else if (!strcmp(yytext, "default")){
		return KEY_DEFAULT;
	}
}

null|true|false {
	/*Keywords NULLTF*/
	strcat(tokenBuf, "#key:");
	strcat(tokenBuf, yytext);
	strcat(tokenBuf, "\n");
	strcat(srcBuf, yytext);
	
	if (!strcmp(yytext, "null")){
		return KEY_NULL;
	} else if (!strcmp(yytext, "true")){
		return KEY_TRUE;
	} else if (!strcmp(yytext, "false")){
		return KEY_FALSE;
	}
}

const {
	/*Keywords Const*/
	strcat(tokenBuf, "#key:");
	strcat(tokenBuf, yytext);
	strcat(tokenBuf, "\n");
	strcat(srcBuf, yytext);
	
	return KEY_CONST;
}

int|double|bool|char {
	/*Keywords Type*/
	strcat(tokenBuf, "#key:");
	strcat(tokenBuf, yytext);
	strcat(tokenBuf, "\n");
	strcat(srcBuf, yytext);
	
	if(!strcmp(yytext, "int")){
		return TYPE_INT;
	} else if(!strcmp(yytext, "double")){
		return TYPE_DOUBLE;
	} else if(!strcmp(yytext, "bool")){
		return TYPE_BOOL;
	} else if(!strcmp(yytext, "char")){
		return TYPE_CHAR;
	}
}

void {
	/*Keywords Void Type*/
	strcat(tokenBuf, "#key:");
	strcat(tokenBuf, yytext);
	strcat(tokenBuf, "\n");
	strcat(srcBuf, yytext);
	
	return TYPE_VOID;
}

remove|rename|tmpfile|tmpnam|fclose|fflush|fopen|freopen|setbuf|setvbuf|fprintf|fscanf|printf|scanf|snprintf|sprintf|sscanf|vfprintf|vscanf|vprintf|vscanf|vsnprintf|vsprintf|vsscanf|fgetc|fgets|fputc|fputs|getc|getchar|gets|putc|putchar|puts|ungetc|fread|fwrite|fgetpos|fseek|fsetpos|ftell|rewind|clearerr|feof|ferror|perror {
	/*Keywords*/
	strcat(tokenBuf, "#key:");
	strcat(tokenBuf, yytext);
	strcat(tokenBuf, "\n");
	strcat(srcBuf, yytext);
	
	return ID;

}

("_"|[a-zA-Z])([a-zA-Z0-9]|"_")* {
	/*Identifier*/
	strcat(tokenBuf, "#id:");
	strcat(tokenBuf, yytext);
	strcat(tokenBuf, "\n");
	strcat(srcBuf, yytext);
	
	strcpy(yylval.ident, yytext);
	return ID;
}

[0-9]/([a-zA-Z]|"_") {
	/*Identifier&Integer Error*/
	fprintf(stderr, "Error at line %d: %s\n", num_line, yytext);exit(1);
}

"+"|"-"|"*"|"/"|"%"|"++"|"--"|"="|"&&"|"||"|"!"|"&" {
	/*Operators*/
	strcat(tokenBuf, "#op:");
	strcat(tokenBuf, yytext);
	strcat(tokenBuf, "\n");
	strcat(srcBuf, yytext);
	
	if (strlen(yytext) == 1){
		return yytext[0];
	} else if (!strcmp(yytext, "++")){
		return OPER_PP;
	} else if (!strcmp(yytext, "--")){
		return OPER_SS;
	} else if (!strcmp(yytext, "&&")){
		return OPER_AA;
	} else if (!strcmp(yytext, "||")){
		return OPER_OO;
	}
}

"<"|"<="|">"|">="|"=="|"!=" {
	/*Operators*/
	strcat(tokenBuf, "#op:");
	strcat(tokenBuf, yytext);
	strcat(tokenBuf, "\n");
	strcat(srcBuf, yytext);
	
	return OPER_CMP;
}

":"|";"|","|"."|"["|"]"|"("|")"|"{"|"}" {
	/*Punctuation*/
	strcat(tokenBuf, "#punc:");
	strcat(tokenBuf, yytext);
	strcat(tokenBuf, "\n");
	strcat(srcBuf, yytext);
	
	return yytext[0];
}

(([0-9]+)|((([0-9]*)"."([0-9])+)|(([0-9]+)"."([0-9]*))))(E|e)("-"|"+")?[0-9]+ {
	/*Sci*/
	/*(Int+Double)(E+e)(Int)*/
	strcat(tokenBuf, "#sci:");
	strcat(tokenBuf, yytext);
	strcat(tokenBuf, "\n");
	strcat(srcBuf, yytext);
	
	return SCI;
}

([1-9]([0-9])*)|"0" {
	/*Integer*/
	strcat(tokenBuf, "#integer:");
	strcat(tokenBuf, yytext);
	strcat(tokenBuf, "\n");
	strcat(srcBuf, yytext);
	
	yylval.intVal = atoi(yytext);
	return INT;
}

"0"/[0-9]+ {
	/*Integer Error*/
	fprintf(stderr, "Error at line %d: %s\n", num_line, yytext);exit(1);
}

(([0-9]*)"."([0-9])+)|(([0-9]+)"."([0-9]*)) {
	/*Double*/
	strcat(tokenBuf, "#double:");
	strcat(tokenBuf, yytext);
	strcat(tokenBuf, "\n");
	strcat(srcBuf, yytext);
	
	return DOUBLE;
}

\'(.|\\n|\\t)\' {
	/*Char*/
	strcat(tokenBuf, "#char:");
	strcat(tokenBuf, yytext);
	strcat(tokenBuf, "\n");
	strcat(srcBuf, yytext);
	
	return CHAR;
}

\" {
	/*String*/
	strcat(srcBuf, yytext);
	strcat(tokenBuf, "#string:");
	BEGIN STRING;
}
<STRING>\" {
	/*End String*/
	strcat(srcBuf, yytext);
	strcat(tokenBuf, "\n");
	BEGIN 0;
	
	return STR;
}
<STRING>\n {
	/*Error String*/
	fprintf(stderr, "Error at line %d: %s\n", num_line, yytext);exit(1);
}
<STRING>(.|\\n) {
	/*During String*/
	strcat(srcBuf, yytext);
	strcat(tokenBuf, yytext);
	BEGIN STRING;
}

. {
	fprintf(stderr, "Error at line %d: %s\n", num_line, yytext); exit(1);
}

%%

int yywrap()
{
	return 1;
}

