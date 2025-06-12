package com.osivia.spreadsheet.api.dto;

import javax.validation.constraints.NotNull;
import java.util.List;

public class ColumnInsertRequest {

    @NotNull(message = "Values cannot be null")
    private List<String> values;

    private String columnName;

    public ColumnInsertRequest() {}

    public ColumnInsertRequest(List<String> values) {
        this.values = values;
    }

    public ColumnInsertRequest(List<String> values, String columnName) {
        this.values = values;
        this.columnName = columnName;
    }

    public List<String> getValues() {
        return values;
    }

    public void setValues(List<String> values) {
        this.values = values;
    }

    public String getColumnName() {
        return columnName;
    }

    public void setColumnName(String columnName) {
        this.columnName = columnName;
    }
}