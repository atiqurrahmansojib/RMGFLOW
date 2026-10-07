package com.rmgflow.config;

import com.rmgflow.security.JwtAuthenticationFilter;
import jakarta.servlet.DispatcherType;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.argon2.Argon2PasswordEncoder;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.HttpStatusEntryPoint;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

/**
 * Document 15: backend is the sole authority for authentication/authorization.
 * Stateless (no server session cookie) — every request authenticates via the
 * JWT access token (Doc 15.1/ADR-04).
 */
@Configuration
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable()) // stateless JWT API, no cookie-based session to protect
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        // Let the container's error dispatch render the real status; without
                        // this every 400/404/500 reached the client as an empty 403.
                        .dispatcherTypeMatchers(DispatcherType.ERROR).permitAll()
                        .requestMatchers("/api/v1/auth/**", "/actuator/health").permitAll()
                        // Document 15.4: the download link carries its own short-lived signed
                        // token (verified in AttachmentService/AttachmentDownloadTokenService) —
                        // that token, not a Bearer access token, IS the credential for this one
                        // endpoint, matching how a real S3 pre-signed URL works.
                        .requestMatchers("/api/v1/attachments/download").permitAll()
                        .anyRequest().authenticated())
                // Missing/expired/invalid access token -> 401 (not the default 403), so the
                // mobile client knows to refresh its token instead of reporting "no permission".
                .exceptionHandling(ex -> ex.authenticationEntryPoint(new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED)))
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    /** Document 15.1 recommendation: Argon2id over bcrypt — stronger modern default. */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return Argon2PasswordEncoder.defaultsForSpringSecurity_v5_8();
    }
}
