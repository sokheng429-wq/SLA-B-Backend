package com.bgroceries.sla.dto;

import com.bgroceries.sla.entity.Role;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminCreateUserRequest {

    @NotBlank(message = "Username is required")
    private String username;

    private String email;

    private String phoneNumber;

    @NotBlank(message = "Full name is required")
    private String fullName;

    private String fullNameKh;

    @NotBlank(message = "Password is required")
    private String password;

    @Builder.Default
    private Role role = Role.REQUESTER;

    private String department;

    @Builder.Default
    private String sessionTimeout = "15 min";

    @Builder.Default
    private boolean mustChangePassword = true;
}
