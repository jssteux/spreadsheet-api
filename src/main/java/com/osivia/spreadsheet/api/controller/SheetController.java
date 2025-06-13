package com.osivia.spreadsheet.api.controller;


import com.osivia.spreadsheet.api.dto.*;
import com.osivia.spreadsheet.api.service.SpreadsheetService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.security.Principal;

@RestController
@RequestMapping("/sheets")
@CrossOrigin(origins = "*", maxAge = 3600)
public class SheetController {
    

    private final SpreadsheetService spreadsheetService;

    public SheetController(SpreadsheetService spreadsheetService) {
        this.spreadsheetService = spreadsheetService;
    }

    @PostMapping("/spreadsheet/{spreadsheetId}")
    public ResponseEntity<SheetDTO> createSheet(
            @PathVariable Long spreadsheetId,
            @Valid @RequestBody CreateSheetRequest request,
            Principal principal) {
        SheetDTO sheet = spreadsheetService.createSheet(
            spreadsheetId, 
            request.getName(), 
            principal.getName()
        );
        return new ResponseEntity<>(sheet, HttpStatus.CREATED);
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<SheetDTO> getSheet(
            @PathVariable Long id,
            Principal principal) {
        SheetDTO sheet = spreadsheetService.getSheet(id, principal.getName());
        return ResponseEntity.ok(sheet);
    }
    
    @PutMapping("/{id}/cells")
    public ResponseEntity<MessageResponse> updateCells(
            @PathVariable Long id,
            @Valid @RequestBody CellUpdateRequest request,
            Principal principal) {
        spreadsheetService.updateCells(id, request.getCells(), principal.getName());
        return ResponseEntity.ok(new MessageResponse("Cells updated successfully"));
    }

    @PutMapping("/{id}/rows/{rowIndex}")
    public ResponseEntity<MessageResponse> updateRow(
            @PathVariable Long id,
            @PathVariable Integer rowIndex,
            @Valid @RequestBody RowUpdateRequest request,
            Principal principal) {
        spreadsheetService.updateRow(id, rowIndex, request.getValues(), principal.getName());
        return ResponseEntity.ok(new MessageResponse("Row updated successfully"));
    }

    @PostMapping("/{id}/rows")
    public ResponseEntity<MessageResponse> appendRow(
            @PathVariable Long id,
            @Valid @RequestBody RowUpdateRequest request,
            Principal principal) {
        Integer newRowIndex = spreadsheetService.appendRow(id, request.getValues(), principal.getName());
        return ResponseEntity.ok(new MessageResponse("Row appended at index " + newRowIndex));
    }

    @DeleteMapping("/{id}/rows")
    public ResponseEntity<MessageResponse> deleteRows(
            @PathVariable Long id,
            @RequestParam Integer startRow,
            @RequestParam(defaultValue = "1") Integer count,
            Principal principal) {
        spreadsheetService.deleteRows(id, startRow, count, principal.getName());
        return ResponseEntity.ok(new MessageResponse(count + " row(s) deleted successfully"));
    }

    @DeleteMapping("/{id}/rows/{rowIndex}")
    public ResponseEntity<MessageResponse> deleteRow(
            @PathVariable Long id,
            @PathVariable Integer rowIndex,
            Principal principal) {
        spreadsheetService.deleteRows(id, rowIndex, 1, principal.getName());
        return ResponseEntity.ok(new MessageResponse("Row deleted successfully"));
    }


    @PostMapping("/{id}/rows/multiple")
    public ResponseEntity<MessageResponse> appendMultipleRows(
            @PathVariable Long id,
            @Valid @RequestBody MultipleRowsRequest request,
            Principal principal) {
        int appendedCount = spreadsheetService.appendMultipleRows(id, request.getRows(), principal.getName());
        return ResponseEntity.ok(new MessageResponse("Successfully appended " + appendedCount + " rows"));
    }

    @PostMapping("/{id}/columns/{columnIndex}")
    public ResponseEntity<MessageResponse> insertColumn(
            @PathVariable Long id,
            @PathVariable Integer columnIndex,
            @Valid @RequestBody ColumnInsertRequest request,
            Principal principal) {
        spreadsheetService.insertColumn(id, columnIndex, request.getValues(), principal.getName());
        return ResponseEntity.ok(new MessageResponse("Column inserted successfully"));
    }

    @DeleteMapping("/{id}/columns/{columnIndex}")
    public ResponseEntity<MessageResponse> deleteColumn(
            @PathVariable Long id,
            @PathVariable Integer columnIndex,
            Principal principal) {
        spreadsheetService.deleteColumn(id, columnIndex, principal.getName());
        return ResponseEntity.ok(new MessageResponse("Column deleted successfully"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteSheet(
            @PathVariable Long id,
            Principal principal) {
        spreadsheetService.deleteSheet(id, principal.getName());
        return ResponseEntity.noContent().build();
    }

}