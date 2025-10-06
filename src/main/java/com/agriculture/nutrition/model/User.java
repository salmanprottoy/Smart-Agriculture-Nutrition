package com.agriculture.nutrition.model;

import java.sql.Timestamp;
import java.util.Set;

public class User {
    private Long id;
    private String username;
    private String passwordHash;
    private String email;
    private Set<String> roles;
    private Timestamp createdAt;

    public User() {
    }

    public User(String username, String passwordHash, String email, Set<String> roles) {
        this.username = username;
        this.passwordHash = passwordHash;
        this.email = email;
        this.roles = roles;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getPasswordHash() { return passwordHash; }
    public void setPasswordHash(String passwordHash) { this.passwordHash = passwordHash; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public Set<String> getRoles() { return roles; }
    public void setRoles(Set<String> roles) { this.roles = roles; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }
}
