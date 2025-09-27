package com.agriculture.nutrition.resources;

import com.agriculture.nutrition.model.PersonalNutritionTracker;
import com.agriculture.nutrition.model.MealSource;
import com.agriculture.nutrition.service.NutritionTrackingService;

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

@Path("/nutrition-trackers")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Personal Nutrition Trackers", description = "Personal nutrition tracking and health goal management")
public class PersonalNutritionTrackerResource {

	private NutritionTrackingService trackingService = new NutritionTrackingService();

	@GET
	@Operation(summary = "Get all nutrition trackers", description = "Retrieve personal nutrition trackers with BMI integration and health goal tracking. "
			+ "Supports filtering by BMI range, health goals, and local sourcing preferences.")
	@ApiResponses(value = {
			@ApiResponse(responseCode = "200", description = "List of nutrition trackers retrieved successfully", content = @Content(schema = @Schema(implementation = PersonalNutritionTracker.class))),
			@ApiResponse(responseCode = "500", description = "Internal server error") })
	public List<PersonalNutritionTracker> getNutritionTrackers(
			@Parameter(description = "Filter by BMI range (e.g., '20-25', 'under-18.5', 'over-30')", example = "20-25") @QueryParam("bmi_range") String bmiRange,
			@Parameter(description = "Filter by health goal", example = "Weight Maintenance") @QueryParam("health_goal") String healthGoal,
			@Parameter(description = "Minimum local source percentage", example = "0.7") @QueryParam("local_source_min") Double localSourceMin) {
		if (bmiRange != null) {
			return trackingService.getTrackersByBMIRange(bmiRange);
		}
		if (healthGoal != null) {
			return trackingService.getTrackersByHealthGoal(healthGoal);
		}
		return trackingService.getAllTrackers();
	}

	@GET
	@Path("/{trackerId}")
	@Operation(summary = "Get specific nutrition tracker", description = "Retrieve a specific nutrition tracker with HATEOAS navigation links")
	@ApiResponses(value = {
			@ApiResponse(responseCode = "200", description = "Nutrition tracker retrieved successfully", content = @Content(schema = @Schema(implementation = PersonalNutritionTracker.class))),
			@ApiResponse(responseCode = "404", description = "Nutrition tracker not found"),
			@ApiResponse(responseCode = "500", description = "Internal server error") })
	public PersonalNutritionTracker getNutritionTracker(
			@Parameter(description = "Nutrition tracker ID", required = true, example = "1") @PathParam("trackerId") long id,
			@Context UriInfo uriInfo) {
		PersonalNutritionTracker tracker = trackingService.getTracker(id);
		addHateoasLinks(tracker, uriInfo);
		return tracker;
	}

	@POST
	@Operation(summary = "Create new nutrition tracker", description = "Create a new nutrition tracker with BMI integration and automatic farm-to-fork scoring")
	@ApiResponses(value = {
			@ApiResponse(responseCode = "201", description = "Nutrition tracker created successfully", content = @Content(schema = @Schema(implementation = PersonalNutritionTracker.class))),
			@ApiResponse(responseCode = "400", description = "Invalid input data"),
			@ApiResponse(responseCode = "500", description = "Internal server error") })
	public Response createNutritionTracker(PersonalNutritionTracker tracker, @Context UriInfo uriInfo) {
		// Calculate farm-to-fork score based on food sources
		tracker.setFarmToForkScore(trackingService.calculateFarmToForkScore(tracker));

		// Generate personalized nutrition recommendations based on BMI
		trackingService.generateNutritionRecommendations(tracker);

		PersonalNutritionTracker created = trackingService.addTracker(tracker);
		addHateoasLinks(created, uriInfo);

		URI location = uriInfo.getAbsolutePathBuilder().path(String.valueOf(created.getId())).build();
		return Response.created(location).entity(created).build();
	}

	@PUT
	@Path("/{trackerId}")
	@Operation(summary = "Update nutrition tracker", description = "Update an existing nutrition tracker with recalculated farm-to-fork scoring")
	@ApiResponses(value = {
			@ApiResponse(responseCode = "200", description = "Nutrition tracker updated successfully", content = @Content(schema = @Schema(implementation = PersonalNutritionTracker.class))),
			@ApiResponse(responseCode = "404", description = "Nutrition tracker not found"),
			@ApiResponse(responseCode = "400", description = "Invalid input data"),
			@ApiResponse(responseCode = "500", description = "Internal server error") })
	public PersonalNutritionTracker updateNutritionTracker(
			@Parameter(description = "Nutrition tracker ID", required = true, example = "1") @PathParam("trackerId") long id,
			PersonalNutritionTracker tracker, @Context UriInfo uriInfo) {
		tracker.setId(id);

		// Recalculate farm-to-fork score
		tracker.setFarmToForkScore(trackingService.calculateFarmToForkScore(tracker));

		PersonalNutritionTracker updated = trackingService.updateTracker(tracker);
		addHateoasLinks(updated, uriInfo);
		return updated;
	}

	@DELETE
	@Path("/{trackerId}")
	@Operation(summary = "Delete nutrition tracker", description = "Remove a nutrition tracker and all associated data")
	@ApiResponses(value = { @ApiResponse(responseCode = "204", description = "Nutrition tracker deleted successfully"),
			@ApiResponse(responseCode = "404", description = "Nutrition tracker not found"),
			@ApiResponse(responseCode = "500", description = "Internal server error") })
	public Response deleteNutritionTracker(
			@Parameter(description = "Nutrition tracker ID", required = true, example = "1") @PathParam("trackerId") long id) {
		trackingService.removeTracker(id);
		return Response.noContent().build();
	}

	// Nested resource: Meal Sources
	@GET
	@Path("/{trackerId}/meal-sources")
	@Operation(summary = "Get meal sources for tracker", description = "Retrieve meal sources with farm-to-fork tracking and local sourcing percentages")
	@ApiResponses(value = {
			@ApiResponse(responseCode = "200", description = "Meal sources retrieved successfully", content = @Content(schema = @Schema(implementation = MealSource.class))),
			@ApiResponse(responseCode = "404", description = "Nutrition tracker not found"),
			@ApiResponse(responseCode = "500", description = "Internal server error") })
	public List<MealSource> getMealSources(
			@Parameter(description = "Nutrition tracker ID", required = true, example = "1") @PathParam("trackerId") long trackerId,
			@Parameter(description = "Filter by minimum local percentage", example = "0.8") @QueryParam("local_percentage") Double localPercentage,
			@Parameter(description = "Filter by date (YYYY-MM-DD)", example = "2024-03-15") @QueryParam("date") String date,
			@Context UriInfo uriInfo) {
		List<MealSource> meals;
		if (localPercentage != null) {
			meals = trackingService.getMealsByLocalPercentage(trackerId, localPercentage);
		} else if (date != null) {
			meals = trackingService.getMealsByDate(trackerId, date);
		} else {
			meals = trackingService.getAllMealSources(trackerId);
		}

		// Add HATEOAS links to each meal
		for (MealSource meal : meals) {
			addMealSourceLinks(meal, uriInfo);
		}

		return meals;
	}

	@POST
	@Path("/{trackerId}/meal-sources")
	@Operation(summary = "Add meal source to tracker", description = "Add a new meal source with automatic local sourcing percentage and nutritional density calculation")
	@ApiResponses(value = {
			@ApiResponse(responseCode = "201", description = "Meal source added successfully", content = @Content(schema = @Schema(implementation = MealSource.class))),
			@ApiResponse(responseCode = "404", description = "Nutrition tracker not found"),
			@ApiResponse(responseCode = "400", description = "Invalid input data"),
			@ApiResponse(responseCode = "500", description = "Internal server error") })
	public Response addMealSource(
			@Parameter(description = "Nutrition tracker ID", required = true, example = "1") @PathParam("trackerId") long trackerId,
			MealSource mealSource, @Context UriInfo uriInfo) {
		mealSource.setTrackerId(trackerId);

		// Calculate local source percentage and nutritional density
		mealSource.setLocalSourcePercentage(trackingService.calculateLocalPercentage(mealSource));
		mealSource.setNutritionalDensity(trackingService.calculateNutritionalDensity(mealSource));

		MealSource created = trackingService.addMealSource(mealSource);
		addMealSourceLinks(created, uriInfo);

		URI location = uriInfo.getAbsolutePathBuilder().path("meal-sources").path(String.valueOf(created.getId()))
				.build();
		return Response.created(location).entity(created).build();
	}

	// Nested resource: Health Correlations (GET only)
	@GET
	@Path("/{trackerId}/health-correlations")
	@Produces(MediaType.APPLICATION_JSON)
	public Response getHealthCorrelations(@PathParam("trackerId") long trackerId) {
		PersonalNutritionTracker tracker = trackingService.getTracker(trackerId);

		// Create a simple health correlation analysis response
		String analysis = String.format(
				"Health Correlation Analysis for %s: BMI: %.1f, Farm-to-Fork Score: %.1f, Health Goals: %s, Nutrient Status: %s",
				tracker.getUserName(), tracker.getCurrentBMI(), tracker.getFarmToForkScore(),
				tracker.getHealthGoals() != null ? String.join(", ", tracker.getHealthGoals()) : "None",
				tracker.getDailyNutrientIntake() != null ? "Tracked" : "Not tracked");

		return Response.ok().entity("{\"analysis\": \"" + analysis + "\"}").build();
	}

	// BMI Integration endpoint (connecting to Task-2)
	@GET
	@Path("/{trackerId}/bmi-analysis")
	@Produces(MediaType.APPLICATION_JSON)
	public Response getBMIAnalysis(@PathParam("trackerId") long trackerId) {
		PersonalNutritionTracker tracker = trackingService.getTracker(trackerId);

		String bmiCategory;
		String recommendations;

		double bmi = tracker.getCurrentBMI();
		if (bmi < 18.5) {
			bmiCategory = "Underweight";
			recommendations = "Increase caloric intake with nutrient-dense foods from local farms";
		} else if (bmi >= 18.5 && bmi < 25.0) {
			bmiCategory = "Normal weight";
			recommendations = "Maintain current nutrition with focus on local, sustainable sources";
		} else if (bmi >= 25.0 && bmi < 30.0) {
			bmiCategory = "Overweight";
			recommendations = "Focus on portion control and increase fiber-rich vegetables from local farms";
		} else {
			bmiCategory = "Obese";
			recommendations = "Consult healthcare provider and focus on nutrient-dense, low-calorie local foods";
		}

		String response = String.format(
				"{\"userName\": \"%s\", \"bmi\": %.1f, \"category\": \"%s\", \"recommendations\": \"%s\", \"farmToForkScore\": %.1f}",
				tracker.getUserName(), bmi, bmiCategory, recommendations, tracker.getFarmToForkScore());

		return Response.ok().entity(response).build();
	}

	private void addHateoasLinks(PersonalNutritionTracker tracker, UriInfo uriInfo) {
		String selfUri = uriInfo.getBaseUriBuilder().path(PersonalNutritionTrackerResource.class)
				.path(String.valueOf(tracker.getId())).build().toString();
		tracker.addLink(selfUri, "self");

		String mealSourcesUri = uriInfo.getBaseUriBuilder().path(PersonalNutritionTrackerResource.class)
				.path(String.valueOf(tracker.getId())).path("meal-sources").build().toString();
		tracker.addLink(mealSourcesUri, "meal-sources");

		String healthCorrelationsUri = uriInfo.getBaseUriBuilder().path(PersonalNutritionTrackerResource.class)
				.path(String.valueOf(tracker.getId())).path("health-correlations").build().toString();
		tracker.addLink(healthCorrelationsUri, "health-correlations");

		String bmiAnalysisUri = uriInfo.getBaseUriBuilder().path(PersonalNutritionTrackerResource.class)
				.path(String.valueOf(tracker.getId())).path("bmi-analysis").build().toString();
		tracker.addLink(bmiAnalysisUri, "bmi-analysis");

		String updateUri = uriInfo.getBaseUriBuilder().path(PersonalNutritionTrackerResource.class)
				.path(String.valueOf(tracker.getId())).build().toString();
		tracker.addLink(updateUri, "update");

		String deleteUri = uriInfo.getBaseUriBuilder().path(PersonalNutritionTrackerResource.class)
				.path(String.valueOf(tracker.getId())).build().toString();
		tracker.addLink(deleteUri, "delete");
	}

	private void addMealSourceLinks(MealSource meal, UriInfo uriInfo) {
		String selfUri = uriInfo.getBaseUriBuilder().path(PersonalNutritionTrackerResource.class)
				.path(String.valueOf(meal.getTrackerId())).path("meal-sources").path(String.valueOf(meal.getId()))
				.build().toString();
		meal.addLink(selfUri, "self");

		String trackerUri = uriInfo.getBaseUriBuilder().path(PersonalNutritionTrackerResource.class)
				.path(String.valueOf(meal.getTrackerId())).build().toString();
		meal.addLink(trackerUri, "nutrition-tracker");
	}
}
