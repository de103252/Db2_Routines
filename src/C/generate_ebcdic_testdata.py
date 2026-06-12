#!/usr/bin/env python3
"""
Generate test data encoded in EBCDIC with fixed 80-byte records.

Record Layout:
- Columns 1-8:   Zoned numerical data
- Columns 9-43:  Last name (padded with spaces)
- Columns 44-57: Random binary data (14 bytes)
- Columns 58-65: Date in YYYYMMDD format (1970 or later)
- Columns 66-69: Time in HHMM format
- Columns 70-74: Packed decimal number (5000 to 9999999.99)
- Columns 75-80: Random binary data (6 bytes)
"""

import random
import os
from datetime import datetime, timedelta

# Sample last names for test data (in title case)
LAST_NAMES = [
    "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller",
    "Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez",
    "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin",
    "Lee", "Perez", "Thompson", "White", "Harris", "Sanchez", "Clark",
    "Ramirez", "Lewis", "Robinson", "Walker", "Young", "Allen", "King",
    "Wright", "Scott", "Torres", "Nguyen", "Hill", "Flores", "Green",
    "Adams", "Nelson", "Baker", "Hall", "Rivera", "Campbell", "Mitchell",
    "Carter", "Roberts", "Phillips", "Evans", "Turner", "Diaz", "Parker",
    "Cruz", "Edwards", "Collins", "Reyes", "Stewart", "Morris", "Morales",
    "Murphy", "Cook", "Rogers", "Gutierrez", "Ortiz", "Morgan", "Cooper",
    "Peterson", "Bailey", "Reed", "Kelly", "Howard", "Ramos", "Kim",
    "Cox", "Ward", "Richardson", "Watson", "Brooks", "Chavez", "Wood",
    "James", "Bennett", "Gray", "Mendoza", "Ruiz", "Hughes", "Price",
    "Alvarez", "Castillo", "Sanders", "Patel", "Myers", "Long", "Ross",
    "Foster", "Jimenez", "Powell", "Jenkins", "Perry", "Russell", "Sullivan",
    "Bell", "Coleman", "Butler", "Henderson", "Barnes", "Gonzales", "Fisher"
]


def generate_zoned_decimal(value, length):
    """
    Generate zoned decimal representation in EBCDIC.
    In EBCDIC zoned decimal, each digit is represented with zone bits F.
    For positive numbers, the last digit has zone bits C (positive sign).
    """
    # Format the number as a string with leading zeros
    num_str = str(int(value)).zfill(length)
    
    # Convert to bytes in EBCDIC
    result = bytearray()
    for i, digit in enumerate(num_str):
        if i == len(num_str) - 1:
            # Last digit: positive sign (zone C)
            result.append(0xC0 + int(digit))
        else:
            # Other digits: zone F
            result.append(0xF0 + int(digit))
    
    return bytes(result)


def generate_packed_decimal(value, length):
    """
    Generate packed decimal representation.
    In packed decimal, each byte holds two decimal digits (nibbles),
    except the last nibble which contains the sign.
    
    Format: Each byte = (digit1 << 4) | digit2
    Last byte = (last_digit << 4) | sign
    Sign: 0xC for positive, 0xD for negative, 0xF for unsigned
    
    Args:
        value: The numeric value to encode
        length: The number of bytes for the packed decimal field
    
    Returns:
        bytes: The packed decimal representation
    """
    # Format the number as a string with leading zeros
    # For packed decimal, we need (length * 2 - 1) digits
    num_digits = length * 2 - 1
    num_str = str(int(value)).zfill(num_digits)
    
    result = bytearray()
    
    # Process pairs of digits
    for i in range(0, len(num_str) - 1, 2):
        digit1 = int(num_str[i])
        digit2 = int(num_str[i + 1])
        result.append((digit1 << 4) | digit2)
    
    # Last byte: last digit + sign (0xC for positive)
    last_digit = int(num_str[-1])
    result.append((last_digit << 4) | 0x0C)
    
    return bytes(result)


def generate_random_date():
    """Generate a random date from 1970 onwards in YYYYMMDD format."""
    start_date = datetime(1970, 1, 1)
    end_date = datetime(2026, 12, 31)
    
    days_between = (end_date - start_date).days
    random_days = random.randint(0, days_between)
    random_date = start_date + timedelta(days=random_days)
    
    return random_date.strftime("%Y%m%d")


def generate_random_time():
    """Generate a random time in HHMM format."""
    hour = random.randint(0, 23)
    minute = random.randint(0, 59)
    return f"{hour:02d}{minute:02d}"


def ascii_to_ebcdic(text):
    """
    Convert ASCII text to EBCDIC encoding.
    Uses Python's built-in cp037 codec (EBCDIC US).
    """
    return text.encode('cp037')


def generate_record():
    """Generate a single 80-byte EBCDIC record."""
    record = bytearray(80)
    
    # Columns 1-8: Zoned numerical data (8 digits)
    zoned_num = random.randint(0, 99999999)
    zoned_bytes = generate_zoned_decimal(zoned_num, 8)
    record[0:8] = zoned_bytes
    
    # Columns 9-43: Last name padded with spaces (35 characters)
    last_name = random.choice(LAST_NAMES)
    last_name_padded = last_name.ljust(35)
    last_name_ebcdic = ascii_to_ebcdic(last_name_padded)
    record[8:43] = last_name_ebcdic
    
    # Columns 44-57: Random binary data (14 bytes)
    random_binary_1 = os.urandom(14)
    record[43:57] = random_binary_1
    
    # Columns 58-65: Date in YYYYMMDD format (8 characters)
    date_str = generate_random_date()
    date_ebcdic = ascii_to_ebcdic(date_str)
    record[57:65] = date_ebcdic
    
    # Columns 66-69: Time in HHMM format (4 characters)
    time_str = generate_random_time()
    time_ebcdic = ascii_to_ebcdic(time_str)
    record[65:69] = time_ebcdic
    
    # Columns 70-74: Packed decimal number (5000 to 9999999.99)
    # Represented as 5 bytes packed decimal (9 digits with 2 decimal places)
    # Range: 500000 to 999999999 (representing 5000.00 to 9999999.99)
    amount_cents = random.randint(500000, 999999999)  # 5000.00 to 9999999.99 in cents
    amount_bytes = generate_packed_decimal(amount_cents, 5)
    record[69:74] = amount_bytes
    
    # Columns 75-80: Random binary data (6 bytes)
    random_binary_2 = os.urandom(6)
    record[74:80] = random_binary_2
    
    return bytes(record)


def generate_test_file(filename, num_records=100):
    """
    Generate a test file with the specified number of records.
    
    Args:
        filename: Output filename
        num_records: Number of records to generate (default: 100)
    """
    print(f"Generating {num_records} records...")
    
    with open(filename, 'wb') as f:
        for i in range(num_records):
            record = generate_record()
            f.write(record)
            
            if (i + 1) % 10 == 0:
                print(f"  Generated {i + 1} records...")
    
    file_size = os.path.getsize(filename)
    print(f"\nFile '{filename}' created successfully!")
    print(f"  Records: {num_records}")
    print(f"  File size: {file_size} bytes ({file_size / 1024:.2f} KB)")
    print(f"  Record length: 80 bytes")


def display_sample_record(filename):
    """Display a sample record in hex format for verification."""
    print("\n" + "="*80)
    print("SAMPLE RECORD (First record in hex):")
    print("="*80)
    
    with open(filename, 'rb') as f:
        record = f.read(80)
    
    # Display in hex format with column markers
    print("\nColumns 1-8 (Zoned Decimal):")
    print("  Hex:", record[0:8].hex(' '))
    
    print("\nColumns 9-43 (Last Name):")
    print("  Hex:", record[8:43].hex(' '))
    print("  ASCII:", record[8:43].decode('cp037').rstrip())
    
    print("\nColumns 44-57 (Random Binary):")
    print("  Hex:", record[43:57].hex(' '))
    
    print("\nColumns 58-65 (Date YYYYMMDD):")
    print("  Hex:", record[57:65].hex(' '))
    print("  ASCII:", record[57:65].decode('cp037'))
    
    print("\nColumns 66-69 (Time HHMM):")
    print("  Hex:", record[65:69].hex(' '))
    print("  ASCII:", record[65:69].decode('cp037'))
    
    print("\nColumns 70-74 (Packed Decimal Amount):")
    print("  Hex:", record[69:74].hex(' '))
    # Decode packed decimal for display
    packed_hex = record[69:74].hex()
    digits = []
    for i in range(0, len(packed_hex) - 1, 2):
        byte_val = packed_hex[i:i+2]
        digit1 = int(byte_val[0], 16)
        digit2 = int(byte_val[1], 16)
        if i == len(packed_hex) - 2:  # Last byte
            digits.append(str(digit1))
            sign = 'C' if digit2 == 12 else ('D' if digit2 == 13 else 'F')
            print(f"  Decoded: {''.join(digits)} (sign: {sign}, value: {int(''.join(digits))/100:.2f})")
        else:
            digits.append(str(digit1))
            digits.append(str(digit2))
    
    print("\nColumns 75-80 (Random Binary):")
    print("  Hex:", record[74:80].hex(' '))
    
    print("\n" + "="*80)


if __name__ == "__main__":
    import sys
    
    # Default values
    output_file = "testdata.ebcdic"
    num_records = 100
    
    # Parse command line arguments
    if len(sys.argv) > 1:
        output_file = sys.argv[1]
    if len(sys.argv) > 2:
        try:
            num_records = int(sys.argv[2])
        except ValueError:
            print(f"Error: Invalid number of records '{sys.argv[2]}'")
            sys.exit(1)
    
    print("EBCDIC Test Data Generator")
    print("="*80)
    print(f"Output file: {output_file}")
    print(f"Number of records: {num_records}")
    print(f"Record length: 80 bytes (fixed)")
    print("="*80 + "\n")
    
    # Generate the test file
    generate_test_file(output_file, num_records)
    
    # Display a sample record
    display_sample_record(output_file)
    
    print("\nUsage: python generate_ebcdic_testdata.py [output_file] [num_records]")
    print("  Default: python generate_ebcdic_testdata.py testdata.ebcdic 100")

# Made with Bob
