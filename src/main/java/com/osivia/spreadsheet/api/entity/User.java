package com.osivia.spreadsheet.api.entity;

import javax.persistence.*;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(unique = true, nullable = false)
    private String username;
    
    @Column(unique = true, nullable = false)
    private String email;
    
    @Column(nullable = false)
    private String password;
    
    @OneToMany(mappedBy = "owner", cascade = CascadeType.ALL)
    private Set<Spreadsheet> ownedSpreadsheets = new HashSet<>();
    
    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
    private Set<SpreadsheetPermission> permissions = new HashSet<>();
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
    
    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    
    public Set<Spreadsheet> getOwnedSpreadsheets() { return ownedSpreadsheets; }
    public void setOwnedSpreadsheets(Set<Spreadsheet> ownedSpreadsheets) { 
        this.ownedSpreadsheets = ownedSpreadsheets; 
    }
    
    public Set<SpreadsheetPermission> getPermissions() { return permissions; }
    public void setPermissions(Set<SpreadsheetPermission> permissions) { 
        this.permissions = permissions; 
    }
    
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}