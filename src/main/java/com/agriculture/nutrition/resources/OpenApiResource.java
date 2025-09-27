package com.agriculture.nutrition.resources;

import io.swagger.v3.oas.integration.SwaggerConfiguration;
import io.swagger.v3.oas.integration.api.OpenAPIConfiguration;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.servers.Server;
import io.swagger.v3.jaxrs2.integration.JaxrsOpenApiContextBuilder;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Application;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.UriInfo;
import java.util.HashSet;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Resource to serve OpenAPI specification Provides the openapi.json endpoint
 * that Swagger UI needs
 */
@Path("/")
public class OpenApiResource {

	@Context
	private Application application;

	@Context
	private UriInfo uriInfo;

	@GET
	@Path("openapi.json")
	@Produces(MediaType.APPLICATION_JSON)
	public Response getOpenApiSpec() {
		try {
			OpenAPI openAPI = createOpenAPISpec();

			// Convert to JSON string manually for better control
			String jsonSpec = convertToJson(openAPI);

			return Response.ok(jsonSpec).header("Access-Control-Allow-Origin", "*")
					.header("Access-Control-Allow-Methods", "GET")
					.header("Access-Control-Allow-Headers", "Content-Type").build();

		} catch (Exception e) {
			// Return a basic fallback OpenAPI spec
			String fallbackSpec = createFallbackOpenApiSpec();
			return Response.ok(fallbackSpec).header("Access-Control-Allow-Origin", "*").build();
		}
	}

	private OpenAPI createOpenAPISpec() {
		OpenAPI openAPI = new OpenAPI();

		// Set API info
		Info info = new Info().title("Smart Agriculture Nutrition").version("1.0.0")
				.description("Professional REST API integrating weather and nutrition data for agricultural analysis")
				.contact(new Contact().name("Smart Agriculture Team").email("agriculture@nutrition.com")
						.url("https://github.com/agriculture-nutrition/api"))
				.license(new License().name("MIT License").url("https://opensource.org/licenses/MIT"));

		openAPI.setInfo(info);

		// Add servers
		String baseUrl = getBaseUrl();
		openAPI.addServersItem(new Server().url(baseUrl + "/api/v1").description("API Server"));

		return openAPI;
	}

	private String getBaseUrl() {
		if (uriInfo != null) {
			return uriInfo.getBaseUri().toString().replaceAll("/api/v1/?$", "");
		}
		return "http://localhost:8080/SmartAgricultureNutrition";
	}

	private String convertToJson(OpenAPI openAPI) {
		// Create a basic JSON representation
		StringBuilder json = new StringBuilder();
		json.append("{\n");
		json.append("  \"openapi\": \"3.0.1\",\n");
		json.append("  \"info\": {\n");
		json.append("    \"title\": \"").append(openAPI.getInfo().getTitle()).append("\",\n");
		json.append("    \"version\": \"").append(openAPI.getInfo().getVersion()).append("\",\n");
		json.append("    \"description\": \"").append(openAPI.getInfo().getDescription()).append("\"\n");
		json.append("  },\n");
		json.append("  \"servers\": [\n");
		if (openAPI.getServers() != null && !openAPI.getServers().isEmpty()) {
			json.append("    {\n");
			json.append("      \"url\": \"").append(openAPI.getServers().get(0).getUrl()).append("\",\n");
			json.append("      \"description\": \"").append(openAPI.getServers().get(0).getDescription())
					.append("\"\n");
			json.append("    }\n");
		}
		json.append("  ],\n");
		json.append("  \"paths\": {\n");
		json.append(createPathsJson());
		json.append("  },\n");
		json.append("  \"components\": {\n");
		json.append("    \"schemas\": {}\n");
		json.append("  }\n");
		json.append("}");

		return json.toString();
	}

	private String createPathsJson() {
		StringBuilder paths = new StringBuilder();

		// Crop Nutrition Profiles endpoints
		paths.append("    \"/crop-nutrition-profiles\": {\n");
		paths.append("      \"get\": {\n");
		paths.append("        \"tags\": [\"Crop Nutrition Profiles\"],\n");
		paths.append("        \"summary\": \"Get all crop nutrition profiles\",\n");
		paths.append("        \"responses\": {\n");
		paths.append("          \"200\": {\n");
		paths.append("            \"description\": \"List of crop nutrition profiles\"\n");
		paths.append("          }\n");
		paths.append("        }\n");
		paths.append("      },\n");
		paths.append("      \"post\": {\n");
		paths.append("        \"tags\": [\"Crop Nutrition Profiles\"],\n");
		paths.append("        \"summary\": \"Create a new crop nutrition profile\",\n");
		paths.append("        \"responses\": {\n");
		paths.append("          \"201\": {\n");
		paths.append("            \"description\": \"Crop nutrition profile created\"\n");
		paths.append("          }\n");
		paths.append("        }\n");
		paths.append("      }\n");
		paths.append("    },\n");

		// Weather endpoints
		paths.append("    \"/weather/current/{city}\": {\n");
		paths.append("      \"get\": {\n");
		paths.append("        \"tags\": [\"Weather\"],\n");
		paths.append("        \"summary\": \"Get current weather for a city\",\n");
		paths.append("        \"parameters\": [\n");
		paths.append("          {\n");
		paths.append("            \"name\": \"city\",\n");
		paths.append("            \"in\": \"path\",\n");
		paths.append("            \"required\": true,\n");
		paths.append("            \"schema\": {\n");
		paths.append("              \"type\": \"string\"\n");
		paths.append("            }\n");
		paths.append("          }\n");
		paths.append("        ],\n");
		paths.append("        \"responses\": {\n");
		paths.append("          \"200\": {\n");
		paths.append("            \"description\": \"Current weather data\"\n");
		paths.append("          }\n");
		paths.append("        }\n");
		paths.append("      }\n");
		paths.append("    },\n");

		// Nutrition endpoints
		paths.append("    \"/nutrition/crop/{cropName}\": {\n");
		paths.append("      \"get\": {\n");
		paths.append("        \"tags\": [\"Nutrition\"],\n");
		paths.append("        \"summary\": \"Get nutrition data for a crop\",\n");
		paths.append("        \"parameters\": [\n");
		paths.append("          {\n");
		paths.append("            \"name\": \"cropName\",\n");
		paths.append("            \"in\": \"path\",\n");
		paths.append("            \"required\": true,\n");
		paths.append("            \"schema\": {\n");
		paths.append("              \"type\": \"string\"\n");
		paths.append("            }\n");
		paths.append("          }\n");
		paths.append("        ],\n");
		paths.append("        \"responses\": {\n");
		paths.append("          \"200\": {\n");
		paths.append("            \"description\": \"Nutrition data for the crop\"\n");
		paths.append("          }\n");
		paths.append("        }\n");
		paths.append("      }\n");
		paths.append("    },\n");

		// Personal Nutrition Trackers
		paths.append("    \"/personal-nutrition-trackers\": {\n");
		paths.append("      \"get\": {\n");
		paths.append("        \"tags\": [\"Personal Nutrition Trackers\"],\n");
		paths.append("        \"summary\": \"Get all personal nutrition trackers\",\n");
		paths.append("        \"responses\": {\n");
		paths.append("          \"200\": {\n");
		paths.append("            \"description\": \"List of personal nutrition trackers\"\n");
		paths.append("          }\n");
		paths.append("        }\n");
		paths.append("      }\n");
		paths.append("    }\n");

		return paths.toString();
	}

	private String createFallbackOpenApiSpec() {
		return "{\n" + "  \"openapi\": \"3.0.1\",\n" + "  \"info\": {\n"
				+ "    \"title\": \"Smart Agriculture Nutrition\",\n" + "    \"version\": \"1.0.0\",\n"
				+ "    \"description\": \"Professional REST API integrating weather and nutrition data for agricultural analysis\"\n"
				+ "  },\n" + "  \"servers\": [\n" + "    {\n" + "      \"url\": \"" + getBaseUrl() + "/api/v1\",\n"
				+ "      \"description\": \"API Server\"\n" + "    }\n" + "  ],\n" + "  \"paths\": {\n"
				+ "    \"/crop-nutrition-profiles\": {\n" + "      \"get\": {\n"
				+ "        \"tags\": [\"Crop Nutrition Profiles\"],\n"
				+ "        \"summary\": \"Get all crop nutrition profiles\",\n" + "        \"responses\": {\n"
				+ "          \"200\": {\n" + "            \"description\": \"List of crop nutrition profiles\"\n"
				+ "          }\n" + "        }\n" + "      }\n" + "    },\n"
				+ "    \"/personal-nutrition-trackers\": {\n" + "      \"get\": {\n"
				+ "        \"tags\": [\"Personal Nutrition Trackers\"],\n"
				+ "        \"summary\": \"Get all personal nutrition trackers\",\n" + "        \"responses\": {\n"
				+ "          \"200\": {\n" + "            \"description\": \"List of personal nutrition trackers\"\n"
				+ "          }\n" + "        }\n" + "      }\n" + "    }\n" + "  },\n" + "  \"components\": {\n"
				+ "    \"schemas\": {}\n" + "  }\n" + "}";
	}
}
