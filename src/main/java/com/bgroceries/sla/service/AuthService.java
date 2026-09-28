package com.bgroceries.sla.service;

import com.bgroceries.sla.dto.AuthRequest;
import com.bgroceries.sla.dto.AuthResponse;
import com.bgroceries.sla.dto.RegisterRequest;
import com.bgroceries.sla.dto.UserDto;

public interface AuthService {

    AuthResponse login(AuthRequest request);

    AuthResponse register(RegisterRequest request);

    UserDto getCurrentUser(String username);
}
