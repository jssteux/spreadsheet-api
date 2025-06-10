package com.example.spreadsheet.entity;

import javax.persistence.*;

@Entity
@Table(name = "cells", indexes = {
    @Index(name = "idx_sheet_row_col", columnList = "sheet_id, row_index, column_index")
})
public class Cell {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sheet_id", nullable = false)
    private Sheet sheet;
    
    @Column(name = "row_index", nullable = false)
    private Integer rowIndex;
    
    @Column(name = "column_index", nullable = false)
    private Integer columnIndex;
    
    @Column(name = "cell_value", columnDefinition = "TEXT")
    private String value;
    
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public Sheet getSheet() { return sheet; }
    public void setSheet(Sheet sheet) { this.sheet = sheet; }
    
    public Integer getRowIndex() { return rowIndex; }
    public void setRowIndex(Integer rowIndex) { this.rowIndex = rowIndex; }
    
    public Integer getColumnIndex() { return columnIndex; }
    public void setColumnIndex(Integer columnIndex) { this.columnIndex = columnIndex; }
    
    public String getValue() { return value; }
    public void setValue(String value) { this.value = value; }
}