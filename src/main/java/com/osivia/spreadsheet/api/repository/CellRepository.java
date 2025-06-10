package com.osivia.spreadsheet.api.repository;

import com.osivia.spreadsheet.api.entity.Cell;
import com.osivia.spreadsheet.api.entity.Sheet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.List;

@Repository
public interface CellRepository extends JpaRepository<Cell, Long> {
    Optional<Cell> findBySheetAndRowIndexAndColumnIndex(Sheet sheet, Integer rowIndex, Integer columnIndex);
    List<Cell> findBySheet(Sheet sheet);
    
    @Modifying
    @Query("DELETE FROM Cell c WHERE c.sheet = :sheet")
    void deleteBySheet(@Param("sheet") Sheet sheet);
    
    @Query("SELECT c FROM Cell c WHERE c.sheet = :sheet ORDER BY c.rowIndex, c.columnIndex")
    List<Cell> findBySheetOrdered(@Param("sheet") Sheet sheet);
}