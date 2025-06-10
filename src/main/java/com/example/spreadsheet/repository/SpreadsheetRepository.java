package com.example.spreadsheet.repository;

import com.example.spreadsheet.entity.Spreadsheet;
import com.example.spreadsheet.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface SpreadsheetRepository extends JpaRepository<Spreadsheet, Long> {
    List<Spreadsheet> findByOwner(User owner);
}