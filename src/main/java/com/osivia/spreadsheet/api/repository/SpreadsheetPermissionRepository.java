package com.osivia.spreadsheet.api.repository;

import com.osivia.spreadsheet.api.entity.Spreadsheet;
import com.osivia.spreadsheet.api.entity.SpreadsheetPermission;
import com.osivia.spreadsheet.api.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface SpreadsheetPermissionRepository extends JpaRepository<SpreadsheetPermission, Long> {
    Optional<SpreadsheetPermission> findBySpreadsheetAndUser(Spreadsheet spreadsheet, User user);
    List<SpreadsheetPermission> findByUser(User user);
    List<SpreadsheetPermission> findBySpreadsheet(Spreadsheet spreadsheet);
}