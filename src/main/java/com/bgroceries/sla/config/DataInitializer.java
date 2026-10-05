package com.bgroceries.sla.config;

import com.bgroceries.sla.entity.Role;
import com.bgroceries.sla.entity.User;
import com.bgroceries.sla.repository.UserRepository;
import com.bgroceries.sla.util.PhoneUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Seeds the single default admin account on startup so there is always a way in.
 * Login with username "Heng" / password "012793921".
 * All other accounts must be created by the Admin from the "Manage Users" module.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {

    public static final String DEFAULT_ADMIN_USERNAME = "Heng";
    private static final String DEFAULT_ADMIN_PASSWORD = "012793921";

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        try {
            User existing = userRepository.findByUsernameOrEmailIgnoreCase(DEFAULT_ADMIN_USERNAME).orElse(null);

            if (existing != null) {
                // Make sure the default admin can always sign in (active + ADMIN role)
                boolean changed = false;
                if (!existing.isActive()) {
                    existing.setActive(true);
                    changed = true;
                }
                if (existing.getRole() != Role.ADMIN) {
                    existing.setRole(Role.ADMIN);
                    changed = true;
                }
                if (changed) {
                    userRepository.save(existing);
                    log.info("Default admin '{}' re-activated with ADMIN role", DEFAULT_ADMIN_USERNAME);
                }
                return;
            }

            String adminPhone = PhoneUtil.normalize(DEFAULT_ADMIN_PASSWORD);
            User admin = User.builder()
                    .username(DEFAULT_ADMIN_USERNAME)
                    .fullName("Heng")
                    .email("heng@bgroceries.com")
                    .phoneNumber(userRepository.existsByPhoneNumber(adminPhone) ? null : adminPhone)
                    .passwordHash(passwordEncoder.encode(DEFAULT_ADMIN_PASSWORD))
                    .role(Role.ADMIN)
                    .department("Information Technology")
                    .sessionTimeout("60 min")
                    .enabled(true)
                    .mustChangePassword(false)
                    .build();
            userRepository.save(admin);
            log.info("Seeded default admin -> username: {}", DEFAULT_ADMIN_USERNAME);
        } catch (Exception e) {
            log.warn("Could not seed default admin: {}", e.getMessage());
        }
    }
}
