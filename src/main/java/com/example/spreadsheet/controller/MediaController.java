package com.example.spreadsheet.controller;

import com.example.spreadsheet.dto.MessageResponse;
import com.example.spreadsheet.entity.Media;
import com.example.spreadsheet.service.MediaService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.MalformedURLException;
import java.security.Principal;

@RestController
@RequestMapping("/media")
@CrossOrigin(origins = "*", maxAge = 3600)
public class MediaController {
    
    @Autowired
    private MediaService mediaService;
    
    @PostMapping("/spreadsheet/{spreadsheetId}")
    public ResponseEntity<Media> uploadMedia(
            @PathVariable Long spreadsheetId,
            @RequestParam("file") MultipartFile file,
            Principal principal) throws IOException {
        Media media = mediaService.uploadMedia(spreadsheetId, file, principal.getName());
        return new ResponseEntity<>(media, HttpStatus.CREATED);
    }
    
    @GetMapping("/{id}/download")
    public ResponseEntity<Resource> downloadMedia(
            @PathVariable Long id,
            Principal principal) throws MalformedURLException {
        Resource resource = mediaService.downloadMedia(id, principal.getName());
        Media media = mediaService.getMediaById(id);
        
        return ResponseEntity.ok()
            .contentType(MediaType.parseMediaType(media.getContentType()))
            .header(HttpHeaders.CONTENT_DISPOSITION, 
                   "attachment; filename=\"" + media.getFilename() + "\"")
            .body(resource);
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<MessageResponse> deleteMedia(
            @PathVariable Long id,
            Principal principal) throws IOException {
        mediaService.deleteMedia(id, principal.getName());
        return ResponseEntity.ok(new MessageResponse("Media deleted successfully"));
    }
}