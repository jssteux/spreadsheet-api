package com.example.spreadsheet.service;

import com.example.spreadsheet.dto.*;
import com.example.spreadsheet.entity.*;
import com.example.spreadsheet.exception.*;
import com.example.spreadsheet.repository.*;

import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.DateUtil;
import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.*;
import java.util.stream.Collectors;

@Service
@Transactional
public class SpreadsheetService {
    
    @Autowired
    private SpreadsheetRepository spreadsheetRepository;
    
    @Autowired
    private SheetRepository sheetRepository;
    
    @Autowired
    private CellRepository cellRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private SpreadsheetPermissionRepository permissionRepository;
    
    @Autowired
    private MediaRepository mediaRepository;
    
    @Value("${media.upload.path}")
    private String uploadPath;
    
    public SpreadsheetDTO createSpreadsheet(String name, String description, String username) {
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        
        Spreadsheet spreadsheet = new Spreadsheet();
        spreadsheet.setName(name);
        spreadsheet.setDescription(description);
        spreadsheet.setOwner(user);
        
        // Create default sheet
        Sheet sheet = new Sheet();
        sheet.setName("Sheet1");
        sheet.setOrderIndex(0);
        sheet.setSpreadsheet(spreadsheet);
        spreadsheet.getSheets().add(sheet);
        
        Spreadsheet saved = spreadsheetRepository.save(spreadsheet);
        return convertToDTO(saved, username);
    }
    
    public SpreadsheetDTO getSpreadsheet(Long id, String username) {
        Spreadsheet spreadsheet = spreadsheetRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Spreadsheet not found"));
        
        checkPermission(spreadsheet, username, PermissionType.VIEW);
        return convertToDTO(spreadsheet, username);
    }
    
    public List<SpreadsheetDTO> getUserSpreadsheets(String username) {
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        
        List<Spreadsheet> owned = spreadsheetRepository.findByOwner(user);
        List<Spreadsheet> shared = permissionRepository.findByUser(user).stream()
            .map(SpreadsheetPermission::getSpreadsheet)
            .collect(Collectors.toList());
        
        Set<Spreadsheet> all = new HashSet<>(owned);
        all.addAll(shared);
        
        return all.stream()
            .map(s -> convertToDTO(s, username))
            .collect(Collectors.toList());
    }
    
    public void deleteSpreadsheet(Long id, String username) {
        Spreadsheet spreadsheet = spreadsheetRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Spreadsheet not found"));
        
        if (!spreadsheet.getOwner().getUsername().equals(username)) {
            throw new UnauthorizedException("Only owner can delete spreadsheet");
        }
        
        // Delete associated media files
        for (Media media : spreadsheet.getMediaFiles()) {
            deleteMediaFile(media.getFilePath());
        }
        
        spreadsheetRepository.delete(spreadsheet);
    }
    
    public SheetDTO createSheet(Long spreadsheetId, String name, String username) {
        Spreadsheet spreadsheet = spreadsheetRepository.findById(spreadsheetId)
            .orElseThrow(() -> new ResourceNotFoundException("Spreadsheet not found"));
        
        checkPermission(spreadsheet, username, PermissionType.EDIT);
        
        Sheet sheet = new Sheet();
        sheet.setName(name);
        sheet.setSpreadsheet(spreadsheet);
        sheet.setOrderIndex(spreadsheet.getSheets().size());
        
        Sheet saved = sheetRepository.save(sheet);
        return convertToSheetDTO(saved);
    }
    
    public SheetDTO getSheet(Long sheetId, String username) {
        Sheet sheet = sheetRepository.findById(sheetId)
            .orElseThrow(() -> new ResourceNotFoundException("Sheet not found"));
        
        checkPermission(sheet.getSpreadsheet(), username, PermissionType.VIEW);
        
        return convertToSheetDTO(sheet);
    }
    
    public void updateCells(Long sheetId, List<CellDTO> cellUpdates, String username) {
        Sheet sheet = sheetRepository.findById(sheetId)
            .orElseThrow(() -> new ResourceNotFoundException("Sheet not found"));
        
        checkPermission(sheet.getSpreadsheet(), username, PermissionType.EDIT);
        
        for (CellDTO cellDTO : cellUpdates) {
            com.example.spreadsheet.entity.Cell cell = cellRepository.findBySheetAndRowIndexAndColumnIndex(
                sheet, cellDTO.getRow(), cellDTO.getCol()
            ).orElse(new com.example.spreadsheet.entity.Cell());
            
            cell.setSheet(sheet);
            cell.setRowIndex(cellDTO.getRow());
            cell.setColumnIndex(cellDTO.getCol());
            cell.setValue(cellDTO.getValue());
            
            if (cellDTO.getValue() == null || cellDTO.getValue().isEmpty()) {
                if (cell.getId() != null) {
                    cellRepository.delete(cell);
                }
            } else {
                cellRepository.save(cell);
            }
        }
    }
    
    public void grantPermission(Long spreadsheetId, String ownerUsername, 
                               String targetUsername, PermissionType permissionType) {
        Spreadsheet spreadsheet = spreadsheetRepository.findById(spreadsheetId)
            .orElseThrow(() -> new ResourceNotFoundException("Spreadsheet not found"));
        
        if (!spreadsheet.getOwner().getUsername().equals(ownerUsername)) {
            checkPermission(spreadsheet, ownerUsername, PermissionType.ADMIN);
        }
        
        User targetUser = userRepository.findByUsername(targetUsername)
            .orElseThrow(() -> new ResourceNotFoundException("Target user not found"));
        
        if (targetUser.getUsername().equals(spreadsheet.getOwner().getUsername())) {
            throw new IllegalArgumentException("Cannot change owner permissions");
        }
        
        SpreadsheetPermission permission = permissionRepository
            .findBySpreadsheetAndUser(spreadsheet, targetUser)
            .orElse(new SpreadsheetPermission());
        
        permission.setSpreadsheet(spreadsheet);
        permission.setUser(targetUser);
        permission.setPermissionType(permissionType);
        
        permissionRepository.save(permission);
    }
    
    public void revokePermission(Long spreadsheetId, String ownerUsername, String targetUsername) {
        Spreadsheet spreadsheet = spreadsheetRepository.findById(spreadsheetId)
            .orElseThrow(() -> new ResourceNotFoundException("Spreadsheet not found"));
        
        if (!spreadsheet.getOwner().getUsername().equals(ownerUsername)) {
            throw new UnauthorizedException("Only owner can revoke permissions");
        }
        
        User targetUser = userRepository.findByUsername(targetUsername)
            .orElseThrow(() -> new ResourceNotFoundException("Target user not found"));
        
        permissionRepository.findBySpreadsheetAndUser(spreadsheet, targetUser)
            .ifPresent(permissionRepository::delete);
    }
    
    public byte[] exportToExcel(Long spreadsheetId, String username) throws IOException {
        Spreadsheet spreadsheet = spreadsheetRepository.findById(spreadsheetId)
            .orElseThrow(() -> new ResourceNotFoundException("Spreadsheet not found"));
        
        checkPermission(spreadsheet, username, PermissionType.VIEW);
        
        try (Workbook workbook = new XSSFWorkbook()) {
            for (Sheet sheetEntity : spreadsheet.getSheets()) {
                org.apache.poi.ss.usermodel.Sheet excelSheet = workbook.createSheet(sheetEntity.getName());
                
                List<com.example.spreadsheet.entity.Cell> cells = cellRepository.findBySheetOrdered(sheetEntity);
                
                for (com.example.spreadsheet.entity.Cell cellEntity : cells) {
                    Row row = excelSheet.getRow(cellEntity.getRowIndex());
                    if (row == null) {
                        row = excelSheet.createRow(cellEntity.getRowIndex());
                    }
                    
                    org.apache.poi.ss.usermodel.Cell excelCell = row.createCell(cellEntity.getColumnIndex());
                    excelCell.setCellValue(cellEntity.getValue());
                }
            }
            
            ByteArrayOutputStream bos = new ByteArrayOutputStream();
            workbook.write(bos);
            return bos.toByteArray();
        }
    }
    
    public SpreadsheetDTO importFromExcel(MultipartFile file, String username) throws IOException {
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        
        Spreadsheet spreadsheet = new Spreadsheet();
        spreadsheet.setName(file.getOriginalFilename());
        spreadsheet.setOwner(user);
        
        try (Workbook workbook = WorkbookFactory.create(file.getInputStream())) {
            for (int i = 0; i < workbook.getNumberOfSheets(); i++) {
                org.apache.poi.ss.usermodel.Sheet excelSheet = workbook.getSheetAt(i);
                
                Sheet sheet = new Sheet();
                sheet.setName(excelSheet.getSheetName());
                sheet.setOrderIndex(i);
                sheet.setSpreadsheet(spreadsheet);
                spreadsheet.getSheets().add(sheet);
                
                for (Row row : excelSheet) {
                    for (org.apache.poi.ss.usermodel.Cell excelCell : row) {
                        if (excelCell.getCellType() != CellType.BLANK) {
                            com.example.spreadsheet.entity.Cell cell = new com.example.spreadsheet.entity.Cell();
                            cell.setSheet(sheet);
                            cell.setRowIndex(row.getRowNum());
                            cell.setColumnIndex(excelCell.getColumnIndex());
                            cell.setValue(getCellValueAsString(excelCell));
                            sheet.getCells().add(cell);
                        }
                    }
                }
            }
        }
        
        Spreadsheet saved = spreadsheetRepository.save(spreadsheet);
        return convertToDTO(saved, username);
    }
    
    private String getCellValueAsString(org.apache.poi.ss.usermodel.Cell cell) {
        switch (cell.getCellType()) {
            case STRING:
                return cell.getStringCellValue();
            case NUMERIC:
                if (DateUtil.isCellDateFormatted(cell)) {
                    return cell.getDateCellValue().toString();
                }
                return String.valueOf(cell.getNumericCellValue());
            case BOOLEAN:
                return String.valueOf(cell.getBooleanCellValue());
            case FORMULA:
                try {
                    return cell.getStringCellValue();
                } catch (Exception e) {
                    return String.valueOf(cell.getNumericCellValue());
                }
            default:
                return "";
        }
    }
    
    private void checkPermission(Spreadsheet spreadsheet, String username, PermissionType requiredPermission) {
        if (spreadsheet.getOwner().getUsername().equals(username)) {
            return; // Owner has all permissions
        }
        
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        
        Optional<SpreadsheetPermission> permission = permissionRepository.findBySpreadsheetAndUser(spreadsheet, user);
        
        if (permission.isEmpty()) {
            throw new UnauthorizedException("No permission to access this spreadsheet");
        }
        
        PermissionType userPermission = permission.get().getPermissionType();
        
        if (requiredPermission == PermissionType.VIEW) {
            return; // Any permission allows viewing
        }
        
        if (requiredPermission == PermissionType.EDIT && userPermission == PermissionType.VIEW) {
            throw new UnauthorizedException("No edit permission for this spreadsheet");
        }
        
        if (requiredPermission == PermissionType.ADMIN && userPermission != PermissionType.ADMIN) {
            throw new UnauthorizedException("Admin permission required");
        }
    }
    
    public SpreadsheetPermissionRepository getPermissionRepository() {
        return permissionRepository;
    }
    
    private SpreadsheetDTO convertToDTO(Spreadsheet spreadsheet, String username) {
        SpreadsheetDTO dto = new SpreadsheetDTO();
        dto.setId(spreadsheet.getId());
        dto.setName(spreadsheet.getName());
        dto.setDescription(spreadsheet.getDescription());
        dto.setOwnerUsername(spreadsheet.getOwner().getUsername());
        dto.setMediaCount(spreadsheet.getMediaFiles().size());
        dto.setCreatedAt(spreadsheet.getCreatedAt());
        dto.setUpdatedAt(spreadsheet.getUpdatedAt());
        
        dto.setSheets(spreadsheet.getSheets().stream()
            .map(s -> new SheetSummaryDTO(s.getId(), s.getName(), s.getOrderIndex()))
            .collect(Collectors.toList()));
        
        // Set user's permission level
        if (spreadsheet.getOwner().getUsername().equals(username)) {
            dto.setUserPermission("OWNER");
        } else {
            User user = userRepository.findByUsername(username).orElse(null);
            if (user != null) {
                permissionRepository.findBySpreadsheetAndUser(spreadsheet, user)
                    .ifPresent(p -> dto.setUserPermission(p.getPermissionType().toString()));
            }
        }
        
        return dto;
    }
    
    private SheetDTO convertToSheetDTO(Sheet sheet) {
        SheetDTO dto = new SheetDTO();
        dto.setId(sheet.getId());
        dto.setName(sheet.getName());
        dto.setSpreadsheetId(sheet.getSpreadsheet().getId());
        dto.setOrderIndex(sheet.getOrderIndex());
        dto.setRowCount(sheet.getRowCount());
        dto.setColumnCount(sheet.getColumnCount());
        dto.setCreatedAt(sheet.getCreatedAt());
        dto.setUpdatedAt(sheet.getUpdatedAt());
        
        List<com.example.spreadsheet.entity.Cell> cells = cellRepository.findBySheetOrdered(sheet);
        dto.setCells(cells.stream()
            .map(c -> new CellDTO(c.getRowIndex(), c.getColumnIndex(), c.getValue()))
            .collect(Collectors.toList()));
        
        return dto;
    }
    
    private void deleteMediaFile(String filePath) {
        try {
            Path path = Paths.get(filePath);
            Files.deleteIfExists(path);
        } catch (IOException e) {
            // Log error but don't fail the operation
            System.err.println("Failed to delete file: " + filePath);
        }
    }
}