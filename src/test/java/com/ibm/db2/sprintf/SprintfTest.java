package com.ibm.db2.sprintf;

import java.sql.SQLException;

import org.junit.jupiter.api.Test;
import org.junit.platform.commons.annotation.Testable;
import static com.ibm.db2.sprintf.Sprintf.*;

@Testable
public class SprintfTest {

	//@Test
	void testFoo() {
		try {
			Object[] u;
			u = unpack(decodeHexString("00000101e4050200899c"));
			System.out.println(sprintf("%tm%n",
					decodeHexString("00000401c0018001e001e404b80005416c696e61197708013fe00000000000000802000004711c")));
			u = unpack(
					decodeHexString("00000401c0018001e001e404b80005416c696e61197708013fe00000000000000802000004711c"));
			u = unpack(decodeHexString(
					"00000401c00180018801e404b80005416c696e61197708010006202401041452535813980802000004711c"));
			u = unpack(decodeHexString("00000201c0099004b80005416c696e610006202401041437497936240100"));
			System.out.println(u);

		} catch (SQLException e) {
			e.printStackTrace();
		}
	}

	@Test
	void testUnpack() {
		
	}
}
