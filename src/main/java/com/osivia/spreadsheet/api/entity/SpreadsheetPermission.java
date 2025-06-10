package com.osivia.spreadsheet.api.entity;

import javax.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "spreadsheet_permissions", 
       uniqueConstraints = @UniqueConstraint(columnNames = {"spreadsheet_id", "user_id"}))
public class SpreadsheetPermission {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "spreadsheet_id", nullable = false)
    private Spreadsheet spreadsheet;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "permission_type", nullable = false)
    private PermissionType permissionType;
    
    @Column(name = "granted_at")
    private LocalDateTime grantedAt;
    
    @PrePersist
    protected void onCreate() {
        grantedAt = LocalDateTime.now();
    }
    
    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public Spreadsheet getSpreadsheet() { return spreadsheet; }
    public void setSpreadsheet(Spreadsheet spreadsheet) { this.spreadsheet = spreadsheet; }
    
    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }
    
    public PermissionType getPermissionType() { return permissionType; }
    public void setPermissionType(PermissionType permissionType) { 
        this.permissionType = permissionType; 
    }
    
    public LocalDateTime getGrantedAt() { return grantedAt; }
    public void setGrantedAt(LocalDateTime grantedAt) { this.grantedAt = grantedAt; }
}