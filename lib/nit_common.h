#ifndef NIT_COMMON_H
#define NIT_COMMON_H

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

/* *** Types *** */
typedef int (*fun_t)(int);	     				/* generic function pointer */
typedef unsigned int cid_t;					/* class identifier */
typedef unsigned long int val_t;	/* value (everything is a val_t) */
typedef union obj_tu {union classtable_elt_tu * vft; val_t attr;} *obj_t; /* standard object */
typedef union classtable_elt_tu { int i; fun_t f; cid_t cid;} classtable_elt_t;	/* classtable element */

typedef classtable_elt_t * classtable_t;    	 		/* classtable */

/*****************************************************************************
 * Types macros (primitive and less primitives) ******************************
 *****************************************************************************
 *
 * ** types are: **
 * 
 * OBJ	(obj_t)	: standard object representation (including boxes + NIL)
 * Int	(int)	: integers
 * Char	(car)	: characters
 * Bool	(int)	: booleans (true or false)
 * 
 * X	(x_t)	: generic representatio of the previous four types
 *
 * ** macros are: **
 *
 * int ISX(val_t v)		: true if v is a X
 * x_t VAL2X(val_t v)		: convert a val_t to a primitive type (you should check ISX before)
 * val_t X2VAL(x_t x)		: convert a type to a val_t
 * int XTAG			: numeric identifier of a type
 * int TAG(val_t v)		: return the XTAG (ie TAG(Char2VAL('e')) == CharTag)
 * 
 * classtable_t VAL2VFT(val_t v): the virtual function table of a value
 *
 * val_t NIT_NULL		: the instance of the None class
 *****************************************************************************/

#define TAG(x) ((int)(x) & 3)
#ifndef IntTAG 
#	define IntTAG 1
#endif
#define TAG_Int(x) ((val_t)(((x)<<2)|IntTAG))
#define UNTAG_Int(x) ((int)(x)>>2)
#ifndef CharTAG
#	define CharTAG 2
#endif
#define TAG_Char(x) ((val_t)((((int)(x))<<2)|CharTAG))
#define UNTAG_Char(x) ((char)((int)(x)>>2))
#ifndef BoolTAG
#	define BoolTAG 3
#endif
#define TAG_Bool(x) ((val_t)(((x)<<2)|BoolTAG))
#define UNTAG_Bool(x) ((int)(x)>>2)
#ifndef OBJTAG
#	define OBJTAG 0
#endif
	
#define ISOBJ(x) (TAG((x)) == OBJTAG)
#define VAL2OBJ(x) ((obj_t)(x))
#define OBJ2VAL(o) ((val_t)(o))
#define VAL2VFT(x) (ISOBJ(x) ? VAL2OBJ(x)->vft : TAG2VFT[TAG(x)])
/*#define VAL2CID(x) (ISOBJ(x) ? (VAL2OBJ(x)->vft->cid) : (-TAG(x)))*/
#define VAL2CID(x) (VAL2OBJ(x)->vft->cid)

#define NIT_NULL ((val_t)0)
#define ISNULL(x) ((x)==NIT_NULL)

/* Equal comparaison */
/* O = Non nil object ; N = Object or nil ; P = Primitive */
#define OBJ_IS_BOX(x) ((VAL2OBJ(x)->vft->i) < 0)
#define IS_BOX(x) (ISOBJ(x) && OBJ_IS_BOX(x))
#define IS_EQUAL_BOX(x, y) (ISOBJ(y) && (VAL2OBJ(x)[1].vft==VAL2OBJ(y)[1].vft) && (VAL2OBJ(x)->vft==VAL2OBJ(y)->vft))
#define IS_EQUAL_OO(x, y) ((x)==(y) || (IS_BOX(x) && IS_EQUAL_BOX((x), (y))))
#define IS_EQUAL_ON(x, y) ((x)==(y) || (IS_BOX(x) && !ISNULL(y) && IS_EQUAL_BOX((x), (y))))
#define IS_EQUAL_NN(x, y) ((x)==(y) || (!ISNULL(x) && IS_BOX(x) && !ISNULL(y) && IS_EQUAL_BOX((x), (y))))

/* Subclass comparaison */
/* check is e is a subtype of c2 */
/* Warning, only subclasse comparaison is performed, not subtype */
/* e is a val (not nil) */
/* c a class name (eg: Int) */
#define VALISA(e, c) (VAL2VFT(e)[COLOR_ ## c].cid == (cid_t) ID_ ## c)
#define OBJISA(e, c) (VAL2OBJ(e)->vft[COLOR_ ## c].cid == (cid_t) ID_ ## c)

#define VAL_ISA(e, c, i) (VAL2VFT((e))[(c)].cid == (cid_t)(i))

void * alloc(size_t);
extern val_t G_args;
extern val_t G_stdin;
extern val_t G_stdout;
extern val_t G_stderr;
extern val_t G_sys;

extern int glob_argc;
extern char ** glob_argv;

struct trace_t {
	struct trace_t *prev; /* previous stack frame */
	const char *file; /* source filename */
	int line; /* line number */
	const char *meth; /* method name */
};
extern struct trace_t *tracehead;
typedef enum {true = (1==1),false = (0==1)} bool;

void nit_exit(int);

#define CALL(r,c) ((VAL2VFT(r)[c].f))
#define ATTR(r,c) (*(val_t*)(VAL2OBJ(r)+c))
#define ATTRS(r,c,o) ((VAL2OBJ(r)+VAL2VFT(r)[c].i)[o].attr)

void prepare_signals(void);
extern classtable_t TAG2VFT[4];
#endif
