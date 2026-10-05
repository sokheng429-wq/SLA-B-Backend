package com.bgroceries.sla.service;

import com.bgroceries.sla.dto.AdminCreateUserRequest;
import com.bgroceries.sla.dto.AdminUpdateUserRequest;
import com.bgroceries.sla.dto.UserDto;

import java.util.List;

public interface UserService {

    List<UserDto> getAllUsers();

    UserDto getUserById(Long id);

    UserDto createUser(AdminCreateUserRequest request);

    UserDto updateUser(Long id, AdminUpdateUserRequest request, String currentUsername);

    UserDto toggleUserStatus(Long id, String currentUsername);

    UserDto resetPasswordByAdmin(Long id, String newTemporaryPassword);

    UserDto adminChangePassword(Long id, String newPassword, boolean forceResetOnLogin);

    void deleteUser(Long id, String currentUsername);
}
