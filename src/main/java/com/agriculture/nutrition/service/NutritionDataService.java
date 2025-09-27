package com.agriculture.nutrition.service;

import com.agriculture.nutrition.model.FoodNutritionData;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;

import javax.ws.rs.client.Client;
import javax.ws.rs.client.ClientBuilder;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import java.util.concurrent.ConcurrentHashMap;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;
import java.util.logging.Logger;
import java.util.logging.Level;

/**
 * Service for integrating with USDA FoodData Central API Provides comprehensive
 * nutrition data for foods
 */
public class NutritionDataService {

	private static final Logger LOGGER = Logger.getLogger(NutritionDataService.class.getName());

	// USDA FoodData Central API configuration
	private static final String USDA_API_BASE_URL = "https://api.nal.usda.gov/fdc/v1";
	private static final String API_KEY = loadApiKey();

	/**
	 * Load API key from environment or .env file
	 */
	private static String loadApiKey() {
		// First try system environment
		String key = System.getenv("USDA_API_KEY");
		if (key != null && !key.trim().isEmpty() && !"demo_key".equals(key)) {
			return key;
		}

		// Try loading from configuration files (multiple locations and formats)
		String[] configPaths = { "application.properties", // Eclipse-friendly properties file
				".env", // Standard .env file
				"src/main/webapp/.env", // Webapp .env
				"/WEB-INF/.env" // Deployed .env
		};

		for (String configPath : configPaths) {
			try {
				java.util.Properties props = new java.util.Properties();

				// Try as resource from classpath first (for application.properties)
				java.io.InputStream is = NutritionDataService.class.getClassLoader().getResourceAsStream(configPath);
				if (is != null) {
					props.load(is);
					is.close();
				} else {
					// Try as file
					try {
						java.io.FileInputStream fis = new java.io.FileInputStream(configPath);
						props.load(fis);
						fis.close();
					} catch (Exception e) {
						continue; // Try next path
					}
				}

				String envKey = props.getProperty("USDA_API_KEY");
				if (envKey != null && !envKey.trim().isEmpty()) {
					LOGGER.info("Loaded USDA API key from config file: " + configPath);
					return envKey;
				}
			} catch (Exception e) {
				// Continue to next path
				continue;
			}
		}

		LOGGER.warning("Could not load USDA API key from any configuration file");

		LOGGER.warning("USDA API key not found, using fallback data");
		return "demo_key";
	}

	// Simple in-memory cache (30 minutes TTL for nutrition data)
	private final Map<String, CachedNutritionData> nutritionCache = new ConcurrentHashMap<>();
	private static final long CACHE_TTL = 30 * 60 * 1000; // 30 minutes in milliseconds

	private final Client httpClient;
	private final ObjectMapper objectMapper;

	// Cache entry class
	private static class CachedNutritionData {
		final FoodNutritionData data;
		final long timestamp;

		CachedNutritionData(FoodNutritionData data) {
			this.data = data;
			this.timestamp = System.currentTimeMillis();
		}

		boolean isExpired() {
			return System.currentTimeMillis() - timestamp > CACHE_TTL;
		}
	}

	public NutritionDataService() {
		this.httpClient = ClientBuilder.newClient();
		this.objectMapper = new ObjectMapper();
	}

	/**
	 * Get nutrition data by USDA FDC ID
	 * 
	 * @param fdcId USDA Food Data Central ID
	 * @return Nutrition data or fallback data if API fails
	 */
	public FoodNutritionData getNutritionDataById(long fdcId) {
		// Check cache first
		String cacheKey = "fdc_" + fdcId;
		CachedNutritionData cached = nutritionCache.get(cacheKey);

		if (cached != null && !cached.isExpired()) {
			LOGGER.info("Returning cached nutrition data for FDC ID: " + fdcId);
			return cached.data;
		}

		try {
			// Make API call
			String url = String.format("%s/food/%d?api_key=%s", USDA_API_BASE_URL, fdcId, API_KEY);

			Response response = httpClient.target(url).request(MediaType.APPLICATION_JSON).get();

			if (response.getStatus() == 200) {
				String jsonResponse = response.readEntity(String.class);
				FoodNutritionData nutritionData = objectMapper.readValue(jsonResponse, FoodNutritionData.class);

				// Cache the result
				nutritionCache.put(cacheKey, new CachedNutritionData(nutritionData));

				LOGGER.info("Successfully fetched nutrition data for FDC ID: " + fdcId);
				return nutritionData;
			} else {
				LOGGER.warning("USDA API returned status: " + response.getStatus() + " for FDC ID: " + fdcId);
				return createFallbackNutritionData("Unknown Food", fdcId);
			}

		} catch (Exception e) {
			LOGGER.log(Level.WARNING, "Failed to fetch nutrition data for FDC ID: " + fdcId, e);
			return createFallbackNutritionData("Unknown Food", fdcId);
		}
	}

	/**
	 * Search for foods by name
	 * 
	 * @param foodName Name of the food to search for
	 * @param pageSize Number of results to return (max 200)
	 * @return List of matching foods with basic info
	 */
	public List<FoodSearchResult> searchFoods(String foodName, int pageSize) {
		// Check cache first
		String cacheKey = "search_" + foodName.toLowerCase() + "_" + pageSize;

		try {
			// Make API call
			String url = String.format("%s/foods/search?api_key=%s&query=%s&pageSize=%d", USDA_API_BASE_URL, API_KEY,
					foodName, Math.min(pageSize, 200));

			Response response = httpClient.target(url).request(MediaType.APPLICATION_JSON).get();

			if (response.getStatus() == 200) {
				String jsonResponse = response.readEntity(String.class);
				return parseSearchResults(jsonResponse);
			} else {
				LOGGER.warning("USDA search API returned status: " + response.getStatus() + " for query: " + foodName);
				return createFallbackSearchResults(foodName);
			}

		} catch (Exception e) {
			LOGGER.log(Level.WARNING, "Failed to search foods for: " + foodName, e);
			return createFallbackSearchResults(foodName);
		}
	}

	/**
	 * Get nutrition data for common crops
	 * 
	 * @param cropName Name of the crop
	 * @return Nutrition data for the crop
	 */
	public FoodNutritionData getCropNutritionData(String cropName) {
		// Map crop names to known USDA FDC IDs
		Map<String, Long> cropToFdcId = getCropFdcIdMapping();

		Long fdcId = cropToFdcId.get(cropName.toLowerCase());
		if (fdcId != null) {
			return getNutritionDataById(fdcId);
		} else {
			// Try searching for the crop
			List<FoodSearchResult> searchResults = searchFoods(cropName, 5);
			if (!searchResults.isEmpty()) {
				return getNutritionDataById(searchResults.get(0).getFdcId());
			} else {
				return createFallbackNutritionData(cropName, 0);
			}
		}
	}

	/**
	 * Analyze nutritional compatibility between crops and dietary goals
	 * 
	 * @param cropName    Name of the crop
	 * @param dietaryGoal Dietary goal (e.g., "weight_loss", "muscle_building")
	 * @return Compatibility analysis
	 */
	public String analyzeCropNutritionalCompatibility(String cropName, String dietaryGoal) {
		FoodNutritionData nutritionData = getCropNutritionData(cropName);

		StringBuilder analysis = new StringBuilder();
		analysis.append(String.format("Nutritional Analysis for %s:\n", cropName));
		analysis.append(
				String.format("Nutrition Density Score: %.1f/10\n", nutritionData.calculateNutritionDensityScore()));
		analysis.append(String.format("Health Benefits: %s\n", nutritionData.getHealthBenefits()));
		analysis.append(String.format("Dietary Goal Compatibility: %s\n",
				nutritionData.getDietaryGoalSuitability(dietaryGoal)));

		// Add key nutrients information
		Map<String, String> nutrients = nutritionData.getSimplifiedNutrients();
		if (!nutrients.isEmpty()) {
			analysis.append("\nKey Nutrients (per 100g):\n");
			nutrients.entrySet().stream().filter(entry -> isKeyNutrient(entry.getKey())).limit(8) // Show top 8 key
																									// nutrients
					.forEach(entry -> analysis.append(String.format("- %s: %s\n", entry.getKey(), entry.getValue())));
		}

		return analysis.toString();
	}

	/**
	 * Parse search results from USDA API response
	 * 
	 * @param jsonResponse JSON response from USDA search API
	 * @return List of food search results
	 */
	private List<FoodSearchResult> parseSearchResults(String jsonResponse) {
		List<FoodSearchResult> results = new ArrayList<>();

		try {
			JsonNode root = objectMapper.readTree(jsonResponse);
			JsonNode foods = root.get("foods");

			if (foods != null && foods.isArray()) {
				for (JsonNode food : foods) {
					FoodSearchResult result = new FoodSearchResult();
					result.setFdcId(food.get("fdcId").asLong());
					result.setDescription(food.get("description").asText());
					result.setDataType(food.get("dataType").asText());

					if (food.has("foodCategory")) {
						result.setFoodCategory(food.get("foodCategory").asText());
					}

					results.add(result);
				}
			}
		} catch (Exception e) {
			LOGGER.log(Level.WARNING, "Failed to parse search results", e);
		}

		return results;
	}

	/**
	 * Get mapping of crop names to USDA FDC IDs
	 * 
	 * @return Map of crop names to FDC IDs
	 */
	private Map<String, Long> getCropFdcIdMapping() {
		Map<String, Long> mapping = new HashMap<>();

		// Common crops with known FDC IDs (these would be real IDs in production)
		mapping.put("tomato", 167512L);
		mapping.put("tomatoes", 167512L);
		mapping.put("carrot", 170393L);
		mapping.put("carrots", 170393L);
		mapping.put("lettuce", 169248L);
		mapping.put("spinach", 168462L);
		mapping.put("broccoli", 170379L);
		mapping.put("potato", 170093L);
		mapping.put("potatoes", 170093L);
		mapping.put("onion", 170000L);
		mapping.put("onions", 170000L);
		mapping.put("bell pepper", 170427L);
		mapping.put("cucumber", 168409L);
		mapping.put("corn", 169998L);
		mapping.put("wheat", 168876L);

		return mapping;
	}

	/**
	 * Check if a nutrient is considered a key nutrient for display
	 * 
	 * @param nutrientName Name of the nutrient
	 * @return True if it's a key nutrient
	 */
	private boolean isKeyNutrient(String nutrientName) {
		String name = nutrientName.toLowerCase();
		return name.contains("protein") || name.contains("fiber") || name.contains("vitamin")
				|| name.contains("calcium") || name.contains("iron") || name.contains("potassium")
				|| name.contains("energy") || name.contains("carbohydrate");
	}

	/**
	 * Create fallback nutrition data when API is unavailable
	 * 
	 * @param foodName Name of the food
	 * @param fdcId    FDC ID (can be 0 for unknown)
	 * @return Fallback nutrition data
	 */
	private FoodNutritionData createFallbackNutritionData(String foodName, long fdcId) {
		FoodNutritionData fallback = new FoodNutritionData();
		fallback.setFdcId(fdcId);
		fallback.setDescription(foodName + " (Fallback data - API unavailable)");
		fallback.setDataType("Fallback");
		fallback.setPublicationDate("2024-01-01");

		// Create basic nutrition data
		List<FoodNutritionData.FoodNutrient> nutrients = new ArrayList<>();

		// Add basic nutrients with moderate values
		addFallbackNutrient(nutrients, "Energy", 25.0, "kcal");
		addFallbackNutrient(nutrients, "Protein", 1.0, "g");
		addFallbackNutrient(nutrients, "Total lipid (fat)", 0.2, "g");
		addFallbackNutrient(nutrients, "Carbohydrate, by difference", 6.0, "g");
		addFallbackNutrient(nutrients, "Fiber, total dietary", 2.0, "g");
		addFallbackNutrient(nutrients, "Vitamin C, total ascorbic acid", 10.0, "mg");
		addFallbackNutrient(nutrients, "Calcium, Ca", 20.0, "mg");
		addFallbackNutrient(nutrients, "Iron, Fe", 0.5, "mg");
		addFallbackNutrient(nutrients, "Potassium, K", 200.0, "mg");

		fallback.setFoodNutrients(nutrients);

		LOGGER.info("Created fallback nutrition data for: " + foodName);
		return fallback;
	}

	/**
	 * Add a fallback nutrient to the nutrients list
	 */
	private void addFallbackNutrient(List<FoodNutritionData.FoodNutrient> nutrients, String name, double amount,
			String unit) {
		FoodNutritionData.FoodNutrient nutrient = new FoodNutritionData.FoodNutrient();
		nutrient.setAmount(amount);
		nutrient.setUnitName(unit);

		FoodNutritionData.Nutrient nutrientInfo = new FoodNutritionData.Nutrient();
		nutrientInfo.setName(name);
		nutrientInfo.setUnitName(unit);
		nutrient.setNutrient(nutrientInfo);

		nutrients.add(nutrient);
	}

	/**
	 * Create fallback search results when API is unavailable
	 * 
	 * @param foodName Name of the food searched
	 * @return Fallback search results
	 */
	private List<FoodSearchResult> createFallbackSearchResults(String foodName) {
		List<FoodSearchResult> results = new ArrayList<>();

		FoodSearchResult result = new FoodSearchResult();
		result.setFdcId(0L);
		result.setDescription(foodName + " (Fallback result - API unavailable)");
		result.setDataType("Fallback");
		result.setFoodCategory("Unknown");

		results.add(result);

		LOGGER.info("Created fallback search results for: " + foodName);
		return results;
	}

	/**
	 * Clear expired cache entries
	 */
	public void clearExpiredCache() {
		nutritionCache.entrySet().removeIf(entry -> entry.getValue().isExpired());
		LOGGER.info("Cleared expired nutrition cache entries");
	}

	/**
	 * Get cache statistics
	 * 
	 * @return Cache statistics as string
	 */
	public String getCacheStats() {
		long expired = nutritionCache.values().stream().mapToLong(cached -> cached.isExpired() ? 1 : 0).sum();

		return String.format("Nutrition Cache: %d total entries, %d expired", nutritionCache.size(), expired);
	}

	/**
	 * Simple class for food search results
	 */
	public static class FoodSearchResult {
		private long fdcId;
		private String description;
		private String dataType;
		private String foodCategory;

		// Getters and setters
		public long getFdcId() {
			return fdcId;
		}

		public void setFdcId(long fdcId) {
			this.fdcId = fdcId;
		}

		public String getDescription() {
			return description;
		}

		public void setDescription(String description) {
			this.description = description;
		}

		public String getDataType() {
			return dataType;
		}

		public void setDataType(String dataType) {
			this.dataType = dataType;
		}

		public String getFoodCategory() {
			return foodCategory;
		}

		public void setFoodCategory(String foodCategory) {
			this.foodCategory = foodCategory;
		}
	}
}
