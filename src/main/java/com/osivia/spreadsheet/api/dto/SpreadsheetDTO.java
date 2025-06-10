package com.osivia.spreadsheet.api.dto;

import java.time.LocalDateTime;
import java.util.List;

public class SpreadsheetDTO {
    private Long id;
    private String name;
    private String description;
    private String ownerUsername;
    private List<SheetSummaryDTO> sheets;
    private Integer mediaCount;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private String userPermission;
    
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    
    public String getOwnerUsername() { return ownerUsername; }
    public void setOwnerUsername(String ownerUsername) { this.ownerUsername = ownerUsername; }
    
    public List<SheetSummaryDTO> getSheets() { return sheets; }
    public void setSheets(List<SheetSummaryDTO> sheets) { this.sheets = sheets; }
    
    public Integer getMediaCount() { return mediaCount; }
    public void setMediaCount(Integer mediaCount) { this.mediaCount = mediaCount; }
    
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
    
    public String getUserPermission() { return userPermission; }
    public void setUserPermission(String userPermission) { this.userPermission = userPermission; }
}