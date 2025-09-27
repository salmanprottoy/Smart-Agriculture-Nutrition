package com.agriculture.nutrition.resources;

import com.agriculture.nutrition.model.WeatherData;
import com.agriculture.nutrition.model.FoodNutritionData;
import com.agriculture.nutrition.service.WeatherService;
import com.agriculture.nutrition.service.NutritionDataService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;

import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

/**
 * REST resource for weather-nutrition correlations Combines weather and
 * nutrition data for comprehensive agricultural analysis
 */
@Path("/correlations")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Weather-Nutrition Correlations", description = "Combined analysis of weather impact on crop nutrition")
public class CorrelationResource {

	private final WeatherService weatherService = new WeatherService();
	private final NutritionDataService nutritionService = new NutritionDataService();

	/**
	 * Get comprehensive weather-nutrition analysis for a crop in a specific
	 * location
	 */
	@GET
	@Path("/crop-weather-nutrition/{city}/{crop}")
	@Operation(summary = "Comprehensive crop weather-nutrition analysis", description = "Analyze how current weather conditions in a specific location affect "
			+ "the nutritional quality and development of a crop. Combines real weather data "
			+ "with USDA nutrition information for actionable insights.")
	@ApiResponses(value = {
			@ApiResponse(responseCode = "200", description = "Analysis completed successfully", content = @Content(schema = @Schema(type = "object"))),
			@ApiResponse(responseCode = "400", description = "Invalid parameters"),
			@ApiResponse(responseCode = "500", description = "Analysis service unavailable") })
	public Response getCropWeatherNutritionAnalysis(
			@Parameter(description = "City name", example = "Jyväskylä", required = true) @PathParam("city") String city,
			@Parameter(description = "Crop name", example = "tomato", required = true) @PathParam("crop") String crop) {

		if (city == null || city.trim().isEmpty()) {
			throw new WebApplicationException("City name is required", Response.Status.BAD_REQUEST);
		}

		if (crop == null || crop.trim().isEmpty()) {
			throw new WebApplicationException("Crop name is required", Response.Status.BAD_REQUEST);
		}

		// Get weather data
		WeatherData weather = weatherService.getCurrentWeather(city.trim());

		// Get nutrition data
		FoodNutritionData nutrition = nutritionService.getCropNutritionData(crop.trim());

		// Calculate scores
		double weatherScore = weather.calculateAgricultureImpactScore();
		double nutritionScore = nutrition.calculateNutritionDensityScore();

		// Create comprehensive analysis
		StringBuilder analysis = new StringBuilder();
		analysis.append("COMPREHENSIVE CROP ANALYSIS\\n");
		analysis.append("=========================\\n\\n");

		analysis.append(String.format("Location: %s\\n", city));
		analysis.append(String.format("Crop: %s\\n", crop));
		analysis.append(String.format("Analysis Date: %s\\n\\n", new java.util.Date().toString()));

		// Weather section
		analysis.append("WEATHER CONDITIONS:\\n");
		if (weather.getWeather() != null && !weather.getWeather().isEmpty()) {
			analysis.append(String.format("Current Conditions: %s\\n", weather.getWeather().get(0).getDescription()));
		}

		if (weather.getMain() != null) {
			double tempCelsius = weather.getMain().getTemp() - 273.15;
			analysis.append(String.format("Temperature: %.1f°C\\n", tempCelsius));
			analysis.append(String.format("Humidity: %.0f%%\\n", weather.getMain().getHumidity()));
		}

		analysis.append(String.format("Agricultural Impact Score: %.1f/10\\n", weatherScore));
		analysis.append(String.format("Weather Impact on Nutrition: %s\\n\\n", weather.getNutritionImpact()));

		// Nutrition section
		analysis.append("NUTRITIONAL PROFILE:\\n");
		analysis.append(String.format("Nutrition Density Score: %.1f/10\\n", nutritionScore));
		analysis.append(String.format("Health Benefits: %s\\n\\n", nutrition.getHealthBenefits()));

		// Key nutrients
		analysis.append("Key Nutrients (per 100g):\\n");
		analysis.append(String.format("- Energy: %.1f kcal\\n", nutrition.getNutrientAmount("Energy")));
		analysis.append(String.format("- Protein: %.1f g\\n", nutrition.getNutrientAmount("Protein")));
		analysis.append(String.format("- Fiber: %.1f g\\n", nutrition.getNutrientAmount("Fiber")));
		analysis.append(String.format("- Vitamin C: %.1f mg\\n", nutrition.getNutrientAmount("Vitamin C")));
		analysis.append(String.format("- Calcium: %.1f mg\\n", nutrition.getNutrientAmount("Calcium")));
		analysis.append(String.format("- Iron: %.1f mg\\n", nutrition.getNutrientAmount("Iron")));
		analysis.append(String.format("- Potassium: %.1f mg\\n\\n", nutrition.getNutrientAmount("Potassium")));

		// Combined recommendations
		analysis.append("INTEGRATED RECOMMENDATIONS:\\n");
		analysis.append(getIntegratedRecommendations(crop, weather, nutrition, weatherScore, nutritionScore));

		// Create JSON response
		String jsonResponse = String.format(
				"{\"city\": \"%s\", \"crop\": \"%s\", \"weatherScore\": %.1f, "
						+ "\"nutritionScore\": %.1f, \"overallQuality\": \"%.1f\", "
						+ "\"analysis\": \"%s\", \"timestamp\": %d}",
				city, crop, weatherScore, nutritionScore, (weatherScore + nutritionScore) / 2.0,
				analysis.toString().replace("\"", "\\\"").replace("\n", "\\n"), System.currentTimeMillis());

		return Response.ok(jsonResponse).build();
	}

	/**
	 * Compare multiple crops under current weather conditions
	 */
	@GET
	@Path("/crop-comparison/{city}")
	@Operation(summary = "Compare multiple crops under current weather", description = "Compare how different crops perform under current weather conditions "
			+ "in terms of nutritional development and agricultural suitability.")
	@ApiResponses(value = {
			@ApiResponse(responseCode = "200", description = "Crop comparison completed", content = @Content(schema = @Schema(type = "object"))) })
	public Response compareCropsUnderWeather(
			@Parameter(description = "City name", example = "Jyväskylä", required = true) @PathParam("city") String city,
			@Parameter(description = "Comma-separated crop names", example = "tomato,lettuce,carrot") @QueryParam("crops") @DefaultValue("tomato,lettuce,carrot") String crops) {

		if (city == null || city.trim().isEmpty()) {
			throw new WebApplicationException("City name is required", Response.Status.BAD_REQUEST);
		}

		String[] cropList = crops.split(",");
		if (cropList.length == 0) {
			throw new WebApplicationException("At least one crop must be specified", Response.Status.BAD_REQUEST);
		}

		// Get weather data once
		WeatherData weather = weatherService.getCurrentWeather(city.trim());
		double weatherScore = weather.calculateAgricultureImpactScore();

		StringBuilder comparison = new StringBuilder();
		comparison.append("{");
		comparison.append(String.format("\"city\": \"%s\",", city));
		comparison.append(String.format("\"weatherScore\": %.1f,", weatherScore));
		comparison.append(String.format("\"weatherConditions\": \"%s\",",
				weather.getWeather() != null && !weather.getWeather().isEmpty()
						? weather.getWeather().get(0).getDescription()
						: "Unknown"));
		comparison.append("\"cropComparison\": [");

		for (int i = 0; i < cropList.length; i++) {
			String crop = cropList[i].trim();
			if (!crop.isEmpty()) {
				FoodNutritionData nutrition = nutritionService.getCropNutritionData(crop);
				double nutritionScore = nutrition.calculateNutritionDensityScore();
				double combinedScore = (weatherScore + nutritionScore) / 2.0;

				if (i > 0)
					comparison.append(",");
				comparison.append("{");
				comparison.append(String.format("\"crop\": \"%s\",", crop));
				comparison.append(String.format("\"nutritionScore\": %.1f,", nutritionScore));
				comparison.append(String.format("\"combinedScore\": %.1f,", combinedScore));
				comparison.append(String.format("\"recommendation\": \"%s\"",
						getCropRecommendation(crop, weatherScore, nutritionScore)));
				comparison.append("}");
			}
		}

		comparison.append("],");
		comparison.append(String.format("\"timestamp\": %d", System.currentTimeMillis()));
		comparison.append("}");

		return Response.ok(comparison.toString()).build();
	}

	/**
	 * Get seasonal nutrition optimization recommendations
	 */
	@GET
	@Path("/seasonal-optimization/{city}")
	@Operation(summary = "Get seasonal nutrition optimization", description = "Provide recommendations for optimizing crop nutrition based on "
			+ "current weather patterns and seasonal considerations.")
	@ApiResponses(value = {
			@ApiResponse(responseCode = "200", description = "Seasonal optimization analysis completed", content = @Content(schema = @Schema(type = "string"))) })
	@Produces(MediaType.TEXT_PLAIN)
	public String getSeasonalNutritionOptimization(
			@Parameter(description = "City name", example = "Jyväskylä", required = true) @PathParam("city") String city) {

		if (city == null || city.trim().isEmpty()) {
			throw new WebApplicationException("City name is required", Response.Status.BAD_REQUEST);
		}

		WeatherData weather = weatherService.getCurrentWeather(city.trim());

		StringBuilder optimization = new StringBuilder();
		optimization.append("SEASONAL NUTRITION OPTIMIZATION REPORT\n");
		optimization.append("=====================================\n\n");

		optimization.append(String.format("Location: %s\n", city));
		optimization
				.append(String.format("Current Weather Score: %.1f/10\n\n", weather.calculateAgricultureImpactScore()));

		// Seasonal recommendations based on current conditions
		if (weather.getMain() != null) {
			double tempCelsius = weather.getMain().getTemp() - 273.15;

			optimization.append("SEASONAL CROP RECOMMENDATIONS:\n");

			if (tempCelsius < 10) {
				optimization.append("- Cold season crops: Kale, Brussels sprouts, winter squash\n");
				optimization.append("- Focus on: Vitamin C and antioxidant-rich vegetables\n");
				optimization.append("- Nutrition tip: Cold weather enhances sweetness in root vegetables\n");
			} else if (tempCelsius < 20) {
				optimization.append("- Cool season crops: Lettuce, spinach, peas, carrots\n");
				optimization.append("- Focus on: Leafy greens for maximum vitamin content\n");
				optimization.append("- Nutrition tip: Optimal temperature for vitamin retention\n");
			} else if (tempCelsius < 30) {
				optimization.append("- Warm season crops: Tomatoes, peppers, cucumbers\n");
				optimization.append("- Focus on: Lycopene and beta-carotene development\n");
				optimization.append("- Nutrition tip: Perfect conditions for antioxidant synthesis\n");
			} else {
				optimization.append("- Heat-tolerant crops: Okra, eggplant, hot peppers\n");
				optimization.append("- Focus on: Heat-stable nutrients and minerals\n");
				optimization.append("- Nutrition tip: Provide shade to prevent nutrient degradation\n");
			}

			optimization.append("\nWEATHER-SPECIFIC NUTRITION STRATEGIES:\n");
			optimization.append(weather.getNutritionImpact()).append("\n");

			// Humidity considerations
			if (weather.getMain().getHumidity() > 70) {
				optimization.append("- High humidity: Focus on disease-resistant varieties\n");
				optimization.append("- Ensure good air circulation to maintain nutrient quality\n");
			} else if (weather.getMain().getHumidity() < 40) {
				optimization.append("- Low humidity: Increase irrigation for nutrient transport\n");
				optimization.append("- Consider mulching to retain soil moisture\n");
			}
		}

		return optimization.toString();
	}

	/**
	 * Generate integrated recommendations based on weather and nutrition data
	 */
	private String getIntegratedRecommendations(String crop, WeatherData weather, FoodNutritionData nutrition,
			double weatherScore, double nutritionScore) {
		StringBuilder recommendations = new StringBuilder();

		double combinedScore = (weatherScore + nutritionScore) / 2.0;

		if (combinedScore >= 8.0) {
			recommendations.append("EXCELLENT CONDITIONS: Optimal weather and high nutritional value.\\n");
			recommendations.append("- Perfect time for harvesting maximum nutritional content\\n");
			recommendations.append("- Consider extending growing season if possible\\n");
		} else if (combinedScore >= 6.0) {
			recommendations.append("GOOD CONDITIONS: Favorable weather with good nutritional profile.\\n");
			recommendations.append("- Standard harvesting and processing recommended\\n");
			recommendations.append("- Monitor weather changes for optimization opportunities\\n");
		} else if (combinedScore >= 4.0) {
			recommendations.append("MODERATE CONDITIONS: Some challenges present.\\n");
			recommendations.append("- Consider protective measures to preserve nutrition\\n");
			recommendations.append("- May need supplemental nutrition from other sources\\n");
		} else {
			recommendations.append("CHALLENGING CONDITIONS: Weather or nutrition concerns.\\n");
			recommendations.append("- Implement protective growing strategies\\n");
			recommendations.append("- Consider alternative crops better suited to conditions\\n");
		}

		// Specific recommendations based on weather
		if (weather.getMain() != null) {
			double tempCelsius = weather.getMain().getTemp() - 273.15;

			if (tempCelsius > 30) {
				recommendations.append("- High temperature: Harvest early morning for best quality\\n");
				recommendations.append("- Provide shade protection during peak heat\\n");
			} else if (tempCelsius < 10) {
				recommendations.append("- Low temperature: Protect from frost damage\\n");
				recommendations.append("- Consider season extension techniques\\n");
			}

			if (weather.getMain().getHumidity() > 80) {
				recommendations.append("- High humidity: Ensure proper ventilation\\n");
				recommendations.append("- Monitor for fungal diseases that affect nutrition\\n");
			}
		}

		return recommendations.toString();
	}

	/**
	 * Get crop recommendation based on scores
	 */
	private String getCropRecommendation(String crop, double weatherScore, double nutritionScore) {
		double combined = (weatherScore + nutritionScore) / 2.0;

		if (combined >= 8.0) {
			return "Highly recommended - excellent conditions";
		} else if (combined >= 6.0) {
			return "Recommended - good conditions";
		} else if (combined >= 4.0) {
			return "Moderate - consider with care";
		} else {
			return "Not recommended - challenging conditions";
		}
	}
}
