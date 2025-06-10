package com.osivia.spreadsheet.api.controller;


import com.osivia.spreadsheet.api.dto.CellUpdateRequest;
import com.osivia.spreadsheet.api.dto.CreateSheetRequest;
import com.osivia.spreadsheet.api.dto.MessageResponse;
import com.osivia.spreadsheet.api.dto.SheetDTO;
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
    
    @Autowired
    private SpreadsheetService spreadsheetService;
    
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
}