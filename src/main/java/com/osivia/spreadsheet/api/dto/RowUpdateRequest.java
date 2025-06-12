package com.osivia.spreadsheet.api.dto;

import javax.validation.constraints.NotNull;
import java.util.List;

public class RowUpdateRequest {

    @NotNull(message = "Values cannot be null")
    private List<String> values;

    public RowUpdateRequest() {}

    public RowUpdateRequest(List<String> values) {
        this.values = values;
    }

    public List<String> getValues() {
        return values;
    }

    public void setValues(List<String> values) {
        this.values = values;
    }
}