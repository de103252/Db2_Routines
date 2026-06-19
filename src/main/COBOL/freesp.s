*
* Free memory allocated from a specific private subpool
*
* Parameter list passed in GPR 1:
*    Address of memory area to be released
*    Address of fullword length of memory area to be released
*    Address of fullword subpool
FREESP   CSECT
FREESP   AMODE 31
FREESP   RMODE ANY
         SAVE  (14,12)       Save caller's registers
         LR    12,15         Use R12 as base register for CSECT
         USING FREESP,12     Make CSECT addressable
         LR    6,1           Save parameter list address
         LA    2,WKAREAL     Allocate a save area
         STORAGE OBTAIN,LENGTH=(2)
         ST    13,4(1)       Store back pointer to register save area
         ST    1,8(13)       Store forward pointer in caller's area
         LR    13,1          Point R13 at register save area
         USING WKAREA,13     Make work area addressable
         LR    1,6           Restore parameter list address
***
         L     6,0(1)        Load allocated memory address
         L     7,4(1)        Load address of allocated memory length
         L     7,0(7)        Load allocated memory length
         L     8,8(1)        Load address of memory subpool
         L     8,0(8)        Load memory subpool
         STORAGE RELEASE,    Release storage                           X
               ADDR=(6),                                               X
               LENGTH=(7),                                             X
               SP=(8),                                                 X
               COND=YES      Don't ABEND on failure
***
         LR    7,15          Save return code
         L     6,4(13)       Save caller's R13
         LR    1,13          Free work area
         LA    2,WKAREAL
         STORAGE RELEASE,ADDR=(1),LENGTH=(2)
         DROP  13
         LR    13,6          Restore caller's R13
         LR    15,7          Restore return code
         RETURN (14,12),RC=(15)
*
WKAREA   DSECT
SVAREA   DS    18F
WKAREAL  EQU   *-WKAREA
         END
