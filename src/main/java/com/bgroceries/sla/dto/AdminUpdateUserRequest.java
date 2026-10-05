package com.bgroceries.sla.dto;

import com.bgroceries.sla.entity.Role;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Payload used by an Administrator to edit an existing user account.
 * Password changes are handled separately via PUT /api/users/{id}/password.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminUpdateUserRequest {

    @NotBlank(message = "Full name is required")
    private String fullName;

    @NotBlank(message = "Email is required")
    private String email;

    private String phoneNumber;

    private Role role;

    private String department;

    private String sessionTimeout;

    private Boolean active;
}
