#pragma langlvl(EXTC99)
/*********************************************************************
 *
 * This generic table UDF reads records from a flat file and converts
 * them into relational rows, according to the column specification
 * in the SELECT statement's typed-correlation-clause.
 *
 * The file can be any kind of file that can be read using the
 * C fread() function, including sequential files (fixed or variable),
 * PDS(E) members (fixed or variable), and VSAM KSDS or ESDS.
 *
 * Here is an example of a SELECT statement using the UDF:
 *
 * SELECT *
 *   FROM TABLE(READ_GENERIC_FILE('ADCDMST.FLAT.TEST')) T (
 *           id     char(8)
 *         , name   varchar(20)
 *         , int64  bigint
 *         , int32  integer
 *         , int16  smallint
 *         , dec7_2 decimal(13, 2)
 *         , ddd    date
 *         , tm     time
 *         , rst    varbinary(80)
 *         )
 *
 * The UDF expects the flat file to be in a format that is in sync
 * with the column specification in the typed correlation clause,
 * that is, each supported SQL type corresponds with a native type
 * that may be described, for example, with a COBOL picture clause.
 *
 * In this example, the records in file ADCDMST.FLAT.TEST are expected
 * to be in the following format:
 * - 8 alphanumeric bytes
 * - 20 alphanumeric bytes
 * - 8-byte binary integer
 * - 4-byte binary integer
 * - 2-byte binary integer
 * - 8 byte date in zoned decimal format (YYYYMMDD)
 * - 4 byte time in zoned decimal format (hhmm)
 * - Up to 80 alphanumeric bytes
 *
 * The following SQL types are supported, and correspond to the
 * respective native data types:
 *
 * CHARACTER(x)          PIC X(x)
 * VARCHAR(x)            PIC X(x)
 * BINARY(x)             PIC X(x)
 * VARBINARY(x)          PIC X(x)
 * SMALLINT              PIC S9(4)      COMP-5
 * INTEGER               PIC S9(9)      COMP-5
 * BIGINT                PIC S9((18)    COMP-5
 * DECIMAL(p,s)          PIC S9(p)V(s)  COMP-3
 * DATE                  PIC 9999-99-99 DISPLAY
 * TIME                  PIC 99.99      DISPLAY
 *
 * To install the function, use the following SQL:
 *
 * CREATE FUNCTION READ_GENERIC_FILE(FILENAME VARCHAR(54))
 *   RETURNS GENERIC TABLE
 *   LANGUAGE C
 *   SECURITY USER
 *   EXTERNAL NAME RDGENFIL
 *   PARAMETER STYLE DB2SQL
 *   PARAMETER CCSID EBCDIC
 *   PARAMETER VARCHAR STRUCTURE
 *   FINAL CALL
 *   FENCED
 *   NOT DETERMINISTIC
 *   EXTERNAL ACTION
 *   DISALLOW PARALLEL
 *   SCRATCHPAD 16
 *   WLM ENVIRONMENT DBCGENVG
 *   STAY RESIDENT YES
 *   RUN OPTIONS 'POSIX(ON),XPLINK(ON)'
 *   -- for debug:
 *   --   'POSIX(ON),XPLINK(ON),TEST(,,,TCPIP&10.1.1.1%8001:*)'
 *   CARDINALITY 100000
 *
 * Compile the source code like this:
 *
 * c99 -Wc,'XPLINK,LANGLVL(EXTC99)' -g -o "//'load.lib(RDGENFIL)'" \
 *     -I "//'DSNC10.SDSNC.h'" \
 *     rdgenfil.c
 *
 * Where load.lib is a load library in the WLM address space's STEPLIB
 * concatenation.
 * 
 * In z/OS batch, compile like this:
 *
 * //COMPILE    EXEC  EDCXCB,
 * //  CPARM='OPTFILE(DD:CCOPTS)',
 * //  OUTFILE='DSNC10.DBCG.RUNLIB.LOAD(RDGENFIL),DISP=SHR'
 * //SYSPRINT   DD    SYSOUT=*
 * //CCOPTS     DD    *
 * XPLINK
 * LOCALE(En_US.IBM-1047)
 * SEARCH('DSNC10.SDSNC.H')
 * //SYSIN DD *
 *
 *********************************************************************/

#include <dynit.h>
#include <inttypes.h>
#include <errno.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <sql.h>
#include <sqludf.h>
#include <time.h>

#define SQLSTATE_ALLOC_ERROR  "38701"
#define SQLSTATE_OPEN_ERROR   "38702"
#define SQLSTATE_FREE_ERROR   "38703"
#define SQLSTATE_READ_ERROR   "38704"
#define SQLSTATE_SHORT_BUFFER "38705"
#define SQLSTATE_INVALID_DATA "38706"
#define SQLSTATE_INVALID_TYPE "38707"

#define NULL_ON_SHORT_BUF    1
#define NULL_ON_INVALID_DATA 2

/* Struct for scratchpad area */
struct scr {
  sqluint32 len;    // Scratchpad length
  FILE *fp;// Input file
  sqlint64 recno;// Current record number
};

static FILE *
dynalloc_file(struct sqlchar *filename, char *sqlstate, char *msgtext)
{
  __dyn_t ip;
  char dsname[45];
  char ddname[12] = "DD:????????"; // Let the system create a DDname
  char *tokptr;

  dyninit(&ip);
  ip.__ddname = ddname + 3; // Point to ddname (after "DD:")
  strncpy(dsname, filename->data, filename->length);
  dsname[filename->length] = '\0';
  ip.__dsname = dsname;

  // Check whether filename contains a member name
  tokptr = strchr(dsname, '(');
  if (tokptr != NULL) {
    // Split into dataset name and member name
    *tokptr = '\0';
    ip.__member = tokptr + 1;
    tokptr = strchr(tokptr, ')');
    if (tokptr != NULL) {
      *tokptr = '\0';
    }
  }
  ip.__status = __DISP_SHR;

  // Allocate and open data set
  FILE *fp = NULL;
  if (dynalloc(&ip) == 0) {
    fp = fopen(ddname, "rb,type=record,noseek");
    if (fp == NULL) {
      sprintf(msgtext, "%*s open error %d-%d",
                       dsname, errno, __errno2());
      strcpy(sqlstate, SQLSTATE_OPEN_ERROR);
    }
  } else {
    if (ip.__errcode == 528) {
      sprintf(msgtext, "Data set %s in use", dsname);
    } else {
      sprintf(msgtext, "Allocation error %d-%d", ip.__errcode,
          ip.__infocode);
    }
    strcpy(sqlstate, SQLSTATE_ALLOC_ERROR);
  }
  return fp;
}

/**
 * Close and free our input file.
 */
static void dynfree_file(FILE *fp, char *sqlstate, char *msgtext) {
  fldata_t info;
  __dyn_t free_ip;
  char ddname[12];

  dyninit(&free_ip);
  fldata(fp, ddname, &info);
  free_ip.__ddname = ddname + 3;

  fclose(fp);
  if (dynfree(&free_ip) != 0) {
    sprintf(msgtext, "FREE failed for ddname %s: %d-%d",
                     free_ip.__ddname,
                     free_ip.__errcode,
                     free_ip.__infocode);
    strcpy(sqlstate, SQLSTATE_FREE_ERROR);
  }
}

static void signal_short_buffer(sqlint64 recno, int colno, int offset,
    char *sqlstate, char *msgtext) {
  sprintf(msgtext, "Short buffer for column %d (record %" PRId64 ":%d)",
               colno + 1, recno, offset + 1);
  strcpy(sqlstate, SQLSTATE_SHORT_BUFFER);
}

static void signal_invalid_data(sqlint64 recno, int colno, int offset,
    char *sqlstate, char *msgtext) {
  sprintf(msgtext, "Invalid data for column %d (record %" PRId64 ":%d)",
               colno + 1, recno, offset + 1);
  strcpy(sqlstate, SQLSTATE_INVALID_DATA);
}

static inline bool
buflen_ok(int offset,
    size_t datalen,
    size_t reclen)
{
  return offset + datalen < reclen;
}

/**
 * Check whether a given string is a valid number
 * in packed decimal representation.
 */
static bool
is_numeric(unsigned char *data, size_t datalen) {
  int i;
  // Check all but last byte; each nibble must be 0..9
  for (i = 0; i < datalen - 1; i++) {
    if ((data[i] & 0xF0) > 0x90) return false;
    if ((data[i] & 0x0F) > 0x09) return false;
  }
  // Upper nibble of last byte must be 0..0; lower nibble (sign) must be A..F
  if ((data[i] & 0xF0) > 0x90) return false;
  if ((data[i] & 0x0F) < 0x0A) return false;
  return true;
}

/**
 * Check whether a given string is a valid date in format YYYY-MM-DD.
 */
static bool
is_date(const char *datestr) {
  struct tm tm;
  char buf[11];
  const char *end = strptime(datestr, "%Y-%m-%d", &tm);
  if (end == NULL || end-datestr != 10) return false;
  if (!strftime(buf, sizeof buf, "%Y-%m-%d", &tm)) return false;
  return strcmp(datestr, buf) == 0;
}

/**
 * Check whether a given string is a valid time in format HH.MM.SS.
 */
static bool
is_time(const char *timestr) {
  struct tm tm;
  char buf[9];
  const char *end = strptime(timestr, "%H.%M.%S", &tm);
  if (end == NULL || end-timestr != 8) return false;
  if (!strftime(buf, sizeof buf, "%H.%M.%S", &tm)) return false;
  return strcmp(timestr, buf) == 0;
}

/**
 * Build next row from current input record.
 */
static void build_row(sqlint64       recno,
                      char          *buf,
                      size_t         reclen,
                      SQLUDF_OTDESC *otdesc,
                      char          *sqlstate,
                      char          *msgtext,
                      sqlint32       flags)
{
  int offset = 0;
  strcpy(sqlstate, "00000");
  for (int i = 0; i < otdesc->numtfcol; i++) {
    void *coldata = otdesc->coldata[i];
    int colind = 0;
    struct sqlchar *chardata;
    sqluint32 datalen = otdesc->column_info[i].u.datalen;
    switch (otdesc->column_info[i].datatype & ~1) {
      case SQL_TYP_CHAR:
      case SQL_TYP_BINARY:
        if (buflen_ok(offset, datalen, reclen)) {
          memcpy(coldata, buf + offset, datalen);
        } else if (flags & NULL_ON_SHORT_BUF) {
          colind = -1;
        } else {
          signal_short_buffer(recno, i, offset, sqlstate, msgtext);
        }
        break;
      case SQL_TYP_VARCHAR:
      case SQL_TYP_VARBINARY:
        if (offset + datalen > reclen) {
          datalen = reclen - offset;
        }
        chardata = coldata;
        memcpy(chardata->data, buf + offset, datalen);
        chardata->length = datalen;
        break;
      case SQL_TYP_SMALL:
      case SQL_TYP_INTEGER:
      case SQL_TYP_BIGINT:
        if (buflen_ok(offset, datalen, reclen)) {
          memcpy(otdesc->coldata[i], buf + offset, datalen);
        } else if (flags & NULL_ON_SHORT_BUF) {
          colind = -1;
        } else {
          signal_short_buffer(recno, i, offset, sqlstate, msgtext);
        }
      break;
      case SQL_TYP_DECIMAL:
      case SQL_TYP_NUMERIC:
        datalen = (otdesc->column_info[i].u.declen.precision + 1) / 2;
        if (buflen_ok(offset, datalen, reclen)) {
          if (is_numeric(buf + offset, datalen)) {
            memcpy(otdesc->coldata[i], buf + offset, datalen);
          } else if (flags & NULL_ON_INVALID_DATA) {
            colind = -1;
          } else {
            signal_invalid_data(recno, i, offset, sqlstate, msgtext);
          }
        } else if (flags & NULL_ON_SHORT_BUF) {
          colind = -1;
        } else {
          signal_short_buffer(recno, i, offset, sqlstate, msgtext);
        }
        break;
      case SQL_TYP_DATE:
        datalen = 8;
        if (buflen_ok(offset, datalen, reclen)) {
          char datestr[11] = "yyyy-MM-dd";
          memcpy(datestr, buf + offset, 4);
          memcpy(datestr + 5, buf + offset + 4, 2);
          memcpy(datestr + 8, buf + offset + 6, 2);
          if (is_date(datestr)) {
            memcpy(otdesc->coldata[i], datestr, sizeof datestr - 1);
          } else if (flags & NULL_ON_INVALID_DATA) {
            colind = -1;
          } else {
            signal_invalid_data(recno, i, offset, sqlstate, msgtext);
          }
        } else if (flags & NULL_ON_SHORT_BUF) {
          colind = -1;
        } else {
          signal_short_buffer(recno, i, offset, sqlstate, msgtext);
        }
        break;
      case SQL_TYP_TIME:
        datalen = 4;
        if (buflen_ok(offset, datalen, reclen)) {
          char timestr[9] = "HH.MM.00";
          memcpy(timestr, buf + offset, 2);
          memcpy(timestr + 3, buf + offset + 2, 2);
          if (is_time(timestr)) {
            memcpy(otdesc->coldata[i], timestr, sizeof timestr - 1);
          } else if (flags & NULL_ON_INVALID_DATA) {
            colind = -1;
          } else {
            signal_invalid_data(recno, i, offset, sqlstate, msgtext);
          }
        } else if (flags & NULL_ON_SHORT_BUF) {
          colind = -1;
        } else {
          signal_short_buffer(recno, i, offset, sqlstate, msgtext);
        }
        break;
      default:
        sprintf(msgtext, "Invalid SQL type %d for column %d",
                     otdesc->column_info[i].datatype,
                     i + 1);
        strcpy(sqlstate, SQLSTATE_INVALID_TYPE);
        break;
    }
    if (strcmp(sqlstate, "00000")) {
      // Break loop if an error was detected
      break;
    }
    offset += datalen;
    otdesc->colind[i] = colind;
  }
}

static size_t fetch_record(struct scr    *scratchpad,
                       SQLUDF_OTDESC *otdesc,
                       char          *sqlstate,
                       char          *msgtext,
                       sqlint32       flags)
{
  FILE *fp = scratchpad->fp;
  char buf[32767];
  size_t reclen = fread(buf, 1, sizeof buf, fp);

  if (ferror(fp)) {
    strcpy(sqlstate, SQLSTATE_READ_ERROR);
    sprintf(msgtext, "Error reading record: %d reason %d", errno,
        __errno2());
    return 0;
  }
  if (reclen == 0) {
    strcpy(sqlstate, "02000");
  } else {
    build_row(++scratchpad->recno, buf, reclen, otdesc,
              sqlstate, msgtext, flags);
  }
  return reclen;
}

/**
 * External entry point to the UDF.
 */
#pragma linkage(RDGENFIL,fetchable)
void RDGENFIL(struct sqlchar   *filename,
        sqlint32         *pflags,
        SQLUDF_NULLIND   *filename_ind,
        SQLUDF_NULLIND   *flags_ind,
        SQLUDF_OTDESC    *otdesc,
        char             *sqlstate,
        char             *sqludf_fname,
        char             *sqludf_fspecname,
        char             *msgtext,
        struct scr       *scratchpad,
        SQLUDF_CALL_TYPE *call_type)
{
  sqlint32 flags = pflags == NULL || *flags_ind < 0 ? 0 : *pflags;
  strcpy(sqlstate, "00000");
  *msgtext = '\0';
  switch (*call_type) {
    case SQLUDF_TF_FIRST:
      // First call: allocate input data set
      scratchpad->fp = dynalloc_file(filename, sqlstate, msgtext);
      scratchpad->recno = 0;
      scratchpad->len = sizeof *scratchpad;
      break;
    case SQLUDF_TF_OPEN:
      break;
    case SQLUDF_TF_FETCH:
      // Read next record from input data set
      fetch_record(scratchpad, otdesc, sqlstate, msgtext, flags);
      break;
    case SQLUDF_TF_CLOSE:
    default:
      if (scratchpad->fp != NULL) {
        dynfree_file(scratchpad->fp, sqlstate, msgtext);
        scratchpad->fp = NULL;
      }
      break;
  }
}
@@
//CREATFN EXEC PGM=IKJEFT01
//STEPLIB  DD DISP=SHR,DSN=DSNC10.SDSNLOAD
//         DD DISP=SHR,DSN=DSNC10.DBCG.RUNLIB.LOAD
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
 DSN SYSTEM(DBCG)
 RUN PROGRAM(DSNTEP2) PLAN(DSNTEP12)
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSIN    DD *
CREATE FUNCTION READ_GENERIC_FILE(FILENAME VARCHAR(54), FLAGS INTEGER)
  RETURNS GENERIC TABLE
  LANGUAGE C
  EXTERNAL NAME RDGENFIL
  PARAMETER STYLE DB2SQL
  PARAMETER CCSID EBCDIC
  PARAMETER VARCHAR STRUCTURE
  FINAL CALL
  FENCED
  NOT DETERMINISTIC
  EXTERNAL ACTION
  DISALLOW PARALLEL
  SCRATCHPAD 16
  WLM ENVIRONMENT DBCGENVG
  STAY RESIDENT YES
  RUN OPTIONS 'POSIX(ON),XPLINK(ON)'
  CARDINALITY 100000
//TESTFN   EXEC PGM=IKJEFT01
//STEPLIB  DD DISP=SHR,DSN=DSNC10.SDSNLOAD
//         DD DISP=SHR,DSN=DSNC10.DBCG.RUNLIB.LOAD
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
 DSN SYSTEM(DBCG)
 RUN PROGRAM(DSNTEP2) PLAN(DSNTEP12)
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSIN    DD *
 SELECT *
   FROM TABLE(READ_GENERIC_FILE('ADCDMST.FLAT.FILE', 0)) T (
           id     char(8)
         , name   varchar(20)
         , int64  bigint
         , int32  integer
         , int16  smallint
         , dec7_2 decimal(13, 2)
         , ddd    date
         , tm     time
         , rst    varbinary(80)
         )
