#pragma langlvl(EXTC99)
/*********************************************************************
 *
 * This UDF splits a string into tokens separated by
 * a delimiter character.
 * It returns a table that has one row per token.
 *
 * Example usage:
 *   SELECT * FROM TABLE(SPLIT('foo,bar,,baz', ','))
 * This returns:
 *   SEQ TOKEN
 *     1 foo
 *     2 bar
 *     3
 *     4 baz
 *
 * To install the function, use the following SQL:
 *
REATE FUNCTION SPLIT(STR VARCHAR(32704), SEP CHAR(1))
 RETURNS TABLE (SEQ INTEGER, TOKEN VARCHAR(32704))
 LANGUAGE C
 EXTERNAL NAME SPLIT
 PARAMETER STYLE DB2SQL
 PARAMETER CCSID EBCDIC
 PARAMETER VARCHAR STRUCTURE
 NO FINAL CALL
 FENCED
 RETURNS NULL ON NULL INPUT
 DETERMINISTIC
 NO EXTERNAL ACTION
 DISALLOW PARALLEL
 SCRATCHPAD 16
 WLM ENVIRONMENT &WLMENV
 STAY RESIDENT YES
 PROGRAM TYPE SUB
 RUN OPTIONS 'POSIX(ON),XPLINK(ON)'
 -- for debug: RUN OPTIONS
POSIX(ON),XPLINK(ON),TEST(,,,TCPIP&10.1.1.1%8001:*)'
 CARDINALITY 100
 ;
 *
 * Compile the source code like this:
 *
 * c99 -Wc,'XPLINK,LANGLVL(EXTC99)' -g -o "//'load.lib(SPLIT)'" ™
 *     -I "//'DSNB10.SDSNC.h'" ™
 *     SPLIT.c
 *
 * Where load.lib is a load library in the WLM address space's STEPLIB
 * concatenation.
 *
 *****************************************************************/   /
include <string.h>
include <sql.h>
include <sqludf.h>

* Struct for scratchpad area */
truct scr {
   sqluint32 len;    // Scratchpad length
   sqluint32 offset; // Current offset into source string
   sqluint32 seq;    // Current row number
;

**
* External entry point to the UDF.
*/
pragma linkage(SPLIT,fetchable)
nt SPLIT(struct sqlchar   *str,               // Input string
         const char       *sep,               // Separator
         sqlint32         *seq,               // Output: Row number
         struct sqlchar   *tok,               // Output: Next token
         SQLUDF_NULLIND   *str_ind,           // NULL indicators
         SQLUDF_NULLIND   *sep_ind,
         SQLUDF_NULLIND   *seq_ind,
         SQLUDF_NULLIND   *tok_ind,
         char             *sqlstate,          // SQLSTATE
         char             *sqludf_fname,      // UDF name
         char             *sqludf_fspecname,  // UDF specific name
         char             *msgtext,           // Error message
         struct scr       *scr,               // Scratchpad
         SQLUDF_CALL_TYPE *call_type)         // Call type

   switch (*call_type) {
       case SQLUDF_TF_OPEN:
           scr->offset = 0;
           scr->seq = 1;
           break;
       case SQLUDF_TF_FETCH:
           if (scr->offset > str->length) {
               // End of input string. Return SQLSTATE of 02000.
               tok->length = 0;
               strcpy(sqlstate, "02000");
           } else {
               sqluint32 offset = scr->offset;
               // Find next separator.
               const char *token = memchr(str->data + offset,
                                          sep[0],
                                          str->length - offset);
               *seq = scr->seq++;
               *seq_ind = 1;
               if (token == NULL) {
                   // No more separators -- current token was last one
                   tok->length = str->length - offset;
               } else {
                   // Current token spans from current offset
                   // till one before next separator.
                   tok->length = token - (str->data + offset);
               }
               memcpy(tok->data, str->data + offset, tok->length);
               *tok_ind = 1;
               scr->offset += tok->length + 1;
           }
           break;
   }
   return 0;
}
