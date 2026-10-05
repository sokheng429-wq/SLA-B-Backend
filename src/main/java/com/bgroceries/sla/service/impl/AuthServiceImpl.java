package com.bgroceries.sla.service.impl;

import com.bgroceries.sla.dto.AuthRequest;
import com.bgroceries.sla.dto.AuthResponse;
import com.bgroceries.sla.dto.ChangePasswordRequest;
import com.bgroceries.sla.dto.RegisterRequest;
import com.bgroceries.sla.dto.UserDto;
import com.bgroceries.sla.entity.Role;
import com.bgroceries.sla.entity.User;
import com.bgroceries.sla.exception.BadRequestException;
import com.bgroceries.sla.exception.ResourceNotFoundException;
import com.bgroceries.sla.repository.UserRepository;
import com.bgroceries.sla.security.JwtTokenProvider;
import com.bgroceries.sla.service.AuthService;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtTokenProvider jwtTokenProvider;

    public AuthServiceImpl(UserRepository userRepository,
                           PasswordEncoder passwordEncoder,
                           AuthenticationManager authenticationManager,
                           JwtTokenProvider jwtTokenProvider) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.authenticationManager = authenticationManager;
        this.jwtTokenProvider = jwtTokenProvider;
    }

    @Override
    @Transactional(readOnly = true)
    public AuthResponse login(AuthRequest request) {
        // Find user by either username or email
        User user = userRepository.findByUsernameOrEmailIgnoreCase(request.getUsername())
                .orElseThrow(() -> new BadCredentialsException("Invalid username or password"));

        if (!user.isActive()) {
            throw new BadRequestException("User account is deactivated. Please contact your system administrator.");
        }

        // Authenticate with Spring Security
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(user.getUsername(), request.getPassword())
            );
        } catch (BadCredentialsException ex) {
            throw new BadCredentialsException("Invalid username or password");
        }

        // Generate JWT
        String token = jwtTokenProvider.generateToken(user);
        long expiresInSeconds = jwtTokenProvider.getExpirationMs() / 1000;

        return new AuthResponse("Login successful", token, expiresInSeconds, UserDto.fromEntity(user));
    }

    @Override
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String username = request.getUsername().trim();
        String email = request.getEmail().trim().toLowerCase();

        if (userRepository.existsByUsernameIgnoreCase(username)) {
            throw new BadRequestException("Username '" + username + "' is already taken");
        }

        if (userRepository.existsByEmailIgnoreCase(email)) {
            throw new BadRequestException("Email '" + email + "' is already registered");
        }

        Role role = request.getRole() != null ? request.getRole() : Role.REQUESTER;
        String department = request.getDepartment() != null ? request.getDepartment() : "General";

        User user = new User(
                username,
                email,
                passwordEncoder.encode(request.getPassword()),
                request.getFullName(),
                role,
                department
        );

        User savedUser = userRepository.save(user);
        String token = jwtTokenProvider.generateToken(savedUser);
        long expiresInSeconds = jwtTokenProvider.getExpirationMs() / 1000;

        return new AuthResponse("Registration successful", token, expiresInSeconds, UserDto.fromEntity(savedUser));
    }

    @Override
    @Transactional(readOnly = true)
    public UserDto getCurrentUser(String username) {
        User user = userRepository.findByUsernameOrEmailIgnoreCase(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with identifier: " + username));

        return UserDto.fromEntity(user);
    }

    @Override
    @Transactional
    public AuthResponse changePassword(String username, ChangePasswordRequest request) {
        if (request.getNewPassword() == null || request.getNewPassword().trim().length() < 6) {
            throw new BadRequestException("New password must be at least 6 characters long");
        }

        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new BadRequestException("New password and confirm password do not match");
        }

        User user = userRepository.findByUsernameOrEmailIgnoreCase(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + username));

        // Update password and clear mustChangePassword
        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword().trim()));
        user.setMustChangePassword(false);
        User savedUser = userRepository.save(user);

        // Generate fresh JWT token
        String token = jwtTokenProvider.generateToken(savedUser);
        long expiresInSeconds = jwtTokenProvider.getExpirationMs() / 1000;

        return new AuthResponse("Password successfully updated", token, expiresInSeconds, UserDto.fromEntity(savedUser));
    }
}
