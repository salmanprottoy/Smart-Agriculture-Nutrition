package com.agriculture.nutrition.resources;

import com.agriculture.nutrition.auth.Secured;
import com.agriculture.nutrition.model.FoodNutritionData;
import com.agriculture.nutrition.service.NutritionDataService;
import com.agriculture.nutrition.service.NutritionDataService.FoodSearchResult;

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
import java.util.List;

@Path("/nutrition")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Secured
@SecurityRequirement(name = "basicAuth")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Nutrition Data", description = "Comprehensive nutrition information from USDA FoodData Central")
public class NutritionDataResource {

    private final NutritionDataService nutritionService = new NutritionDataService();

    @GET
    @Path("/food/{fdcId}")
    @RolesAllowed("USER")
    @Operation(summary = "Get nutrition data by USDA FDC ID", description = "Retrieve comprehensive nutrition information for a specific food "
            + "using USDA Food Data Central ID. Includes vitamins, minerals, and macronutrients.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Nutrition data retrieved successfully", content = @Content(schema = @Schema(implementation = FoodNutritionData.class))),
            @ApiResponse(responseCode = "404", description = "Food not found"),
            @ApiResponse(responseCode = "500", description = "Nutrition service unavailable - fallback data provided") })
    public FoodNutritionData getNutritionDataById(
            @Parameter(description = "USDA Food Data Central ID", example = "167512", required = true) @PathParam("fdcId") long fdcId) {
        if (fdcId <= 0) {
            throw new WebApplicationException("Invalid FDC ID provided", Response.Status.BAD_REQUEST);
        }
        return nutritionService.getNutritionDataById(fdcId);
    }

    @GET
    @Path("/search")
    @RolesAllowed("USER")
    @Operation(summary = "Search foods by name", description = "Search for foods in the USDA database by name. "
            + "Returns a list of matching foods with basic information.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Search completed successfully", content = @Content(schema = @Schema(implementation = FoodSearchResult.class))),
            @ApiResponse(responseCode = "400", description = "Invalid search parameters"),
            @ApiResponse(responseCode = "500", description = "Search service unavailable") })
    public List<FoodSearchResult> searchFoods(
            @Parameter(description = "Food name to search for", example = "tomato", required = true) @QueryParam("query") String query,
            @Parameter(description = "Number of results to return (max 200)", example = "10") @QueryParam("pageSize") @DefaultValue("10") int pageSize) {

        if (query == null || query.trim().isEmpty()) {
            throw new WebApplicationException("Search query is required", Response.Status.BAD_REQUEST);
        }
        if (pageSize < 1 || pageSize > 200) {
            throw new WebApplicationException("Page size must be between 1 and 200", Response.Status.BAD_REQUEST);
        }
        return nutritionService.searchFoods(query.trim(), pageSize);
    }

    @GET
    @Path("/crop/{cropName}")
    @RolesAllowed("USER")
    @Operation(summary = "Get nutrition data for crops", description = "Retrieve nutrition information for common agricultural crops. "
            + "Maps crop names to USDA nutrition data automatically.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Crop nutrition data retrieved successfully", content = @Content(schema = @Schema(implementation = FoodNutritionData.class))),
            @ApiResponse(responseCode = "500", description = "Nutrition service unavailable - fallback data provided") })
    public FoodNutritionData getCropNutritionData(
            @Parameter(description = "Crop name", example = "tomato", required = true) @PathParam("cropName") String cropName) {
        if (cropName == null || cropName.trim().isEmpty()) {
            throw new WebApplicationException("Crop name is required", Response.Status.BAD_REQUEST);
        }
        return nutritionService.getCropNutritionData(cropName.trim());
    }

    @GET
    @Path("/crop-analysis/{cropName}")
    @RolesAllowed("USER")
    @Operation(summary = "Analyze crop nutritional compatibility", description = "Analyze how well a crop's nutritional profile matches specific dietary goals. "
            + "Provides detailed compatibility assessment and recommendations.")
    @Produces(MediaType.TEXT_PLAIN)
    public String analyzeCropNutritionalCompatibility(
            @Parameter(description = "Crop name", example = "tomato", required = true) @PathParam("cropName") String cropName,
            @Parameter(description = "Dietary goal", example = "weight_loss") @QueryParam("goal") @DefaultValue("general_health") String dietaryGoal) {
        if (cropName == null || cropName.trim().isEmpty()) {
            throw new WebApplicationException("Crop name is required", Response.Status.BAD_REQUEST);
        }
        return nutritionService.analyzeCropNutritionalCompatibility(cropName.trim(), dietaryGoal);
    }

    @GET
    @Path("/density-score/{cropName}")
    @RolesAllowed("USER")
    @Operation(summary = "Get nutrition density score", description = "Calculate a nutrition density score (0-10) for a crop based on "
            + "vitamin and mineral content. Higher scores indicate more nutrient-dense foods.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Nutrition density score calculated", content = @Content(schema = @Schema(type = "object"))) })
    public Response getNutritionDensityScore(
            @Parameter(description = "Crop name", example = "spinach", required = true) @PathParam("cropName") String cropName) {
        if (cropName == null || cropName.trim().isEmpty()) {
            throw new WebApplicationException("Crop name is required", Response.Status.BAD_REQUEST);
        }

        FoodNutritionData nutritionData = nutritionService.getCropNutritionData(cropName.trim());
        double densityScore = nutritionData.calculateNutritionDensityScore();
        String healthBenefits = nutritionData.getHealthBenefits();

        String jsonResponse = String.format(
                "{\"crop\": \"%s\", \"nutritionDensityScore\": %.1f, \"healthBenefits\": \"%s\", "
                        + "\"fdcId\": %d, \"timestamp\": %d}",
                cropName, densityScore, healthBenefits, nutritionData.getFdcId(), System.currentTimeMillis());

        return Response.ok(jsonResponse).build();
    }

    @GET
    @Path("/nutrients/{cropName}")
    @RolesAllowed("USER")
    @Operation(summary = "Get simplified nutrient summary", description = "Get a simplified summary of key nutrients for a crop. "
            + "Returns easy-to-read nutrient information with amounts and units.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Nutrient summary retrieved successfully", content = @Content(schema = @Schema(type = "object"))) })
    public Response getSimplifiedNutrients(
            @Parameter(description = "Crop name", example = "broccoli", required = true) @PathParam("cropName") String cropName) {
        if (cropName == null || cropName.trim().isEmpty()) {
            throw new WebApplicationException("Crop name is required", Response.Status.BAD_REQUEST);
        }

        FoodNutritionData nutritionData = nutritionService.getCropNutritionData(cropName.trim());

        StringBuilder jsonBuilder = new StringBuilder();
        jsonBuilder.append("{");
        jsonBuilder.append(String.format("\"crop\": \"%s\",", cropName));
        jsonBuilder.append(String.format("\"fdcId\": %d,", nutritionData.getFdcId()));
        jsonBuilder.append("\"keyNutrients\": {");
        jsonBuilder.append(String.format("\"energy\": \"%.1f kcal\",", nutritionData.getNutrientAmount("Energy")));
        jsonBuilder.append(String.format("\"protein\": \"%.1f g\",", nutritionData.getNutrientAmount("Protein")));
        jsonBuilder.append(String.format("\"fiber\": \"%.1f g\",", nutritionData.getNutrientAmount("Fiber")));
        jsonBuilder.append(String.format("\"vitaminC\": \"%.1f mg\",", nutritionData.getNutrientAmount("Vitamin C")));
        jsonBuilder.append(String.format("\"calcium\": \"%.1f mg\",", nutritionData.getNutrientAmount("Calcium")));
        jsonBuilder.append(String.format("\"iron\": \"%.1f mg\",", nutritionData.getNutrientAmount("Iron")));
        jsonBuilder.append(String.format("\"potassium\": \"%.1f mg\"", nutritionData.getNutrientAmount("Potassium")));
        jsonBuilder.append("},");
        jsonBuilder.append(String.format("\"timestamp\": %d", System.currentTimeMillis()));
        jsonBuilder.append("}");
        return Response.ok(jsonBuilder.toString()).build();
    }

    @GET
    @Path("/cache/stats")
    @RolesAllowed("ADMIN")
    @Operation(summary = "Get nutrition cache statistics", description = "Retrieve information about nutrition data caching performance and status.")
    @Produces(MediaType.TEXT_PLAIN)
    public String getCacheStats() {
        return nutritionService.getCacheStats();
    }

    @DELETE
    @Path("/cache/expired")
    @RolesAllowed("ADMIN")
    @Operation(summary = "Clear expired nutrition cache", description = "Remove expired entries from nutrition data cache to free up memory.")
    @ApiResponses(value = { @ApiResponse(responseCode = "204", description = "Expired cache entries cleared successfully") })
    public Response clearExpiredCache() {
        nutritionService.clearExpiredCache();
        return Response.noContent().build();
    }
}
