package com.osivia.spreadsheet.api.repository;


import com.osivia.spreadsheet.api.entity.Cell;
import com.osivia.spreadsheet.api.entity.Sheet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.List;

@Repository
public interface CellRepository extends JpaRepository<Cell, Long> {

    // EXISTING METHODS - Keep these unchanged
    Optional<Cell> findBySheetAndRowIndexAndColumnIndex(Sheet sheet, Integer rowIndex, Integer columnIndex);


    @Query("SELECT c FROM Cell c WHERE c.sheet = :sheet ORDER BY c.rowIndex, c.columnIndex")
    List<Cell> findBySheetOrdered(@Param("sheet") Sheet sheet);

    /**
     * Find all cells in a specific row
     */
    List<Cell> findBySheetAndRowIndex(Sheet sheet, Integer rowIndex);

    /**
     * Find all cells in a specific column
     */
    List<Cell> findBySheetAndColumnIndex(Sheet sheet, Integer columnIndex);

    /**
     * Find all cells with row index greater than specified value
     */
    List<Cell> findBySheetAndRowIndexGreaterThan(Sheet sheet, Integer rowIndex);

    /**
     * Find all cells with column index greater than specified value
     */
    List<Cell> findBySheetAndColumnIndexGreaterThan(Sheet sheet, Integer columnIndex);

    /**
     * Find all cells with column index greater than or equal to specified value
     */
    List<Cell> findBySheetAndColumnIndexGreaterThanEqual(Sheet sheet, Integer columnIndex);

    /**
     * Find the maximum row index in a sheet
     */
    @Query("SELECT MAX(c.rowIndex) FROM Cell c WHERE c.sheet = :sheet")
    Integer findMaxRowIndexBySheet(@Param("sheet") Sheet sheet);

    List<Cell> findBySheet(Sheet sheet);
}
