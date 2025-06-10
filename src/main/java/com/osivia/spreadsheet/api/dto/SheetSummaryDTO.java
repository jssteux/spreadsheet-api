package com.osivia.spreadsheet.api.dto;

public class SheetSummaryDTO {
    private Long id;
    private String name;
    private Integer orderIndex;
    
    public SheetSummaryDTO() {}
    
    public SheetSummaryDTO(Long id, String name, Integer orderIndex) {
        this.id = id;
        this.name = name;
        this.orderIndex = orderIndex;
    }
    
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    
    public Integer getOrderIndex() { return orderIndex; }
    public void setOrderIndex(Integer orderIndex) { this.orderIndex = orderIndex; }
}