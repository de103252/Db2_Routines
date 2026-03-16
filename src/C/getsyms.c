#pragma langlvl(EXTC99)
#pragma csect(CODE,"GETSYMS")
/*********************************************************************
 *
 * GET_SYSTEM_SYMBOLS - Db2 Table UDF
 *
 * This table UDF returns z/OS system symbols as relational rows.
 * System symbols are substitution variables maintained by z/OS
 * that are available to JCL and other system components.
 *
 * Common symbols include:
 *   &SYSNAME  - System name
 *   &SYSPLEX  - Sysplex name
 *   &SYSCLONE - System clone identifier
 *   &LPARNAME - LPAR name
 *   &JOBNAME  - Job name (when in batch)
 *   &SYSUID   - User ID
 *
 * To compile from z/OS Unix, run:
 *   c99 -Wc,'XPLINK,LANGLVL(EXTC99),METAL' -g \
 *       -o "//'DSNC10.DBCG.RUNLIB.LOAD(GETSYMS)'" \
 *       -I "//'DSNC10.SDSNC.H'" \
 *       -I "//'SYS1.MACLIB'" \
 *       getsyms.c
 *
 * Where DSNC10.DBCG.RUNLIB.LOAD is a load library in your WLM
 * environment's STEPLIB concatenation.
 *
 * In Db2, declare the function as follows:
 *
 * CREATE FUNCTION GET_SYSTEM_SYMBOLS()
 * RETURNS TABLE(SYMBOL  VARCHAR(8),
 *               VALUE   VARCHAR(256))
 * LANGUAGE C
 * PARAMETER STYLE SQL
 * PARAMETER CCSID EBCDIC
 * SCRATCHPAD 1000
 * SECURITY USER
 * EXTERNAL NAME GETSYMS
 * FINAL CALL
 * DISALLOW PARALLEL
 * NO EXTERNAL ACTION
 * DETERMINISTIC
 * CARDINALITY 50
 * WLM ENVIRONMENT DBCGENVG
 * STAY RESIDENT YES
 * ASUTIME NO LIMIT
 * FENCED
 * RUN OPTIONS 'POSIX(ON),XPLINK(ON)';
 *
 * Usage example:
 * SELECT * FROM TABLE(GET_SYSTEM_SYMBOLS()) ORDER BY SYMBOL;
 *
 *********************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sqlstate.h>
#include <sqludf.h>

/* ASASYMBM service parameter list structure */
typedef struct {
    int version;           /* Version (input) - must be 1 */
    int num_symbols;       /* Number of symbols (output) */
    void *symbol_ptr;      /* Pointer to symbol array (output) */
    int return_code;       /* Return code (output) */
    int reason_code;       /* Reason code (output) */
} ASASYMBM_PLIST;

/* Symbol entry structure */
typedef struct {
    char name[8];          /* Symbol name (8 bytes) */
    int value_length;      /* Length of value */
    char value[256];       /* Symbol value (up to 256 bytes) */
} SYMBOL_ENTRY;

/* Scratchpad structure */
typedef struct {
    int current_index;     /* Current symbol index */
    int total_symbols;     /* Total number of symbols */
    char initialized;      /* Initialization flag */
    void *symbol_array;    /* Pointer to symbol array */
} SCRATCHPAD;

/*********************************************************************
 * call_asasymbm - Invoke ASASYMBM macro using inline assembly
 *
 * ASASYMBM is a macro, not a callable function, so we must use
 * inline assembly to invoke it properly.
 *********************************************************************/
static void call_asasymbm(ASASYMBM_PLIST *plist) {
    /* Save registers and set up parameter list */
    void *plist_addr = (void *)plist;
    void (*ASASYMBM)(void *plist) = fetch("ASASYMBM");
    #pragma linkage(ASASYMBM, fetchable)

    ASASYMBM(plist);
    /*
    __asm(
        " PUSH USING                                           \n"
        " DROP                                                 \n"
        "         LARL  15,ASASYMBM_EPA    Get EPA address    \n"
        "         L     15,0(,15)          Load EPA           \n"
        "         LR    1,%0               Load plist address \n"
        "         BASR  14,15              Call ASASYMBM      \n"
        "         B     ASASYMBM_DONE      Skip EPA           \n"
        "ASASYMBM_EPA DC A(ASASYMBM)       EPA address        \n"
        "ASASYMBM_DONE DS 0H                                  \n"
        " POP  USING                                          \n"
        :  // no outputs
        : "r"(plist_addr)
        : "r0", "r1", "r14", "r15"
    );
    */
}

/*********************************************************************
 * GET_SYSTEM_SYMBOLS - Main UDF function
 *********************************************************************/
void getsyms(
    /* Output columns */
    SQLUDF_VARCHAR_FBD *symbol,       // Symbol name
    SQLUDF_SMALLINT    *symbol_ind,   // Symbol indicator
    SQLUDF_VARCHAR_FBD *value,        // Symbol value
    SQLUDF_SMALLINT    *value_ind,    // Value indicator
    
    /* Standard UDF parameters */
    SQLUDF_TRAIL_ARGS_ALL
)
{
    SCRATCHPAD *scratchpad;
    ASASYMBM_PLIST plist;
    SYMBOL_ENTRY *symbol_entry;
    char msg[1000];
    
    /* Get scratchpad pointer */
    scratchpad = (SCRATCHPAD *)SQLUDF_SCRAT->data;
    
    /* Handle different call types */
    switch (SQLUDF_CALLT) {
        
        case SQLUDF_TF_OPEN:
        case SQLUDF_TF_FIRST:
            /* Initialize on first call */
            if (scratchpad->initialized != 'Y') {
                /* Call ASASYMBM to get system symbols */
                memset(&plist, 0, sizeof(plist));
                plist.version = 1;
                
                call_asasymbm(&plist);
                
                /* Check return code */
                if (plist.return_code != 0) {
                    sprintf(msg, 
                        "Failed to retrieve system symbols. RC=%d Reason=%d",
                        plist.return_code, plist.reason_code);
                    strcpy(SQLUDF_MSGTX, msg);
                    strcpy(SQLUDF_STATE, "SY001");
                    return;
                }
                
                /* Save symbol information in scratchpad */
                scratchpad->total_symbols = plist.num_symbols;
                scratchpad->symbol_array = plist.symbol_ptr;
                scratchpad->initialized = 'Y';
            }
            
            /* Reset index for new scan */
            scratchpad->current_index = 0;
            break;
            
        case SQLUDF_TF_FETCH:
            /* Return next symbol */
            if (scratchpad->current_index >= scratchpad->total_symbols) {
                /* No more rows */
                strcpy(SQLUDF_STATE, SQL_NODATA_EXCEPTION);
                return;
            }
            
            /* Get pointer to current symbol entry */
            symbol_entry = (SYMBOL_ENTRY *)
                ((char *)scratchpad->symbol_array + 
                 (scratchpad->current_index * sizeof(SYMBOL_ENTRY)));
            
            /* Return symbol name */
            memcpy(symbol->data, symbol_entry->name, 8);
            symbol->length = 8;
            *symbol_ind = 0;
            
            /* Return symbol value */
            if (symbol_entry->value_length > 0 && 
                symbol_entry->value_length <= 256) {
                memcpy(value->data, symbol_entry->value, 
                       symbol_entry->value_length);
                value->length = symbol_entry->value_length;
                *value_ind = 0;
            } else {
                value->length = 0;
                *value_ind = -1;  /* NULL */
            }
            
            /* Move to next symbol */
            scratchpad->current_index++;
            break;
            
        case SQLUDF_TF_CLOSE:
            /* Cleanup if needed */
            break;
            
        case SQLUDF_TF_FINAL:
            /* Final cleanup */
            scratchpad->initialized = 'N';
            break;
    }
}
