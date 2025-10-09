package com.agriculture.nutrition.resources;

import com.agriculture.nutrition.auth.Secured;
import com.agriculture.nutrition.model.CropNutritionProfile;
import com.agriculture.nutrition.model.HarvestBatch;
import com.agriculture.nutrition.service.CropNutritionService;

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
import javax.ws.rs.core.*;
import java.net.URI;
import java.util.List;

@Path("/crop-nutrition-profiles")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Secured
@SecurityRequirement(name = "basicAuth")
@SecurityRequirement(name="bearerAuth")
@Tag(name = "Crop Nutrition Profiles", description = "Operations related to crop nutrition profiles and agricultural data")
public class CropNutritionResource {

    private CropNutritionService cropService = new CropNutritionService();

    @GET
    @RolesAllowed("USER")
    @Operation(summary = "Get all crop nutrition profiles", description = "Retrieve a list of crop nutrition profiles with optional filtering by crop type, growing method, region, or season. "
            + "Returns comprehensive agricultural data including sustainability scores and nutritional content.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "List of crop nutrition profiles retrieved successfully", content = @Content(schema = @Schema(implementation = CropNutritionProfile.class))),
            @ApiResponse(responseCode = "500", description = "Internal server error") })
    public List<CropNutritionProfile> getCropProfiles(
            @Parameter(description = "Filter by crop type (e.g., tomato, carrot, wheat)", example = "tomato") @QueryParam("crop_type") String cropType,
            @Parameter(description = "Filter by growing method (e.g., organic, hydroponic, traditional)", example = "organic") @QueryParam("growing_method") String method,
            @Parameter(description = "Filter by region/location", example = "Jyväskylä, Finland") @QueryParam("region") String region,
            @Parameter(description = "Filter by growing season", example = "spring") @QueryParam("season") String season) {
        if (cropType != null) {
            return cropService.getProfilesByCropType(cropType);
        }
        if (method != null) {
            return cropService.getProfilesByGrowingMethod(method);
        }
        if (region != null) {
            return cropService.getProfilesByRegion(region);
        }
        return cropService.getAllProfiles();
    }

    @GET
    @Path("/{profileId}")
    @RolesAllowed("USER")
    @Operation(summary = "Get specific crop nutrition profile", description = "Retrieve a specific crop nutrition profile with HATEOAS navigation links")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Crop nutrition profile retrieved successfully", content = @Content(schema = @Schema(implementation = CropNutritionProfile.class))),
            @ApiResponse(responseCode = "404", description = "Crop nutrition profile not found"),
            @ApiResponse(responseCode = "500", description = "Internal server error") })
    public CropNutritionProfile getCropProfile(
            @Parameter(description = "Crop nutrition profile ID", required = true, example = "1") @PathParam("profileId") long id,
            @Context UriInfo uriInfo) {
        CropNutritionProfile profile = cropService.getProfile(id);
        addHateoasLinks(profile, uriInfo);
        return profile;
    }

    @POST
    @RolesAllowed("ADMIN")
    @Operation(summary = "Create new crop nutrition profile", description = "Create a new crop nutrition profile with automatic sustainability scoring and nutritional content prediction")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Crop nutrition profile created successfully", content = @Content(schema = @Schema(implementation = CropNutritionProfile.class))),
            @ApiResponse(responseCode = "400", description = "Invalid input data"),
            @ApiResponse(responseCode = "500", description = "Internal server error") })
    public Response createCropProfile(CropNutritionProfile profile, @Context UriInfo uriInfo) {
        profile.setSustainabilityScore(cropService.calculateSustainabilityScore(profile));
        if (profile.getCropNutrients() == null || profile.getCropNutrients().isEmpty()) {
            profile.setCropNutrients(cropService.predictNutritionalContent(profile));
        }
        CropNutritionProfile created = cropService.addProfile(profile);
        addHateoasLinks(created, uriInfo);
        URI location = uriInfo.getAbsolutePathBuilder().path(String.valueOf(created.getId())).build();
        return Response.created(location).entity(created).build();
    }

    @PUT
    @Path("/{profileId}")
    @RolesAllowed("ADMIN")
    @Operation(summary = "Update crop nutrition profile", description = "Update an existing crop nutrition profile with recalculated sustainability scoring")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Crop nutrition profile updated successfully", content = @Content(schema = @Schema(implementation = CropNutritionProfile.class))),
            @ApiResponse(responseCode = "404", description = "Crop nutrition profile not found"),
            @ApiResponse(responseCode = "400", description = "Invalid input data"),
            @ApiResponse(responseCode = "500", description = "Internal server error") })
    public CropNutritionProfile updateCropProfile(
            @Parameter(description = "Crop nutrition profile ID", required = true, example = "1") @PathParam("profileId") long id,
            CropNutritionProfile profile, @Context UriInfo uriInfo) {
        profile.setId(id);
        profile.setSustainabilityScore(cropService.calculateSustainabilityScore(profile));
        CropNutritionProfile updated = cropService.updateProfile(profile);
        addHateoasLinks(updated, uriInfo);
        return updated;
    }

    @DELETE
    @Path("/{profileId}")
    @RolesAllowed("ADMIN")
    @Operation(summary = "Delete crop nutrition profile", description = "Remove a crop nutrition profile and all associated harvest batches")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "204", description = "Crop nutrition profile deleted successfully"),
            @ApiResponse(responseCode = "404", description = "Crop nutrition profile not found"),
            @ApiResponse(responseCode = "500", description = "Internal server error") })
    public Response deleteCropProfile(
            @Parameter(description = "Crop nutrition profile ID", required = true, example = "1") @PathParam("profileId") long id) {
        cropService.removeProfile(id);
        return Response.noContent().build();
    }

    @GET
    @Path("/{profileId}/harvest-batches")
    @RolesAllowed("USER")
    @Operation(summary = "Get harvest batches for crop profile", description = "Retrieve harvest batches with quality grading and actual nutrient analysis")
    public List<HarvestBatch> getHarvestBatches(
            @PathParam("profileId") long profileId,
            @QueryParam("harvest_date") String harvestDate,
            @QueryParam("quality_grade") String qualityGrade,
            @Context UriInfo uriInfo) {
        List<HarvestBatch> batches;
        if (harvestDate != null) {
            batches = cropService.getBatchesByDate(profileId, harvestDate);
        } else if (qualityGrade != null) {
            batches = cropService.getBatchesByQuality(profileId, qualityGrade);
        } else {
            batches = cropService.getAllBatches(profileId);
        }
        for (HarvestBatch batch : batches) addHarvestBatchLinks(batch, uriInfo);
        return batches;
    }

    @POST
    @Path("/{profileId}/harvest-batches")
    @RolesAllowed("ADMIN")
    @Operation(summary = "Add harvest batch to crop profile", description = "Add a new harvest batch with automatic nutrient analysis based on growing conditions")
    public Response createHarvestBatch(
            @PathParam("profileId") long profileId,
            HarvestBatch batch, @Context UriInfo uriInfo) {
        batch.setCropProfileId(profileId);
        if (batch.getActualNutrients() == null || batch.getActualNutrients().isEmpty()) {
            batch.setActualNutrients(cropService.calculateActualNutrients(batch));
        }
        HarvestBatch created = cropService.addHarvestBatch(batch);
        addHarvestBatchLinks(created, uriInfo);
        URI location = uriInfo.getAbsolutePathBuilder().path("harvest-batches").path(String.valueOf(created.getId())).build();
        return Response.created(location).entity(created).build();
    }

    @GET
    @Path("/search/crop-type")
    @RolesAllowed("USER")
    public List<CropNutritionProfile> searchByCropType(@QueryParam("cropType") String cropType) {
        if (cropType == null || cropType.trim().isEmpty()) {
            throw new WebApplicationException("Crop type parameter is required", Response.Status.BAD_REQUEST);
        }
        return cropService.getProfilesByCropType(cropType);
    }

    @GET
    @Path("/search/growing-method")
    @RolesAllowed("USER")
    public List<CropNutritionProfile> searchByGrowingMethod(@QueryParam("method") String method) {
        if (method == null || method.trim().isEmpty()) {
            throw new WebApplicationException("Growing method parameter is required", Response.Status.BAD_REQUEST);
        }
        return cropService.getProfilesByGrowingMethod(method);
    }

    @GET
    @Path("/search/region")
    @RolesAllowed("USER")
    public List<CropNutritionProfile> searchByRegion(@QueryParam("region") String region) {
        if (region == null || region.trim().isEmpty()) {
            throw new WebApplicationException("Region parameter is required", Response.Status.BAD_REQUEST);
        }
        return cropService.getProfilesByRegion(region);
    }

    @GET
    @Path("/{profileId}/soil-impact")
    @RolesAllowed("USER")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getSoilImpact(@PathParam("profileId") long profileId) {
        CropNutritionProfile profile = cropService.getProfile(profileId);
        String analysis = String.format(
                "Soil Impact Analysis for %s: Sustainability Score: %.1f, Growing Method: %s, Soil Quality: %s",
                profile.getCropName(), profile.getSustainabilityScore(), profile.getGrowingMethod(),
                profile.getSoilNutrients() != null ? "Rich in nutrients" : "Standard");
        return Response.ok().entity("{\"analysis\": \"" + analysis + "\"}").build();
    }

    private void addHateoasLinks(CropNutritionProfile profile, UriInfo uriInfo) {
        String selfUri = uriInfo.getBaseUriBuilder().path(CropNutritionResource.class)
                .path(String.valueOf(profile.getId())).build().toString();
        profile.addLink(selfUri, "self");

        String batchesUri = uriInfo.getBaseUriBuilder().path(CropNutritionResource.class)
                .path(String.valueOf(profile.getId())).path("harvest-batches").build().toString();
        profile.addLink(batchesUri, "harvest-batches");

        String soilImpactUri = uriInfo.getBaseUriBuilder().path(CropNutritionResource.class)
                .path(String.valueOf(profile.getId())).path("soil-impact").build().toString();
        profile.addLink(soilImpactUri, "soil-impact");

        String updateUri = uriInfo.getBaseUriBuilder().path(CropNutritionResource.class)
                .path(String.valueOf(profile.getId())).build().toString();
        profile.addLink(updateUri, "update");

        String deleteUri = uriInfo.getBaseUriBuilder().path(CropNutritionResource.class)
                .path(String.valueOf(profile.getId())).build().toString();
        profile.addLink(deleteUri, "delete");
    }

    private void addHarvestBatchLinks(HarvestBatch batch, UriInfo uriInfo) {
        String selfUri = uriInfo.getBaseUriBuilder().path(CropNutritionResource.class)
                .path(String.valueOf(batch.getCropProfileId())).path("harvest-batches")
                .path(String.valueOf(batch.getId())).build().toString();
        batch.addLink(selfUri, "self");

        String cropProfileUri = uriInfo.getBaseUriBuilder().path(CropNutritionResource.class)
                .path(String.valueOf(batch.getCropProfileId())).build().toString();
        batch.addLink(cropProfileUri, "crop-profile");
    }
}
