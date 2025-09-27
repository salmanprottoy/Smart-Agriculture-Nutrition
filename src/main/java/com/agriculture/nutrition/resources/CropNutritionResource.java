package com.agriculture.nutrition.resources;

import com.agriculture.nutrition.model.CropNutritionProfile;
import com.agriculture.nutrition.model.HarvestBatch;
import com.agriculture.nutrition.service.CropNutritionService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;

import javax.ws.rs.*;
import javax.ws.rs.core.*;
import java.net.URI;
import java.util.List;

@Path("/crop-nutrition-profiles")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Crop Nutrition Profiles", description = "Operations related to crop nutrition profiles and agricultural data")
public class CropNutritionResource {

	private CropNutritionService cropService = new CropNutritionService();

	@GET
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
	@Operation(summary = "Create new crop nutrition profile", description = "Create a new crop nutrition profile with automatic sustainability scoring and nutritional content prediction")
	@ApiResponses(value = {
			@ApiResponse(responseCode = "201", description = "Crop nutrition profile created successfully", content = @Content(schema = @Schema(implementation = CropNutritionProfile.class))),
			@ApiResponse(responseCode = "400", description = "Invalid input data"),
			@ApiResponse(responseCode = "500", description = "Internal server error") })
	public Response createCropProfile(CropNutritionProfile profile, @Context UriInfo uriInfo) {
		// Calculate sustainability score based on growing method and soil health
		profile.setSustainabilityScore(cropService.calculateSustainabilityScore(profile));

		// Predict nutritional content based on soil nutrients
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

		// Recalculate sustainability score
		profile.setSustainabilityScore(cropService.calculateSustainabilityScore(profile));

		CropNutritionProfile updated = cropService.updateProfile(profile);
		addHateoasLinks(updated, uriInfo);
		return updated;
	}

	@DELETE
	@Path("/{profileId}")
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

	// Nested resource: Harvest Batches
	@GET
	@Path("/{profileId}/harvest-batches")
	@Operation(summary = "Get harvest batches for crop profile", description = "Retrieve harvest batches with quality grading and actual nutrient analysis")
	@ApiResponses(value = {
			@ApiResponse(responseCode = "200", description = "Harvest batches retrieved successfully", content = @Content(schema = @Schema(implementation = HarvestBatch.class))),
			@ApiResponse(responseCode = "404", description = "Crop nutrition profile not found"),
			@ApiResponse(responseCode = "500", description = "Internal server error") })
	public List<HarvestBatch> getHarvestBatches(
			@Parameter(description = "Crop nutrition profile ID", required = true, example = "1") @PathParam("profileId") long profileId,
			@Parameter(description = "Filter by harvest date (YYYY-MM-DD)", example = "2024-03-15") @QueryParam("harvest_date") String harvestDate,
			@Parameter(description = "Filter by quality grade (A, B, C)", example = "A") @QueryParam("quality_grade") String qualityGrade,
			@Context UriInfo uriInfo) {
		List<HarvestBatch> batches;
		if (harvestDate != null) {
			batches = cropService.getBatchesByDate(profileId, harvestDate);
		} else if (qualityGrade != null) {
			batches = cropService.getBatchesByQuality(profileId, qualityGrade);
		} else {
			batches = cropService.getAllBatches(profileId);
		}

		// Add HATEOAS links to each batch
		for (HarvestBatch batch : batches) {
			addHarvestBatchLinks(batch, uriInfo);
		}

		return batches;
	}

	@POST
	@Path("/{profileId}/harvest-batches")
	@Operation(summary = "Add harvest batch to crop profile", description = "Add a new harvest batch with automatic nutrient analysis based on growing conditions")
	@ApiResponses(value = {
			@ApiResponse(responseCode = "201", description = "Harvest batch created successfully", content = @Content(schema = @Schema(implementation = HarvestBatch.class))),
			@ApiResponse(responseCode = "404", description = "Crop nutrition profile not found"),
			@ApiResponse(responseCode = "400", description = "Invalid input data"),
			@ApiResponse(responseCode = "500", description = "Internal server error") })
	public Response createHarvestBatch(
			@Parameter(description = "Crop nutrition profile ID", required = true, example = "1") @PathParam("profileId") long profileId,
			HarvestBatch batch, @Context UriInfo uriInfo) {
		batch.setCropProfileId(profileId);

		// Calculate actual nutrients based on growing conditions
		if (batch.getActualNutrients() == null || batch.getActualNutrients().isEmpty()) {
			batch.setActualNutrients(cropService.calculateActualNutrients(batch));
		}

		HarvestBatch created = cropService.addHarvestBatch(batch);
		addHarvestBatchLinks(created, uriInfo);

		URI location = uriInfo.getAbsolutePathBuilder().path("harvest-batches").path(String.valueOf(created.getId()))
				.build();
		return Response.created(location).entity(created).build();
	}

	// Search endpoints
	@GET
	@Path("/search/crop-type")
	@Operation(summary = "Search crop profiles by crop type", description = "Search for crop nutrition profiles by crop type")
	@ApiResponses(value = {
			@ApiResponse(responseCode = "200", description = "Crop profiles found", content = @Content(schema = @Schema(implementation = CropNutritionProfile.class))),
			@ApiResponse(responseCode = "400", description = "Invalid crop type parameter"),
			@ApiResponse(responseCode = "500", description = "Internal server error") })
	public List<CropNutritionProfile> searchByCropType(
			@Parameter(description = "Crop type to search for", required = true, example = "tomato") @QueryParam("cropType") String cropType) {
		if (cropType == null || cropType.trim().isEmpty()) {
			throw new WebApplicationException("Crop type parameter is required", Response.Status.BAD_REQUEST);
		}
		return cropService.getProfilesByCropType(cropType);
	}

	@GET
	@Path("/search/growing-method")
	@Operation(summary = "Search crop profiles by growing method", description = "Search for crop nutrition profiles by growing method")
	@ApiResponses(value = {
			@ApiResponse(responseCode = "200", description = "Crop profiles found", content = @Content(schema = @Schema(implementation = CropNutritionProfile.class))),
			@ApiResponse(responseCode = "400", description = "Invalid growing method parameter"),
			@ApiResponse(responseCode = "500", description = "Internal server error") })
	public List<CropNutritionProfile> searchByGrowingMethod(
			@Parameter(description = "Growing method to search for", required = true, example = "organic") @QueryParam("method") String method) {
		if (method == null || method.trim().isEmpty()) {
			throw new WebApplicationException("Growing method parameter is required", Response.Status.BAD_REQUEST);
		}
		return cropService.getProfilesByGrowingMethod(method);
	}

	@GET
	@Path("/search/region")
	@Operation(summary = "Search crop profiles by region", description = "Search for crop nutrition profiles by region")
	@ApiResponses(value = {
			@ApiResponse(responseCode = "200", description = "Crop profiles found", content = @Content(schema = @Schema(implementation = CropNutritionProfile.class))),
			@ApiResponse(responseCode = "400", description = "Invalid region parameter"),
			@ApiResponse(responseCode = "500", description = "Internal server error") })
	public List<CropNutritionProfile> searchByRegion(
			@Parameter(description = "Region to search for", required = true, example = "Finland") @QueryParam("region") String region) {
		if (region == null || region.trim().isEmpty()) {
			throw new WebApplicationException("Region parameter is required", Response.Status.BAD_REQUEST);
		}
		return cropService.getProfilesByRegion(region);
	}

	// Nested resource: Soil Impact Analysis (GET only)
	@GET
	@Path("/{profileId}/soil-impact")
	@Produces(MediaType.APPLICATION_JSON)
	public Response getSoilImpact(@PathParam("profileId") long profileId) {
		CropNutritionProfile profile = cropService.getProfile(profileId);

		// Create a simple soil impact analysis response
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
