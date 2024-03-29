/**************************************************
 * 
 * Copyright 2009 Garrett Kiel, Cory Luitjohan, Feng Cao, Phil Slama, Ed Han, Michael Covert
 * 
 * This file is part of Shader Sense.
 *
 *   Shader Sense is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   Shader Sense is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with Shader Sense.  If not, see <http://www.gnu.org/licenses/>.
 *
 *************************************************/

%using Microsoft.VisualStudio.TextManager.Interop
%namespace Babel.Parser
%valuetype LexValue
%partial

/* %expect 5 */


%union {
    public string str;
}


%{
    ErrorHandler handler = null;
    public void SetHandler(ErrorHandler hdlr) { handler = hdlr; }
    internal void CallHdlr(string msg, LexLocation val)
    {
        handler.AddError(msg, val.sLin, val.sCol, val.eCol - val.sCol);
    }
    internal TextSpan MkTSpan(LexLocation s) { return TextSpan(s.sLin, s.sCol, s.eLin, s.eCol); }

    internal void Match(LexLocation lh, LexLocation rh) 
    {
        DefineMatch(MkTSpan(lh), MkTSpan(rh)); 
    } 
%}

%token IDENTIFIER NUMBER INTRINSIC STRUCTIDENTIFIER

%token KWBLENDSTATE KWBOOL KWBREAK KWBUFFER KWCBUFFER KWCOMPILE KWCONST 
%token KWCONTINUE KWDEPTHSTENCILSTATE KWDEPTHSTENCILVIEW KWDISCARD KWDO 
%token KWDOUBLE KWELSE KWEXTERN KWFALSE KWFLOAT KWFOR KWGEOMETRYSHADER 
%token KWHALF KWIF KWIN KWINLINE KWINOUT KWINT KWMATRIX KWNAMESPACE 
%token KWNOINTERPOLATION KWOUT KWPASS KWPIXELSHADER KWRASTERIZERSTATE 
%token KWRENDERTARGETVIEW KWRETURN KWREGISTER KWSAMPLER KWSAMPLER1D 
%token KWSAMPLER2D KWSAMPLER3D KWSAMPLERCUBE KWSAMPLERSTATE 
%token KWSAMPLERCOMPARISONSTATE KWSHARED KWSNORM KWSTATEBLOCK KWSTATEBLOCKSTATE 
%token KWSTATIC KWSTRING KWSTRUCT KWSWITCH KWTBUFFER KWTECHNIQUE KWTECHNIQUE10 
%token KWTEXTURE KWTEXTURE1D KWTEXTURE1DARRAY KWTEXTURE2D KWTEXTURE2DARRAY 
%token KWTEXTURE2DMS KWTEXTURE2DMSARRAY KWTEXTURE3D KWTEXTURECUBE 
%token KWTEXTURECUBEARRAY KWTRUE KWTYPEDEF KWUINT KWUNORM KWUNIFORM KWVECTOR KWVERTEXSHADER 
%token KWVOID KWVOLATILE KWWHILE
%token KWCENTROID KWLINEAR KWNOPERSPECTIVE KWSAMPLE KWD3D10SAMPLERSTATE KWUPPERTEXTURE
%token KWROWMAJOR KWCOLMAJOR KWPACKOFFSET

%token RWAUTO RWCASE RWCATCH RWCHAR RWCLASS RWCONSTCAST RWDEFAULT RWDELETE
%token RWDYNAMICCAST RWENUM RWEXPLICIT RWFRIEND RWGOTO RWLONG RWMUTABLE
%token RWNEW RWOPERATOR RWPRIVATE RWPROTECTED RWPUBLIC RWREINTERPRETCAST
%token RWSHORT RWSIGNED RWSIZEOF RWSTATICCAST RWTEMPLATE RWTHIS RWTHROW
%token RWTRY RWTYPENAME RWUNION RWUNSIGNED RWUSING RWVIRTUAL

//	Special types 

  // %token ',' ';' '(' ')' '{' '}' '=' '[' ']' '.' '"' '#'
  // %token '+' '-' '*' '/' '!' '&' '|' '^' ':' '%' '\' '?'

%token EQ NEQ GT GTE LT LTE AMPAMP BARBAR
%token POUNDPOUND POUNDAT INCR DECR SCOPE
%token LSHIFT LSHIFTASSN RSHIFT RSHIFTASSN
%token ELLIPSIS MULTASSN DIVASSN ADDASSN SUBASSN
%token MODASSN ANDASSN ORASSN XORASSN ARROW
%token STRING
%token PPDEFINE PPDEFINED PPELIF PPELSE PPENDIF PPERROR
%token PPIF PPIFDEF PPIFNDEF PPINCLUDE
%token PPLINE PPUNDEF PPINCLFILE
%token maxParseToken 
%token LEX_WHITE LEX_COMMENT LEX_ERROR

%left '+' '-'
%left '*' '/'

%%

Program
    : Declarations				{ /*AddProgramScope(@1);*/ }
    ;

Declarations
    : Declaration Declarations
    | Declaration error         { CallHdlr("Expected Declaration", @2); }
    | /* empty */
    ;
    
Declaration   /* might need an init action for symtab init here */
	: Declaration_
	;

Declaration_
	: SimpleDeclarations1
    | Preprocessor
    ;
    
Preprocessor
	: PPDEFINE IDENTIFIER Expr
	| PPDEFINE IDENTIFIER
	| PPELIF error
	| PPELSE
	| PPENDIF
	| PPERROR error
	| PPIF PPIfExpr
	| PPIFDEF IDENTIFIER
	| PPIFNDEF IDENTIFIER
	| PPINCLUDE STRING			{ AddIncludeFile(@2); }
	| PPLINE NUMBER
	| PPLINE NUMBER STRING
	| PPUNDEF IDENTIFIER
	| '#'
	;

PPIfExpr
	: PPDEFINED ParenExpr
	| '!' PPDEFINED ParenExpr
	| PPIfExpr BoolOp PPDEFINED ParenExpr
	| PPIfExpr BoolOp '!' PPDEFINED ParenExpr
	;
	

SimpleDeclarations1
    : SimpleDeclaration SimpleDeclarations1
    | SimpleDeclaration 
    | KWINLINE Type IDENTIFIER ParenParams Block					{ AddFunction($2,$3,$4);
																	  /*AddScope(@5);*/ }
	| Type IDENTIFIER ParenParams Block								{ AddFunction($1,$2,$3);
																	  /*AddScope(@4);*/ }
	| KWINLINE Type IDENTIFIER ParenParams ':' IDENTIFIER Block		{ AddFunction($2,$3,$4);
																	  /*AddScope(@7);*/ }
	| Type IDENTIFIER ParenParams ':' IDENTIFIER Block				{ AddFunction($1,$2,$3);
																	  /*AddScope(@6);*/ }
	| KWTECHNIQUE IDENTIFIER TechniqueBlock
    ;

SimpleDeclaration
    : SemiDeclaration ';'
    | SemiDeclaration error ';'     { CallHdlr("Bad declaration, expected ';'", @2); }
    ;


SemiDeclaration
    : VariableDeclaration						{ /*AddVarAsGlobal();*/ }
    | KWSTRUCT IDENTIFIER StructBlock			{ AddStructType($2); }
    | KWSTRUCT STRUCTIDENTIFIER StructBlock		{ AddStructType($2); }
    | SamplerType IDENTIFIER '=' SamplerBlock		{ AddVariable($2, $1, @2);
												  /*AddVarAsGlobal();*/ }
    | KWTYPEDEF Type IDENTIFIER					{ AddTypedefType($2, $3); }
    ;
    
VariableDeclaration
	: StorageClass TypeModifier Type IDENTIFIER Index		{ AddVariable($4, $3, @4); }
	| TypeModifier Type IDENTIFIER Index					{ AddVariable($3, $2, @3); }
	| StorageClass Type IDENTIFIER Index					{ AddVariable($3, $2, @3); }
	| Type IDENTIFIER Index									{ AddVariable($2, $1, @2); }
	| StorageClass TypeModifier SamplerType IDENTIFIER Index		{ AddVariable($4, $3, @4); }
	| TypeModifier SamplerType IDENTIFIER Index					{ AddVariable($3, $2, @3); }
	| StorageClass SamplerType IDENTIFIER Index					{ AddVariable($3, $2, @3); }
	| SamplerType IDENTIFIER Index									{ AddVariable($2, $1, @2); }
	;
	
SamplerType
	: KWSAMPLER
	| KWSAMPLER1D
	| KWSAMPLER2D
	| KWSAMPLER3D
	| KWSAMPLERCUBE
	;

StorageClass                 
    : KWNOINTERPOLATION
    | KWSHARED
    | KWUNIFORM
    | KWVOLATILE
    | KWSTATIC
	| KWEXTERN
	;
    
TypeModifier
	: KWCONST
	| KWROWMAJOR
	| KWCOLMAJOR
	;
	
Index
	: '[' NUMBER ']' Semantic		{ Match(@1, @3); }
	| Semantic
	;
	
Semantic
	: ':' IDENTIFIER Annotation
	| Annotation
	;
	
Annotation
	: LT AnnotationPairs GT InitialValue
	| InitialValue
	;
	
AnnotationPairs
	: AnnotationPair
	| AnnotationPairs AnnotationPair
	;

AnnotationPair
	: ScalarType IDENTIFIER '=' NUMBER ';'  
	| ScalarType IDENTIFIER '=' IDENTIFIER ';'
	| KWSTRING IDENTIFIER '=' STRING ';'
	| KWSTRING IDENTIFIER '=' IDENTIFIER ';'
	;
	
InitialValue
	: '=' InitValue PackOffset
	| PackOffset
	;
	
InitValue
	: Expr
	| '{' ScalarArrayVals '}'
	| '{' NumberVals '}'
	| '{' BoolVals '}'
	;
	
ScalarArrayVals
	: ScalarArray
	| ScalarArrayVals ',' ScalarArray
	;
	
ScalarArray
	: ScalarType '(' NumberVals ')'
	| ScalarType '(' BoolVals ')'
	| '{' NumberVals '}'
	| '{' BoolVals '}'
	;
	
NumberVals
	: NUMBER
	| NumberVals ',' NUMBER
	;
	
BoolVals
	: BoolValues
	| BoolVals ',' BoolValues
	;
	
BoolValues
	: KWTRUE
	| KWFALSE
	;
	
PackOffset
	: ':' KWPACKOFFSET '(' ')' Register
	| ':' KWPACKOFFSET '(' IDENTIFIER ')' Register
	| ':' KWPACKOFFSET '(' IDENTIFIER '.' IDENTIFIER ')' Register
	| ':' KWPACKOFFSET '(' IDENTIFIER IDENTIFIER '.' IDENTIFIER ')' Register
	| Register
	;
	
Register
	: ':' KWREGISTER '(' IDENTIFIER ')'
	| /* empty */
	;
	


Params1
    : Params1 ',' InputMod Type IDENTIFIER					{ $$ = Lexify($1.str + ", " + $3.str + " " + $4.str + " " + $5.str); 
																AddFunctionParamVar($5, $4, @5);/* */ }
    | Params1 ',' InputMod Type IDENTIFIER ':' IDENTIFIER	{ $$ = Lexify($1.str + ", " + $3.str + " " + $4.str + " " + $5.str); 
																AddFunctionParamVar($5, $4, @5);/* */ }
    | InputMod Type IDENTIFIER								{ $$ = Lexify($1.str + " " + $2.str + " " + $3.str);
																AddFunctionParamVar($3, $2, @3);/* */ }
    | InputMod Type IDENTIFIER ':' IDENTIFIER				{ $$ = Lexify($1.str + " " + $2.str + " " + $3.str);
																AddFunctionParamVar($3, $2, @3);/* */ }
    | Params1 ',' InputMod IDENTIFIER IDENTIFIER					{ $$ = Lexify($1.str + ", " + $3.str + " " + $4.str + " " + $5.str); 
																		AddFunctionParamVar($5, $4, @5);/* Do some sort of type checking (red underlining)? */ }
    | Params1 ',' InputMod IDENTIFIER IDENTIFIER ':' IDENTIFIER	    { $$ = Lexify($1.str + ", " + $3.str + " " + $4.str + " " + $5.str);
																		AddFunctionParamVar($5, $4, @5); /* */ }
    | InputMod IDENTIFIER IDENTIFIER								{ $$ = Lexify($1.str + " " + $2.str + " " + $3.str);
																		AddFunctionParamVar($3, $2, @3);/* */ }
    | InputMod IDENTIFIER IDENTIFIER ':' IDENTIFIER				    { $$ = Lexify($1.str + " " + $2.str + " " + $3.str);
																		AddFunctionParamVar($3, $2, @3);/* */ }
    ;

ParenParams
    :  '(' ')'                   { $$ = Lexify(""); Match(@1, @2); }
    |  '(' Params1 ')'           { $$ = $2; Match(@1, @3);}
    |  '(' Params1 error         { CallHdlr("unmatched parentheses", @3); }
    |  '(' error ')'             { CallHdlr("error in params", @2); }
    ;
    
InputMod
	: KWIN
	| KWOUT
	| KWINOUT
	| KWUNIFORM
	| /* empty */
	;

Type
    : ScalarType
    | BufferType
    | VectorType	 
    | MatrixType
    | TextureType
    | OtherTypes
    ;
    
ScalarType
	: KWINT      
    | KWBOOL
    | KWFLOAT
    | KWHALF
    | KWDOUBLE
    | KWUINT
    ;
    
BufferType
	: KWBUFFER LT ScalarType GT
	;
	
VectorType
	: KWVECTOR LT ScalarType ',' NUMBER GT
	;
	
MatrixType
	: KWMATRIX LT ScalarType ',' NUMBER GT
	| KWMATRIX LT ScalarType ',' NUMBER ',' NUMBER GT
	;
	
TextureType
	: KWTEXTURE
	| KWTEXTURE1D
	| KWTEXTURE1DARRAY
	| KWTEXTURE2D
	| KWTEXTURE2DARRAY
	| KWTEXTURE3D
	| KWTEXTURECUBE
	;
 
OtherTypes
	: KWVOID
	| KWSAMPLER
	| STRUCTIDENTIFIER
    ;
    
StructBlock
	: '{' '}'		{ Match(@1, @2); }
	| '{' StructBlockContents '}'
	                            { Match(@1, @3); }
    | '{' StructBlockContents error 
                                { CallHdlr("missing '}'", @3); }
    | '{' error '}'
                                { Match(@1, @3); }
    ;
    
StructBlockContents
	: StructBlockContent StructBlockContents
	| StructBlockContent
	;
	
StructBlockContent
	: Type IDENTIFIER ';'				{ AddStructMember($1, $2); }  
	| Type IDENTIFIER ':' IDENTIFIER ';'	{ AddStructMember($1, $2); }
	| InterpMod Type IDENTIFIER ';'		{ AddStructMember($2, $3); }
	| InterpMod Type IDENTIFIER ':' IDENTIFIER ';'	{ AddStructMember($2, $3); }
	;
	
InterpMod
	: KWCENTROID
	| KWLINEAR
	| KWNOINTERPOLATION
	| KWNOPERSPECTIVE
	| KWSAMPLE
	;
	
SamplerBlock
	: SamplerType '{' SamplerBlockContents '}'		{ Match(@2, @4); }
	;
	
SamplerType
	: KWSAMPLER
	| KWSAMPLER1D
	| KWSAMPLER2D
	| KWSAMPLER3D
	| KWSAMPLERCUBE
	| KWSAMPLERSTATE
	| KWSAMPLERCOMPARISONSTATE
	| KWD3D10SAMPLERSTATE
	;
	
SamplerBlockContents
	: SamplerTexture
	| SamplerTexture SamplerStates
	;

SamplerTexture
	: KWUPPERTEXTURE '=' LT IDENTIFIER GT ';'		{ /* perhaps verify that the identifier is a texture */ }
	;
	
SamplerStates
	: SamplerState SamplerStates
	| SamplerState
	;

SamplerState
	: IDENTIFIER '=' IDENTIFIER ';'
	;

Block
    : OpenBlock CloseBlock      { Match(@1, @2); }
    | OpenBlock BlockContent1 CloseBlock
                                { Match(@1, @3); }
    | OpenBlock BlockContent1 error 
                                { CallHdlr("missing '}'", @3); }
    | OpenBlock error CloseBlock
                                { Match(@1, @3); }
    ;

OpenBlock
    : '{'                       { BeginScope(@1); }
    ;

CloseBlock
    : '}'                       { EndScope(@1); }
    ;

BlockContent1
    : SimpleDeclarations1 Statements1
    | SimpleDeclarations1
    | Statements1
    ;

Statements1
    : Statement Statements1
    | Statement
    ;

Statement
	: VariableDeclaration ';'
    | SemiStatement ';'
    | SemiStatement error ';'       { CallHdlr("expected ';'", @2); } 
  
    | KWWHILE ParenExprAlways Statement
    | KWFOR ForHeader Statement			{ DeferCheckForLoopScope($2, @2, @3); }
    | KWIF ParenExprAlways Statement
    | KWIF ParenExprAlways Statement KWELSE Statement
                                { /*  */ }
    | Block						{ /*AddScope(@1);*/ }
    | Preprocessor
    ;

ParenExprAlways
    : ParenExpr
    | error ')'                 { CallHdlr("error in expr", @1); }
    | error                     { CallHdlr("error in expr", @1); }
    ;

ParenExpr
    : '(' Expr ')'              { Match(@1, @3); }
    | '(' Expr error            { CallHdlr("unmatched parentheses", @3); }
    ;

ForHeader
    : '(' ForBlock ')'          { $$ = $2;
								  Match(@1, @3); }
    | '(' ForBlock error        { $$ = $2;
								  CallHdlr("unmatched parentheses", @3); }
    | '(' error ')'             { Match(@1, @3); 
                                  CallHdlr("error in for", @2); }
    ;

ForBlock
    : AssignExpr ';' Expr ';' AssignExpr				{ $$ = Lexify(string.Empty); }
    | ScalarType AssignExpr ';' Expr ';' AssignExpr		{ $$ = Lexify($1.str + " " + $2.str); }
    | ScalarType AssignExpr ';' error					{ AddVariable($2, $1, @2); }
    | ScalarType AssignExpr ';' Expr ';' error			{ AddVariable($2, $1, @2); }
    ;

SemiStatement
    : AssignExpr 
    | KWRETURN Expr 
    | KWBREAK 
    | KWCONTINUE     
    ;
    
Arguments1
    : Expr ',' Arguments1
    | Expr
    ;

ParenArguments
    : StartArg EndArg                { Match(@1, @2); } 
    | StartArg Arguments1 EndArg     { Match(@1, @3); }
    | StartArg Arguments1 error      { CallHdlr("unmatched parentheses", @3); }
    ;

StartArg
    : '('
    ;

EndArg
    : ')'
    ;    

AssignExpr
    : Identifier AssignOps Expr		{ $$ = $1; }
    | Identifier INCR
    | Identifier DECR
    | Expr
    ;
    
AssignOps
	: '='
	| LSHIFTASSN
	| RSHIFTASSN
	| MULTASSN
	| DIVASSN
	| ADDASSN
	| SUBASSN
	| MODASSN
	| ANDASSN
	| ORASSN
	| XORASSN
	;

Expr
    : RelExpr BoolOp Expr
    | RelExpr '?' RelExpr ':' RelExpr
    | RelExpr
    | STRING
    | '"'
    | RelExpr RelExpr           { CallHdlr("error in relational expression", @2); }
    | error	                    { CallHdlr("unexpected symbol skipping to '}'", @1); }
    ;

BoolOp
    : AMPAMP | BARBAR 
    ;

RelExpr
    : BitExpr RelOp RelExpr
    | BitExpr
    ;

RelOp
    : GT | GTE | LT | LTE | EQ | NEQ
    ;
     
BitExpr
    : AddExpr BitOp BitExpr
    | AddExpr
    ;

BitOp
    : '|' | '&' | '^'
    ;


AddExpr
    : MulExpr AddOp AddExpr
    | MulExpr
    ;

AddOp
    : '+' | '-'
    ;


MulExpr
    : PreExpr MulOp MulExpr
    | PreExpr 
    ;

MulOp 
    : '*' | '/'
    ;

PreExpr
    : PrefixOp Factor
    | Factor
    ;

PrefixOp
    : '!' 
    ;


Factor
    : Identifier ParenArguments		{ MarkIdentifierAsFunction($1, @1); }
    | Identifier ParenArguments '.' Identifier		{ MarkIdentifierAsFunction($1, @1); }
    | INTRINSIC ParenArguments
    | INTRINSIC ParenArguments '.' IDENTIFIER
    | ScalarType ParenArguments
    | Identifier
    | NUMBER
    | ParenExpr
    | BoolValues
    ;     
    
Identifier
    : IDENTIFIER				  { AddIdentifierToCheck($1, @1); }
    | IDENTIFIER ArrayIndex       { AddIdentifierToCheck($1, @1); }
    | Identifier '.' IDENTIFIER	  { AddStructVarForCompletion($1, @1); }	
    | Identifier '.' error        { CallHdlr("expected identifier", @3);
									AddStructVarForCompletion($1, @1); }
/*    | error						  { CallHdlr("expected identifier", @1); } */
    ;
    
ArrayIndex
	: '[' Factor ']'			  { Match(@1, @3); }
	| '[' Factor ']' '[' Factor ']'		{ Match(@1, @3);
										  Match(@4, @6); }
	;
	
TechniqueBlock
	: '{' Passes '}'
	;
	
Passes
	: Pass
	| Passes Pass
	;
	
Pass
	: KWPASS IDENTIFIER PassBlock
	;
	
PassBlock
	: '{' PassStatements '}'
	;
	
PassStatements
	: PassStatement
	| PassStatements PassStatement
	;
	
PassStatement
	: ShaderType '=' KWCOMPILE IDENTIFIER IDENTIFIER '(' OptionalParams ')' ';'
	| ShaderType '=' IDENTIFIER ';' /* IDENTIFIER should be the word NULL */
	| IDENTIFIER '=' IDENTIFIER ';'
	| IDENTIFIER '=' LT IDENTIFIER GT ';'
	| IDENTIFIER '[' NUMBER ']' '=' IDENTIFIER ';'
	| IDENTIFIER '[' NUMBER ']' '=' LT IDENTIFIER GT ';'
	;
	
ShaderType
	: KWVERTEXSHADER
	| KWPIXELSHADER
	;
	
OptionalParams
	: OptionalParams
	| OptionalParams OptionalParam
	| /* */
	;
	
OptionalParam
    : IDENTIFIER
    | NUMBER
    | BoolValues
    ;
%%



