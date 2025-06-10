package com.osivia.spreadsheet.api.controller;


import com.osivia.spreadsheet.api.dto.CreateSpreadsheetRequest;
import com.osivia.spreadsheet.api.dto.MessageResponse;
import com.osivia.spreadsheet.api.dto.PermissionRequest;
import com.osivia.spreadsheet.api.dto.SpreadsheetDTO;
import com.osivia.spreadsheet.api.service.SpreadsheetService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import javax.validation.Valid;
import java.io.IOException;
import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/spreadsheets")
@CrossOrigin(origins = "*", maxAge = 3600)
public class SpreadsheetController {
    
    @Autowired
    private SpreadsheetService spreadsheetService;
    
    @PostMapping
    public ResponseEntity<SpreadsheetDTO> createSpreadsheet(
            @Valid @RequestBody CreateSpreadsheetRequest request,
            Principal principal) {
        SpreadsheetDTO spreadsheet = spreadsheetService.createSpreadsheet(
            request.getName(), 
            request.getDescription(), 
            principal.getName()
        );
        return new ResponseEntity<>(spreadsheet, HttpStatus.CREATED);
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<SpreadsheetDTO> getSpreadsheet(
            @PathVariable Long id,
            Principal principal) {
        SpreadsheetDTO spreadsheet = spreadsheetService.getSpreadsheet(id, principal.getName());
        return ResponseEntity.ok(spreadsheet);
    }
    
    @GetMapping
    public ResponseEntity<List<SpreadsheetDTO>> getUserSpreadsheets(Principal principal) {
        List<SpreadsheetDTO> spreadsheets = spreadsheetService.getUserSpreadsheets(principal.getName());
        return ResponseEntity.ok(spreadsheets);
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteSpreadsheet(
            @PathVariable Long id,
            Principal principal) {
        spreadsheetService.deleteSpreadsheet(id, principal.getName());
        return ResponseEntity.noContent().build();
    }
    
    @PostMapping("/{id}/permissions")
    public ResponseEntity<MessageResponse> grantPermission(
            @PathVariable Long id,
            @Valid @RequestBody PermissionRequest request,
            Principal principal) {
        spreadsheetService.grantPermission(
            id, 
            principal.getName(), 
            request.getUsername(), 
            request.getPermissionType()
        );
        return ResponseEntity.ok(new MessageResponse("Permission granted successfully"));
    }
    
    @DeleteMapping("/{id}/permissions/{username}")
    public ResponseEntity<Void> revokePermission(
            @PathVariable Long id,
            @PathVariable String username,
            Principal principal) {
        spreadsheetService.revokePermission(id, principal.getName(), username);
        return ResponseEntity.noContent().build();
    }
    
    @GetMapping("/{id}/export")
    public ResponseEntity<byte[]> exportToExcel(
            @PathVariable Long id,
            Principal principal) throws IOException {
        byte[] excelData = spreadsheetService.exportToExcel(id, principal.getName());
        
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_OCTET_STREAM);
        headers.setContentDispositionFormData("attachment", "spreadsheet_" + id + ".xlsx");
        
        return ResponseEntity.ok()
            .headers(headers)
            .body(excelData);
    }
    
    @PostMapping("/import")
    public ResponseEntity<SpreadsheetDTO> importFromExcel(
            @RequestParam("file") MultipartFile file,
            Principal principal) throws IOException {
        SpreadsheetDTO spreadsheet = spreadsheetService.importFromExcel(file, principal.getName());
        return new ResponseEntity<>(spreadsheet, HttpStatus.CREATED);
    }
}