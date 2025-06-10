package com.example.spreadsheet.repository;

import com.example.spreadsheet.entity.Media;
import com.example.spreadsheet.entity.Spreadsheet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface MediaRepository extends JpaRepository<Media, Long> {
    List<Media> findBySpreadsheet(Spreadsheet spreadsheet);
}