package com.ibm.db2.csv;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

import org.junit.jupiter.api.Test;
import org.junit.platform.commons.annotation.Testable;

@Testable
public class UnloadTest {

    @Test
    void testUnloadCSV() throws Exception {
        String format = """
                delimiter=\t;
                quoteMode=MINIMAL;
                commentMarker=\u0023;
                headerComments=This is a test for the UNLOADCSV stored procedure,Should appear as comment;
                trim=true
                """;
        try (Connection conn = openConnection()) {
            Unload.unload(conn, "select * from dsn81310.emp", "unload.csv", format, 923, 'Y');
        }
    }

    private Connection openConnection() throws SQLException {
        return DriverManager.getConnection("jdbc:db2://newg:5045/DALLASD:user=adcdmst;password=he1del;");
    }

}
