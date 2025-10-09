package com.agriculture.nutrition.resources;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

@Path("/swagger")
public class SwaggerUIResource {

    @GET
    @Produces(MediaType.TEXT_HTML)
    public Response getSwaggerUI() {
        String html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <title>Smart Agriculture Nutrition - Swagger UI</title>
            <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui.css">
        </head>
        <body>
            <div id="swagger-ui"></div>
            <script src="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui-bundle.js"></script>
            <script src="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui-standalone-preset.js"></script>
            <script>
                window.onload = function() {
                    // Get the current URL base
                    const baseUrl = window.location.protocol + '//' + window.location.host;
                    const apiUrl = baseUrl + '/SmartAgricultureNutrition/api/v1/openapi.json';
                    
                    SwaggerUIBundle({
                        url: apiUrl,
                        dom_id: '#swagger-ui',
                        presets: [SwaggerUIBundle.presets.apis, SwaggerUIStandalonePreset],
                        layout: "StandaloneLayout",
                        validatorUrl: null,
                        tryItOutEnabled: true
                    });
                };
            </script>
        </body>
        </html>
        """;

        return Response.ok(html).build();
    }
}
