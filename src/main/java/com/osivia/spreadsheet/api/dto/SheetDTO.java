package com.osivia.spreadsheet.api.dto;

import java.time.LocalDateTime;
import java.util.List;

public class SheetDTO {
    private Long id;
    private String name;
    private Long spreadsheetId;
    private Integer orderIndex;
    private Integer rowCount;
    private Integer columnCount;
    private List<CellDTO> cells;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    
    public Long getSpreadsheetId() { return spreadsheetId; }
    public void setSpreadsheetId(Long spreadsheetId) { this.spreadsheetId = spreadsheetId; }
    
    public Integer getOrderIndex() { return orderIndex; }
    public void setOrderIndex(Integer orderIndex) { this.orderIndex = orderIndex; }
    
    public Integer getRowCount() { return rowCount; }
    public void setRowCount(Integer rowCount) { this.rowCount = rowCount; }
    
    public Integer getColumnCount() { return columnCount; }
    public void setColumnCount(Integer columnCount) { this.columnCount = columnCount; }
    
    public List<CellDTO> getCells() { return cells; }
    public void setCells(List<CellDTO> cells) { this.cells = cells; }
    
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}