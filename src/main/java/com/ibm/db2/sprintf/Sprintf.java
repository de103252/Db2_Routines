package com.ibm.db2.sprintf;

import java.io.ByteArrayInputStream;
import java.io.DataInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.GregorianCalendar;
import java.util.Locale;

public class Sprintf {

	/*
	 * Db2 internal type codes for PACK function.
	 * These values are defined by Db2 for z/OS and must not be changed.
	 * 
	 * @see <a href="https://www.ibm.com/docs/en/db2-for-zos/13">Db2 for z/OS
	 *      Documentation</a>
	 */
	private static final int TYPE_DATE = 384;
	private static final int TYPE_TIME = 388;
	private static final int TYPE_TIMESTAMP = 392;
	private static final int TYPE_VARCHAR = 448;
	private static final int TYPE_CHAR = 452;
	private static final int TYPE_REAL = 480;
	private static final int TYPE_DECIMAL = 484;
	private static final int TYPE_SMALLINT = 500;
	private static final int TYPE_INTEGER = 496;
	private static final int TYPE_BIGINT = 492;
	private static final int TYPE_TIMESTAMP_TZ = 2448;

	private static class PackInputStream extends DataInputStream {

		public PackInputStream(InputStream in) {
			super(in);
		}

		public Object readTimestamp(boolean withTimezone) throws IOException {
			int p = readUnsignedShort();
			GregorianCalendar c = new GregorianCalendar(readPackedInt(2), readPackedInt(1) - 1, readPackedInt(1),
					readPackedInt(1), readPackedInt(1), readPackedInt(1));
			long fraction = readPackedLong((p + 1) / 2);
			while (p++ < 12)
				fraction *= 10;
			Timestamp dbTimestamp = new Timestamp(c.getTimeInMillis()); // instant.plusNanos(fraction).;
			// dbTimestamp.setPicos(fraction);
			if (withTimezone) {
				int offset = readShort();
				// dbTimestamp.setTimeZone(new SimpleTimeZone(offset, "dummy"));
			}
			return dbTimestamp;
		}

		public BigDecimal readDecimal() throws IOException {
			int p = readUnsignedByte() / 2;
			int s = readUnsignedByte();
			BigInteger result = BigInteger.valueOf(0);
			while (p-- > 0) {
				int by = readUnsignedByte();
				result = result.multiply(BigInteger.valueOf(10));
				result = result.add(BigInteger.valueOf(by >>> 4));
				result = result.multiply(BigInteger.valueOf(10));
				result = result.add(BigInteger.valueOf(by & 0x0f));
			}
			int by = readUnsignedByte();
			result = result.multiply(BigInteger.valueOf(10));
			result = result.add(BigInteger.valueOf(by >>> 4));
			if ((by & 0x0f) == 0x0d) {
				result = result.negate();
			}
			return new BigDecimal(result, s);
		}

		public int readPackedInt(int count) throws IOException {
			int result = 0;
			while (count-- > 0) {
				result *= 100;
				int by = readUnsignedByte();
				result += ((by & 0xf0) >>> 4) * 10;
				result += (by & 0x0f);
			}
			return result;
		}

		public long readPackedLong(int count) throws IOException {
			long result = 0;
			while (count-- > 0) {
				result *= 100;
				int by = readUnsignedByte();
				result += ((by & 0xf0) >>> 4) * 10;
				result += (by & 0x0f);
			}
			return result;
		}

	}

	/**
	 * Unpacks a {@code byte[]} returned by the Db2 {@code PACK} function.
	 * Character data must have been packed using UTF-8 encoding, that is,
	 * with the CCSID1208 clause:
	 * 
	 * <PRE>
	 * PACK(CCSID 1208, 'This is VARCHAR data')
	 * </PRE>
	 *
	 * @param by the {@code byte[]} returned by the Db2 {@code PACK} function
	 * @return the unpacked {@code Object[]}
	 * @throws SQLException if the data was not packed using the PACK function,
	 *                      or if character data was not packed using UTF-8
	 *                      encoding.
	 * @see https://www.ibm.com/docs/en/db2-for-zos/13.0.0?topic=functions-pack-scalar-function
	 */
	static Object[] unpack(byte[] by) throws SQLException {
		if (by == null)
			return null;
		PackInputStream dis = new PackInputStream(new ByteArrayInputStream(by));
		int[] types;
		Object[] result;
		try {
			byte flag = dis.readByte();
			int count = dis.readUnsignedShort();
			types = new int[count];
			result = new Object[count];
			for (int i = 0; i < count; i++) {
				types[i] = dis.readUnsignedShort();
			}
			for (int i = 0; i < count; i++) {
				Object o = null;
				if ((types[i] & 1) == 0) {
					switch (types[i] & ~1) {
						case TYPE_SMALLINT:
							o = dis.readShort();
							break;
						case TYPE_INTEGER:
							o = dis.readInt();
							break;
						case TYPE_BIGINT:
							o = dis.readLong();
							break;
						case TYPE_CHAR:
						case TYPE_VARCHAR:
							if (dis.readUnsignedShort() != 1208) {
								throw new SQLException(
										"Character data must be UTF-8 encoded. Use PACK(CCSID1208, ...).");
							}
							o = dis.readUTF();
							break;
						case TYPE_DATE:
							o = new java.sql.Date(new GregorianCalendar(dis.readPackedInt(2), dis.readPackedInt(1) - 1,
									dis.readPackedInt(1)).getTimeInMillis());
							break;
						case TYPE_TIME:
							o = new java.sql.Time(dis.readPackedInt(1), dis.readPackedInt(1), dis.readPackedInt(1));
							break;
						case TYPE_TIMESTAMP:
							o = dis.readTimestamp(false);
							break;
						case TYPE_TIMESTAMP_TZ:
							o = dis.readTimestamp(true);
							break;
						case TYPE_REAL:
							o = Double.longBitsToDouble(dis.readLong());
							break;
						case TYPE_DECIMAL:
							o = dis.readDecimal();
							break;
					}
					result[i] = o;
				}
			}
			return result;
		} catch (IOException e) {
			throw new SQLException("Data appears not to be encoded with PACK");
		}
	}

	public static byte hexToByte(String hexString) {
		int firstDigit = toDigit(hexString.charAt(0));
		int secondDigit = toDigit(hexString.charAt(1));
		return (byte) ((firstDigit << 4) + secondDigit);
	}

	private static int toDigit(char hexChar) {
		int digit = Character.digit(hexChar, 16);
		if (digit == -1) {
			throw new IllegalArgumentException("Invalid Hexadecimal Character: " + hexChar);
		}
		return digit;
	}

	public static byte[] decodeHexString(String hexString) {
		if (hexString.length() % 2 == 1) {
			throw new IllegalArgumentException("Invalid hexadecimal String supplied.");
		}

		byte[] bytes = new byte[hexString.length() / 2];
		for (int i = 0; i < hexString.length(); i += 2) {
			bytes[i / 2] = hexToByte(hexString.substring(i, i + 2));
		}
		return bytes;
	}

	public static String sprintf(String format, byte[] packedData) throws SQLException {
		return String.format(format, unpack(packedData));
	}

	public static String sprintf(String locale, String format, byte[] packedData) throws SQLException {
		return String.format(Locale.forLanguageTag(locale), format, unpack(packedData));
	}
}
