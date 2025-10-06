package com.agriculture.nutrition.service;

import com.agriculture.nutrition.model.User;
import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import io.github.cdimascio.dotenv.Dotenv;

import javax.crypto.SecretKey;
import java.time.Instant;
import java.util.*;

public class JwtService {

    private static final String SECRET_ENV = "JWT_SECRET";
    private static final long EXPIRATION_MINUTES = 60;

    private final SecretKey secretKey;

    public JwtService() {
        this.secretKey = loadSecretKey();
    }

    private SecretKey loadSecretKey() {
        Dotenv dotenv = Dotenv.load();  // loads .env file and environment variables
        String base64 = dotenv.get(SECRET_ENV);

        if (base64 == null || base64.isBlank()) {
            throw new RuntimeException("JWT_SECRET environment variable is not set or is empty");
        }

        try {
            return Keys.hmacShaKeyFor(Base64.getDecoder().decode(base64));
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Invalid JWT_SECRET: must be a valid base64-encoded key", e);
        }
    }

    public String generateToken(User user) {
        Instant now = Instant.now();
        Instant exp = now.plusSeconds(EXPIRATION_MINUTES * 60);

        return Jwts.builder()
                .setSubject(user.getUsername())
                .claim("email", user.getEmail())
                .claim("roles", user.getRoles())
                .setIssuedAt(Date.from(now))
                .setExpiration(Date.from(exp))
                .signWith(secretKey)
                .compact();
    }

    public User validateToken(String token) {
        try {
            Jws<Claims> parsed = Jwts.parserBuilder()
                    .setSigningKey(secretKey)
                    .build()
                    .parseClaimsJws(token);

            Claims claims = parsed.getBody();

            String username = claims.getSubject();
            String email = claims.get("email", String.class);
            List<String> rolesList = claims.get("roles", List.class);
            Set<String> roles = rolesList == null ? Set.of() : new HashSet<>(rolesList);

            User user = new User();
            user.setUsername(username);
            user.setEmail(email);
            user.setRoles(roles);

            return user;

        } catch (ExpiredJwtException e) {
            throw new RuntimeException("JWT expired");
        } catch (JwtException e) {
            throw new RuntimeException("Invalid JWT: " + e.getMessage());
        }
    }
}
