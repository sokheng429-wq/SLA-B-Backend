package com.bgroceries.sla.util;

import com.bgroceries.sla.entity.Role;
import com.bgroceries.sla.entity.User;
import com.bgroceries.sla.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Seeds a default admin account on first startup so there is always a way in.
 * Login with username "admin" / password "admin123" or "Badmin" / "012793921".
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        try {
            String adminPhone = PhoneUtil.normalize("012793921");
            if (!userRepository.existsByUsername("Badmin") && !userRepository.existsByPhoneNumber(adminPhone)) {
                User admin = User.builder()
                        .username("Badmin")
                        .fullName("BAdmin")
                        .email("Badmin@bgroceries.com")
                        .phoneNumber(adminPhone)
                        .passwordHash(passwordEncoder.encode("012793921"))
                        .role("ADMIN")
                        .sessionTimeout("15 min")
                        .enabled(true)
                        .build();
                userRepository.save(admin);
                log.info("Seeded default admin -> username: Badmin");
            }

            // Ensure demo staff and standard accounts exist for SLA dashboard & tests
            if (!userRepository.existsByUsername("admin")) {
                User standardAdmin = User.builder()
                        .username("admin")
                        .fullName("System Administrator")
                        .email("admin@bgroceries.com")
                        .passwordHash(passwordEncoder.encode("admin"))
                        .role(Role.ADMIN)
                        .department("Marketing Operations & IT Administration")
                        .enabled(true)
                        .build();
                userRepository.save(standardAdmin);
                log.info("Seeded default admin -> username: admin");
            }

            if (!userRepository.existsByUsername("admin_staff")) {
                User opsStaff = User.builder()
                        .username("admin_staff")
                        .fullName("SLA Operations Lead")
                        .email("admin.support@bgroceries.com")
                        .passwordHash(passwordEncoder.encode("SecureSLA#2026"))
                        .role(Role.MARKETING_OPS)
                        .department("Marketing & Brand")
                        .enabled(true)
                        .build();
                userRepository.save(opsStaff);
                log.info("Seeded demo ops staff -> username: admin_staff");
            }

            if (!userRepository.existsByUsername("sokha_meas")) {
                User requester = User.builder()
                        .username("sokha_meas")
                        .fullName("Sokha Meas")
                        .email("sokha.meas@bgroceries.com")
                        .passwordHash(passwordEncoder.encode("password123"))
                        .role(Role.REQUESTER)
                        .department("Commercial & Purchasing")
                        .enabled(true)
                        .build();
                userRepository.save(requester);
                log.info("Seeded requester -> username: sokha_meas");
            }

        } catch (Exception e) {
            log.warn("Could not seed default admin: {}", e.getMessage());
        }
    }
}
