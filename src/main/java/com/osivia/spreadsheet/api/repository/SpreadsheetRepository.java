package com.osivia.spreadsheet.api.repository;

import com.osivia.spreadsheet.api.entity.Spreadsheet;
import com.osivia.spreadsheet.api.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface SpreadsheetRepository extends JpaRepository<Spreadsheet, Long> {
    List<Spreadsheet> findByOwner(User owner);
}