package com.osivia.spreadsheet.api.dto;

public class CellDTO {
    private Integer row;
    private Integer col;
    private String value;
    
    public CellDTO() {}
    
    public CellDTO(Integer row, Integer col, String value) {
        this.row = row;
        this.col = col;
        this.value = value;
    }
    
    public Integer getRow() { return row; }
    public void setRow(Integer row) { this.row = row; }
    
    public Integer getCol() { return col; }
    public void setCol(Integer col) { this.col = col; }
    
    public String getValue() { return value; }
    public void setValue(String value) { this.value = value; }
}