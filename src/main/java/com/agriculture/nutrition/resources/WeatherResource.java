package com.agriculture.nutrition.resources;

import com.agriculture.nutrition.auth.Secured;
import com.agriculture.nutrition.model.WeatherData;
import com.agriculture.nutrition.service.WeatherService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;

import javax.annotation.security.RolesAllowed;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

@Path("/weather")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@SecurityRequirement(name = "basicAuth")
@SecurityRequirement(name = "bearerAuth")
@Secured
@Tag(name = "Weather Data", description = "Real-time weather information for agricultural analysis")
public class WeatherResource {

    private final WeatherService weatherService = new WeatherService();

    @GET
    @Path("/current/{city}")
    @RolesAllowed("USER")
    @Operation(summary = "Get current weather for a city", description = "Retrieve current weather conditions for agricultural analysis. "
            + "Includes temperature, humidity, and agricultural impact scoring.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Weather data retrieved successfully", content = @Content(schema = @Schema(implementation = WeatherData.class))),
            @ApiResponse(responseCode = "500", description = "Weather service unavailable - fallback data provided") })
    public WeatherData getCurrentWeather(
            @Parameter(description = "City name", example = "Jyväskylä", required = true) @PathParam("city") String city) {

        return weatherService.getCurrentWeather(city);
    }

    @GET
    @Path("/coordinates")
    @RolesAllowed("USER")
    @Operation(summary = "Get weather by coordinates", description = "Retrieve weather data using latitude and longitude coordinates. "
            + "Useful for precise farm location weather analysis.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Weather data retrieved successfully", content = @Content(schema = @Schema(implementation = WeatherData.class))),
            @ApiResponse(responseCode = "400", description = "Invalid coordinates provided"),
            @ApiResponse(responseCode = "500", description = "Weather service unavailable - fallback data provided") })
    public WeatherData getWeatherByCoordinates(
            @Parameter(description = "Latitude", example = "62.2426", required = true) @QueryParam("lat") double latitude,
            @Parameter(description = "Longitude", example = "25.7342", required = true) @QueryParam("lon") double longitude) {

        if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
            throw new WebApplicationException("Invalid coordinates provided", Response.Status.BAD_REQUEST);
        }

        return weatherService.getWeatherByCoordinates(latitude, longitude);
    }

    @GET
    @Path("/crop-impact/{city}/{crop}")
    @RolesAllowed("USER")
    @Operation(summary = "Analyze weather impact on crop nutrition", description = "Get detailed analysis of how current weather conditions affect "
            + "crop nutritional development and quality. Includes recommendations.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Weather impact analysis completed", content = @Content(schema = @Schema(type = "string"))),
            @ApiResponse(responseCode = "500", description = "Analysis service unavailable") })
    @Produces(MediaType.TEXT_PLAIN)
    public String analyzeWeatherImpactOnNutrition(
            @Parameter(description = "City name", example = "Jyväskylä", required = true) @PathParam("city") String city,
            @Parameter(description = "Crop type", example = "tomato", required = true) @PathParam("crop") String cropType) {

        return weatherService.analyzeWeatherImpactOnNutrition(city, cropType);
    }

    @GET
    @Path("/cache/stats")
    @RolesAllowed("USER")
    @Operation(summary = "Get weather cache statistics", description = "Retrieve information about weather data caching performance and status.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Cache statistics retrieved", content = @Content(schema = @Schema(type = "string"))) })
    @Produces(MediaType.TEXT_PLAIN)
    public String getCacheStats() {
        return weatherService.getCacheStats();
    }

    @DELETE
    @Path("/cache/expired")
    @RolesAllowed("ADMIN")
    @Operation(summary = "Clear expired weather cache", description = "Remove expired entries from weather data cache to free up memory.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "204", description = "Expired cache entries cleared successfully") })
    public Response clearExpiredCache() {
        weatherService.clearExpiredCache();
        return Response.noContent().build();
    }

    @GET
    @Path("/agriculture-score/{city}")
    @RolesAllowed("USER")
    @Operation(summary = "Get agricultural impact score", description = "Calculate a score (0-10) indicating how favorable current weather "
            + "conditions are for agricultural activities and crop development.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Agricultural impact score calculated", content = @Content(schema = @Schema(type = "object"))) })
    public Response getAgricultureImpactScore(
            @Parameter(description = "City name", example = "Jyväskylä", required = true) @PathParam("city") String city) {

        WeatherData weather = weatherService.getCurrentWeather(city);
        double score = weather.calculateAgricultureImpactScore();
        String impact = weather.getNutritionImpact();

        String jsonResponse = String.format(
                "{\"city\": \"%s\", \"agricultureScore\": %.1f, \"nutritionImpact\": \"%s\", "
                        + "\"conditions\": \"%s\", \"timestamp\": %d}",
                city, score, impact,
                weather.getWeather() != null && !weather.getWeather().isEmpty()
                        ? weather.getWeather().get(0).getDescription()
                        : "Unknown",
                System.currentTimeMillis());

        return Response.ok(jsonResponse).build();
    }
}
