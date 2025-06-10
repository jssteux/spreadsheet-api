package com.osivia.spreadsheet.api.dto;

import javax.validation.constraints.NotBlank;

public class CreateSpreadsheetRequest {
    @NotBlank(message = "Name is required")
    private String name;
    
    private String description;
    
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
}