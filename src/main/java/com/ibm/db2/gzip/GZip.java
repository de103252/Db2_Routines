package com.ibm.db2.gzip;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.sql.Blob;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.zip.GZIPInputStream;
import java.util.zip.GZIPOutputStream;
import java.util.zip.ZipException;

/**
 * Implements Db2 stored procedures for GZIP compression and decompression of BLOB data.
 * <p>
 * This class provides two main methods:
 * <ul>
 *   <li>{@link #gzip(Blob)} - Compresses BLOB data using GZIP compression</li>
 *   <li>{@link #gunzip(Blob)} - Decompresses GZIP-compressed BLOB data</li>
 * </ul>
 * <p>
 * Both methods are designed to be called as Db2 for z/OS stored procedures
 * using the JDBC default connection context.
 * <p>
 * <b>Installation DDL:</b>
 * <pre>
 * create procedure gzip(in input blob(10m), out result blob(10m))
 *   language java
 *   parameter style java
 *   external name 'com.ibm.db2.gzip.GZip.gzip'
 *   fenced
 *   no sql;
 * </pre>
 *
 * @author Uli Seelbach, IBM Expert Labs
 * @version 1.1
 */
public class GZip {
    
    /**
     * Default buffer size for stream operations (64KB).
     * Optimized for typical BLOB sizes in Db2 for z/OS.
     */
    private static final int BUFFER_SIZE = 64 * 1024;
    
    /**
     * Maximum allowed input size (100MB) to prevent memory exhaustion.
     */
    private static final long MAX_INPUT_SIZE = 100L * 1024 * 1024;
    
    /**
     * JDBC connection URL for Db2 stored procedure context.
     */
    private static final String JDBC_DEFAULT_CONNECTION = "jdbc:default:connection";
    
    /**
     * Compresses BLOB data using GZIP compression.
     * <p>
     * This method reads the input BLOB, compresses it using GZIP algorithm,
     * and returns a new BLOB containing the compressed data. The compression
     * level is set to default (6) which provides a good balance between
     * compression ratio and speed.
     * <p>
     * <b>Performance Considerations:</b>
     * <ul>
     *   <li>Uses buffered I/O for optimal performance</li>
     *   <li>Validates input size to prevent memory issues</li>
     *   <li>Properly closes all resources via try-with-resources</li>
     * </ul>
     *
     * @param input the BLOB to compress; must not be null
     * @return a new BLOB containing the GZIP-compressed data
     * @throws SQLException if a database access error occurs or input is null
     * @throws IOException if an I/O error occurs during compression
     * @throws IllegalArgumentException if input BLOB exceeds maximum size
     */
    public static Blob gzip(Blob input) throws IOException, SQLException {
        // Validate input
        if (input == null) {
            throw new SQLException("Input BLOB cannot be null");
        }
        
        // Check input size to prevent memory exhaustion
        long inputLength = input.length();
        if (inputLength > MAX_INPUT_SIZE) {
            throw new IllegalArgumentException(
                String.format("Input BLOB size (%d bytes) exceeds maximum allowed size (%d bytes)",
                    inputLength, MAX_INPUT_SIZE));
        }
        
        // Handle empty BLOB
        if (inputLength == 0) {
            return createEmptyBlob();
        }
        
        try (Connection conn = DriverManager.getConnection(JDBC_DEFAULT_CONNECTION)) {
            Blob result = conn.createBlob();
            
            try (InputStream inputStream = input.getBinaryStream();
                 OutputStream outputStream = result.setBinaryStream(1);
                 GZIPOutputStream gzipOutputStream = new GZIPOutputStream(outputStream, BUFFER_SIZE)) {
                
                // Transfer data with explicit buffer for better control
                byte[] buffer = new byte[BUFFER_SIZE];
                int bytesRead;
                while ((bytesRead = inputStream.read(buffer)) != -1) {
                    gzipOutputStream.write(buffer, 0, bytesRead);
                }
                
                // Ensure all data is flushed and GZIP trailer is written
                gzipOutputStream.finish();
                gzipOutputStream.flush();
                
                return result;
                
            } catch (IOException | SQLException e) {
                // Clean up result BLOB on error
                freeBlob(result, e);
                throw e;
            }
        }
    }
    
    /**
     * Decompresses GZIP-compressed BLOB data.
     * <p>
     * This method reads a GZIP-compressed BLOB, decompresses it,
     * and returns a new BLOB containing the original uncompressed data.
     * <p>
     * <b>Performance Considerations:</b>
     * <ul>
     *   <li>Uses buffered I/O for optimal performance</li>
     *   <li>Validates GZIP format before processing</li>
     *   <li>Properly closes all resources via try-with-resources</li>
     * </ul>
     *
     * @param input the GZIP-compressed BLOB to decompress; must not be null
     * @return a new BLOB containing the decompressed data
     * @throws SQLException if a database access error occurs or input is null
     * @throws IOException if an I/O error occurs or input is not valid GZIP format
     * @throws IllegalArgumentException if input BLOB exceeds maximum size
     */
    public static Blob gunzip(Blob input) throws IOException, SQLException {
        // Validate input
        if (input == null) {
            throw new SQLException("Input BLOB cannot be null");
        }
        
        // Check input size to prevent memory exhaustion
        long inputLength = input.length();
        if (inputLength > MAX_INPUT_SIZE) {
            throw new IllegalArgumentException(
                String.format("Input BLOB size (%d bytes) exceeds maximum allowed size (%d bytes)",
                    inputLength, MAX_INPUT_SIZE));
        }
        
        // Handle empty BLOB
        if (inputLength == 0) {
            throw new IOException("Input BLOB is empty; cannot decompress");
        }
        
        try (Connection conn = DriverManager.getConnection(JDBC_DEFAULT_CONNECTION)) {
            Blob result = conn.createBlob();
            
            try (InputStream rawInputStream = input.getBinaryStream()) {
                
                // Validate GZIP magic number before creating GZIPInputStream
                if (!isValidGzipFormat(rawInputStream)) {
                    throw new IOException("Input BLOB is not in valid GZIP format");
                }
                
                try (GZIPInputStream gzipInputStream = new GZIPInputStream(rawInputStream, BUFFER_SIZE);
                     OutputStream outputStream = result.setBinaryStream(1)) {
                    
                    // Transfer data with explicit buffer for better control
                    byte[] buffer = new byte[BUFFER_SIZE];
                    int bytesRead;
                    while ((bytesRead = gzipInputStream.read(buffer)) != -1) {
                        outputStream.write(buffer, 0, bytesRead);
                    }
                    
                    outputStream.flush();
                    
                    return result;
                }
                
            } catch (ZipException e) {
                // Provide more specific error message for GZIP format errors
                freeBlob(result, e);
                throw new IOException("Invalid GZIP format or corrupted data: " + e.getMessage(), e);
                
            } catch (IOException | SQLException e) {
                // Clean up result BLOB on error
                freeBlob(result, e);
                throw e;
            }
        }
    }
    
    /**
     * Validates if the input stream starts with GZIP magic number (0x1f8b).
     * <p>
     * This method reads the first two bytes to check for GZIP format,
     * then resets the stream if it supports mark/reset. If not supported,
     * the caller must handle the consumed bytes.
     *
     * @param inputStream the input stream to validate
     * @return true if the stream starts with GZIP magic number
     * @throws IOException if an I/O error occurs
     */
    private static boolean isValidGzipFormat(InputStream inputStream) throws IOException {
        // GZIP magic number: 0x1f 0x8b
        if (!inputStream.markSupported()) {
            // If mark not supported, we'll let GZIPInputStream handle validation
            return true;
        }
        
        inputStream.mark(2);
        int byte1 = inputStream.read();
        int byte2 = inputStream.read();
        inputStream.reset();
        
        return (byte1 == 0x1f && byte2 == 0x8b);
    }
    
    /**
     * Creates an empty BLOB for edge case handling.
     *
     * @return an empty BLOB
     * @throws SQLException if a database access error occurs
     */
    private static Blob createEmptyBlob() throws SQLException {
        try (Connection conn = DriverManager.getConnection(JDBC_DEFAULT_CONNECTION)) {
            return conn.createBlob();
        }
    }
    
    /**
     * Safely frees a BLOB resource, adding any cleanup exception as suppressed.
     * <p>
     * This utility method ensures proper cleanup of BLOB resources while
     * preserving the original exception for proper error reporting.
     *
     * @param blob the BLOB to free; may be null
     * @param originalException the original exception to which cleanup exceptions are added
     */
    private static void freeBlob(Blob blob, Exception originalException) {
        if (blob != null) {
            try {
                blob.free();
            } catch (SQLException cleanupEx) {
                // Add cleanup failure as suppressed exception
                originalException.addSuppressed(cleanupEx);
            }
        }
    }
}
