package com.bgroceries.sla.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "sla_users", indexes = {
    @Index(name = "idx_user_username", columnList = "username"),
    @Index(name = "idx_user_email", columnList = "email"),
    @Index(name = "idx_user_phone", columnList = "phone_number")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@ToString(exclude = "passwordHash")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 60)
    private String username;

    @Column(nullable = false, unique = true, length = 120)
    private String email;

    @Column(name = "phone_number", unique = true, length = 30)
    private String phoneNumber;

    @Column(name = "password_hash", nullable = false, length = 255)
    private String passwordHash;

    @Column(name = "full_name", nullable = false, length = 120)
    private String fullName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    @Builder.Default
    private Role role = Role.REQUESTER;

    @Column(length = 100)
    private String department;

    @Column(name = "session_timeout", length = 50)
    @Builder.Default
    private String sessionTimeout = "15 min";

    @Column(nullable = false)
    @Builder.Default
    private Boolean enabled = true;

    @Column(name = "must_change_password", nullable = false)
    @Builder.Default
    private Boolean mustChangePassword = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public User(String username, String email, String password, String fullName, Role role, String department) {
        this.username = username;
        this.email = email;
        this.passwordHash = password;
        this.fullName = fullName;
        this.role = role != null ? role : Role.REQUESTER;
        this.department = department;
        this.enabled = true;
        this.sessionTimeout = "15 min";
    }

    // Spring Security & backwards compatibility helpers
    public String getPassword() {
        return passwordHash;
    }

    public void setPassword(String password) {
        this.passwordHash = password;
    }

    public boolean isActive() {
        return Boolean.TRUE.equals(enabled);
    }

    public void setActive(boolean active) {
        this.enabled = active;
    }

    public void setRole(Role role) {
        this.role = role != null ? role : Role.REQUESTER;
    }

    public void setRole(String roleStr) {
        if (roleStr != null) {
            try {
                this.role = Role.valueOf(roleStr.toUpperCase());
            } catch (Exception e) {
                this.role = Role.REQUESTER;
            }
        }
    }

    public boolean isMustChangePassword() {
        return Boolean.TRUE.equals(mustChangePassword);
    }

    public void setMustChangePassword(boolean mustChangePassword) {
        this.mustChangePassword = mustChangePassword;
    }

    @PrePersist
    protected void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        this.createdAt = now;
        this.updatedAt = now;
        if (this.enabled == null) this.enabled = true;
        if (this.mustChangePassword == null) this.mustChangePassword = false;
        if (this.sessionTimeout == null) this.sessionTimeout = "15 min";
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    // Custom builder extensions to support both Role enum and String, plus aliases
    public static class UserBuilder {
        public UserBuilder role(Role role) {
            this.role$value = role;
            this.role$set = true;
            return this;
        }

        public UserBuilder role(String roleName) {
            if (roleName != null) {
                this.role$value = Role.valueOf(roleName.toUpperCase());
                this.role$set = true;
            }
            return this;
        }

        public UserBuilder password(String password) {
            this.passwordHash = password;
            return this;
        }

        public UserBuilder active(boolean active) {
            this.enabled$value = active;
            this.enabled$set = true;
            return this;
        }

        public UserBuilder mustChangePassword(boolean mustChangePassword) {
            this.mustChangePassword$value = mustChangePassword;
            this.mustChangePassword$set = true;
            return this;
        }
    }
}
