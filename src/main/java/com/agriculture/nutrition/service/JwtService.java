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
        // First try to get from system environment variables (for production/Railway)
        String secret = System.getenv(SECRET_ENV);
        
        // If not found in environment, try to load from .env file (for local development)
        if (secret == null || secret.isBlank()) {
            try {
                Dotenv dotenv = Dotenv.load();
                secret = dotenv.get(SECRET_ENV);
            } catch (Exception e) {
                // .env file not found, continue with environment variable check
                System.out.println("Note: .env file not found, using system environment variables");
            }
        }

        if (secret == null || secret.isBlank()) {
            // Use a default key for development if JWT_SECRET is not set
            System.out.println("WARNING: JWT_SECRET not set, using default development key");
            secret = "dGhpcy1pcy1hLWRlZmF1bHQtZGV2ZWxvcG1lbnQta2V5LWZvci10ZXN0aW5nLW9ubHk="; // base64 encoded default key
        }

        try {
            // Check if it's base64 encoded
            return Keys.hmacShaKeyFor(Base64.getDecoder().decode(secret));
        } catch (IllegalArgumentException e) {
            // If not base64, use the string directly (but ensure it's at least 256 bits)
            byte[] keyBytes = secret.getBytes();
            if (keyBytes.length < 32) {
                // Pad the key to 32 bytes if it's too short
                byte[] paddedKey = new byte[32];
                System.arraycopy(keyBytes, 0, paddedKey, 0, Math.min(keyBytes.length, 32));
                return Keys.hmacShaKeyFor(paddedKey);
            }
            return Keys.hmacShaKeyFor(keyBytes);
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
