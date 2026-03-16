//GETSYMS  JOB (ACCT),'COMPILE GETSYMS',
//         CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID
//*
//* Compile COBOL program GETSYMS for Db2 UDF
//* This program retrieves z/OS system symbols
//*
//COMPILE  EXEC IGYWCL,
//         PARM.COBOL='LIB,APOST,RENT,SSRANGE,DYNAM'
//COBOL.SYSIN DD *
       [Copy getsyms.cbl source here]
/*
//LKED.SYSLMOD DD DISP=SHR,DSN=DSND10.DBDG.RUNLIB.LOAD(GETSYMS)
//LKED.SYSIN DD *
  NAME GETSYMS(R)
/*