package com.bgroceries.sla.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuthResponse {

    @Builder.Default
    private int status = 200;
    private String message;
    private String token;
    @Builder.Default
    private String tokenType = "Bearer";
    private long expiresIn;
    private UserDto user;

    public AuthResponse(String message, String token, long expiresIn, UserDto user) {
        this.status = 200;
        this.message = message;
        this.token = token;
        this.tokenType = "Bearer";
        this.expiresIn = expiresIn;
        this.user = user;
    }
}
