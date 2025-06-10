package com.example.spreadsheet.entity;

import javax.persistence.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Entity
@Table(name = "spreadsheets")
public class Spreadsheet {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false)
    private String name;
    
    private String description;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_id", nullable = false)
    private User owner;
    
    @OneToMany(mappedBy = "spreadsheet", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("orderIndex ASC")
    private List<Sheet> sheets = new ArrayList<>();
    
    @OneToMany(mappedBy = "spreadsheet", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<Media> mediaFiles = new HashSet<>();
    
    @OneToMany(mappedBy = "spreadsheet", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<SpreadsheetPermission> permissions = new HashSet<>();
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
    
    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    
    public User getOwner() { return owner; }
    public void setOwner(User owner) { this.owner = owner; }
    
    public List<Sheet> getSheets() { return sheets; }
    public void setSheets(List<Sheet> sheets) { this.sheets = sheets; }
    
    public Set<Media> getMediaFiles() { return mediaFiles; }
    public void setMediaFiles(Set<Media> mediaFiles) { this.mediaFiles = mediaFiles; }
    
    public Set<SpreadsheetPermission> getPermissions() { return permissions; }
    public void setPermissions(Set<SpreadsheetPermission> permissions) { 
        this.permissions = permissions; 
    }
    
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}