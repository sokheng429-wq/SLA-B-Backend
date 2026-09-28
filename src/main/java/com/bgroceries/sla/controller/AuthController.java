package com.bgroceries.sla.controller;

import com.bgroceries.sla.dto.ApiResponse;
import com.bgroceries.sla.dto.AuthRequest;
import com.bgroceries.sla.dto.AuthResponse;
import com.bgroceries.sla.dto.RegisterRequest;
import com.bgroceries.sla.dto.UserDto;
import com.bgroceries.sla.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody AuthRequest request) {
        AuthResponse response = authService.login(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        AuthResponse response = authService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserDto>> getCurrentUser(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error(HttpStatus.UNAUTHORIZED.value(), "Not authenticated"));
        }
        UserDto userDto = authService.getCurrentUser(authentication.getName());
        return ResponseEntity.ok(ApiResponse.success("User profile retrieved successfully", userDto));
    }

    @GetMapping("/health")
    public ResponseEntity<ApiResponse<Map<String, Object>>> healthCheck() {
        Map<String, Object> details = new HashMap<>();
        details.put("service", "Marketing SLA Tracker Backend API");
        details.put("status", "UP");
        details.put("database", "PostgreSQL");
        details.put("version", "1.0.0");
        return ResponseEntity.ok(ApiResponse.success("SLA Backend is operational", details));
    }
}
