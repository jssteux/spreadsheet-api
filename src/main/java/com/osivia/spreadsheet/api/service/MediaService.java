package com.osivia.spreadsheet.api.service;



import com.osivia.spreadsheet.api.entity.*;
import com.osivia.spreadsheet.api.exception.ResourceNotFoundException;
import com.osivia.spreadsheet.api.exception.UnauthorizedException;
import com.osivia.spreadsheet.api.repository.MediaRepository;
import com.osivia.spreadsheet.api.repository.SpreadsheetRepository;
import com.osivia.spreadsheet.api.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

@Service
@Transactional
public class MediaService {
    
    @Value("${media.upload.path}")
    private String uploadPath;
    
    private final MediaRepository mediaRepository;
    
    private final SpreadsheetRepository spreadsheetRepository;
    
    private final UserRepository userRepository;
    
    private final SpreadsheetService spreadsheetService;

    @Value("${app.upload.dir:uploads}")
    private String uploadDir;

    public MediaService(MediaRepository mediaRepository, SpreadsheetRepository spreadsheetRepository, UserRepository userRepository, SpreadsheetService spreadsheetService) {
        this.mediaRepository = mediaRepository;
        this.spreadsheetRepository = spreadsheetRepository;
        this.userRepository = userRepository;
        this.spreadsheetService = spreadsheetService;
    }


    public Media uploadMedia(Long spreadsheetId, MultipartFile file, String username) throws IOException {
        Spreadsheet spreadsheet = spreadsheetRepository.findById(spreadsheetId)
            .orElseThrow(() -> new ResourceNotFoundException("Spreadsheet not found"));
        
        // Check edit permission
        if (!spreadsheet.getOwner().getUsername().equals(username)) {
            User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
            
            SpreadsheetPermission permission = spreadsheetService.getPermissionRepository()
                .findBySpreadsheetAndUser(spreadsheet, user)
                .orElseThrow(() -> new UnauthorizedException("No permission to upload media"));
            
            if (permission.getPermissionType() == PermissionType.VIEW) {
                throw new UnauthorizedException("Edit permission required to upload media");
            }
        }
        
        // Create upload directory if it doesn't exist
        Path uploadDir = Paths.get(uploadPath);
        if (!Files.exists(uploadDir)) {
            Files.createDirectories(uploadDir);
        }
        
        // Generate unique filename
        String originalFilename = file.getOriginalFilename();
        String extension = "";
        if (originalFilename != null && originalFilename.contains(".")) {
            extension = originalFilename.substring(originalFilename.lastIndexOf("."));
        }
        String newFilename = UUID.randomUUID().toString() + extension;
        Path filePath = uploadDir.resolve(newFilename);
        
        // Save file
        Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);
        
        // Save media entity
        Media media = new Media();
        media.setFilename(originalFilename);
        media.setContentType(file.getContentType());
        media.setFileSize(file.getSize());
        media.setSpreadsheet(spreadsheet);
        
        return mediaRepository.save(media);
    }
    
    public Resource downloadMedia(Long mediaId, String username) throws MalformedURLException {
        Media media = mediaRepository.findById(mediaId)
            .orElseThrow(() -> new ResourceNotFoundException("Media not found"));
        
        // Check view permission
        Spreadsheet spreadsheet = media.getSpreadsheet();
        if (!spreadsheet.getOwner().getUsername().equals(username)) {
            User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
            
            spreadsheetService.getPermissionRepository()
                .findBySpreadsheetAndUser(spreadsheet, user)
                .orElseThrow(() -> new UnauthorizedException("No permission to access this media"));
        }

        Path targetPath = Paths.get(uploadDir, media.getFilename());
        Path filePath = Paths.get(targetPath.toUri());
        Resource resource = new UrlResource(filePath.toUri());
        
        if (!resource.exists() || !resource.isReadable()) {
            throw new ResourceNotFoundException("Media file not found");
        }
        
        return resource;
    }
    
    public void deleteMedia(Long mediaId, String username) throws IOException {
        Media media = mediaRepository.findById(mediaId)
            .orElseThrow(() -> new ResourceNotFoundException("Media not found"));
        
        // Check permission
        Spreadsheet spreadsheet = media.getSpreadsheet();
        if (!spreadsheet.getOwner().getUsername().equals(username)) {
            User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
            
            SpreadsheetPermission permission = spreadsheetService.getPermissionRepository()
                .findBySpreadsheetAndUser(spreadsheet, user)
                .orElseThrow(() -> new UnauthorizedException("No permission to delete media"));
            
            if (permission.getPermissionType() == PermissionType.VIEW) {
                throw new UnauthorizedException("Edit permission required to delete media");
            }
        }
        
        // Delete file
        Path targetPath = Paths.get(uploadDir, media.getFilename());
        Path filePath = Paths.get(targetPath.toUri());

        Files.deleteIfExists(filePath);
        
        // Delete entity
        mediaRepository.delete(media);
    }
    
    public Media getMediaById(Long id) {
        return mediaRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Media not found"));
    }
}