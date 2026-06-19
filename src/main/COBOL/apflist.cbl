       Identification Division.
      ******************************************************************
      * This Db2 table UDF returns a list of APF authorized datasets
      * on the system.
      *
      * To compile it from z/OS Unix, run
      *   cob2 -g -o "//'DSNC10.DBCG.RUNLIB.LOAD(apflist)'" apflist.cbl
      * Where xxx.LOAD is a load library in your WLM environment's
      * STEPLIB concatenation.
      *
      * In Db2, declare the function as follows:
      *
      * drop function apflist();
      * create function apflist()
      * returns table(seqid  integer,
      *               dsname varchar(44),
      *               volume varchar(6))
      * language cobol
      * parameter style sql
      * parameter ccsid ebcdic
      * scratchpad
      * security user
      * external name apflist
      * program type main
      * -- continue after failure
      * -- run options 'TEST(,,,TCPIP&192.168.160.1%8002:*)'
      * ;
      ******************************************************************
       Program-Id. Apflist.
       Data Division.
       Working-Storage Section.
       01 Psa-Ptr Pointer                      Value Null.
       Linkage Section.
       01 Tbl-Seqid                Pic S9(9) Comp-5.
       01 Tbl-Seqid-Ind            Pic S9(4) Comp-5.
       01 Tbl-Dsn.
          49 Tbl-Dsn-Len           Pic S9(4) Comp-5.
          49 Tbl-Dsn-Txt           Pic X(44).
       01 Tbl-Dsn-Ind              Pic S9(4) Comp-5.

       01 Tbl-Volser.
          49 Tbl-Volser-Len        Pic S9(4) Comp-5.
          49 Tbl-Volser-Txt        Pic X(6).
       01 Tbl-Volser-Ind           Pic S9(4) Comp-5.

       01 Udf-Sqlstate             Pic X(5).
      *********************************************************
      * Declare the qualified function name                   *
      *********************************************************
       01 Udf-Func.
          49 Udf-Func-Len          Pic 9(4) Usage Binary.
          49 Udf-Func-Text         Pic X(137).
      *********************************************************
      * Declare the specific function name                    *
      *********************************************************
       01 Udf-Spec.
          49 Udf-Spec-Len          Pic 9(4) Usage Binary.
          49 Udf-Spec-Text         Pic X(128).
      *********************************************************
      * Declare SQL diagnostic message token                  *
      *********************************************************
       01 Udf-Diag.
          49 Udf-Diag-Len          Pic 9(4)  Comp-5.
          49 Udf-Diag-Text         Pic X(1000).
      *********************************************************
      * Declare the scratchpad                                *
      *********************************************************
       01 Udf-Scratchpad.
          49 Udf-Spad-Len          Pic 9(9)  Comp-5.
          49 Apf-Counter           Pic S9(9) Comp-5.
          49 Sp-Last-Apfentry-Ptr  Pointer.
          49 Sp-Curr-Apfentry-Ptr  Pointer.
      *********************************************************
      * Declare the call type                                 *
      *********************************************************
       01 Udf-Call-Type            Pic S9(9) Binary.
          88 Call-Type-First                   Value -2.
          88 Call-Type-Open                    Value -1.
          88 Call-Type-Fetch                   Value  0.
          88 Call-Type-Close                   Value  1.
          88 Call-Type-Final                   Value  2, 255.
       01 Psa.
          03 Filler                Pic X(16).
          03 Cvt-Ptr Pointer.
       01 Cvt.
          03 Filler                Pic X(140).
          03 Cvtecvt-Ptr Pointer.
          03 Filler                Pic X(340).
          03 Cvtauthl Pointer.
          03 Cvtauthl-Num Redefines Cvtauthl
                                   Pic S9(9) Comp-5.
       01 Cvtecvt.
          03 Filler                Pic X(228).
          03 Ecvtcsvt-Ptr          Pointer.
       01 Ecvtcsvt.
          03 Filler                Pic X(12).
          03 Apfa-Ptr              Pointer.
       01 Apfa.
          03 Filler                Pic X(8).
          03 Afirst                Pointer.
          03 Alast                 Pointer.
       01 Apfentry.
          03 Filler                Pic X(4).
          03 Flags                 Pic X.
          03 Filler                Pic X(3).
          03 Apfentry-Next Pointer.
          03 Filler                Pic X(12).
          03 Apfdsn                Pic X(44).
          03 Apfvol                Pic X(6).
       Procedure Division Using Tbl-Seqid
                                Tbl-Dsn
                                Tbl-Volser
                                Tbl-Seqid-Ind
                                Tbl-Dsn-Ind
                                Tbl-Volser-Ind
                                Udf-Sqlstate
                                Udf-Func
                                Udf-Spec
                                Udf-Diag
                                Udf-Scratchpad
                                Udf-Call-Type.
       Mainline Section.
           Evaluate True
           When Call-Type-Open         *> If initial call, perform setup
                Perform Open-Call
           When Call-Type-Fetch        *> Fetch next result row
                Perform Fetch-Call
           When Call-Type-Close
                Perform Close-Call
           End-Evaluate
           Goback.
       Open-Call Section.
           Set Address Of Psa To Psa-Ptr
           Set Address Of Cvt To Cvt-Ptr
           *> Check for dynamic APF table.
           If Cvtauthl-Num = 2147479553 Then
              *> Dynamic APF table
              Set Address Of Cvtecvt To Cvtecvt-Ptr
              Set Address Of Ecvtcsvt To Ecvtcsvt-Ptr
              Set Address Of Apfa To Apfa-Ptr
              Set Sp-Last-Apfentry-Ptr To Alast
              Set Sp-Curr-Apfentry-Ptr To Afirst
              Move 0 To Apf-Counter
           Else
              *> Static APF table. Indicate failure.
              Move -1 To Apf-Counter
           End-If
           Continue.
       Fetch-Call Section.
           Move '02000' To Udf-Sqlstate

           *> Do nothing if system uses static APF.
           If Apf-Counter < 0 Exit Section End-If

           *> Start with the last entry seen (remembered in scratchpad).
           Set Address Of Apfentry To Sp-Curr-Apfentry-Ptr

           *> Loop through APF list until we found a valid entry
           *> or the end of the list has been reached.
           Perform Until Udf-Sqlstate = '00000'
                      Or Address Of Apfentry = Sp-Last-Apfentry-Ptr
              Display "155"
              If Apfdsn(1:1) Not = Low-Values Then
                 *> Found a valid entry.
                 Move '00000' To Udf-Sqlstate  *> Indicate success

                 *> Increment sequence number and move it to result row
                 Add 1 To Apf-Counter
                 Move Apf-Counter To Tbl-Seqid

                 *> Move dataset name and volume serial to result row
                 *> without trailing spaces
                 Move Apfdsn To Tbl-Dsn-Txt
                 Move 0 to Tbl-Dsn-Len, Tbl-Volser-Len
                 Inspect Tbl-Dsn-Txt
                    Tallying Tbl-Dsn-Len
                    For Characters Before Initial Space
                 Move Apfvol To Tbl-Volser-Txt
                 Inspect Tbl-Volser-Txt
                    Tallying Tbl-Volser-Len
                    For Characters Before Initial Space
              End-If
              *> Remember current entry in scratchpad
              Set Sp-Curr-Apfentry-Ptr To Apfentry-Next
              Set Address Of Apfentry To Apfentry-Next
           End-Perform
           Continue.
       Close-Call Section.
           If Apf-Counter < 0
             Move 1 to Udf-Diag-Len
             String 'Static APF not supported by this UDF'
               delimited by size
               into Udf-Diag-Text
               pointer Udf-Diag-Len
             Subtract 1 from Udf-Diag-Len
             Move '71000' to Udf-Sqlstate
           End-If
           Continue.
