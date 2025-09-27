package com.agriculture.nutrition.resources;

import io.swagger.v3.jaxrs2.integration.resources.OpenApiResource;
import io.swagger.v3.oas.annotations.Hidden;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.UriInfo;
import java.io.InputStream;

/**
 * Swagger UI Resource for serving OpenAPI documentation Provides interactive
 * API documentation interface
 */
@Path("/swagger")
@Hidden // Hide this resource from Swagger documentation itself
public class SwaggerUIResource {

	/**
	 * Serve Swagger UI HTML page
	 * 
	 * @return HTML response with Swagger UI
	 */
	@GET
	@Produces(MediaType.TEXT_HTML)
	public Response getSwaggerUI() {
		String html = """
				<!DOCTYPE html>
				<html lang="en">
				<head>
				    <meta charset="UTF-8">
				    <title>Smart Agriculture Nutrition - Swagger UI</title>
				    <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui.css" />
				    <link rel="icon" type="image/png" href="https://unpkg.com/swagger-ui-dist@5.9.0/favicon-32x32.png" sizes="32x32" />
				    <style>
				        html {
				            box-sizing: border-box;
				            overflow: -moz-scrollbars-vertical;
				            overflow-y: scroll;
				        }
				        *, *:before, *:after {
				            box-sizing: inherit;
				        }
				        body {
				            margin:0;
				            background: #fafafa;
				        }
				        .swagger-ui .topbar {
				            background-color: #2c5530;
				        }
				        .swagger-ui .topbar .download-url-wrapper .select-label {
				            color: white;
				        }
				        .swagger-ui .info .title {
				            color: #2c5530;
				        }
				        .custom-header {
				            background: linear-gradient(135deg, #2c5530 0%, #4a7c59 100%);
				            color: white;
				            padding: 20px;
				            text-align: center;
				            margin-bottom: 20px;
				        }
				        .custom-header h1 {
				            margin: 0;
				            font-size: 2.5em;
				            font-weight: 300;
				        }
				        .custom-header p {
				            margin: 10px 0 0 0;
				            font-size: 1.2em;
				            opacity: 0.9;
				        }
				    </style>
				</head>
				<body>
				    <div class="custom-header">
				        <h1>🌱 Smart Agriculture Nutrition</h1>
				        <p>From Farm to Fork to Fitness - Interactive API Documentation</p>
				    </div>
				    <div id="swagger-ui"></div>
				    <script src="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui-bundle.js"></script>
				    <script src="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui-standalone-preset.js"></script>
				    <script>
				    window.onload = function() {
				        const ui = SwaggerUIBundle({
				            url: '/SmartAgricultureNutrition/openapi.json',
				            dom_id: '#swagger-ui',
				            deepLinking: true,
				            presets: [
				                SwaggerUIBundle.presets.apis,
				                SwaggerUIStandalonePreset
				            ],
				            plugins: [
				                SwaggerUIBundle.plugins.DownloadUrl
				            ],
				            layout: "StandaloneLayout",
				            tryItOutEnabled: true,
				            supportedSubmitMethods: ['get', 'post', 'put', 'delete', 'patch'],
				            onComplete: function() {
				                console.log("Swagger UI loaded successfully");
				            },
				            onFailure: function(data) {
				                console.log("Failed to load API definition", data);
				            }
				        });
				    };
				    </script>
				</body>
				</html>
				""";

		return Response.ok(html).build();
	}

	/**
	 * Serve OpenAPI JSON specification
	 * 
	 * @return JSON response with OpenAPI spec
	 */
	@GET
	@Path("/openapi.json")
	@Produces(MediaType.APPLICATION_JSON)
	public Response getOpenApiJson(@Context UriInfo uriInfo) {
		// Provide a comprehensive OpenAPI specification
		String openApiJson = """
				{
				    "openapi": "3.0.1",
				    "info": {
				        "title": "Smart Agriculture Nutrition",
				        "description": "REST API connecting smart agriculture data with personal nutrition tracking. This API bridges the gap between agricultural production and personal health outcomes, creating a complete food-to-health ecosystem.",
				        "version": "1.0.0",
				        "contact": {
				            "name": "Smart Agriculture Team",
				            "email": "agriculture@nutrition.com",
				            "url": "https://github.com/agriculture-nutrition/api"
				        },
				        "license": {
				            "name": "MIT License",
				            "url": "https://opensource.org/licenses/MIT"
				        }
				    },
				    "servers": [
				        {
				            "url": "http://localhost:8080/SmartAgricultureNutrition/api/v1",
				            "description": "Development Server"
				        }
				    ],
				    "tags": [
				        {
				            "name": "Crop Nutrition Profiles",
				            "description": "Operations related to crop nutrition profiles and agricultural data"
				        },
				        {
				            "name": "Personal Nutrition Trackers",
				            "description": "Personal nutrition tracking and health goal management"
				        }
				    ],
				    "paths": {
				        "/crop-nutrition-profiles": {
				            "get": {
				                "tags": ["Crop Nutrition Profiles"],
				                "summary": "Get all crop nutrition profiles",
				                "description": "Retrieve a list of crop nutrition profiles with optional filtering by crop type, growing method, region, or season. Returns comprehensive agricultural data including sustainability scores and nutritional content.",
				                "parameters": [
				                    {
				                        "name": "crop_type",
				                        "in": "query",
				                        "description": "Filter by crop type (e.g., tomato, carrot, wheat)",
				                        "schema": { "type": "string" },
				                        "example": "tomato"
				                    },
				                    {
				                        "name": "growing_method",
				                        "in": "query",
				                        "description": "Filter by growing method (e.g., organic, hydroponic, traditional)",
				                        "schema": { "type": "string" },
				                        "example": "organic"
				                    }
				                ],
				                "responses": {
				                    "200": {
				                        "description": "List of crop nutrition profiles retrieved successfully",
				                        "content": {
				                            "application/json": {
				                                "schema": {
				                                    "type": "array",
				                                    "items": { "$ref": "#/components/schemas/CropNutritionProfile" }
				                                }
				                            }
				                        }
				                    }
				                }
				            },
				            "post": {
				                "tags": ["Crop Nutrition Profiles"],
				                "summary": "Create new crop nutrition profile",
				                "description": "Create a new crop nutrition profile with automatic sustainability scoring and nutritional prediction",
				                "requestBody": {
				                    "required": true,
				                    "content": {
				                        "application/json": {
				                            "schema": { "$ref": "#/components/schemas/CropNutritionProfile" }
				                        }
				                    }
				                },
				                "responses": {
				                    "201": {
				                        "description": "Crop profile created successfully",
				                        "content": {
				                            "application/json": {
				                                "schema": { "$ref": "#/components/schemas/CropNutritionProfile" }
				                            }
				                        }
				                    }
				                }
				            }
				        },
				        "/crop-nutrition-profiles/{profileId}": {
				            "get": {
				                "tags": ["Crop Nutrition Profiles"],
				                "summary": "Get specific crop nutrition profile",
				                "parameters": [
				                    {
				                        "name": "profileId",
				                        "in": "path",
				                        "required": true,
				                        "schema": { "type": "integer", "format": "int64" }
				                    }
				                ],
				                "responses": {
				                    "200": {
				                        "description": "Crop profile retrieved successfully",
				                        "content": {
				                            "application/json": {
				                                "schema": { "$ref": "#/components/schemas/CropNutritionProfile" }
				                            }
				                        }
				                    },
				                    "404": { "description": "Crop profile not found" }
				                }
				            }
				        },
				        "/nutrition-trackers": {
				            "get": {
				                "tags": ["Personal Nutrition Trackers"],
				                "summary": "Get all nutrition trackers",
				                "description": "Retrieve personal nutrition trackers with BMI integration and health goal tracking",
				                "responses": {
				                    "200": {
				                        "description": "List of nutrition trackers retrieved successfully",
				                        "content": {
				                            "application/json": {
				                                "schema": {
				                                    "type": "array",
				                                    "items": { "$ref": "#/components/schemas/PersonalNutritionTracker" }
				                                }
				                            }
				                        }
				                    }
				                }
				            }
				        }
				    },
				    "components": {
				        "schemas": {
				            "CropNutritionProfile": {
				                "type": "object",
				                "properties": {
				                    "id": { "type": "integer", "format": "int64" },
				                    "cropName": { "type": "string", "example": "Organic Cherry Tomatoes" },
				                    "farmLocation": { "type": "string", "example": "Jyväskylä, Finland" },
				                    "growingMethod": { "type": "string", "example": "Organic" },
				                    "sustainabilityScore": { "type": "number", "format": "double", "example": 8.7 },
				                    "soilNutrients": { "type": "object" },
				                    "cropNutrients": { "type": "object" },
				                    "certifications": { "type": "array", "items": { "type": "string" } },
				                    "links": { "type": "array", "items": { "$ref": "#/components/schemas/Link" } }
				                }
				            },
				            "PersonalNutritionTracker": {
				                "type": "object",
				                "properties": {
				                    "id": { "type": "integer", "format": "int64" },
				                    "userName": { "type": "string", "example": "John Farmer" },
				                    "age": { "type": "integer", "example": 34 },
				                    "currentBmi": { "type": "number", "format": "double", "example": 24.5 },
				                    "healthGoals": { "type": "array", "items": { "type": "string" } },
				                    "farmToForkScore": { "type": "number", "format": "double", "example": 8.2 }
				                }
				            },
				            "Link": {
				                "type": "object",
				                "properties": {
				                    "link": { "type": "string" },
				                    "rel": { "type": "string" }
				                }
				            }
				        }
				    }
				}
				""";
		return Response.ok(openApiJson).build();
	}

	/**
	 * Redirect root swagger path to UI
	 * 
	 * @return Redirect response to Swagger UI
	 */
	@GET
	@Path("/")
	public Response redirectToUI() {
		return Response.seeOther(javax.ws.rs.core.UriBuilder.fromPath("swagger").build()).build();
	}

	/**
	 * Alternative OpenAPI endpoint at root level for compatibility
	 * 
	 * @return JSON response with OpenAPI spec
	 */
	@GET
	@Path("../openapi.json")
	@Produces(MediaType.APPLICATION_JSON)
	public Response getOpenApiJsonRoot(@Context UriInfo uriInfo) {
		return getOpenApiJson(uriInfo);
	}
}
