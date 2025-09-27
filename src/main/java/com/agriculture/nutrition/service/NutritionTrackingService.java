package com.agriculture.nutrition.service;

import com.agriculture.nutrition.model.PersonalNutritionTracker;
import com.agriculture.nutrition.model.MealSource;
import com.agriculture.nutrition.exception.TrackerNotFoundException;
import com.agriculture.nutrition.config.DatabaseConfig;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.sql.*;
import java.util.*;
import java.util.concurrent.atomic.AtomicLong;
import java.util.stream.Collectors;
import java.util.logging.Logger;
import java.util.logging.Level;

public class NutritionTrackingService {

	private static final Logger LOGGER = Logger.getLogger(NutritionTrackingService.class.getName());
	private final DatabaseConfig dbConfig;
	private final ObjectMapper objectMapper;

	// In-memory storage (fallback when database is not available)
	private static Map<Long, PersonalNutritionTracker> nutritionTrackers = new HashMap<>();
	private static Map<Long, MealSource> mealSources = new HashMap<>();
	private static AtomicLong trackerIdCounter = new AtomicLong(1);
	private static AtomicLong mealIdCounter = new AtomicLong(1);

	// Static initialization with sample data
	static {
		initializeSampleData();
	}

	public NutritionTrackingService() {
		this.dbConfig = DatabaseConfig.getInstance();
		this.objectMapper = new ObjectMapper();
	}

	// Nutrition Tracker operations - ALL DATABASE OPERATIONS
	public List<PersonalNutritionTracker> getAllTrackers() {
		if (dbConfig.isDatabaseAvailable()) {
			return getAllTrackersFromDatabase();
		} else {
			// Fallback to in-memory only if database unavailable
			return new ArrayList<>(nutritionTrackers.values());
		}
	}

	public PersonalNutritionTracker getTracker(long id) {
		if (dbConfig.isDatabaseAvailable()) {
			return getTrackerFromDatabase(id);
		} else {
			// Fallback to in-memory only if database unavailable
			PersonalNutritionTracker tracker = nutritionTrackers.get(id);
			if (tracker == null) {
				throw new TrackerNotFoundException("Personal nutrition tracker with id " + id + " not found");
			}
			return tracker;
		}
	}

	private List<PersonalNutritionTracker> getAllTrackersFromDatabase() {
		String sql = "SELECT id, user_name, age, current_bmi, health_goals, dietary_restrictions, "
				+ "daily_nutrient_intake, farm_to_fork_score, created_at, updated_at "
				+ "FROM personal_nutrition_trackers ORDER BY id";

		List<PersonalNutritionTracker> trackers = new ArrayList<>();

		try (Connection conn = dbConfig.getConnection();
				PreparedStatement stmt = conn.prepareStatement(sql);
				ResultSet rs = stmt.executeQuery()) {

			while (rs.next()) {
				PersonalNutritionTracker tracker = mapResultSetToTracker(rs);
				trackers.add(tracker);
			}

			LOGGER.info("Retrieved " + trackers.size() + " trackers from database");
			return trackers;

		} catch (Exception e) {
			LOGGER.log(Level.SEVERE, "Failed to get trackers from database: " + e.getMessage(), e);
			// Fallback to in-memory
			return new ArrayList<>(nutritionTrackers.values());
		}
	}

	private PersonalNutritionTracker getTrackerFromDatabase(long id) {
		String sql = "SELECT id, user_name, age, current_bmi, health_goals, dietary_restrictions, "
				+ "daily_nutrient_intake, farm_to_fork_score, created_at, updated_at "
				+ "FROM personal_nutrition_trackers WHERE id = ?";

		try (Connection conn = dbConfig.getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {

			stmt.setLong(1, id);
			ResultSet rs = stmt.executeQuery();

			if (rs.next()) {
				PersonalNutritionTracker tracker = mapResultSetToTracker(rs);
				LOGGER.info("Retrieved tracker from database with ID: " + id);
				return tracker;
			} else {
				throw new TrackerNotFoundException("Personal nutrition tracker with id " + id + " not found");
			}

		} catch (SQLException e) {
			LOGGER.log(Level.SEVERE, "Failed to get tracker from database: " + e.getMessage(), e);
			throw new TrackerNotFoundException("Personal nutrition tracker with id " + id + " not found");
		}
	}

	private PersonalNutritionTracker mapResultSetToTracker(ResultSet rs) throws SQLException {
		PersonalNutritionTracker tracker = new PersonalNutritionTracker();
		tracker.setId(rs.getLong("id"));
		tracker.setUserName(rs.getString("user_name"));
		tracker.setCurrentBMI(rs.getBigDecimal("current_bmi").doubleValue());
		tracker.setFarmToForkScore(rs.getBigDecimal("farm_to_fork_score").doubleValue());
		tracker.setTrackingDate(rs.getTimestamp("created_at"));

		// Handle arrays
		Array healthGoalsArray = rs.getArray("health_goals");
		if (healthGoalsArray != null) {
			String[] goals = (String[]) healthGoalsArray.getArray();
			tracker.setHealthGoals(Arrays.asList(goals));
		}

		// Handle JSON
		String nutrientJson = rs.getString("daily_nutrient_intake");
		if (nutrientJson != null) {
			try {
				Map<String, Double> nutrients = objectMapper.readValue(nutrientJson, Map.class);
				tracker.setDailyNutrientIntake(nutrients);
			} catch (Exception e) {
				LOGGER.warning("Failed to parse nutrient JSON: " + e.getMessage());
			}
		}

		return tracker;
	}

	public PersonalNutritionTracker addTracker(PersonalNutritionTracker tracker) {
		if (dbConfig.isDatabaseAvailable()) {
			return addTrackerToDatabase(tracker);
		} else {
			// Fallback to in-memory storage
			long id = trackerIdCounter.getAndIncrement();
			tracker.setId(id);
			tracker.setTrackingDate(new java.util.Date());
			nutritionTrackers.put(id, tracker);
			LOGGER.info("Added tracker to in-memory storage (database not available)");
			return tracker;
		}
	}

	private PersonalNutritionTracker addTrackerToDatabase(PersonalNutritionTracker tracker) {
		String sql = "INSERT INTO personal_nutrition_trackers "
				+ "(user_name, current_bmi, health_goals, daily_nutrient_intake, farm_to_fork_score) "
				+ "VALUES (?, ?, ?, ?::jsonb, ?) RETURNING id, created_at";

		try (Connection conn = dbConfig.getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {

			stmt.setString(1, tracker.getUserName());
			stmt.setBigDecimal(2, java.math.BigDecimal.valueOf(tracker.getCurrentBMI()));

			// Convert health goals to PostgreSQL array
			if (tracker.getHealthGoals() != null) {
				Array healthGoalsArray = conn.createArrayOf("text", tracker.getHealthGoals().toArray());
				stmt.setArray(3, healthGoalsArray);
			} else {
				stmt.setNull(3, Types.ARRAY);
			}

			// Convert daily nutrient intake to JSON
			if (tracker.getDailyNutrientIntake() != null) {
				String nutrientJson = objectMapper.writeValueAsString(tracker.getDailyNutrientIntake());
				stmt.setString(4, nutrientJson);
			} else {
				stmt.setNull(4, Types.OTHER);
			}

			stmt.setBigDecimal(5, java.math.BigDecimal.valueOf(tracker.getFarmToForkScore()));

			ResultSet rs = stmt.executeQuery();
			if (rs.next()) {
				tracker.setId(rs.getLong("id"));
				tracker.setTrackingDate(rs.getTimestamp("created_at"));
				LOGGER.info("Successfully added tracker to database with ID: " + tracker.getId());
				return tracker;
			}

		} catch (Exception e) {
			LOGGER.log(Level.SEVERE, "Failed to add tracker to database: " + e.getMessage(), e);
			// Fallback to in-memory storage
			long id = trackerIdCounter.getAndIncrement();
			tracker.setId(id);
			tracker.setTrackingDate(new java.util.Date());
			nutritionTrackers.put(id, tracker);
			LOGGER.info("Added tracker to in-memory storage as fallback");
		}

		return tracker;
	}

	public PersonalNutritionTracker updateTracker(PersonalNutritionTracker tracker) {
		if (dbConfig.isDatabaseAvailable()) {
			return updateTrackerInDatabase(tracker);
		} else {
			// Fallback to in-memory
			if (!nutritionTrackers.containsKey(tracker.getId())) {
				throw new TrackerNotFoundException(
						"Personal nutrition tracker with id " + tracker.getId() + " not found");
			}
			tracker.setTrackingDate(new java.util.Date());
			nutritionTrackers.put(tracker.getId(), tracker);
			return tracker;
		}
	}

	public void removeTracker(long id) {
		if (dbConfig.isDatabaseAvailable()) {
			removeTrackerFromDatabase(id);
		} else {
			// Fallback to in-memory
			if (!nutritionTrackers.containsKey(id)) {
				throw new TrackerNotFoundException("Personal nutrition tracker with id " + id + " not found");
			}
			nutritionTrackers.remove(id);
			// Also remove associated meal sources
			mealSources.entrySet().removeIf(entry -> entry.getValue().getTrackerId() == id);
		}
	}

	private PersonalNutritionTracker updateTrackerInDatabase(PersonalNutritionTracker tracker) {
		String sql = "UPDATE personal_nutrition_trackers SET " + "user_name = ?, current_bmi = ?, health_goals = ?, "
				+ "daily_nutrient_intake = ?::jsonb, farm_to_fork_score = ?, updated_at = CURRENT_TIMESTAMP "
				+ "WHERE id = ? RETURNING updated_at";

		try (Connection conn = dbConfig.getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {

			stmt.setString(1, tracker.getUserName());
			stmt.setBigDecimal(2, java.math.BigDecimal.valueOf(tracker.getCurrentBMI()));

			// Convert health goals to PostgreSQL array
			if (tracker.getHealthGoals() != null) {
				Array healthGoalsArray = conn.createArrayOf("text", tracker.getHealthGoals().toArray());
				stmt.setArray(3, healthGoalsArray);
			} else {
				stmt.setNull(3, Types.ARRAY);
			}

			// Convert daily nutrient intake to JSON
			if (tracker.getDailyNutrientIntake() != null) {
				String nutrientJson = objectMapper.writeValueAsString(tracker.getDailyNutrientIntake());
				stmt.setString(4, nutrientJson);
			} else {
				stmt.setNull(4, Types.OTHER);
			}

			stmt.setBigDecimal(5, java.math.BigDecimal.valueOf(tracker.getFarmToForkScore()));
			stmt.setLong(6, tracker.getId());

			ResultSet rs = stmt.executeQuery();
			if (rs.next()) {
				tracker.setTrackingDate(rs.getTimestamp("updated_at"));
				LOGGER.info("Successfully updated tracker in database with ID: " + tracker.getId());
				return tracker;
			} else {
				throw new TrackerNotFoundException(
						"Personal nutrition tracker with id " + tracker.getId() + " not found");
			}

		} catch (Exception e) {
			LOGGER.log(Level.SEVERE, "Failed to update tracker in database: " + e.getMessage(), e);
			throw new TrackerNotFoundException("Personal nutrition tracker with id " + tracker.getId() + " not found");
		}
	}

	private void removeTrackerFromDatabase(long id) {
		// First delete associated meal sources, then the tracker
		String deleteMealsSql = "DELETE FROM meal_sources WHERE tracker_id = ?";
		String deleteTrackerSql = "DELETE FROM personal_nutrition_trackers WHERE id = ?";

		try (Connection conn = dbConfig.getConnection()) {
			conn.setAutoCommit(false); // Start transaction

			try {
				// Delete meal sources first
				try (PreparedStatement stmt = conn.prepareStatement(deleteMealsSql)) {
					stmt.setLong(1, id);
					int mealsDeleted = stmt.executeUpdate();
					LOGGER.info("Deleted " + mealsDeleted + " meal sources for tracker ID: " + id);
				}

				// Delete tracker
				try (PreparedStatement stmt = conn.prepareStatement(deleteTrackerSql)) {
					stmt.setLong(1, id);
					int trackersDeleted = stmt.executeUpdate();

					if (trackersDeleted == 0) {
						throw new TrackerNotFoundException("Personal nutrition tracker with id " + id + " not found");
					}

					LOGGER.info("Successfully deleted tracker from database with ID: " + id);
				}

				conn.commit(); // Commit transaction

			} catch (Exception e) {
				conn.rollback(); // Rollback on error
				throw e;
			}

		} catch (SQLException e) {
			LOGGER.log(Level.SEVERE, "Failed to delete tracker from database: " + e.getMessage(), e);
			throw new TrackerNotFoundException("Personal nutrition tracker with id " + id + " not found");
		}
	}

	// Query methods - DATABASE OPERATIONS
	public List<PersonalNutritionTracker> getTrackersByBMIRange(String bmiRange) {
		if (dbConfig.isDatabaseAvailable()) {
			return getTrackersByBMIRangeFromDatabase(bmiRange);
		} else {
			// Fallback to in-memory
			String[] range = bmiRange.split("-");
			if (range.length != 2)
				return new ArrayList<>();

			double minBMI = Double.parseDouble(range[0]);
			double maxBMI = Double.parseDouble(range[1]);

			return nutritionTrackers.values().stream()
					.filter(tracker -> tracker.getCurrentBMI() >= minBMI && tracker.getCurrentBMI() <= maxBMI)
					.collect(Collectors.toList());
		}
	}

	public List<PersonalNutritionTracker> getTrackersByHealthGoal(String healthGoal) {
		if (dbConfig.isDatabaseAvailable()) {
			return getTrackersByHealthGoalFromDatabase(healthGoal);
		} else {
			// Fallback to in-memory
			return nutritionTrackers.values().stream().filter(tracker -> tracker.getHealthGoals().contains(healthGoal))
					.collect(Collectors.toList());
		}
	}

	private List<PersonalNutritionTracker> getTrackersByBMIRangeFromDatabase(String bmiRange) {
		String[] range = bmiRange.split("-");
		if (range.length != 2)
			return new ArrayList<>();

		double minBMI = Double.parseDouble(range[0]);
		double maxBMI = Double.parseDouble(range[1]);

		String sql = "SELECT id, user_name, age, current_bmi, health_goals, dietary_restrictions, "
				+ "daily_nutrient_intake, farm_to_fork_score, created_at, updated_at "
				+ "FROM personal_nutrition_trackers WHERE current_bmi BETWEEN ? AND ? ORDER BY id";

		List<PersonalNutritionTracker> trackers = new ArrayList<>();

		try (Connection conn = dbConfig.getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {

			stmt.setBigDecimal(1, java.math.BigDecimal.valueOf(minBMI));
			stmt.setBigDecimal(2, java.math.BigDecimal.valueOf(maxBMI));

			ResultSet rs = stmt.executeQuery();
			while (rs.next()) {
				PersonalNutritionTracker tracker = mapResultSetToTracker(rs);
				trackers.add(tracker);
			}

			LOGGER.info("Retrieved " + trackers.size() + " trackers by BMI range from database");
			return trackers;

		} catch (Exception e) {
			LOGGER.log(Level.SEVERE, "Failed to get trackers by BMI range from database: " + e.getMessage(), e);
			return new ArrayList<>();
		}
	}

	private List<PersonalNutritionTracker> getTrackersByHealthGoalFromDatabase(String healthGoal) {
		String sql = "SELECT id, user_name, age, current_bmi, health_goals, dietary_restrictions, "
				+ "daily_nutrient_intake, farm_to_fork_score, created_at, updated_at "
				+ "FROM personal_nutrition_trackers WHERE ? = ANY(health_goals) ORDER BY id";

		List<PersonalNutritionTracker> trackers = new ArrayList<>();

		try (Connection conn = dbConfig.getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {

			stmt.setString(1, healthGoal);

			ResultSet rs = stmt.executeQuery();
			while (rs.next()) {
				PersonalNutritionTracker tracker = mapResultSetToTracker(rs);
				trackers.add(tracker);
			}

			LOGGER.info("Retrieved " + trackers.size() + " trackers by health goal from database");
			return trackers;

		} catch (Exception e) {
			LOGGER.log(Level.SEVERE, "Failed to get trackers by health goal from database: " + e.getMessage(), e);
			return new ArrayList<>();
		}
	}

	// Meal Source operations - DATABASE OPERATIONS
	public List<MealSource> getAllMealSources(long trackerId) {
		if (dbConfig.isDatabaseAvailable()) {
			return getAllMealSourcesFromDatabase(trackerId);
		} else {
			// Fallback to in-memory
			return mealSources.values().stream().filter(meal -> meal.getTrackerId() == trackerId)
					.collect(Collectors.toList());
		}
	}

	public MealSource addMealSource(MealSource mealSource) {
		if (dbConfig.isDatabaseAvailable()) {
			return addMealSourceToDatabase(mealSource);
		} else {
			// Fallback to in-memory
			long id = mealIdCounter.getAndIncrement();
			mealSource.setId(id);
			mealSources.put(id, mealSource);
			return mealSource;
		}
	}

	private List<MealSource> getAllMealSourcesFromDatabase(long trackerId) {
		String sql = "SELECT id, tracker_id, meal_name, meal_date, ingredients, "
				+ "local_source_percentage, nutritional_density, farm_origins, meal_notes, created_at "
				+ "FROM meal_sources WHERE tracker_id = ? ORDER BY id";

		List<MealSource> meals = new ArrayList<>();

		try (Connection conn = dbConfig.getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {

			stmt.setLong(1, trackerId);

			ResultSet rs = stmt.executeQuery();
			while (rs.next()) {
				MealSource meal = mapResultSetToMealSource(rs);
				meals.add(meal);
			}

			LOGGER.info("Retrieved " + meals.size() + " meal sources from database for tracker: " + trackerId);
			return meals;

		} catch (Exception e) {
			LOGGER.log(Level.SEVERE, "Failed to get meal sources from database: " + e.getMessage(), e);
			return new ArrayList<>();
		}
	}

	private MealSource addMealSourceToDatabase(MealSource mealSource) {
		String sql = "INSERT INTO meal_sources "
				+ "(tracker_id, meal_name, meal_date, ingredients, local_source_percentage, "
				+ "nutritional_density, farm_origins, meal_notes) "
				+ "VALUES (?, ?, ?, ?::jsonb, ?, ?, ?, ?) RETURNING id, created_at";

		try (Connection conn = dbConfig.getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {

			stmt.setLong(1, mealSource.getTrackerId());
			stmt.setString(2, mealSource.getMealName());
			stmt.setDate(3, new java.sql.Date(mealSource.getConsumptionDate().getTime()));

			// Convert ingredients to JSON
			if (mealSource.getIngredients() != null) {
				String ingredientsJson = objectMapper.writeValueAsString(mealSource.getIngredients());
				stmt.setString(4, ingredientsJson);
			} else {
				stmt.setNull(4, Types.OTHER);
			}

			stmt.setBigDecimal(5, java.math.BigDecimal.valueOf(mealSource.getLocalSourcePercentage()));
			stmt.setBigDecimal(6, java.math.BigDecimal.valueOf(mealSource.getNutritionalDensity()));

			// Convert ingredient origins to PostgreSQL array (using values from the map)
			if (mealSource.getIngredientOrigins() != null && !mealSource.getIngredientOrigins().isEmpty()) {
				List<String> origins = new ArrayList<>(mealSource.getIngredientOrigins().values());
				Array originsArray = conn.createArrayOf("text", origins.toArray());
				stmt.setArray(7, originsArray);
			} else {
				stmt.setNull(7, Types.ARRAY);
			}

			stmt.setString(8, "Added via API");

			ResultSet rs = stmt.executeQuery();
			if (rs.next()) {
				mealSource.setId(rs.getLong("id"));
				mealSource.setConsumptionDate(rs.getTimestamp("created_at"));
				LOGGER.info("Successfully added meal source to database with ID: " + mealSource.getId());
				return mealSource;
			}

		} catch (Exception e) {
			LOGGER.log(Level.SEVERE, "Failed to add meal source to database: " + e.getMessage(), e);
			// Fallback to in-memory
			long id = mealIdCounter.getAndIncrement();
			mealSource.setId(id);
			mealSources.put(id, mealSource);
			LOGGER.info("Added meal source to in-memory storage as fallback");
		}

		return mealSource;
	}

	private MealSource mapResultSetToMealSource(ResultSet rs) throws SQLException {
		MealSource meal = new MealSource();
		meal.setId(rs.getLong("id"));
		meal.setTrackerId(rs.getLong("tracker_id"));
		meal.setMealName(rs.getString("meal_name"));
		meal.setConsumptionDate(rs.getTimestamp("meal_date"));
		meal.setLocalSourcePercentage(rs.getBigDecimal("local_source_percentage").doubleValue());
		meal.setNutritionalDensity(rs.getBigDecimal("nutritional_density").doubleValue());

		// Handle JSON ingredients
		String ingredientsJson = rs.getString("ingredients");
		if (ingredientsJson != null) {
			try {
				List<String> ingredients = objectMapper.readValue(ingredientsJson, List.class);
				meal.setIngredients(ingredients);
			} catch (Exception e) {
				LOGGER.warning("Failed to parse ingredients JSON: " + e.getMessage());
			}
		}

		// Handle array farm origins - convert back to ingredient origins map
		Array originsArray = rs.getArray("farm_origins");
		if (originsArray != null) {
			String[] origins = (String[]) originsArray.getArray();
			// Create a simple mapping for the origins
			Map<String, String> ingredientOrigins = new HashMap<>();
			for (int i = 0; i < origins.length && meal.getIngredients() != null
					&& i < meal.getIngredients().size(); i++) {
				ingredientOrigins.put(meal.getIngredients().get(i), origins[i]);
			}
			meal.setIngredientOrigins(ingredientOrigins);
		}

		return meal;
	}

	public List<MealSource> getMealsByLocalPercentage(long trackerId, double localPercentage) {
		return mealSources.values().stream().filter(meal -> meal.getTrackerId() == trackerId)
				.filter(meal -> meal.getLocalSourcePercentage() >= localPercentage).collect(Collectors.toList());
	}

	public List<MealSource> getMealsByDate(long trackerId, String date) {
		return mealSources.values().stream().filter(meal -> meal.getTrackerId() == trackerId)
				.filter(meal -> meal.getConsumptionDate().toString().contains(date)).collect(Collectors.toList());
	}

	// Business logic methods
	public double calculateFarmToForkScore(PersonalNutritionTracker tracker) {
		double score = 5.0; // Base score

		// Calculate based on food sources
		Map<String, String> foodSources = tracker.getFoodSources();
		if (foodSources != null && !foodSources.isEmpty()) {
			long localSources = foodSources.values().stream()
					.mapToLong(source -> source.toLowerCase().contains("local") ? 1 : 0).sum();

			double localPercentage = (double) localSources / foodSources.size();
			score += localPercentage * 3.0; // Up to 3 points for local sourcing
		}

		// Bonus for organic sources
		if (foodSources != null) {
			long organicSources = foodSources.values().stream()
					.mapToLong(source -> source.toLowerCase().contains("organic") ? 1 : 0).sum();

			double organicPercentage = (double) organicSources / foodSources.size();
			score += organicPercentage * 2.0; // Up to 2 points for organic
		}

		return Math.min(score, 10.0); // Cap at 10
	}

	public void generateNutritionRecommendations(PersonalNutritionTracker tracker) {
		// Generate recommendations based on BMI and health goals
		List<String> recommendations = new ArrayList<>();

		double bmi = tracker.getCurrentBMI();
		if (bmi < 18.5) {
			recommendations.add("Increase caloric intake with nutrient-dense foods");
		} else if (bmi > 25.0) {
			recommendations.add("Focus on portion control and increase fiber intake");
		}

		// Add to health goals as recommendations
		if (tracker.getHealthGoals() == null) {
			tracker.setHealthGoals(new ArrayList<>());
		}
		tracker.getHealthGoals().addAll(recommendations);
	}

	public double calculateLocalPercentage(MealSource mealSource) {
		Map<String, String> origins = mealSource.getIngredientOrigins();
		if (origins == null || origins.isEmpty()) {
			return 0.0;
		}

		long localCount = origins.values().stream().mapToLong(
				origin -> origin.toLowerCase().contains("local") || origin.toLowerCase().contains("finland") ? 1 : 0)
				.sum();

		return (double) localCount / origins.size() * 100.0;
	}

	public double calculateNutritionalDensity(MealSource mealSource) {
		// Simple calculation based on number of ingredients and their diversity
		List<String> ingredients = mealSource.getIngredients();
		if (ingredients == null || ingredients.isEmpty()) {
			return 0.0;
		}

		// Base score for ingredient count
		double score = Math.min(ingredients.size() * 0.5, 5.0);

		// Bonus for variety (vegetables, proteins, grains)
		long vegetables = ingredients.stream().mapToLong(ingredient -> isVegetable(ingredient) ? 1 : 0).sum();
		long proteins = ingredients.stream().mapToLong(ingredient -> isProtein(ingredient) ? 1 : 0).sum();
		long grains = ingredients.stream().mapToLong(ingredient -> isGrain(ingredient) ? 1 : 0).sum();

		if (vegetables > 0)
			score += 2.0;
		if (proteins > 0)
			score += 2.0;
		if (grains > 0)
			score += 1.0;

		return Math.min(score, 10.0);
	}

	private boolean isVegetable(String ingredient) {
		String lower = ingredient.toLowerCase();
		return lower.contains("tomato") || lower.contains("carrot") || lower.contains("lettuce")
				|| lower.contains("spinach") || lower.contains("broccoli") || lower.contains("pepper");
	}

	private boolean isProtein(String ingredient) {
		String lower = ingredient.toLowerCase();
		return lower.contains("chicken") || lower.contains("fish") || lower.contains("beef") || lower.contains("egg")
				|| lower.contains("bean") || lower.contains("lentil");
	}

	private boolean isGrain(String ingredient) {
		String lower = ingredient.toLowerCase();
		return lower.contains("rice") || lower.contains("wheat") || lower.contains("oat") || lower.contains("barley")
				|| lower.contains("quinoa") || lower.contains("bread");
	}

	// Initialize sample data
	private static void initializeSampleData() {
		// Sample personal nutrition tracker 1
		PersonalNutritionTracker tracker1 = new PersonalNutritionTracker();
		tracker1.setId(1L);
		tracker1.setUserName("John Farmer");
		tracker1.setCurrentBMI(24.5); // From Task-2 BMI calculator

		Map<String, Double> dailyIntake1 = new HashMap<>();
		dailyIntake1.put("Vitamin C", 85.0);
		dailyIntake1.put("Fiber", 28.0);
		dailyIntake1.put("Protein", 65.0);
		dailyIntake1.put("Potassium", 2800.0);
		tracker1.setDailyNutrientIntake(dailyIntake1);

		tracker1.setHealthGoals(Arrays.asList("Weight Maintenance", "Increase Antioxidants", "Support Local Farming"));

		Map<String, String> foodSources1 = new HashMap<>();
		foodSources1.put("Cherry Tomatoes", "Local Organic Farm - Jyväskylä");
		foodSources1.put("Carrots", "Sustainable Farm - Tampere");
		foodSources1.put("Oats", "Local Grain Producer - Finland");
		tracker1.setFoodSources(foodSources1);

		tracker1.setFarmToForkScore(8.2);

		nutritionTrackers.put(1L, tracker1);

		// Sample personal nutrition tracker 2
		PersonalNutritionTracker tracker2 = new PersonalNutritionTracker();
		tracker2.setId(2L);
		tracker2.setUserName("Maria Sustainable");
		tracker2.setCurrentBMI(22.1);

		Map<String, Double> dailyIntake2 = new HashMap<>();
		dailyIntake2.put("Vitamin C", 95.0);
		dailyIntake2.put("Fiber", 32.0);
		dailyIntake2.put("Protein", 55.0);
		dailyIntake2.put("Beta-Carotene", 4500.0);
		tracker2.setDailyNutrientIntake(dailyIntake2);

		tracker2.setHealthGoals(Arrays.asList("Increase Vegetable Intake", "Reduce Carbon Footprint"));

		Map<String, String> foodSources2 = new HashMap<>();
		foodSources2.put("Hydroponic Carrots", "Sustainable Farm - Tampere");
		foodSources2.put("Organic Spinach", "Local Organic Farm - Jyväskylä");
		foodSources2.put("Quinoa", "Imported - South America");
		tracker2.setFoodSources(foodSources2);

		tracker2.setFarmToForkScore(7.5);

		nutritionTrackers.put(2L, tracker2);

		// Sample meal sources
		MealSource meal1 = new MealSource();
		meal1.setId(1L);
		meal1.setTrackerId(1L);
		meal1.setMealName("Farm Fresh Salad");
		meal1.setIngredients(Arrays.asList("Cherry Tomatoes", "Carrots", "Lettuce", "Olive Oil"));

		Map<String, String> origins1 = new HashMap<>();
		origins1.put("Cherry Tomatoes", "Local Organic Farm - Jyväskylä");
		origins1.put("Carrots", "Sustainable Farm - Tampere");
		origins1.put("Lettuce", "Local Farm - Finland");
		origins1.put("Olive Oil", "Imported - Italy");
		meal1.setIngredientOrigins(origins1);

		meal1.setLocalSourcePercentage(75.0);
		meal1.setNutritionalDensity(8.5);

		mealSources.put(1L, meal1);

		MealSource meal2 = new MealSource();
		meal2.setId(2L);
		meal2.setTrackerId(2L);
		meal2.setMealName("Sustainable Bowl");
		meal2.setIngredients(Arrays.asList("Hydroponic Carrots", "Quinoa", "Spinach", "Chickpeas"));

		Map<String, String> origins2 = new HashMap<>();
		origins2.put("Hydroponic Carrots", "Sustainable Farm - Tampere");
		origins2.put("Quinoa", "Imported - South America");
		origins2.put("Spinach", "Local Organic Farm - Jyväskylä");
		origins2.put("Chickpeas", "Local Producer - Finland");
		meal2.setIngredientOrigins(origins2);

		meal2.setLocalSourcePercentage(75.0);
		meal2.setNutritionalDensity(9.2);

		mealSources.put(2L, meal2);
	}
}
