package com.ibm.db2.json;

import org.json.JSONObject;
import org.json.XML;

public class JsonTest {

    public static void main(String[] args) {
        String jsonString = "{\"name\":\"John\", \"age\":[20, 42, 4711], \"address\":{\"street\":\"Wall Street\", \"city\":\"New York\"}}";
        JSONObject jsonObject = new JSONObject(jsonString);
        String xmlString = XML.toString(jsonObject);
        System.out.println(xmlString);
    }
}
