package com.ibm.db2.json;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.Reader;
import java.io.Writer;
import java.sql.Clob;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

import org.json.JSONObject;
import org.json.XML;

public class Json {
    public static String toXML(String json) {
        return XML.toString(new JSONObject(json));
    }

    public static Clob toXML(Clob json) throws SQLException, IOException {
        Clob result = getConnection().createClob();
        copy(json.getCharacterStream(), result.setCharacterStream(1));
        return result;
    }

    private static void copy(Reader rd, Writer wr) throws IOException {
        int ch;
        BufferedReader br = new BufferedReader(rd);
        
        while ((ch = br.read()) >= 0) wr.write(ch);
    }

    private static Connection getConnection() throws SQLException {
        return DriverManager.getConnection("jdbc:default:connection");
    }

}
