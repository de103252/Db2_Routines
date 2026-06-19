      CBL APOST,RENT
       Identification Division.
      *
      * RACFPROF - Extract RACF profile that covers the input
      * dataset name.
      *
      * Compile and link:
      * cob2 -g -o "//'<target>(RACFPROF)'" racfds.cbl freesp.s
      *
      * Install into Db2 with the following DDL:
      *
      * create function racfprofile(dsname varchar(44), volume char(6))
      *   returns varchar(44)
      *   language cobol
      *   parameter style sql
      *   parameter ccsid ebcdic
      *   security user
      *   external name racfprof
      *
       Program-Id. Racfprof.
       Environment Division.
       Configuration Section.
       Repository.
           function hex-of intrinsic.
       Data Division.
       Working-Storage Section.
      *
      * R_admin (IRRSEQ00) arguments
      *
       01 Work-Items.
          03 Work-Area                 Pic X(1024).
          03 Alet-Saf-Return-Code      Pic S9(9) Comp-5.
          03 Saf-Return-Code           Pic S9(9) Comp-5.
          03 Alet-Racf-Return-Code     Pic S9(9) Comp-5.
          03 Racf-Return-Code          Pic S9(9) Comp-5.
          03 Alet-Racf-Reason-Code     Pic S9(9) Comp-5.
          03 Racf-Reason-Code          Pic S9(9) Comp-5.
          03 Function-Code             Pic X.
          03 Parm-List                 Pic X(1024).
          03 Racf-Userid               Pic X(8).
          03 Acee-Ptr Pointer.
          03 Out-Message-Subpool       Pic X.
          03 Out-Message-Strings Pointer.

       01 Segdesc-Pointer Pointer.
       01 Segdesc-Pointer-Num Redefines Segdesc-Pointer
                                    Pic S9(9) Comp-5.
       01 Flddesc-Pointer Pointer.
       01 Flddesc-Pointer-Num Redefines Flddesc-Pointer
                                    Pic S9(9) Comp-5.
       01 Flddata-Pointer Pointer.
       01 Flddata-Pointer-Num Redefines Flddata-Pointer
                                    Pic S9(9) Comp-5.
       01 Freesp-Subpool            Pic S9(9) Comp-5.
       01 Freesp-Subpool-Num Redefines Freesp-Subpool.
          03 Filler                 Pic X(3).
          03 Freesp-Subpool-Lsb     Pic X.
       01 Freesp-Return-Code        Pic S9(9) Comp-5.

       01 Saf-Return-Code-Disp      Pic 9(3) Display.
       01 Racf-Return-Code-Disp     Pic 9(3) Display.
       01 Racf-Reason-Code-Disp     Pic 9(3) Display.

       Linkage Section.
      *
      * Call parameters
      *
       01 Ds-Name.
          49 Ds-Name-Len            Pic S9(4) Comp-5.
          49 Ds-Name-Text           Pic X(44).
       01 Volume                    Pic X(6).
       01 Profile-Name.
          49 Profile-Name-Len       Pic S9(4) Comp-5.
          49 Profile-Name-Text      Pic X(44).
       01 Ds-Name-Ind               Pic S9(4) Comp-5.
       01 Volume-Ind                Pic S9(4) Comp-5.
       01 Profile-Name-Ind          Pic S9(4) Comp-5.
       01 Udf-Sqlstate              Pic X(5).
      *********************************************************
      * Declare the qualified function name                   *
      *********************************************************
       01 Udf-Func.
          49 Udf-Func-Len           Pic S9(4) Comp-5.
          49 Udf-Func-Text          Pic X(137).
      *********************************************************
      * Declare the specific function name                    *
      *********************************************************
       01 Udf-Spec.
          49 Udf-Spec-Len           Pic S9(4) Comp-5.
          49 Udf-Spec-Text          Pic X(128).
      *********************************************************
      * Declare SQL diagnostic message token                  *
      *********************************************************
       01 Udf-Diag.
          49 Udf-Diag-Len           Pic S9(4) Comp-5.
          49 Udf-Diag-Text          Pic X(1000).


      *
      * Input/output parameter list for R_admin profile extract call
      * (68 bytes for input parameter list)
      *
       01 Admn-Prof-Map.
          03 Admn-Prof-Eye          Pic X(4).
          03 Admn-Prof-Outlen       Pic S9(9) Comp-5.
          03 Admn-Prof-Spid         Pic X.
          03 Admn-Prof-Version      Pic X.
          03 Filler                 Pic X(2).
          03 Admn-Prof-Clsname      Pic X(8).
          03 Admn-Prof-Namelen      Pic S9(9) Comp-5.
          03 Filler                 Pic X(2).
          03 Admn-Prof-Dsvolume     Pic X(6).
          03 Admn-Prof-Dddsc        Pic S9(9) Comp-5.
          03 Admn-Prof-Flag         Pic  9(9) Comp-5.
          03 Admn-Prof-Numseg       Pic S9(9) Comp-5.
          03 Filler                 Pic X(16).
          03 Admn-Prof-Profname     Pic X(44).
      * Segment descriptor
       01 Admn-Prof-Segdesc.
          03 Admn-Prof-Segname      Pic X(8).
          03 Admn-Prof-Segflags     Pic X(4).
          03 Admn-Prof-Numfields    Pic S9(9) Comp-5.
          03 Filler                 Pic X(4).
          03 Admn-Prof-Fieldoffset  Pic S9(9) Comp-5.
          03 Filler                 Pic X(16).
      * Field descriptor
       01 Admn-Prof-Fielddesc.
          03 Admn-Prof-Fieldname    Pic X(8).
          03 Admn-Prof-Fieldtype    Pic X(2).
          03 Filler                 Pic X(2).
          03 Admn-Prof-Fieldflag    Pic X(4).
          03 Admn-Prof-Fieldlen     Pic S9(9) Comp-5.
          03 Filler                 Pic X(4).
          03 Admn-Prof-Data-Offset  Pic S9(9) Comp-5.
          03 Filler                 Pic X(16).
       01 Admn-Prof-Data            Pic X(4096).
       Procedure Division Using Ds-Name
                                Volume
                                Profile-Name
                                Ds-Name-Ind
                                Volume-Ind
                                Profile-Name-Ind
                                Udf-Sqlstate
                                Udf-Func
                                Udf-Spec
                                Udf-Diag.
       Mainline Section.
           *> Prepare exit from UDF
           Move 0 To Udf-Diag-Len
           Move '00000' To Udf-Sqlstate
           Move -1 To Profile-Name-Ind

           *> Prepare R_admin call
           Move Low-Values To Work-Items
           Move Zero To Alet-Saf-Return-Code,
                        Alet-Racf-Return-Code,
                        Alet-Racf-Reason-Code
           *> Function code ADMN_XTR_DATASET
           Move X'22' To Function-Code
           Set Address Of Admn-Prof-Map To Address Of Parm-List
           Move 'DATASET' To Admn-Prof-Clsname
           Move Ds-Name-Text(1:Ds-Name-Len) To Admn-Prof-Profname
           Move Ds-Name-Len To Admn-Prof-Namelen
           If Volume-Ind = 0
              Move Volume To Admn-Prof-Dsvolume
           End-If
           Move X'7F' To Out-Message-Subpool
           Compute Admn-Prof-Flag
                 = 67108864 *> x'04000000': Return only profile name
                 + 33554432 *> x'02000000': Return matching profile

           *> Call R_admin service
           Call 'IRRSEQ00' Using
              Work-Area
              Alet-Saf-Return-Code
              Saf-Return-Code
              Alet-Racf-Return-Code
              Racf-Return-Code
              Alet-Racf-Reason-Code
              Racf-Reason-Code
              Function-Code
              Parm-List
              Racf-Userid
              Acee-Ptr
              Out-Message-Subpool
              Out-Message-Strings

           *> Check return codes.
           *> 0/0/0 is success.
           *> 4/4/4 means the profile does not exist, and the service
           *>       returns the profile that covers the dataset.
           Evaluate Saf-Return-code
               also Racf-Return-Code
               also Racf-Reason-Code
           When 0 also 0 also 0  *> Success
           When 4 also 4 also 4  *> Profile does not exist.
              If Out-Message-Strings Not = Null Then
                 Set Address Of Admn-Prof-Map To Out-Message-Strings
                 Move Admn-Prof-Profname(1:Admn-Prof-Namelen)
                   To Profile-Name-Text
                 Move Admn-Prof-Namelen To Profile-Name-Len
                 Move 0 To Profile-Name-Ind
                 Perform Read-Segments
              End-If
           when other
              Move 1 To Udf-Diag-Len
              Move Saf-Return-Code to Saf-Return-Code-Disp
              Move Racf-Return-Code to Racf-Return-Code-Disp
              Move Racf-Reason-Code to Racf-Reason-Code-Disp
              String 'IRRSEQ00 failed, RC='
                 Saf-Return-Code-Disp '/'
                 Racf-Return-Code-Disp '/'
                 Racf-Reason-Code-Disp
                 Delimited By Size
                 Into Udf-Diag-Text
                 Pointer Udf-Diag-Len
              Subtract 1 From Udf-Diag-Len
              Move 'IR001' To Udf-Sqlstate
           End-Evaluate
           If Out-Message-Strings Not Equal To Null Then
              *> Free output strings allocated by R_admin
              Move 0 To Freesp-Subpool
              Move Out-Message-Subpool To Freesp-Subpool-Lsb
              Call 'FREESP' Using Admn-Prof-Map
                                  Admn-Prof-Outlen
                                  Freesp-Subpool
                        Returning Freesp-Return-Code
              If Freesp-Return-Code Not = 0 Then
      D          Display 'CF4USER FREESP rc=' Freesp-Return-Code
              End-If
           End-If
           Goback.
       Read-Segments Section.
      *            Point at first segment
           Set Segdesc-Pointer To Out-Message-Strings
           Compute Segdesc-Pointer-Num =
              Segdesc-Pointer-Num + 60 + Admn-Prof-Namelen
      *            Check each segment
           Perform Admn-Prof-Numseg Times
              Set Address Of Admn-Prof-Segdesc
                 To Segdesc-Pointer
      D       Display 'Segment ' Admn-Prof-Segname
      *                Point at first field
              Set Flddesc-Pointer To Out-Message-Strings
              Add Admn-Prof-Fieldoffset To Flddesc-Pointer-Num
      *                Check each field
              Perform Admn-Prof-Numfields Times
                 Set Address Of Admn-Prof-Fielddesc
                    To Flddesc-Pointer
                 Set Flddata-Pointer
                    To Out-Message-Strings
                 Add Admn-Prof-Data-Offset
                    To Flddata-Pointer-Num
                 Set Address Of Admn-Prof-Data
                    To Flddata-Pointer
      D          Display Admn-Prof-Fieldname
      D                  " = "
      D                  Admn-Prof-Data(1:Admn-Prof-Fieldlen)
      *                    Point at next field
                 Add Length Of Admn-Prof-Fielddesc
                    To Flddesc-Pointer-Num
              End-Perform
      *                Point at next segment
              Add Length Of Admn-Prof-Segdesc
                 To Segdesc-Pointer-Num
           End-Perform
           Continue.
