package com.agriculture.nutrition.auth;

import com.agriculture.nutrition.model.User;
import com.agriculture.nutrition.service.JwtService;
import com.agriculture.nutrition.service.UserService;
import org.mindrot.jbcrypt.BCrypt;

import javax.annotation.Priority;
import javax.ws.rs.Priorities;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerRequestFilter;
import javax.ws.rs.container.ResourceInfo;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.ext.Provider;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.StringTokenizer;

@Provider
@Secured
@Priority(Priorities.AUTHENTICATION)
public class AuthFilter implements ContainerRequestFilter {

    private final UserService userService = new UserService();
    private final JwtService jwtService = new JwtService();

    @Context
    private ResourceInfo resourceInfo;

    @Override
    public void filter(ContainerRequestContext requestContext) throws IOException {
        String authHeader = requestContext.getHeaderString(HttpHeaders.AUTHORIZATION);

        if (authHeader == null || authHeader.isBlank()) {
            abortWithUnauthorized(requestContext, "Missing Authorization header");
            return;
        }

        try {
            if (authHeader.startsWith("Basic ")) {
                handleBasicAuth(authHeader, requestContext);
            } else if (authHeader.startsWith("Bearer ")) {
                handleJwtAuth(authHeader, requestContext);
            } else {
                abortWithUnauthorized(requestContext, "Unsupported Authorization type");
            }
        } catch (Exception e) {
            abortWithUnauthorized(requestContext, "Authentication failed: " + e.getMessage());
        }
    }

    private void handleBasicAuth(String authHeader, ContainerRequestContext requestContext) {
        try {
            String encodedCredentials = authHeader.substring("Basic ".length()).trim();
            String decoded = new String(Base64.getDecoder().decode(encodedCredentials), StandardCharsets.UTF_8);
            StringTokenizer tokenizer = new StringTokenizer(decoded, ":");
            String username = tokenizer.nextToken();
            String password = tokenizer.nextToken();

            User user = userService.getUserByUsername(username);
            if (user == null || !BCrypt.checkpw(password, user.getPasswordHash())) {
                abortWithUnauthorized(requestContext, "Invalid username or password");
                return;
            }

            requestContext.setProperty("authenticatedUser", user);

        } catch (Exception e) {
            abortWithUnauthorized(requestContext, "Invalid Basic authentication format: " + e.getMessage());
        }
    }

    private void handleJwtAuth(String authHeader, ContainerRequestContext requestContext) {
        try {
            String token = authHeader.substring("Bearer ".length()).trim();
            User user = jwtService.validateToken(token);
            requestContext.setProperty("authenticatedUser", user);
        } catch (Exception e) {
            abortWithUnauthorized(requestContext, "Invalid JWT: " + e.getMessage());
        }
    }

    private void abortWithUnauthorized(ContainerRequestContext requestContext, String message) {
        requestContext.abortWith(
                Response.status(Response.Status.UNAUTHORIZED)
                        .type(MediaType.APPLICATION_JSON)
                        .entity("{\"error\":\"" + message.replace("\"", "\\\"") + "\"}")
                        .build()
        );
    }
}
