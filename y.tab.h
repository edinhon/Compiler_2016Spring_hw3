#define KEY_FOR 257
#define KEY_WHILE 258
#define KEY_DO 259
#define KEY_IF 260
#define KEY_ELSE 261
#define KEY_SWTICH 262
#define KEY_RETURN 263
#define KEY_BREAK 264
#define KEY_CONTINUE 265
#define KEY_STRUCT 266
#define KEY_CASE 267
#define KEY_DEFAULT 268
#define KEY_NULL 269
#define KEY_TRUE 270
#define KEY_FALSE 271
#define KEY_CONST 272
#define TYPE_INT 273
#define TYPE_DOUBLE 274
#define TYPE_CHAR 275
#define TYPE_BOOL 276
#define TYPE_VOID 277
#define OPER_PP 278
#define OPER_SS 279
#define OPER_AA 280
#define OPER_OO 281
#define OPER_CMP 282
#define SCI 283
#define DOUBLE 284
#define CHAR 285
#define STR 286
#define INT 287
#define ID 288
#define UMINUS 289
#ifdef YYSTYPE
#undef  YYSTYPE_IS_DECLARED
#define YYSTYPE_IS_DECLARED 1
#endif
#ifndef YYSTYPE_IS_DECLARED
#define YYSTYPE_IS_DECLARED 1
typedef union{
	int intVal;
	char ident[32];
} YYSTYPE;
#endif /* !YYSTYPE_IS_DECLARED */
extern YYSTYPE yylval;
