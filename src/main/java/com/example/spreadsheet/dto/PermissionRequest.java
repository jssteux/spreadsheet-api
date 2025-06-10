package com.example.spreadsheet.dto;

import com.example.spreadsheet.entity.PermissionType;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;

public class PermissionRequest {
    @NotBlank(message = "Username is required")
    private String username;
    
    @NotNull(message = "Permission type is required")
    private PermissionType permissionType;
    
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    
    public PermissionType getPermissionType() { return permissionType; }
    public void setPermissionType(PermissionType permissionType) { this.permissionType = permissionType; }
}