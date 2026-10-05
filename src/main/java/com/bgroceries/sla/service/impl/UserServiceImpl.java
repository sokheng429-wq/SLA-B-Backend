package com.bgroceries.sla.service.impl;

import com.bgroceries.sla.dto.AdminCreateUserRequest;
import com.bgroceries.sla.dto.AdminUpdateUserRequest;
import com.bgroceries.sla.dto.UserDto;
import com.bgroceries.sla.entity.Role;
import com.bgroceries.sla.entity.User;
import com.bgroceries.sla.exception.BadRequestException;
import com.bgroceries.sla.exception.ResourceNotFoundException;
import com.bgroceries.sla.repository.UserRepository;
import com.bgroceries.sla.service.UserService;
import com.bgroceries.sla.util.PhoneUtil;
import org.springframework.data.domain.Sort;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserServiceImpl(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional(readOnly = true)
    public List<UserDto> getAllUsers() {
        return userRepository.findAll(Sort.by(Sort.Direction.ASC, "id"))
                .stream()
                .map(UserDto::fromEntity)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public UserDto getUserById(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + id));
        return UserDto.fromEntity(user);
    }

    @Override
    @Transactional
    public UserDto createUser(AdminCreateUserRequest request) {
        String username = request.getUsername().trim();
        if (request.getPassword() == null || request.getPassword().trim().length() < 6) {
            throw new BadRequestException("Password must be at least 6 characters long");
        }
        if (userRepository.existsByUsernameIgnoreCase(username)) {
            throw new BadRequestException("Username '" + username + "' is already taken");
        }

        String email = request.getEmail() != null && !request.getEmail().trim().isEmpty()
                ? request.getEmail().trim().toLowerCase()
                : username.toLowerCase() + "@bgroceries.com";

        if (userRepository.existsByEmailIgnoreCase(email)) {
            throw new BadRequestException("Email '" + email + "' is already registered");
        }

        String phone = null;
        if (request.getPhoneNumber() != null && !request.getPhoneNumber().trim().isEmpty()) {
            phone = PhoneUtil.normalize(request.getPhoneNumber().trim());
            if (userRepository.existsByPhoneNumber(phone)) {
                throw new BadRequestException("Phone number '" + request.getPhoneNumber() + "' is already in use");
            }
        }

        Role role = request.getRole() != null ? request.getRole() : Role.REQUESTER;
        String department = request.getDepartment() != null && !request.getDepartment().trim().isEmpty()
                ? request.getDepartment().trim()
                : "Store Operations";

        User user = User.builder()
                .username(username)
                .email(email)
                .phoneNumber(phone)
                .fullName(request.getFullName().trim())
                .passwordHash(passwordEncoder.encode(request.getPassword().trim()))
                .role(role)
                .department(department)
                .sessionTimeout(request.getSessionTimeout() != null ? request.getSessionTimeout() : "15 min")
                .enabled(true)
                .mustChangePassword(request.isMustChangePassword()) // When created by Admin -> true
                .build();

        User saved = userRepository.save(user);
        return UserDto.fromEntity(saved);
    }

    @Override
    @Transactional
    public UserDto updateUser(Long id, AdminUpdateUserRequest request, String currentUsername) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + id));

        boolean isSelf = user.getUsername().equalsIgnoreCase(currentUsername);

        String email = request.getEmail().trim().toLowerCase();
        if (userRepository.existsByEmailIgnoreCaseAndIdNot(email, id)) {
            throw new BadRequestException("Email '" + email + "' is already registered");
        }

        String phone = null;
        if (request.getPhoneNumber() != null && !request.getPhoneNumber().trim().isEmpty()) {
            phone = PhoneUtil.normalize(request.getPhoneNumber().trim());
            if (userRepository.existsByPhoneNumberAndIdNot(phone, id)) {
                throw new BadRequestException("Phone number '" + request.getPhoneNumber() + "' is already in use");
            }
        }

        if (request.getRole() != null && request.getRole() != user.getRole()) {
            if (isSelf && user.getRole() == Role.ADMIN) {
                throw new BadRequestException("You cannot remove the ADMIN role from your own account");
            }
            user.setRole(request.getRole());
        }

        if (request.getActive() != null && request.getActive() != user.isActive()) {
            if (isSelf && !request.getActive()) {
                throw new BadRequestException("You cannot deactivate your own account");
            }
            user.setActive(request.getActive());
        }

        user.setFullName(request.getFullName().trim());
        user.setEmail(email);
        user.setPhoneNumber(phone);
        if (request.getDepartment() != null && !request.getDepartment().trim().isEmpty()) {
            user.setDepartment(request.getDepartment().trim());
        }
        if (request.getSessionTimeout() != null && !request.getSessionTimeout().trim().isEmpty()) {
            user.setSessionTimeout(request.getSessionTimeout().trim());
        }

        User updated = userRepository.save(user);
        return UserDto.fromEntity(updated);
    }

    @Override
    @Transactional
    public UserDto toggleUserStatus(Long id, String currentUsername) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + id));

        if (user.getUsername().equalsIgnoreCase(currentUsername) && user.isActive()) {
            throw new BadRequestException("You cannot deactivate your own account");
        }

        user.setEnabled(!user.isActive());
        User updated = userRepository.save(user);
        return UserDto.fromEntity(updated);
    }

    @Override
    @Transactional
    public UserDto resetPasswordByAdmin(Long id, String newTemporaryPassword) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + id));

        String tempPass = (newTemporaryPassword != null && !newTemporaryPassword.trim().isEmpty())
                ? newTemporaryPassword.trim()
                : "Bgroceries#" + (int)(Math.random() * 9000 + 1000);

        user.setPasswordHash(passwordEncoder.encode(tempPass));
        user.setMustChangePassword(true); // User must reset upon login!
        User updated = userRepository.save(user);
        return UserDto.fromEntity(updated);
    }

    @Override
    @Transactional
    public UserDto adminChangePassword(Long id, String newPassword, boolean forceResetOnLogin) {
        if (newPassword == null || newPassword.trim().length() < 6) {
            throw new BadRequestException("Password must be at least 6 characters long");
        }
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + id));

        user.setPasswordHash(passwordEncoder.encode(newPassword.trim()));
        user.setMustChangePassword(forceResetOnLogin);
        User updated = userRepository.save(user);
        return UserDto.fromEntity(updated);
    }

    @Override
    @Transactional
    public void deleteUser(Long id, String currentUsername) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + id));

        if (user.getUsername().equalsIgnoreCase(currentUsername)) {
            throw new BadRequestException("You cannot delete your own account");
        }

        userRepository.delete(user);
    }
}
