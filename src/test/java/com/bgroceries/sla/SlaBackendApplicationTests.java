package com.bgroceries.sla;

import com.bgroceries.sla.dto.AuthRequest;
import com.bgroceries.sla.dto.AuthResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class SlaBackendApplicationTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void contextLoads() {
    }

    @Test
    void testLoginSuccess_Admin() throws Exception {
        AuthRequest loginRequest = new AuthRequest("admin", "admin");

        MvcResult result = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.user.username").value("admin"))
                .andExpect(jsonPath("$.user.role").value("ADMIN"))
                .andReturn();

        String responseString = result.getResponse().getContentAsString();
        AuthResponse authResponse = objectMapper.readValue(responseString, AuthResponse.class);
        assertNotNull(authResponse.getToken());

        // Test accessing /api/auth/me with Bearer token
        mockMvc.perform(get("/api/auth/me")
                        .header("Authorization", "Bearer " + authResponse.getToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.username").value("admin"))
                .andExpect(jsonPath("$.data.email").value("admin@bgroceries.com"));
    }

    @Test
    void testLoginSuccess_Badmin() throws Exception {
        AuthRequest loginRequest = new AuthRequest("Badmin", "012793921");

        MvcResult result = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.user.username").value("Badmin"))
                .andExpect(jsonPath("$.user.role").value("ADMIN"))
                .andExpect(jsonPath("$.user.phoneNumber").value("+85512793921"))
                .andReturn();

        String responseString = result.getResponse().getContentAsString();
        AuthResponse authResponse = objectMapper.readValue(responseString, AuthResponse.class);
        assertNotNull(authResponse.getToken());
    }

    @Test
    void testLoginSuccess_OpsStaff_DemoCredentials() throws Exception {
        // Test with the demo credentials used by React frontend: admin_staff / SecureSLA#2026
        AuthRequest loginRequest = new AuthRequest("admin_staff", "SecureSLA#2026");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.user.username").value("admin_staff"))
                .andExpect(jsonPath("$.user.role").value("MARKETING_OPS"));
    }

    @Test
    void testLoginFailure_InvalidPassword() throws Exception {
        AuthRequest badRequest = new AuthRequest("admin", "wrong_password");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(badRequest)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Invalid username/email or password"));
    }

    @Test
    void testHealthEndpoint_PublicAccess() throws Exception {
        mockMvc.perform(get("/api/auth/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("UP"));
    }
}
