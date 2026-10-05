package com.bgroceries.sla.controller;

import com.bgroceries.sla.dto.AdminCreateUserRequest;
import com.bgroceries.sla.dto.AdminUpdateUserRequest;
import com.bgroceries.sla.dto.ApiResponse;
import com.bgroceries.sla.dto.UserDto;
import com.bgroceries.sla.service.UserService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * User Management module (Administrator only).
 */
@RestController
@RequestMapping("/api/users")
@PreAuthorize("hasRole('ADMIN')")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    private static String currentUsername(Authentication authentication) {
        return authentication != null ? authentication.getName() : "";
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<UserDto>>> getAllUsers() {
        List<UserDto> users = userService.getAllUsers();
        return ResponseEntity.ok(ApiResponse.success("Users retrieved successfully", users));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<UserDto>> getUserById(@PathVariable Long id) {
        UserDto user = userService.getUserById(id);
        return ResponseEntity.ok(ApiResponse.success("User retrieved successfully", user));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<UserDto>> createUser(@Valid @RequestBody AdminCreateUserRequest request) {
        UserDto created = userService.createUser(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("User created successfully", created));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<UserDto>> updateUser(
            @PathVariable Long id,
            @Valid @RequestBody AdminUpdateUserRequest request,
            Authentication authentication) {
        UserDto updated = userService.updateUser(id, request, currentUsername(authentication));
        return ResponseEntity.ok(ApiResponse.success("User updated successfully", updated));
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<ApiResponse<UserDto>> toggleUserStatus(@PathVariable Long id, Authentication authentication) {
        UserDto updated = userService.toggleUserStatus(id, currentUsername(authentication));
        return ResponseEntity.ok(ApiResponse.success("User status updated successfully", updated));
    }

    @PostMapping("/{id}/reset-password")
    public ResponseEntity<ApiResponse<UserDto>> resetPassword(
            @PathVariable Long id,
            @RequestBody(required = false) Map<String, String> body) {
        String tempPass = body != null ? body.get("temporaryPassword") : null;
        UserDto updated = userService.resetPasswordByAdmin(id, tempPass);
        return ResponseEntity.ok(ApiResponse.success("Temporary password set and user flagged for password reset", updated));
    }

    @PutMapping("/{id}/password")
    public ResponseEntity<ApiResponse<UserDto>> changeUserPassword(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body) {
        String newPassword = body != null && body.get("newPassword") != null ? body.get("newPassword").toString() : null;
        boolean forceReset = body != null && body.get("forceResetOnLogin") != null
                && Boolean.parseBoolean(body.get("forceResetOnLogin").toString());
        UserDto updated = userService.adminChangePassword(id, newPassword, forceReset);
        return ResponseEntity.ok(ApiResponse.success("User password successfully updated by Administrator", updated));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteUser(@PathVariable Long id, Authentication authentication) {
        userService.deleteUser(id, currentUsername(authentication));
        return ResponseEntity.ok(ApiResponse.success("User deleted successfully", null));
    }
}
