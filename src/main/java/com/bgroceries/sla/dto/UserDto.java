package com.bgroceries.sla.dto;

import com.bgroceries.sla.entity.Role;
import com.bgroceries.sla.entity.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserDto {

    private Long id;
    private String username;
    private String email;
    private String phoneNumber;
    private String fullName;
    private Role role;
    private String department;
    private String sessionTimeout;
    private boolean active;
    private boolean mustChangePassword;
    private LocalDateTime createdAt;

    public static UserDto fromEntity(User user) {
        if (user == null) return null;
        return UserDto.builder()
                .id(user.getId())
                .username(user.getUsername())
                .email(user.getEmail())
                .phoneNumber(user.getPhoneNumber())
                .fullName(user.getFullName())
                .role(user.getRole())
                .department(user.getDepartment())
                .sessionTimeout(user.getSessionTimeout())
                .active(user.isActive())
                .mustChangePassword(user.isMustChangePassword())
                .createdAt(user.getCreatedAt())
                .build();
    }
}
