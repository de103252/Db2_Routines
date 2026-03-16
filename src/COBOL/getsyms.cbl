       Identification Division.
      ******************************************************************
      * This Db2 table UDF returns z/OS system symbols.
      *
      * System symbols are substitution variables that z/OS maintains
      * and makes available to JCL and other system components.
      * Common symbols include &SYSNAME, &SYSPLEX, &SYSCLONE, etc.
      *
      * To compile from z/OS Unix, run:
      *   cob2 -g -o "//'DSNC10.DBCG.RUNLIB.LOAD(GETSYMS)'" getsyms.cbl
      * Where DSNC10.DBCG.RUNLIB.LOAD is a load library in your WLM
      * environment's STEPLIB concatenation.
      *
      * In Db2, declare the function as follows:
      *
      * CREATE FUNCTION GET_SYSTEM_SYMBOLS()
      * RETURNS TABLE(SYMBOL  VARCHAR(8),
      *               VALUE   VARCHAR(256))
      * LANGUAGE COBOL
      * PARAMETER STYLE SQL
      * PARAMETER CCSID EBCDIC
      * SCRATCHPAD
      * SECURITY USER
      * EXTERNAL NAME GETSYMS
      * PROGRAM TYPE MAIN
      * DISALLOW PARALLEL
      * NO EXTERNAL ACTION
      * DETERMINISTIC
      * CARDINALITY 50;
      *
      * Usage example:
      * SELECT * FROM TABLE(GET_SYSTEM_SYMBOLS())
      *  ORDER BY SYMBOL;
      *
      ******************************************************************
       Program-Id. GetSyms.
       Data Division.
       Working-Storage Section.
      *********************************************************
      * ASASYMBM - System Symbol Service                      *
      *********************************************************
       01 Asasymbm-Plist.
          05 Asasymbm-Version      Pic S9(9) Comp Value 1.
          05 Asasymbm-Num-Symbols  Pic S9(9) Comp Value 0.
          05 Asasymbm-Symbol-Ptr   Pointer Value Null.
          05 Asasymbm-Return-Code  Pic S9(9) Comp Value 0.
          05 Asasymbm-Reason-Code  Pic S9(9) Comp Value 0.
          05 Asasymbm-Return-Code-Disp  Pic S9(9) Display.
          05 Asasymbm-Reason-Code-Disp  Pic S9(9) Display.

       01 Symbol-Entry.
          05 Symbol-Name           Pic X(8).
          05 Symbol-Value-Len      Pic S9(9) Comp.
          05 Symbol-Value          Pic X(256).

       01 Symbol-Entry-Ptr         Pointer-32.
       01 Symbol-Entry-Ptr-Num     Redefines Symbol-Entry-Ptr
                                   Pic 9(9) Comp-5.

       01 Symbol-Array.
          05 Symbol-Item Occurs 1 To 100 Times
                         Depending On Asasymbm-Num-Symbols
                         Pointer-32.

       01 Work-Areas.
          05 Idx                   Pic S9(9) Comp Value 0.
          05 Current-Symbol        Pic S9(9) Comp Value 0.

       Linkage Section.
      *********************************************************
      * Output columns                                        *
      *********************************************************
       01 Tbl-Symbol.
          49 Tbl-Symbol-Len        Pic S9(4) Comp-5.
          49 Tbl-Symbol-Txt        Pic X(8).
       01 Tbl-Symbol-Ind           Pic S9(4) Comp-5.

       01 Tbl-Value.
          49 Tbl-Value-Len         Pic S9(4) Comp-5.
          49 Tbl-Value-Txt         Pic X(256).
       01 Tbl-Value-Ind            Pic S9(4) Comp-5.

      *********************************************************
      * Standard UDF parameters                               *
      *********************************************************
       01 Udf-Sqlstate             Pic X(5).
       01 Udf-Func.
          49 Udf-Func-Len          Pic 9(4) Usage Binary.
          49 Udf-Func-Text         Pic X(137).
       01 Udf-Spec.
          49 Udf-Spec-Len          Pic 9(4) Usage Binary.
          49 Udf-Spec-Text         Pic X(128).
       01 Udf-Diag.
          49 Udf-Diag-Len          Pic 9(4)  Comp-5.
          49 Udf-Diag-Text         Pic X(1000).
       01 Udf-Scratchpad.
          49 Udf-Spad-Len          Pic 9(9)  Comp-5.
          49 Sp-Current-Idx        Pic S9(9) Comp-5.
          49 Sp-Total-Symbols      Pic S9(9) Comp-5.
          49 Sp-Initialized        Pic X Value 'N'.
             88 Sp-Is-Initialized  Value 'Y'.
       01 Udf-Call-Type            Pic S9(9) Binary.
          88 Call-Type-First       Value -2.
          88 Call-Type-Open        Value -1.
          88 Call-Type-Fetch       Value  0.
          88 Call-Type-Close       Value  1.
          88 Call-Type-Final       Value  2, 255.

       01 Symbol-Entry-Mapped.
          05 Sym-Name              Pic X(8).
          05 Sym-Value-Len         Pic S9(9) Comp.
          05 Sym-Value             Pic X(256).

       Procedure Division Using
           Tbl-Symbol, Tbl-Symbol-Ind,
           Tbl-Value, Tbl-Value-Ind,
           Udf-Sqlstate,
           Udf-Func,
           Udf-Spec,
           Udf-Diag,
           Udf-Scratchpad,
           Udf-Call-Type.

       Main-Logic.
           Evaluate True
              When Call-Type-Open
                 Perform Open-Processing
              When Call-Type-Fetch
                 Perform Fetch-Processing
              When Call-Type-Close
                 Perform Close-Processing
              When Call-Type-Final
                 Continue
           End-Evaluate
           Goback.

       Open-Processing.
      *    Initialize scratchpad on first call
           If Not Sp-Is-Initialized Then
              Perform Get-System-Symbols
              Set Sp-Is-Initialized To True
           End-If
           Move 0 To Sp-Current-Idx.

       Fetch-Processing.
      *    Return next symbol
           Add 1 To Sp-Current-Idx
           If Sp-Current-Idx > Sp-Total-Symbols Then
      *       No more rows
              Move '02000' To Udf-Sqlstate
              Goback
           End-If

      *    Get pointer to current symbol entry
           Set Symbol-Entry-Ptr To Symbol-Item(Sp-Current-Idx)
           Set Address of Symbol-Entry-Mapped to Symbol-Entry-Ptr


      *    Return symbol name
           Move 8 To Tbl-Symbol-Len
           Move Sym-Name To Tbl-Symbol-Txt
           Move 0 To Tbl-Symbol-Ind

      *    Return symbol value
           If Sym-Value-Len > 0 And Sym-Value-Len <= 256 Then
              Move Sym-Value-Len To Tbl-Value-Len
              Move Sym-Value(1:Sym-Value-Len) To
                   Tbl-Value-Txt(1:Sym-Value-Len)
              Move 0 To Tbl-Value-Ind
           Else
              Move 0 To Tbl-Value-Len
              Move -1 To Tbl-Value-Ind
           End-If.

       Close-Processing.
      *    Clean up if needed
           Continue.

       Get-System-Symbols.
      *    Call ASASYMBM to retrieve system symbols
           Call 'ASASYMBM' Using Asasymbm-Plist

           Move Asasymbm-Return-Code to Asasymbm-Return-Code-Disp
           Move Asasymbm-Reason-Code to Asasymbm-Reason-Code-Disp
           If Asasymbm-Return-Code Not = 0 Then
              Move 'SY001' To Udf-Sqlstate
              String 'Failed to retrieve system symbols. RC='
                     Asasymbm-Return-Code-Disp
                     ' Reason='
                     Asasymbm-Reason-Code-Disp
                     Delimited By Size
                     Into Udf-Diag-Text
              Compute Udf-Diag-Len =
                 Function Length(Function Trim(Udf-Diag-Text))
              Goback
           End-If

           Move Asasymbm-Num-Symbols To Sp-Total-Symbols

      *    Build array of pointers to symbol entries
           Set Symbol-Entry-Ptr To Asasymbm-Symbol-Ptr
           Perform Varying Idx From 1 By 1
                   Until Idx > Asasymbm-Num-Symbols
              Set Symbol-Item(Idx) To Symbol-Entry-Ptr
      *       Calculate address of next entry
      *       Set Symbol-Entry-Ptr Up By 268
              Compute Symbol-Entry-Ptr-Num
                    = Symbol-Entry-Ptr-Num + Length of Symbol-Entry
           End-Perform.

       End Program GetSyms.
