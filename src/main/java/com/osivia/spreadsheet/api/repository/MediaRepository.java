package com.osivia.spreadsheet.api.repository;

import com.osivia.spreadsheet.api.entity.Media;
import com.osivia.spreadsheet.api.entity.Spreadsheet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface MediaRepository extends JpaRepository<Media, Long> {

    List<Media> findBySpreadsheetId(Long spreadsheetId);

    Optional<Media> findByIdAndSpreadsheetId(Long id, Long spreadsheetId);

    @Modifying
    @Query("DELETE FROM Media m WHERE m.spreadsheet.id = ?1")
    void deleteBySpreadsheetId(Long spreadsheetId);

    boolean existsByIdAndSpreadsheetId(Long id, Long spreadsheetId);
}