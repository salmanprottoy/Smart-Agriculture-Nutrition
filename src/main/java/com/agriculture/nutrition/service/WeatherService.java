package com.agriculture.nutrition.service;

import com.agriculture.nutrition.model.WeatherData;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import javax.ws.rs.client.Client;
import javax.ws.rs.client.ClientBuilder;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import java.util.concurrent.ConcurrentHashMap;
import java.util.Map;
import java.util.logging.Logger;
import java.util.logging.Level;

/**
 * Service for integrating with WeatherAPI.com Provides real-time weather data
 * for agricultural analysis
 */
public class WeatherService {

	private static final Logger LOGGER = Logger.getLogger(WeatherService.class.getName());

	// WeatherAPI.com configuration
	private static final String WEATHER_API_BASE_URL = "https://api.weatherapi.com/v1";
	private static final String API_KEY = loadApiKey();

	/**
	 * Load API key from environment or .env file
	 */
	private static String loadApiKey() {
		// First try system environment
		String key = System.getenv("WEATHERAPI_KEY");
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
				java.io.InputStream is = WeatherService.class.getClassLoader().getResourceAsStream(configPath);
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

				String envKey = props.getProperty("WEATHERAPI_KEY");
				if (envKey != null && !envKey.trim().isEmpty()) {
					LOGGER.info("Loaded WeatherAPI key from config file: " + configPath);
					return envKey;
				}
			} catch (Exception e) {
				// Continue to next path
				continue;
			}
		}

		LOGGER.warning("Could not load WeatherAPI key from any configuration file");

		LOGGER.warning("WeatherAPI key not found, using fallback data");
		return "demo_key";
	}

	// Simple in-memory cache (5 minutes TTL)
	private final Map<String, CachedWeatherData> weatherCache = new ConcurrentHashMap<>();
	private static final long CACHE_TTL = 5 * 60 * 1000; // 5 minutes in milliseconds

	private final Client httpClient;
	private final ObjectMapper objectMapper;

	// Cache entry class
	private static class CachedWeatherData {
		final WeatherData data;
		final long timestamp;

		CachedWeatherData(WeatherData data) {
			this.data = data;
			this.timestamp = System.currentTimeMillis();
		}

		boolean isExpired() {
			return System.currentTimeMillis() - timestamp > CACHE_TTL;
		}
	}

	public WeatherService() {
		this.httpClient = ClientBuilder.newClient();
		this.objectMapper = new ObjectMapper();
	}

	/**
	 * Get current weather data for a city
	 * 
	 * @param cityName Name of the city
	 * @return Weather data or fallback data if API fails
	 */
	public WeatherData getCurrentWeather(String cityName) {
		if (cityName == null || cityName.trim().isEmpty()) {
			return createFallbackWeatherData("Unknown Location");
		}

		// Check cache first
		String cacheKey = "current_" + cityName.toLowerCase().trim();
		CachedWeatherData cached = weatherCache.get(cacheKey);

		if (cached != null && !cached.isExpired()) {
			LOGGER.info("Returning cached weather data for: " + cityName);
			return cached.data;
		}

		try {
			// Make API call to WeatherAPI.com
			String url = String.format("%s/current.json?key=%s&q=%s&aqi=no", WEATHER_API_BASE_URL, API_KEY,
					cityName.trim());

			Response response = httpClient.target(url).request(MediaType.APPLICATION_JSON).get();

			if (response.getStatus() == 200) {
				String jsonResponse = response.readEntity(String.class);
				WeatherData weatherData = convertWeatherApiResponse(jsonResponse);

				// Cache the result
				weatherCache.put(cacheKey, new CachedWeatherData(weatherData));

				LOGGER.info("Successfully fetched weather data for: " + cityName);
				return weatherData;
			} else {
				LOGGER.warning("Weather API returned status: " + response.getStatus() + " for city: " + cityName);
				return createFallbackWeatherData(cityName);
			}

		} catch (Exception e) {
			LOGGER.log(Level.WARNING, "Failed to fetch weather data for: " + cityName, e);
			return createFallbackWeatherData(cityName);
		}
	}

	/**
	 * Get weather data by coordinates
	 * 
	 * @param latitude  Latitude
	 * @param longitude Longitude
	 * @return Weather data or fallback data if API fails
	 */
	public WeatherData getWeatherByCoordinates(double latitude, double longitude) {
		// Validate coordinates
		if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
			return createFallbackWeatherData("Invalid Coordinates");
		}

		// Check cache first
		String cacheKey = String.format("coords_%.2f_%.2f", latitude, longitude);
		CachedWeatherData cached = weatherCache.get(cacheKey);

		if (cached != null && !cached.isExpired()) {
			LOGGER.info("Returning cached weather data for coordinates: " + latitude + ", " + longitude);
			return cached.data;
		}

		try {
			// Make API call to WeatherAPI.com
			String url = String.format("%s/current.json?key=%s&q=%f,%f&aqi=no", WEATHER_API_BASE_URL, API_KEY, latitude,
					longitude);

			Response response = httpClient.target(url).request(MediaType.APPLICATION_JSON).get();

			if (response.getStatus() == 200) {
				String jsonResponse = response.readEntity(String.class);
				WeatherData weatherData = convertWeatherApiResponse(jsonResponse);

				// Cache the result
				weatherCache.put(cacheKey, new CachedWeatherData(weatherData));

				LOGGER.info("Successfully fetched weather data for coordinates: " + latitude + ", " + longitude);
				return weatherData;
			} else {
				LOGGER.warning("Weather API returned status: " + response.getStatus() + " for coordinates: " + latitude
						+ ", " + longitude);
				return createFallbackWeatherData("Location");
			}

		} catch (Exception e) {
			LOGGER.log(Level.WARNING, "Failed to fetch weather data for coordinates: " + latitude + ", " + longitude,
					e);
			return createFallbackWeatherData("Location");
		}
	}

	/**
	 * Convert WeatherAPI.com response to our WeatherData format
	 * 
	 * @param jsonResponse JSON response from WeatherAPI.com
	 * @return WeatherData object
	 */
	private WeatherData convertWeatherApiResponse(String jsonResponse) throws Exception {
		JsonNode root = objectMapper.readTree(jsonResponse);
		JsonNode location = root.get("location");
		JsonNode current = root.get("current");
		JsonNode condition = current.get("condition");

		WeatherData weatherData = new WeatherData();

		// Location information
		weatherData.setName(location.get("name").asText());
		weatherData.setDt(current.get("last_updated_epoch").asLong());

		// Coordinates
		WeatherData.Coord coord = new WeatherData.Coord();
		coord.setLat(location.get("lat").asDouble());
		coord.setLon(location.get("lon").asDouble());
		weatherData.setCoord(coord);

		// Main weather data
		WeatherData.Main main = new WeatherData.Main();
		main.setTemp(current.get("temp_c").asDouble() + 273.15); // Convert to Kelvin for consistency
		main.setHumidity(current.get("humidity").asDouble());
		main.setPressure(current.get("pressure_mb").asDouble());
		main.setFeelsLike(current.get("feelslike_c").asDouble() + 273.15);
		main.setTempMin(main.getTemp() - 2); // Approximate
		main.setTempMax(main.getTemp() + 2); // Approximate
		weatherData.setMain(main);

		// Weather condition
		WeatherData.Weather weather = new WeatherData.Weather();
		weather.setMain(condition.get("text").asText());
		weather.setDescription(condition.get("text").asText().toLowerCase());
		weather.setIcon(condition.get("icon").asText());
		weatherData.setWeather(java.util.Arrays.asList(weather));

		// Wind data
		WeatherData.Wind wind = new WeatherData.Wind();
		wind.setSpeed(current.get("wind_kph").asDouble() / 3.6); // Convert kph to m/s
		wind.setDeg(current.get("wind_degree").asDouble());
		weatherData.setWind(wind);

		// Visibility
		weatherData.setVisibility(current.get("vis_km").asDouble() * 1000); // Convert to meters

		return weatherData;
	}

	/**
	 * Analyze weather impact on crop nutrition
	 * 
	 * @param cityName City name for weather data
	 * @param cropType Type of crop
	 * @return Analysis of weather impact on crop nutrition
	 */
	public String analyzeWeatherImpactOnNutrition(String cityName, String cropType) {
		WeatherData weather = getCurrentWeather(cityName);
		double impactScore = weather.calculateAgricultureImpactScore();
		String nutritionImpact = weather.getNutritionImpact();

		StringBuilder analysis = new StringBuilder();
		analysis.append(String.format("Weather Analysis for %s in %s:\n", cropType, cityName));
		analysis.append(String.format("Current Conditions: %s\n",
				weather.getWeather() != null && !weather.getWeather().isEmpty()
						? weather.getWeather().get(0).getDescription()
						: "Unknown"));

		if (weather.getMain() != null) {
			double tempCelsius = weather.getMain().getTemp() - 273.15;
			analysis.append(String.format("Temperature: %.1f°C, Humidity: %.0f%%\n", tempCelsius,
					weather.getMain().getHumidity()));
		}

		analysis.append(String.format("Agricultural Impact Score: %.1f/10\n", impactScore));
		analysis.append(String.format("Nutrition Impact: %s\n", nutritionImpact));

		// Crop-specific recommendations
		analysis.append(getCropSpecificImpact(weather, cropType));

		return analysis.toString();
	}

	/**
	 * Get crop-specific weather impact analysis
	 * 
	 * @param weather  Current weather data
	 * @param cropType Type of crop
	 * @return Crop-specific impact analysis
	 */
	public String getCropSpecificImpact(WeatherData weather, String cropType) {
		if (weather.getMain() == null)
			return "Weather data unavailable for analysis.";

		double tempCelsius = weather.getMain().getTemp() - 273.15;
		double humidity = weather.getMain().getHumidity();

		StringBuilder impact = new StringBuilder();
		impact.append("Crop-Specific Impact Analysis:\n");

		switch (cropType.toLowerCase()) {
		case "tomato":
		case "tomatoes":
			if (tempCelsius >= 18 && tempCelsius <= 26) {
				impact.append("- Optimal temperature range for lycopene development\n");
				impact.append("- Vitamin C content will be maximized\n");
			} else if (tempCelsius > 30) {
				impact.append("- High temperature may reduce lycopene content by 10-15%\n");
				impact.append("- Consider shade protection during peak heat\n");
			} else if (tempCelsius < 15) {
				impact.append("- Low temperature slows nutrient development\n");
				impact.append("- Harvest may have reduced vitamin content\n");
			}

			if (humidity > 80) {
				impact.append("- High humidity increases disease risk, affecting nutrition\n");
			} else if (humidity < 40) {
				impact.append("- Low humidity may stress plants, reducing nutrient uptake\n");
			}
			break;

		case "lettuce":
			if (tempCelsius <= 20) {
				impact.append("- Cool temperature optimal for vitamin retention\n");
				impact.append("- Folate and vitamin K content will be high\n");
			} else if (tempCelsius > 25) {
				impact.append("- High temperature may cause bolting\n");
				impact.append("- Nutritional quality may decrease significantly\n");
			}
			break;

		case "carrot":
		case "carrots":
			if (tempCelsius >= 15 && tempCelsius <= 20) {
				impact.append("- Optimal temperature for beta-carotene development\n");
			} else if (tempCelsius > 25) {
				impact.append("- High temperature may reduce beta-carotene by 20%\n");
			}
			break;

		case "spinach":
			if (tempCelsius <= 18) {
				impact.append("- Cool weather enhances iron and folate content\n");
			} else {
				impact.append("- Warm weather may reduce nutritional density\n");
			}
			break;

		case "broccoli":
			if (tempCelsius >= 15 && tempCelsius <= 20) {
				impact.append("- Optimal conditions for vitamin C and sulforaphane\n");
			} else if (tempCelsius > 25) {
				impact.append("- Heat stress may reduce antioxidant compounds\n");
			}
			break;

		default:
			impact.append("- Monitor temperature and humidity for optimal nutrition\n");
			impact.append("- Consider protective measures during extreme weather\n");
		}

		return impact.toString();
	}

	/**
	 * Create fallback weather data when API is unavailable
	 * 
	 * @param locationName Name of the location
	 * @return Fallback weather data
	 */
	private WeatherData createFallbackWeatherData(String locationName) {
		WeatherData fallback = new WeatherData();
		fallback.setName("Fallback Data - " + locationName);
		fallback.setDt(System.currentTimeMillis() / 1000);

		// Create fallback main data (moderate conditions)
		WeatherData.Main main = new WeatherData.Main();
		main.setTemp(293.15); // 20°C in Kelvin
		main.setHumidity(60);
		main.setPressure(1013);
		main.setTempMin(288.15); // 15°C
		main.setTempMax(298.15); // 25°C
		main.setFeelsLike(293.15);
		fallback.setMain(main);

		// Create fallback weather condition
		WeatherData.Weather weatherCondition = new WeatherData.Weather();
		weatherCondition.setMain("Clear");
		weatherCondition.setDescription("fallback data - api unavailable");
		weatherCondition.setIcon("01d");
		fallback.setWeather(java.util.Arrays.asList(weatherCondition));

		// Create fallback coordinates (Jyväskylä, Finland as default)
		WeatherData.Coord coord = new WeatherData.Coord();
		coord.setLat(62.2426);
		coord.setLon(25.7342);
		fallback.setCoord(coord);

		// Create fallback wind data
		WeatherData.Wind wind = new WeatherData.Wind();
		wind.setSpeed(3.0); // 3 m/s
		wind.setDeg(180.0); // South
		fallback.setWind(wind);

		fallback.setVisibility(10000); // 10km

		LOGGER.info("Created fallback weather data for: " + locationName);
		return fallback;
	}

	/**
	 * Clear expired cache entries
	 */
	public void clearExpiredCache() {
		int sizeBefore = weatherCache.size();
		weatherCache.entrySet().removeIf(entry -> entry.getValue().isExpired());
		int sizeAfter = weatherCache.size();
		LOGGER.info(String.format("Cleared %d expired weather cache entries", sizeBefore - sizeAfter));
	}

	/**
	 * Get cache statistics
	 * 
	 * @return Cache statistics as string
	 */
	public String getCacheStats() {
		long expired = weatherCache.values().stream().mapToLong(cached -> cached.isExpired() ? 1 : 0).sum();

		long fresh = weatherCache.size() - expired;

		return String.format(
				"Weather Cache Statistics:\n" + "- Total entries: %d\n" + "- Fresh entries: %d\n"
						+ "- Expired entries: %d\n" + "- Cache TTL: %d minutes\n" + "- API Provider: WeatherAPI.com",
				weatherCache.size(), fresh, expired, CACHE_TTL / 60000);
	}

	/**
	 * Get weather service health status
	 * 
	 * @return Health status information
	 */
	public String getHealthStatus() {
		try {
			// Test API connectivity with a simple request
			WeatherData testData = getCurrentWeather("London");
			boolean isHealthy = testData != null && !testData.getName().contains("Fallback");

			return String.format(
					"Weather Service Health:\n" + "- Status: %s\n" + "- API Provider: WeatherAPI.com\n"
							+ "- Cache Size: %d entries\n" + "- Last Check: %s",
					isHealthy ? "HEALTHY" : "DEGRADED", weatherCache.size(), new java.util.Date().toString());
		} catch (Exception e) {
			return "Weather Service Health: ERROR - " + e.getMessage();
		}
	}
}
