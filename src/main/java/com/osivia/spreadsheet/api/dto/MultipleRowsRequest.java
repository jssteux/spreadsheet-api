package com.osivia.spreadsheet.api.dto;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;
import java.util.List;

public class MultipleRowsRequest {

    @NotNull(message = "Rows cannot be null")
    @Size(min = 1, message = "At least one row must be provided")
    private List<List<String>> rows;

    public MultipleRowsRequest() {}

    public MultipleRowsRequest(List<List<String>> rows) {
        this.rows = rows;
    }

    public List<List<String>> getRows() {
        return rows;
    }

    public void setRows(List<List<String>> rows) {
        this.rows = rows;
    }
}
