package com.ibm.db2.json;

import java.io.IOException;
import java.io.StringWriter;
import java.io.Writer;
import java.sql.Clob;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

import javax.xml.stream.XMLStreamException;

import org.json.JSONException;
import org.json.JSONObject;
import org.json.XML;

/**
 * Implements Db2 stored procedures for JSON data manipulation and conversion.
 * <p>
 * This class provides utility methods to transform JSON strings and CLOB objects
 * into XML format, as well as pretty-print JSON for better readability.
 * Suitable for use as Db2 for z/OS external stored procedures.
 * </p>
 * 
 * <h3>Usage Examples:</h3>
 * <pre>
 * -- Convert JSON string to XML
 * select json2xml('{"name":"John","age":30}')
 *   from sysibm.sysdummyu;
 *
 * -- Convert JSON CLOB to XML CLOB
 * select json2xml(cast('{"data":"value"}' as clob))
 *   from sysibm.sysdummyu;
 *
 * -- Pretty-print JSON string
 * select jsonpretty('{"name":"John","age":30}')
 *   from sysibm.sysdummyu;
 * </pre>
 *
 * @author Uli Seelbach, IBM Expert Labs
 * @version 1.3
 */
public class Json {
    
    /**
     * Maximum CLOB size to process (10MB).
     * Prevents memory exhaustion from extremely large documents.
     */
    private static final long MAX_CLOB_SIZE = 10485760L;
    
    /**
     * Default indentation factor for pretty-printing JSON.
     * Each level of nesting will be indented by this many spaces.
     */
    private static final int DEFAULT_INDENT_FACTOR = 2;
    
    /**
     * Converts a JSON string to XML format.
     * <p>
     * This method parses the input JSON string and converts it to an XML representation
     * using the org.json library's XML conversion utilities.
     * </p>
     *
     * @param json the JSON string to convert; must not be null or empty
     * @return the XML representation of the JSON data
     * @throws IllegalArgumentException if json is null or empty
     * @throws XMLStreamException if the input is not valid JSON or XML generation fails
     */
    public static String jsonStringToXML(String json) throws XMLStreamException {
        // Input validation
        if (json == null || json.trim().isEmpty()) {
            throw new IllegalArgumentException("JSON input must not be null or empty");
        }
        
        try {
            // Parse JSON and convert to XML
            JSONObject jsonObject = new JSONObject(json);
            return XML.toString(jsonObject);
        } catch (JSONException e) {
            throw new XMLStreamException("Invalid JSON format: " + e.getMessage(), e);
        }
    }
    
    /**
     * Converts a JSON CLOB to an XML CLOB.
     * <p>
     * This method is designed for use as a Db2 stored procedure that processes
     * large JSON documents stored as CLOBs. It validates the input size,
     * reads the JSON content, converts it to XML, and returns
     * the result as a new CLOB.
     *
     * @param jsonClob the input JSON CLOB; must not be null
     * @return a new CLOB containing the XML representation
     * @throws IllegalArgumentException if jsonClob is null or exceeds size limit
     * @throws SQLException if database operations fail
     * @throws IOException if CLOB reading fails
     * @throws XMLStreamException if XML generation fails
     */
    public static Clob jsonClobToXML(Clob jsonClob)
            throws SQLException, IOException, XMLStreamException {
        
        // Input validation
        if (jsonClob == null) {
            throw new IllegalArgumentException("Input CLOB must not be null");
        }
        
        long clobLength = jsonClob.length();
        if (clobLength == 0) {
            throw new IllegalArgumentException("Input CLOB must not be empty");
        }
        
        if (clobLength > MAX_CLOB_SIZE) {
            throw new IllegalArgumentException(
                String.format("CLOB size (%d bytes) exceeds maximum allowed size (%d bytes)",
                    clobLength, MAX_CLOB_SIZE));
        }
        
        // Get connection from Db2 stored procedure context
        // Note: Connection is managed by Db2, should not be closed
        Connection conn = DriverManager.getConnection("jdbc:default:connection");
        
        // Read JSON content from input CLOB
        String jsonContent = readContents(jsonClob);
        
        // Convert JSON to XML
        String xmlContent = jsonStringToXML(jsonContent);
        
        // Create result CLOB and write XML content using try-with-resources
        Clob resultClob = conn.createClob();
        try (Writer writer = resultClob.setCharacterStream(1)) {
            writer.write(xmlContent);
            writer.flush();
            return resultClob;
        } catch (SQLException | IOException e) {
            // Clean up result CLOB on error
            try {
                resultClob.free();
            } catch (SQLException cleanupEx) {
                e.addSuppressed(cleanupEx);
            }
            throw e;
        }
    }
    
    /**
     * Pretty-prints a JSON string with proper indentation.
     * <p>
     * This method parses the input JSON string and reformats it with
     * indentation for improved readability. Uses a default indentation
     * of 2 spaces per nesting level.
     * </p>
     *
     * @param json the JSON string to format; must not be null or empty
     * @return the formatted JSON string with indentation
     * @throws IllegalArgumentException if json is null or empty
     * @throws JSONException if the input is not valid JSON
     */
    public static String prettyPrintJson(String json) {
        return prettyPrintJson(json, DEFAULT_INDENT_FACTOR);
    }
    
    /**
     * Pretty-prints a JSON string with specified indentation.
     * <p>
     * This method parses the input JSON string and reformats it with
     * the specified indentation for improved readability.
     * </p>
     *
     * @param json the JSON string to format; must not be null or empty
     * @param indentFactor the number of spaces to indent each nesting level
     * @return the formatted JSON string with indentation
     * @throws IllegalArgumentException if json is null or empty, or if indentFactor is negative
     * @throws JSONException if the input is not valid JSON
     */
    public static String prettyPrintJson(String json, int indentFactor) {
        // Input validation
        if (json == null || json.trim().isEmpty()) {
            throw new IllegalArgumentException("JSON input must not be null or empty");
        }
        
        if (indentFactor < 0) {
            throw new IllegalArgumentException("Indent factor must be non-negative");
        }
        
        try {
            // Parse JSON and format with indentation
            JSONObject jsonObject = new JSONObject(json);
            return jsonObject.toString(indentFactor);
        } catch (JSONException e) {
            // If it's not an object, try parsing as an array
            try {
                org.json.JSONArray jsonArray = new org.json.JSONArray(json);
                return jsonArray.toString(indentFactor);
            } catch (JSONException e2) {
                throw new JSONException("Invalid JSON format: " + e.getMessage(), e);
            }
        }
    }
    
    /**
     * Pretty-prints a JSON CLOB with proper indentation.
     * <p>
     * This method is designed for use as a Db2 stored procedure that processes
     * large JSON documents stored as CLOBs. It validates the input size,
     * reads the JSON content, formats it with indentation, and returns
     * the result as a new CLOB.
     * </p>
     *
     * @param jsonClob the input JSON CLOB; must not be null
     * @return a new CLOB containing the formatted JSON
     * @throws IllegalArgumentException if jsonClob is null or exceeds size limit
     * @throws SQLException if database operations fail
     * @throws IOException if CLOB reading fails
     * @throws JSONException if the input is not valid JSON
     */
    public static Clob prettyPrintJsonClob(Clob jsonClob)
            throws SQLException, IOException {
        
        // Input validation
        if (jsonClob == null) {
            throw new IllegalArgumentException("Input CLOB must not be null");
        }
        
        long clobLength = jsonClob.length();
        if (clobLength == 0) {
            throw new IllegalArgumentException("Input CLOB must not be empty");
        }
        
        if (clobLength > MAX_CLOB_SIZE) {
            throw new IllegalArgumentException(
                String.format("CLOB size (%d bytes) exceeds maximum allowed size (%d bytes)",
                    clobLength, MAX_CLOB_SIZE));
        }
        
        // Get connection from Db2 stored procedure context
        // Note: Connection is managed by Db2, should not be closed
        Connection conn = DriverManager.getConnection("jdbc:default:connection");
        
        // Read JSON content from input CLOB
        String jsonContent = readContents(jsonClob);
        
        // Pretty-print JSON
        String formattedJson = prettyPrintJson(jsonContent);
        
        // Create result CLOB and write formatted content using try-with-resources
        Clob resultClob = conn.createClob();
        try (Writer writer = resultClob.setCharacterStream(1)) {
            writer.write(formattedJson);
            writer.flush();
            return resultClob;
        } catch (SQLException | IOException e) {
            // Clean up result CLOB on error
            try {
                resultClob.free();
            } catch (SQLException cleanupEx) {
                e.addSuppressed(cleanupEx);
            }
            throw e;
        }
    }
    
    /**
     * Reads CLOB content.
     * 
     * @param clob the CLOB to read
     * @return the CLOB content as a String
     * @throws IOException if reading fails
     * @throws SQLException if CLOB access fails
     */
    @Deprecated
    private static String readContents(Clob clob) throws IOException, SQLException {
        StringWriter s = new StringWriter((int) clob.length());
        clob.getCharacterStream().transferTo(s);
        return s.toString();
    }
}
