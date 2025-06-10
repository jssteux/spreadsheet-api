package com.osivia.spreadsheet.api.controller;


import com.osivia.spreadsheet.api.dto.CreateSpreadsheetRequest;
import com.osivia.spreadsheet.api.dto.MessageResponse;
import com.osivia.spreadsheet.api.dto.PermissionRequest;
import com.osivia.spreadsheet.api.dto.SpreadsheetDTO;
import com.osivia.spreadsheet.api.entity.Spreadsheet;
import com.osivia.spreadsheet.api.service.SpreadsheetService;
import com.osivia.spreadsheet.api.service.ZipExportImportService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;
import java.io.IOException;
import java.security.Principal;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/spreadsheets")
@CrossOrigin(origins = "*", maxAge = 3600)
public class SpreadsheetController {
    
    @Autowired
    private SpreadsheetService spreadsheetService;

    @Autowired
    private ZipExportImportService zipService;
    
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


    @GetMapping("/{id}/export/zip")
    public ResponseEntity<byte[]> exportToZip(@PathVariable Long id, Principal principal) {
        try {
            // Récupérer le spreadsheet pour obtenir son nom
            SpreadsheetDTO spreadsheet = spreadsheetService.getSpreadsheet(id, principal.getName());

            // Générer le ZIP
            byte[] zipContent = zipService.exportSpreadsheetToZip(id);

            // Préparer la réponse avec le bon nom de fichier
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_OCTET_STREAM);
            headers.setContentDispositionFormData("attachment",
                    spreadsheet.getName().replaceAll("[^a-zA-Z0-9.-]", "_") + ".zip");
            headers.setContentLength(zipContent.length);

            return new ResponseEntity<>(zipContent, headers, HttpStatus.OK);

        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }


    @PostMapping("/import")
    public ResponseEntity<SpreadsheetDTO> importFromExcel(
            @RequestParam("file") MultipartFile file,
            Principal principal) throws IOException {
        SpreadsheetDTO spreadsheet = spreadsheetService.importFromExcel(file, principal.getName());
        return new ResponseEntity<>(spreadsheet, HttpStatus.CREATED);
    }

    /**
     * Import spreadsheet from ZIP file
     */
    @PostMapping("/import/zip")
    public ResponseEntity<?> importFromZip(
            @RequestParam("file") MultipartFile file,
            HttpServletRequest request, Principal principal) {

        try {
            // Vérifier que c'est bien un fichier ZIP
            if (!file.getContentType().equals("application/zip") &&
                    !file.getContentType().equals("application/x-zip-compressed") &&
                    !file.getOriginalFilename().toLowerCase().endsWith(".zip")) {

                Map<String, String> error = new HashMap<>();
                error.put("error", "File must be a ZIP archive");
                return ResponseEntity.badRequest().body(error);
            }

            // Récupérer l'utilisateur actuel

            // Importer le spreadsheet
            Spreadsheet imported = zipService.importSpreadsheetFromZip(file, principal.getName());

            // Utiliser SpreadsheetDTO pour la réponse
            SpreadsheetDTO dto = convertToDTO(imported);

            return ResponseEntity.ok(dto);

        } catch (IOException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Error processing ZIP file: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Import failed: " + e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    /**
     * Convert Spreadsheet entity to DTO
     */
    private SpreadsheetDTO convertToDTO(Spreadsheet spreadsheet) {
        SpreadsheetDTO dto = new SpreadsheetDTO();
        dto.setId(spreadsheet.getId());
        dto.setName(spreadsheet.getName());
        dto.setDescription(spreadsheet.getDescription());
        dto.setOwnerUsername(spreadsheet.getOwner().getUsername());
        dto.setCreatedAt(LocalDateTime.parse(spreadsheet.getCreatedAt() != null ?
                spreadsheet.getCreatedAt().toString() : LocalDateTime.now().toString()));
        dto.setUpdatedAt(LocalDateTime.parse(spreadsheet.getUpdatedAt() != null ?
                spreadsheet.getUpdatedAt().toString() : LocalDateTime.now().toString()));
        return dto;
    }
}