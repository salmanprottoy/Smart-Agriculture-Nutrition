package com.agriculture.nutrition.auth;

import com.agriculture.nutrition.model.User;

import javax.annotation.Priority;
import javax.annotation.security.RolesAllowed;
import javax.ws.rs.Priorities;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerRequestFilter;
import javax.ws.rs.container.ResourceInfo;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.ext.Provider;
import java.io.IOException;
import java.util.Arrays;

@Provider
@Secured
@Priority(Priorities.AUTHORIZATION)
public class RoleFilter implements ContainerRequestFilter {

    @Context
    private ResourceInfo resourceInfo;

    @Override
    public void filter(ContainerRequestContext requestContext) throws IOException {
        User user = (User) requestContext.getProperty("authenticatedUser");

        if (user == null) {
            requestContext.abortWith(
                    Response.status(Response.Status.UNAUTHORIZED)
                            .type(MediaType.APPLICATION_JSON)
                            .entity("{\"error\":\"User not authenticated\"}")
                            .build()
            );
            return;
        }

        RolesAllowed rolesAnnotation = resourceInfo.getResourceMethod().getAnnotation(RolesAllowed.class);
        if (rolesAnnotation == null) {
            rolesAnnotation = resourceInfo.getResourceClass().getAnnotation(RolesAllowed.class);
        }

        if (rolesAnnotation != null) {
            boolean allowed = Arrays.stream(rolesAnnotation.value())
                    .anyMatch(user.getRoles()::contains);

            if (!allowed) {
                requestContext.abortWith(
                        Response.status(Response.Status.FORBIDDEN)
                                .type(MediaType.APPLICATION_JSON)
                                .entity("{\"error\":\"You don’t have permission to access this resource\"}")
                                .build()
                );
            }
        }
    }
}