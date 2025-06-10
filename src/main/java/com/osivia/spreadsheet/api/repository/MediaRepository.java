package com.osivia.spreadsheet.api.repository;

import com.osivia.spreadsheet.api.entity.Media;
import com.osivia.spreadsheet.api.entity.Spreadsheet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface MediaRepository extends JpaRepository<Media, Long> {
    List<Media> findBySpreadsheet(Spreadsheet spreadsheet);
}