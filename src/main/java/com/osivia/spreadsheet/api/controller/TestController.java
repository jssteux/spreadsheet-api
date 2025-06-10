package com.osivia.spreadsheet.api.controller;

import org.springframework.web.bind.annotation.*;
import java.util.HashMap;
import java.util.Map;

@RestController
@CrossOrigin(origins = "*", maxAge = 3600)
public class TestController {
    
    @GetMapping("/")
    public Map<String, String> home() {
        Map<String, String> response = new HashMap<>();
        response.put("message", "Spreadsheet API is running");
        response.put("status", "OK");
        response.put("endpoints", "/auth/login, /auth/register, /spreadsheets, /sheets");
        return response;
    }
    
    @GetMapping("/test")
    public Map<String, String> test() {
        Map<String, String> response = new HashMap<>();
        response.put("message", "Test endpoint - no auth required");
        response.put("timestamp", new java.util.Date().toString());
        return response;
    }
}