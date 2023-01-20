
// Copyright (C) 2020, 2021, 2022, 2023 John Steven Matthews

grammar Pragma; 
    

// =====================  LEX  =============================
/*


	Pragma tokens fall into 3 categories: reserved words,
	punctuation, and synthetic tokens.

	Reserved words and punctuation are straight forward
	literal tokens. Synthetic tokens are composed by rule.
	
	The most important synthetic token is an EID (entity
	identifier). An EID is a name or reference to

		type 
		object (type instance)
		proxy 
		method 
		subroutine 
		book
		page
		

	An EID can be a simple name or a complex reference
	composed of several parts.  It's the compiler's job to
	determine the validity of an EID in context.  

	Note: The decision was made to put responsibility on
	the compiler to sub-parse and validate an EID for better
	error detection and simpler grammar. 

	The rule for a simple, unqualified EID matches every
	reserved word, but reserved words have precedence
	(they're listed first), so a simple EID can't be a 
	reserved word.  However, a complex general EID may
	contain embedded reserved words.

	This means that a reserved word won't be returned
	as an EID and can't be used to name new entities (good),
	but it's possible to code a syntactically valid reference 
	using reserved words that can't possibly reference a
	real entity. But no big deal, because reference validation
	is what compilers do.

	Pragma has reserved names that are not reserved words.
	"o" is the generic name for implicit method object,
	and these generic namespace names are reserved: @book,
	@page, @type, @proc
	

	basic identifier...

	a-z A-Z 0-9 _ ~ @ & ? ! $ `

	punctuation...
	
	''	literal
	""	formula
	[]	attribute list,proxy analog 
	{}	group
	<>	eid factor
	()	list, operation 
	||	operator
	->	implies (binds)
	.	subobject ref
	\	namespace resolution
	;	group item delimiter
	,	list item separator
	^	literal insert
	=	assignment (operator,alias,result)
	#	factor dimension
	:	method call
	+	plus special operator
	-	minus special operator
	*	mul special operator, var input recognition
	/	div special operator
	

	--		side remark
	{{}}	narrative block
	{++}	exclude block

*/


// reserved words

ABSTRACT			:	'abstract'		;
ACTUAL				:	'actual'		;
ALIAS				:	'alias'			;
AS					:	'as'			;
BASE				:	'base'			;
CASE				:	'case'			;
CONTEXT				:	'context'		;
CONST				:	'const'			;		// constant
DURABLE				:	'durable'		;
ELSE				:	'else'			;
ESCAPE				:	'escape'		;
EVIDENT				:	'evident'		;
FINAL				:	'final'			;
FOR					:	'for'			;
FROM				:	'from'			;
GENERAL				:	'general'		;
IF					:	'if'			;
IMAGE				:	'image'			;
IN					:	'in'			;
INCOMPLETE			:	'incomplete'	;
INSTANCE			:	'instance'		;
ISOLATE				:	'isolate'		;
LOCAL				:	'local'			;
LOOP				:	'loop'			;
METHOD				:	'method'		;
MISC				:	'misc'			;		// miscellaneous
NAF					:	'naf'			;		// not-a-function
NATIVE				:	'native'		;
NEW					:	'new'			;
NULL				:	'null'			;
OPERATION			:	'operation'		;
OPT					:	'opt'			;		// optional
PAGE				:	'page'			;
PROXY				:	'proxy'			;
PWD					:	'pwd'			;		// previously well-defined
QUIT				:	'quit'			;
RETURN				:	'return'		;
SPLIT				:	'split'			;
SUBROUTINE			:	'subroutine'	;
SURE				:	'sure'			;
SWITCH				:	'switch'		;	
TBD					:	'tbd'			;		// to be determined (or defined)
TOKEN				:	'token'			;
TRAP				:	'trap'			;
TYPE				:	'type'			;
USES				:	'uses'			;
WITH				:	'with'			;
VAR					:	'var'			;		// variable
VOID				:	'void'			;

// punctuation

LEFT_CURLY			:	'{'				;
RIGHT_CURLY			:	'}'				;
LEFT_PAREN			:	'('				;
RIGHT_PAREN			:	')'				;
LEFT_SQUARE			:	'['				;
RIGHT_SQUARE		:	']'				;	
COMMA				:	','				;
SEMI_COLON			:	';'				;
COLON				:	':'				;
EQUAL				:	'='				;
DOUBLE_QUOTE		:	'"'				;
ASTERISK			:	'*'				;
PLUS				:	'+'				;
MINUS				:	'-'				;
DIVIDE				:	'/'				;
IMPLIES				:	'->'			;




// literal 

				
fragment
L0					:	'\''						// delim
					;
	
fragment
L1					: [!-&(-\]_-~\r\n\t ]			// char subset: printable, except ^ and ', plus whitespace
					;

fragment
L2					: [0-9][0-9][0-9]				// 3 digits
					;

fragment			
L3					: '^' ( '^' | L0 | L2 )			// insert subexpr		
					;

LITERAL				: L0 ( L1 | L3 )*?  L0
					;



// operator


fragment
P1					: [!-z{}~]						// char subset: printable, except SP and |
					;

OPERATOR			: '|' P1+? '|'
					;



// entity identifier


fragment
I0					: ' '							// embedded space			
					;

fragment
I1					: [a-zA-Z0-9_~@&!?$`]+			// name, char subset = alphanumeric plus _~@&!?$`
					;

fragment			
I2					: '#' [a-zA-Z0-9]* 				// abstract dimension 
					| L0 [0-9]+ L0					// adhoc dimension
					;

fragment												
I3					: '<' I0* ( I2 | I5 ) I0* '>'	// factor   
					;

fragment											// with factors
I4					: I1 ( I3+ I1 )* I3*	
					| I3+ ( I1 I3+ )* I1?
					;

fragment
I5					: ( I1 '\\' )? I4				// namespace qualified  
					;




EID					: I5							// entity name or ref, no sub-object
					| '.' I5						// implicit sub-object ref 
					| I5 '.' I5						// explicit sub-object ref 
					;
					



// commentary ( any char allowed )


EXCLUDE				: '{+' .*? '+}'			-> skip
					;

NARRATIVE			: '{{' .*? '}}'			-> skip
					;

REMARK				: '--' ~[\r\n]*			-> skip 
					;


// inter-token space (lowest precedence)

SPACE				: [ \t\r\n]+			-> skip
					;



// =====================  PARSE  ===========================
/*
	Pragma syntax is fairly simple and regular but context 
	determines usage, so context is captured low in the
	parse tree using redundant rules. 

	In the broad view, a Pragma procedure is comprised of
	executable items that create new objects and call other
	procedures.

	There are two kinds of procedures: method and subroutine.
	A method is defined within the scope of a type definition
	and references an implicit method object "o".  A 
	subroutine stands alone and can only reference an object's 
	typical methods.
	
	Any procedure can have inputs, outputs, and additional
	unspecified objects (extra). Subroutines can have auxiliary 
	inputs.	Variable inputs are marked with an accent `.  

	Auxiliary inputs are used to pass context to a subroutine
	used as a co-routine. 
	
	A co-routine can be called by any method or subroutine
	to adapt it's algorithm.  Auxiliary inputs are given
	to the co-routine using a with-clause in the procedure 
	call.  A co-routine cannot itself call a co-routine 
	(adaptation is only one	level deep).

	A method is always called for some root object given
	in the method call, separate from inputs and outputs.
	Method calls are annotated with a leading colon. The
	result of calling a method is the root object.  Thus,
	methods can be chained together left-to-right, with	
	each method targeting an object to the immediate left
	of the method, where the left object propogates from 
	the previous method. The default result can	be over-
	ridden by designating a particular output with an
	asterisk *.

	A subroutine call can generally be used wherever an 
	object is required provided the subroutine has outputs
	and one of them is designated.  For	simplicity, grammar
	rules allow any (possibly non-conforming) subroutine
	call, but conformance will be verified by the compiler.  

	Other executable items are: new-proxy, bind-proxy, 
	escape_point, return_point, quit_point.
	
	Executable items can be grouped into executable blocks.
	
	Items and blocks can be incorporated into executable
	forms:  if/else, loop, switch/case/else,  isolate/trap.

	A formula is an expression enclosed in double quotes.
	A formula has familiar syntax consisting of operations
	and traditional	function calls.  An operation is a
	sub-expression of operands and operators. A traditional
	function call has an implicit result given a list of 
	const inputs.
	
	A formula has it's own local object scope and it
	cannot have a side effect on any object outside that
	scope.  Any procedure with const inputs and a single 
	output/result can be called functionally inside a
	formula. Since there cannot be any side effects, 
	methods that target objects outside the formula must
	be const.
	
	Operations in a formula are translated into traditional
	function calls using explicit operation definitions.
	Ultimately a formula is translated into a purely func-
	tional expression that has a single result. A 
	formula can generally be used in any context where an
	object is required.  Indeed, it is an object context
	that determines the resulting type and thus provides
	necessary context for interpreting the formula.
		
	Generally, definitions that introduce names can be
	truncated to allow references. These definitions
	introduce names: context, method, subroutine, type, and
	token.

	Here are possible object expressions and their
	semantics:
	
	EID					type ref:  new anon null obj, type = EID
	EID					obj ref:  existing obj, type = per def
	EID					proxy ref: existing obj, type = per proxy 
	EID					dimension: new anon initialized obj, type = expr
	NULL				new anon null input obj, type = per input spec 
	LITERAL				new anon initialized obj, type = expr 
	new_obj				new named null obj, type and name specified
	new_analog			new anon initialized obj, type = analog 
	formula				new anon initialized obj, type = contextual 
	resolution_seq		new anon initialized obj, type = specified
	method_seq			existing obj (method obj, return proxy, designated output)
	subroutine_call		existing obj (return proxy, designated output)

	A standalone EID when used in an object context may 
	be a type ref, object ref, proxy ref, or dimension.
	The compiler must be able to resolve the reference.

	Note: A standalone EID could also be a subroutine
	call (empty call provision) but it cannot be a valid
	obj expression unless it binds a proxy.

	Given an object of known type, the compiler will 
	attempt to match it to a target type determined
	from context. If there is no exact match, but the
	compiler can derive the	target type using a single
	conversion, it will be accepted.  In some cases, 
	the target context may be manifold or indefinite, 
	in which case the app must code an exact match
	which can be accomplished with a resolution sequence.

*/


// EXECUTABLE 


proxy_obj				: EID
						| LITERAL
						| VOID
						| formula
						| method_seq
						| subroutine_call
						| resolution_seq
						;	


new_proxy_name			: EID	// new object alias
						;

new_proxy				: proxy_def new_proxy_name ( IMPLIES proxy_obj )?
						;



proxy_binding_ref		: EID	// proxy name
						;

proxy_binding			: proxy_binding_ref IMPLIES proxy_obj
						;



new_analog_ref			: EID				// proxy name
						| method_seq		// binds proxy
						| subroutine_call	// ditto
						;

new_analog				: LEFT_SQUARE new_analog_ref RIGHT_SQUARE 
						;



new_obj_type_ref		: EID
						;

new_obj_name			: EID
						;

new_obj					: new_obj_type_ref new_obj_name	
						;



resolution_obj			: EID
						| LITERAL
						| formula
						| method_seq
						| subroutine_call
						;

resolution_type_ref		: EID
						;

resolution_seq			: resolution_obj ( AS resolution_type_ref )+  // left to right
						;



formula_obj				: EID
						| LITERAL
						| NULL
						| method_seq
						| subroutine_call	
						| resolution_seq
						| formula_func_call
						| formula_op_unit
						;

formula_func_ref		: EID
						;

formula_func_input		: formula_obj
						| formula_op_seq
						;

formula_func_call		: formula_func_ref LEFT_PAREN ( formula_func_input ( COMMA formula_func_input )* )? RIGHT_PAREN
						;

formula_op_token		: OPERATOR 
						| ( PLUS | MINUS | ASTERISK | DIVIDE )
						;

formula_op_term			: formula_op_token? formula_obj
						;

formula_op_seq			: formula_op_term ( formula_op_token formula_op_term )+ 
						;

formula_op_unit			: LEFT_PAREN formula_op_seq RIGHT_PAREN
						;

formula_def				: formula_op_seq
						| formula_op_unit	 // extraneous parens allowed
						| formula_func_call
						;

formula					: DOUBLE_QUOTE formula_def DOUBLE_QUOTE
						;



input_obj				: EID
						| LITERAL
						| NULL
						| formula
						| method_seq
						| subroutine_call	
						| resolution_seq
						;

input_obj_const			: input_obj
						;

input_obj_var			: ASTERISK input_obj
						;

input_obj_item			: input_obj_const
						| input_obj_var
						;

input_obj_enum			: input_obj_item ( COMMA input_obj_item )*
						;

input_obj_list			: LEFT_PAREN input_obj_enum? RIGHT_PAREN		
						;


output_obj				: EID					
						| new_obj	
						| method_seq	// x:reuse 
						;

output_obj_result		: EQUAL output_obj
						;

output_obj_item			: output_obj
						| output_obj_result	// result
						;

output_obj_enum			: output_obj_item ( COMMA output_obj_item )*	// only one result
						;

output_obj_list			: LEFT_PAREN output_obj_enum? RIGHT_PAREN	
						;


extra_obj				: EID
						| LITERAL
						| NULL
						| new_obj
						| formula	
						| method_seq
						| subroutine_call	
						| resolution_seq
						;

extra_obj_enum			: extra_obj ( COMMA extra_obj )*
						;

extra_obj_list			: LEFT_PAREN extra_obj_enum? RIGHT_PAREN
						;




reg_given_obj_list		: input_obj_list
						| input_obj_list output_obj_list
						| input_obj_list output_obj_list extra_obj_list
						;

aux_given_obj_list		: LEFT_PAREN input_obj_list RIGHT_PAREN  
						;




call_coroutine_ref		: EID
						;

call_coroutine			: WITH call_coroutine_ref aux_given_obj_list?	
						;

call_proxy_name			: EID	
						;

call_provision			: reg_given_obj_list? call_coroutine? call_proxy_name?
						;




method_ref				: EID
						;

method_call				: COLON method_ref call_provision
						;

method_obj				: EID			
						| LITERAL				
						| new_obj	
						| new_analog
						| subroutine_call	
						;

method_seq				: method_obj? method_call+
						;



subroutine_ref			: EID
						;

subroutine_call			: subroutine_ref call_provision
						;


escape_point			: ESCAPE
						;


return_point			: RETURN  
						;



quit_input1				: LITERAL			// fault_id vex
						| EID				// fault_id obj ref
						;
					
quit_input2				: LITERAL			// expr vex
						| EID				// expr obj ref
						;

quit_obj				: EID				// fault obj ref
						| formula
						| method_seq
						| subroutine_call  
						;

quit_point				: QUIT quit_obj?
						| QUIT LEFT_PAREN quit_input1 ( COMMA quit_input2 )? RIGHT_PAREN	
						;



condition_obj			: EID					
						| LITERAL	
						| formula
						| method_seq
						| subroutine_call
						;

condition				: LEFT_PAREN condition_obj RIGHT_PAREN	
						;


for_proxy_name			: EID
						;

for_indexed_obj			: EID				// indexed<t>
						| method_seq
						| subroutine_call
						;

for_spec				: for_proxy_name IN for_indexed_obj
						;


for_index_obj			: EID					
						| new_obj	
						| method_seq	// x:reuse 
						;

for_list				: LEFT_PAREN for_spec ( COMMA for_index_obj )? RIGHT_PAREN
						;


exec_item				: new_obj	
						| new_proxy
						| proxy_binding
						| method_seq	
						| subroutine_call
						| return_point
						| quit_point
						| escape_point
						| if_item
						| loop_item
						| for_item
						| isolate_item
						;
						
if_item					: IF condition exec_item
						| IF condition ( exec_item | block ) ELSE exec_item
						;

loop_item				: LOOP condition? exec_item	
						| LOOP condition		// pure loop
						;


for_item				: FOR for_list exec_item
						;


isolate_item			: ISOLATE exec_item 
						| ISOLATE ( exec_item | block ) TRAP exec_item 
						;


block_item				: exec_item? SEMI_COLON 
						| block			
						| subroutine
						;

plain_block				: LEFT_CURLY block_item* RIGHT_CURLY	
						;

if_block				: IF condition block
						| IF condition ( exec_item | block ) ELSE block
						;

loop_block				: LOOP condition? block
						;

for_block				: FOR for_list block
						;

isolate_block			: ISOLATE block
						| ISOLATE ( exec_item | block ) TRAP block
						;

split_block				: SPLIT LEFT_CURLY plain_block* RIGHT_CURLY
						;


case_value				: LITERAL		 
						| EID		// pure const ref
						;

case_value_list			: LEFT_PAREN case_value ( COMMA case_value )* RIGHT_PAREN
						;

case_label				: CASE case_value_list
						;


switch_obj				: EID
						| formula
						| method_seq
						| subroutine_call	
						;

switch_selector			: LEFT_PAREN switch_obj RIGHT_PAREN
						;

switch_case				: case_label exec_item? SEMI_COLON
						| case_label ( COMMA? case_label )* plain_block
						;

switch_else				: ELSE ( block | exec_item SEMI_COLON )
						;


switch_block			: SWITCH switch_selector LEFT_CURLY switch_case* switch_else? RIGHT_CURLY switch_else?
						;


block					: plain_block			
						| if_block
						| loop_block
						| for_block
						| isolate_block
						| split_block
						| switch_block
						;



//  NON-EXECUTABLE



proxy_def_attribute		: SURE ( COMMA DURABLE )? ( COMMA ACTUAL )? ( COMMA ( CONST | VAR | TBD ) )?
						| DURABLE ( COMMA ACTUAL )? ( COMMA ( CONST | VAR | TBD ) )?
						| ACTUAL ( COMMA ( CONST | VAR | TBD ) )?
						| ( CONST | VAR | TBD )
						;

proxy_def_attribution	: LEFT_SQUARE proxy_def_attribute RIGHT_SQUARE
						;


proxy_def_type_ref		: EID
						;

proxy_def				: PROXY proxy_def_attribution? proxy_def_type_ref  
						;



input_spec_type_ref		: EID
						;

input_spec_name			: EID
						;

input_spec_attribute	: OPT
						| VAR
						;

input_spec_attribution	: LEFT_SQUARE input_spec_attribute RIGHT_SQUARE
						;

input_spec				: input_spec_type_ref input_spec_name? input_spec_attribution?
						;

input_spec_enum			: input_spec ( COMMA input_spec )*
						;

input_spec_list			: LEFT_PAREN input_spec_enum? RIGHT_PAREN
						;


output_spec_type_ref	: EID
						;

output_spec_obj_name	: EID
						;

output_spec				: output_spec_type_ref output_spec_obj_name?
						;

output_spec_enum		: output_spec ( COMMA output_spec )*
						;

output_spec_list		: LEFT_PAREN output_spec_enum? RIGHT_PAREN
						;


extra_spec_type_ref		: EID				// = "extra"
						;

extra_spec_obj_name		: EID
						;

extra_spec				: extra_spec_type_ref extra_spec_obj_name?
						;

extra_spec_list			: LEFT_PAREN extra_spec RIGHT_PAREN		// one item
						;


reg_obj_spec_list		: input_spec_list 
						| input_spec_list output_spec_list
						| input_spec_list output_spec_list extra_spec_list
						;

aux_obj_spec_list		: LEFT_PAREN input_spec_list RIGHT_PAREN 
						;


coroutine_name			: EID
						;

coroutine_spec			: WITH coroutine_name reg_obj_spec_list?
						;


proxy_name				: EID
						;

proxy_spec				: EQUAL proxy_def proxy_name?
						;

subroutine_attribute	: NAF
						;

subroutine_attribution	: LEFT_SQUARE subroutine_attribute RIGHT_SQUARE
						;

subroutine_name			: EID
						;

subroutine_interface	: aux_obj_spec_list? reg_obj_spec_list? subroutine_attribution? coroutine_spec? proxy_spec?
						;

subroutine_header		: subroutine_name subroutine_interface
						;

subroutine_def			: subroutine_header ( SEMI_COLON | plain_block )
						;

subroutine				: SUBROUTINE subroutine_def
						;

subroutine_group		: SUBROUTINE LEFT_CURLY subroutine_def* RIGHT_CURLY
						;


method_attribute		: CONST
						| VAR 
						| CONST COMMA NAF
						;

method_attribution		: LEFT_SQUARE method_attribute RIGHT_SQUARE
						;

method_interface		: reg_obj_spec_list? method_attribution? coroutine_spec? proxy_spec? 
						;

method_name				: EID
						;

method_header			: method_name method_interface  
						;

method_def				: method_header ( SEMI_COLON | plain_block )
						;

method_group			: ( GENERAL | ABSTRACT | BASE | MISC  ) METHOD? LEFT_CURLY method_def* RIGHT_CURLY
						;



recap_attribute			: TBD
						| FINAL
						| ( PWD | NEW ) ( COMMA FINAL )?
						;

recap_attribution		: LEFT_SQUARE recap_attribute RIGHT_SQUARE
						;

recap_base_ref			: EID
						;

recap_method_def		: recap_attribution? method_def
						;


recap_method_group		: ABSTRACT METHOD? IN recap_base_ref LEFT_CURLY recap_method_def* RIGHT_CURLY	
						;



token_value				: LITERAL 
						;

token_list				: LEFT_PAREN token_value ( COMMA token_value )* RIGHT_PAREN
						;

token_type_name			: EID	
						;

token_def				: token_type_name token_list SEMI_COLON
						;

token					: TOKEN token_def
						;

token_group				: TOKEN LEFT_CURLY token_def* RIGHT_CURLY
						;




operation_token			:  OPERATOR
						| ( PLUS | MINUS | ASTERISK | DIVIDE )
						;

operation_operand		: EID		
						;

operation_expr			: operation_token operation_operand
						| operation_operand ( operation_token operation_operand )+ 
						;

operation_func_ref		: EID
						;

operation_func_input	: operation_operand
						| operation_func_call
						;

operation_func_call		: operation_func_ref LEFT_PAREN operation_func_input ( COMMA operation_func_input )* RIGHT_PAREN	
						;

operation_def			: DOUBLE_QUOTE operation_expr DOUBLE_QUOTE EQUAL DOUBLE_QUOTE operation_func_call DOUBLE_QUOTE SEMI_COLON
						;
					
operation				: OPERATION operation_def
						;

operation_group			: OPERATION LEFT_CURLY operation_def* RIGHT_CURLY
						;




context_type_ref		: EID
						;

context_obj_name		: EID
						;

context_attribute		: CONST
						| VAR
						;

context_attribution		: LEFT_SQUARE context_attribute RIGHT_SQUARE
						;

context_def				: context_type_ref context_obj_name method_call? context_attribution? SEMI_COLON  // method call = :begin with literal inputs only
						;

context_begin_name		: EID	// = "begin"
						;

context_begin			: context_begin_name ( SEMI_COLON | plain_block )
						;

context					: CONTEXT context_def
						;

context_group			: CONTEXT LEFT_CURLY context_def* context_begin? RIGHT_CURLY
						;



instance_item_type_ref		: EID
							;

instance_item_obj_name		: EID
							;

instance_item_attribute		: OPT
							;

instance_item_attribution	: LEFT_SQUARE instance_item_attribute RIGHT_SQUARE
							;

instance_item				: instance_item_type_ref instance_item_obj_name? instance_item_attribution? SEMI_COLON 
							;

instance					: INSTANCE LEFT_CURLY instance_item* RIGHT_CURLY
							;


image_item_label		: LITERAL
						;

image_item_fex			: LITERAL
						;

image_item_input		: LEFT_PAREN image_item_fex? RIGHT_PAREN	
						;

image_item_extra		: LEFT_PAREN image_item_fex ( COMMA image_item_fex )* RIGHT_PAREN		
						;

image_item_obj_ref		: EID 
						;

image_item_include_key	: LITERAL
						;

image_item_include		: IMAGE image_item_include_key
						;

image_item				: image_item_obj_ref image_item_label? image_item_input image_item_extra? SEMI_COLON
						| image_item_include SEMI_COLON
						;

image_name				: EID
						;

image_key				: LITERAL
						;

image_attribute			: EVIDENT
						| NATIVE
						;
						
image_attribution		: LEFT_SQUARE image_attribute RIGHT_SQUARE 
						;

image_header			: image_name? image_key image_attribution?
						;

image_def				: image_header LEFT_CURLY image_item* RIGHT_CURLY
						;

image					: IMAGE image_def
						;


						

alias_name				: EID
						;

alias_ref				: EID
						;

alias_def				: alias_name EQUAL alias_ref SEMI_COLON
						;

alias					: ALIAS alias_def
						;

alias_group				: ALIAS LEFT_CURLY alias_def* RIGHT_CURLY
						;



type_item				: context
						| context_group
						| alias
						| alias_group
						| token
						| token_group
						| subroutine
						| subroutine_group
						| method_group
						| recap_method_group
						| instance
						| image
						;

type_block				: LEFT_CURLY type_item* RIGHT_CURLY
						;

type_base_ref			: EID
						;

type_base_list			: LEFT_PAREN type_base_ref ( COMMA type_base_ref )* RIGHT_PAREN
						;

type_base_def			: FROM ( type_base_ref | type_base_list )
						;

type_basis				: type_base_def ( COMMA? type_base_def )*
						;

type_attribute			: INCOMPLETE
						;

type_attribution		: LEFT_SQUARE type_attribute RIGHT_SQUARE
						;

type_name				: EID
						;

type_header				: type_name type_attribution? type_basis?  
						;

type_def				: type_header ( SEMI_COLON | type_block )
						;

type					: TYPE type_def
						;



page_item				: LOCAL? context
						| LOCAL? context_group
						| LOCAL? operation
						| LOCAL? operation_group
						| LOCAL? token
						| LOCAL? token_group
						| LOCAL? alias
						| LOCAL? alias_group
						| LOCAL? subroutine
						| LOCAL? subroutine_group
						| LOCAL? type
						;

page_book_ref			: EID
						;

page_attribute			: NATIVE
						;

page_attribution		: LEFT_SQUARE page_attribute RIGHT_SQUARE
						;

page_uses_alias			: EID
						;

page_uses_ref			: EID ( AS page_uses_alias )?		
						;

page_uses_list			: LEFT_PAREN page_uses_ref ( COMMA page_uses_ref )* RIGHT_PAREN
						;

page_uses				: USES ( page_uses_ref | page_uses_list )
						;

page_name				: EID
						;

page_header				: PAGE page_name IN page_book_ref page_attribution? page_uses*
						;

page					: page_header page_item*
						;



