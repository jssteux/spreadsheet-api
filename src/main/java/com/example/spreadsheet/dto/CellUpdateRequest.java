package com.example.spreadsheet.dto;

import javax.validation.constraints.NotNull;
import java.util.List;

public class CellUpdateRequest {
    @NotNull(message = "Cells list cannot be null")
    private List<CellDTO> cells;
    
    public List<CellDTO> getCells() { return cells; }
    public void setCells(List<CellDTO> cells) { this.cells = cells; }
}