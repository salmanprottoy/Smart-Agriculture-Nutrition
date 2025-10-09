package com.agriculture.nutrition.filter;

import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerResponseContext;
import javax.ws.rs.container.ContainerResponseFilter;
import javax.ws.rs.ext.Provider;
import java.io.IOException;

/**
 * CORS Filter to allow cross-origin requests
 * Necessary for Swagger UI to fetch OpenAPI specification
 */
@Provider
public class CORSFilter implements ContainerResponseFilter {

    @Override
    public void filter(ContainerRequestContext requestContext, 
                      ContainerResponseContext responseContext) throws IOException {
        
        // Allow all origins (for development - restrict in production)
        responseContext.getHeaders().add("Access-Control-Allow-Origin", "*");
        
        // Allow common HTTP methods
        responseContext.getHeaders().add("Access-Control-Allow-Methods", 
            "GET, POST, PUT, DELETE, OPTIONS, HEAD");
        
        // Allow common headers
        responseContext.getHeaders().add("Access-Control-Allow-Headers",
            "origin, content-type, accept, authorization, x-requested-with");
        
        // Allow credentials
        responseContext.getHeaders().add("Access-Control-Allow-Credentials", "true");
        
        // Cache preflight response for 1 hour
        responseContext.getHeaders().add("Access-Control-Max-Age", "3600");
    }
}
