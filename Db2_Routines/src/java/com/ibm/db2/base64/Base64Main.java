package com.ibm.db2.base64;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Base64.Encoder;

public class Base64Main {

    public static void main(String[] args) throws FileNotFoundException, IOException {
        Encoder encoder = java.util.Base64.getEncoder();
        try (InputStream is = new BufferedInputStream(new FileInputStream(args[0]))) {
                copy(is, encoder.wrap(new BufferedOutputStream(new FileOutputStream(args[0] + ".b64"))));
        }
    // TODO Auto-generated method stub

    }

    private static void copy(InputStream source, OutputStream target) throws IOException {
        byte[] buf = new byte[8192];
        int length;
        while ((length = source.read(buf)) > 0) {
            target.write(buf, 0, length);
        }
    }

}
