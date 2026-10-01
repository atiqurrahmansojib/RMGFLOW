package com.rmgflow.config;

import com.rmgflow.identity.entity.Organization;
import com.rmgflow.identity.entity.Role;
import com.rmgflow.identity.entity.User;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.RoleRepository;
import com.rmgflow.identity.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Set;

/**
 * Chicken-and-egg bootstrap: the very first Super Admin cannot be created through the
 * (Super-Admin-only) /api/v1/users endpoint, so it is seeded on first startup if no
 * users exist yet. Controlled entirely by environment variables — never a hardcoded
 * credential (Document 15.6).
 */
@Component
@RequiredArgsConstructor
public class BootstrapSeeder implements ApplicationRunner {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final OrganizationRepository organizationRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (userRepository.count() > 0) {
            return;
        }

        String email = System.getenv().getOrDefault("BOOTSTRAP_ADMIN_EMAIL", "admin@rmgflow.local");
        String password = System.getenv().get("BOOTSTRAP_ADMIN_PASSWORD");
        if (password == null || password.isBlank()) {
            // No bootstrap credential supplied: skip seeding rather than ever generating
            // or hardcoding a default password (Doc 15.6). An operator must set this
            // environment variable on first deploy.
            return;
        }

        Organization organization = new Organization();
        organization.setName(System.getenv().getOrDefault("BOOTSTRAP_ORG_NAME", "Default Organization"));
        organization = organizationRepository.save(organization);

        Role superAdmin = roleRepository.findByName("SUPER_ADMIN")
                .orElseThrow(() -> new IllegalStateException("SUPER_ADMIN role missing — check V2 migration ran"));

        User admin = new User();
        admin.setOrganization(organization);
        admin.setEmail(email);
        admin.setPasswordHash(passwordEncoder.encode(password));
        admin.setFullName("Bootstrap Super Admin");
        admin.setRoles(Set.of(superAdmin));
        userRepository.save(admin);
    }
}
