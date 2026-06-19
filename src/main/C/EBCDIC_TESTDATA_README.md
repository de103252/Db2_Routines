# EBCDIC Test Data Generator

## Overview

This Python script generates test data encoded in EBCDIC format for testing the
"READ_GENERIC_FILE" user-defined function.

## Record Layout

Each record is exactly 80 bytes with the following structure:

| Columns | Length | Description | Format |
|---------|--------|-------------|--------|
| 1-8 | 8 bytes | Zoned numerical data | EBCDIC zoned decimal (0-99999999) |
| 9-43 | 35 bytes | Last name | EBCDIC text, space-padded |
| 44-57 | 14 bytes | Random binary data | Binary |
| 58-65 | 8 bytes | Date | EBCDIC text (YYYYMMDD, 1970+) |
| 66-69 | 4 bytes | Time of day | EBCDIC text (HHMM) |
| 70-74 | 5 bytes | Positive number | Packed decimal (5000.00-9999999.99) |
| 75-80 | 6 bytes | Random binary data | Binary |

## Usage

### Basic Usage

Generate 100 records (default):
```bash
python generate_ebcdic_testdata.py
```

This creates a file named `testdata.ebcdic` with 100 records.

### Custom Output

Specify output filename and number of records:
```bash
python generate_ebcdic_testdata.py mydata.ebcdic 500
```

This creates `mydata.ebcdic` with 500 records.

### Command Line Syntax

```bash
python generate_ebcdic_testdata.py [output_file] [num_records]
```

**Parameters:**
- `output_file` (optional): Name of the output file (default: `testdata.ebcdic`)
- `num_records` (optional): Number of records to generate (default: 100)

## Data Format Details

### Zoned Decimal Format (Columns 1-8)

The script uses EBCDIC zoned decimal format for columns 1-8:
- Each digit has zone bits `F` (0xF0-0xF9)
- The last digit of positive numbers has zone bits `C` (0xC0-0xC9)

**Example:** The number `14890564` in columns 1-8 appears as:
```
Hex: F1 F4 F8 F9 F0 F5 F6 C4
```

### Packed Decimal Format (Columns 70-74)

The script uses packed decimal format for columns 70-74:
- Each byte holds two decimal digits (nibbles)
- The last nibble contains the sign (0xC for positive)
- Format: `(digit1 << 4) | digit2` for each byte
- Last byte: `(last_digit << 4) | 0x0C`

**Example:** The value `3249165.70` (324916570 cents) in columns 70-74 appears as:
```
Hex: 32 49 16 57 0C
Breakdown:
  32 = digits 3,2
  49 = digits 4,9
  16 = digits 1,6
  57 = digits 5,7
  0C = digit 0 + positive sign (C)
Value: 324916570 = 3249165.70
```

This compressed format stores 9 digits in just 5 bytes, compared to 9 bytes needed for zoned decimal.

### Last Names

The script includes 100+ common last names in title case (e.g., "Smith", "Johnson", "Garcia"). Names are:
- Left-justified
- Padded with EBCDIC spaces (0x40) to fill 35 characters
- Encoded in EBCDIC (CP037)

### Date Format

Dates are generated randomly between January 1, 1970, and December 31, 2026:
- Format: YYYYMMDD
- Example: `20060417` (April 17, 2006)
- Encoded in EBCDIC

### Time Format

Times are generated randomly:
- Format: HHMM (24-hour format)
- Range: 0000-2359
- Example: `0544` (5:44 AM)
- Encoded in EBCDIC

### Amount Field (Columns 70-74)

Represents monetary amounts from 5000.00 to 9999999.99:
- Stored as 5-byte packed decimal (9 digits with implied 2 decimal places)
- Range: 500000 to 999999999 (representing 5000.00 to 9999999.99 in cents)
- Example: `32 49 16 57 0C` represents 324916570 cents = 3249165.70
- More space-efficient than zoned decimal (5 bytes vs 9 bytes)

### Binary Data

Random binary data in columns 44-57 and 75-80 provides realistic test scenarios for applications that need to handle mixed data types.

## Output

The script provides:
1. Progress updates during generation
2. File statistics (size, record count)
3. Hex dump of the first record for verification
4. Decoded sample data for human readability

### Sample Output

```
EBCDIC Test Data Generator
================================================================================
Output file: testdata.ebcdic
Number of records: 10
Record length: 80 bytes (fixed)
================================================================================

Generating 10 records...
  Generated 10 records...

File 'testdata.ebcdic' created successfully!
  Records: 10
  File size: 800 bytes (0.78 KB)
  Record length: 80 bytes

================================================================================
SAMPLE RECORD (First record in hex):
================================================================================

Columns 1-8 (Zoned Decimal):
  Hex: f1 f4 f8 f9 f0 f5 f6 c4

Columns 9-43 (Last Name):
  Hex: c2 85 93 93 40 40 40 40 ...
  ASCII: Bell

Columns 58-65 (Date YYYYMMDD):
  Hex: f2 f0 f0 f6 f0 f4 f1 f7
  ASCII: 20060417

Columns 66-69 (Time HHMM):
  Hex: f0 f5 f4 f4
  ASCII: 0544

Columns 70-74 (Packed Decimal Amount):
  Hex: 32 49 16 57 0c
  Decoded: 324916570 (sign: C, value: 3249165.70)
...
```

## Requirements

- Python 3.6 or higher
- No external dependencies (uses only standard library)

## Use Cases

This test data generator is ideal for:
- Testing mainframe data processing applications
- Validating EBCDIC file handling routines
- Testing data conversion utilities
- Creating sample data for Db2 for z/OS external table definitions
- Performance testing with realistic data volumes
- Training and demonstration purposes

## Technical Notes

### EBCDIC Encoding

The script uses Python's `cp037` codec (EBCDIC US) for text encoding. This is compatible with most IBM mainframe systems.

### Character Set

- EBCDIC space: 0x40
- EBCDIC digits 0-9: 0xF0-0xF9 (zone F)
- EBCDIC positive sign (zoned): 0xC0-0xC9 (zone C)
- Packed decimal sign: 0xC (positive), 0xD (negative), 0xF (unsigned)

### File Size Calculation

File size = Number of records × 80 bytes

Examples:
- 100 records = 8,000 bytes (7.81 KB)
- 1,000 records = 80,000 bytes (78.13 KB)
- 10,000 records = 800,000 bytes (781.25 KB)

## Integration with Db2 for z/OS

This test data can be used with the [`ReadGenericFile`](src/C/ReadGenericFile.ddl) external table function to read EBCDIC files directly into Db2 for z/OS queries.

## License

This script is part of the Db2_Routines project. See the main project README for license information.