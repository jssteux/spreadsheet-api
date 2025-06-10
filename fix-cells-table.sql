-- Fix cells table to use TEXT instead of CLOB
DROP TABLE IF EXISTS cells CASCADE;

CREATE TABLE cells (
    id BIGSERIAL PRIMARY KEY,
    sheet_id BIGINT NOT NULL,
    row_index INTEGER NOT NULL,
    column_index INTEGER NOT NULL,
    cell_value TEXT,
    FOREIGN KEY (sheet_id) REFERENCES sheets(id) ON DELETE CASCADE,
    UNIQUE(sheet_id, row_index, column_index)
);

CREATE INDEX idx_sheet_row_col ON cells(sheet_id, row_index, column_index);
