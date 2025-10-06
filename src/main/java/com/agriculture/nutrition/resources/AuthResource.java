package com.agriculture.nutrition.resources;

import com.agriculture.nutrition.model.User;
import com.agriculture.nutrition.service.JwtService;
import com.agriculture.nutrition.service.UserService;
import io.jsonwebtoken.Jwts;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;

import javax.annotation.security.RolesAllowed;
import javax.crypto.SecretKey;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import java.time.Instant;
import java.util.Collection;
import java.util.Date;

@Path("/auth")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Authentication", description = "User registration and login endpoints")
public class AuthResource {

    private final UserService userService = new UserService();
    private final JwtService jwtService = new JwtService();

    public static class RegistrationRequest {
        public String username;
        public String password;
        public String email;
    }

    @POST
    @Path("/register")
    @Operation(summary = "Register a new user")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "User successfully registered"),
            @ApiResponse(responseCode = "400", description = "Invalid input"),
            @ApiResponse(responseCode = "409", description = "Username already exists")
    })
    public Response registerUser(RegistrationRequest request) {
        if (request.username == null || request.username.isBlank() ||
                request.password == null || request.password.isBlank()) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity("{\"error\":\"Username and password are required\"}")
                    .build();
        }

        try {
            User user = userService.registerUser(request.username, request.password, request.email);
            return Response.status(Response.Status.CREATED)
                    .entity("{\"message\":\"User registered successfully\", \"id\":" + user.getId() + "}")
                    .build();
        } catch (Exception e) {
            return Response.status(Response.Status.CONFLICT)
                    .entity("{\"error\":\"Username already exists or invalid data\", \"exception\":\"" + e.getMessage() + "\"}")
                    .build();
        }
    }

    @GET
    @Path("/users")
    @RolesAllowed("ADMIN")
    @Operation(summary = "List all registered users")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "List of users retrieved successfully"),
            @ApiResponse(responseCode = "403", description = "Access forbidden")
    })
    public Response listUsers() {
        try {
            Collection<User> users = userService.getAllUsers(); // You need to add this method
            return Response.ok(users).build();
        } catch (Exception e) {
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("{\"error\":\"Failed to retrieve users\", \"exception\":\"" + e.getMessage() + "\"}")
                    .build();
        }
    }

    public static class LoginRequest {
        public String username;
        public String password;
    }

    @POST
    @Path("/login")
    @Operation(summary = "Login and receive JWT")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Login success"),
            @ApiResponse(responseCode = "401", description = "Invalid credentials")
    })
    public Response login(LoginRequest req) {
        if (req == null || req.username == null || req.password == null) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity("{\"error\":\"username and password required\"}")
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }

        try {
            User user = userService.getUserByUsername(req.username);
            if (user == null || !org.mindrot.jbcrypt.BCrypt.checkpw(req.password, user.getPasswordHash())) {
                return Response.status(Response.Status.UNAUTHORIZED)
                        .entity("{\"error\":\"Invalid username or password\"}")
                        .type(MediaType.APPLICATION_JSON)
                        .build();
            }

            String token = jwtService.generateToken(user);

            return Response.ok("{\"token\":\"" + token + "\"}")
                    .type(MediaType.APPLICATION_JSON)
                    .build();

        } catch (Exception e) {
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("{\"error\":\"login failed\", \"exception\":\"" + e.getMessage() + "\"}")
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }
}

