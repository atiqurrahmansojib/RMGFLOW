package com.rmgflow.security;

import com.rmgflow.identity.repository.RoleRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

/**
 * Document 11.3/15.1: resolves the JWT access token into an AuthenticatedUser principal.
 * This filter establishes IDENTITY (who, which roles — from the signed token) and then
 * resolves those roles to permission codes via the DB (Document 5.3: the token itself
 * never carries permissions, since role-to-permission mappings can change between
 * token issuance and use — e.g. a Super Admin revoking a role's permission must take
 * effect immediately, not after the holder's 15-minute access token expires).
 * @PreAuthorize and service-layer assignment checks make the actual authorization
 * decision; this filter only supplies the authorities they check against.
 */
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final RoleRepository roleRepository;

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request,
                                     @NonNull HttpServletResponse response,
                                     @NonNull FilterChain filterChain) throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            try {
                AuthenticatedUser user = jwtService.parseAccessToken(header.substring(7));

                List<GrantedAuthority> authorities = new ArrayList<>();
                user.roles().forEach(role -> authorities.add(new SimpleGrantedAuthority("ROLE_" + role)));
                roleRepository.findPermissionCodesByRoleNames(user.roles())
                        .forEach(code -> authorities.add(new SimpleGrantedAuthority(code)));

                var authentication = new UsernamePasswordAuthenticationToken(user, null, authorities);
                SecurityContextHolder.getContext().setAuthentication(authentication);
            } catch (Exception ex) {
                SecurityContextHolder.clearContext();
            }
        }
        filterChain.doFilter(request, response);
    }
}
