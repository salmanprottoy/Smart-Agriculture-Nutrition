package com.agriculture.nutrition.service;

import com.agriculture.nutrition.model.CropNutritionProfile;
import com.agriculture.nutrition.model.HarvestBatch;
import com.agriculture.nutrition.exception.CropNotFoundException;
import com.agriculture.nutrition.config.DatabaseConfig;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.sql.*;
import java.util.*;
import java.util.concurrent.atomic.AtomicLong;
import java.util.stream.Collectors;
import java.util.logging.Logger;
import java.util.logging.Level;

public class CropNutritionService {

	private static final Logger LOGGER = Logger.getLogger(CropNutritionService.class.getName());
	private final DatabaseConfig dbConfig;
	private final ObjectMapper objectMapper;

	// In-memory storage (fallback when database is not available)
	private static Map<Long, CropNutritionProfile> cropProfiles = new HashMap<>();
	private static Map<Long, HarvestBatch> harvestBatches = new HashMap<>();
	private static AtomicLong cropIdCounter = new AtomicLong(1);
	private static AtomicLong batchIdCounter = new AtomicLong(1);

	// Static initialization with sample data
	static {
		initializeSampleData();
	}

	public CropNutritionService() {
		this.dbConfig = DatabaseConfig.getInstance();
		this.objectMapper = new ObjectMapper();
	}

	// Crop Profile operations - ALL DATABASE OPERATIONS
	public List<CropNutritionProfile> getAllProfiles() {
		if (dbConfig.isDatabaseAvailable()) {
			return getAllProfilesFromDatabase();
		} else {
			// Fallback to in-memory only if database unavailable
			return new ArrayList<>(cropProfiles.values());
		}
	}

	public CropNutritionProfile getProfile(long id) {
		if (dbConfig.isDatabaseAvailable()) {
			return getProfileFromDatabase(id);
		} else {
			// Fallback to in-memory only if database unavailable
			CropNutritionProfile profile = cropProfiles.get(id);
			if (profile == null) {
				throw new CropNotFoundException("Crop nutrition profile with id " + id + " not found");
			}
			return profile;
		}
	}

	public CropNutritionProfile addProfile(CropNutritionProfile profile) {
		if (dbConfig.isDatabaseAvailable()) {
			return addProfileToDatabase(profile);
		} else {
			// Fallback to in-memory storage
			long id = cropIdCounter.getAndIncrement();
			profile.setId(id);
			profile.setLastUpdated(new java.util.Date());
			cropProfiles.put(id, profile);
			LOGGER.info("Added crop profile to in-memory storage (database not available)");
			return profile;
		}
	}

	public CropNutritionProfile updateProfile(CropNutritionProfile profile) {
		if (dbConfig.isDatabaseAvailable()) {
			return updateProfileInDatabase(profile);
		} else {
			// Fallback to in-memory
			if (!cropProfiles.containsKey(profile.getId())) {
				throw new CropNotFoundException("Crop nutrition profile with id " + profile.getId() + " not found");
			}
			profile.setLastUpdated(new java.util.Date());
			cropProfiles.put(profile.getId(), profile);
			return profile;
		}
	}

	public void removeProfile(long id) {
		if (dbConfig.isDatabaseAvailable()) {
			removeProfileFromDatabase(id);
		} else {
			// Fallback to in-memory
			if (!cropProfiles.containsKey(id)) {
				throw new CropNotFoundException("Crop nutrition profile with id " + id + " not found");
			}
			cropProfiles.remove(id);
			// Also remove associated harvest batches
			harvestBatches.entrySet().removeIf(entry -> entry.getValue().getCropProfileId() == id);
		}
	}

	private List<CropNutritionProfile> getAllProfilesFromDatabase() {
		String sql = "SELECT id, crop_name, farm_location, growing_method, soil_nutrients, "
				+ "crop_nutrients, expected_harvest_date, sustainability_score, certifications, created_at, updated_at "
				+ "FROM crop_nutrition_profiles ORDER BY id";

		List<CropNutritionProfile> profiles = new ArrayList<>();

		try (Connection conn = dbConfig.getConnection();
				PreparedStatement stmt = conn.prepareStatement(sql);
				ResultSet rs = stmt.executeQuery()) {

			while (rs.next()) {
				CropNutritionProfile profile = mapResultSetToProfile(rs);
				profiles.add(profile);
			}

			LOGGER.info("Retrieved " + profiles.size() + " crop profiles from database");
			return profiles;

		} catch (Exception e) {
			LOGGER.log(Level.SEVERE, "Failed to get crop profiles from database: " + e.getMessage(), e);
			// Fallback to in-memory
			return new ArrayList<>(cropProfiles.values());
		}
	}

	private CropNutritionProfile getProfileFromDatabase(long id) {
		String sql = "SELECT id, crop_name, farm_location, growing_method, soil_nutrients, "
				+ "crop_nutrients, expected_harvest_date, sustainability_score, certifications, created_at, updated_at "
				+ "FROM crop_nutrition_profiles WHERE id = ?";

		try (Connection conn = dbConfig.getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {

			stmt.setLong(1, id);
			ResultSet rs = stmt.executeQuery();

			if (rs.next()) {
				CropNutritionProfile profile = mapResultSetToProfile(rs);
				LOGGER.info("Retrieved crop profile from database with ID: " + id);
				return profile;
			} else {
				throw new CropNotFoundException("Crop nutrition profile with id " + id + " not found");
			}

		} catch (SQLException e) {
			LOGGER.log(Level.SEVERE, "Failed to get crop profile from database: " + e.getMessage(), e);
			throw new CropNotFoundException("Crop nutrition profile with id " + id + " not found");
		}
	}

	private CropNutritionProfile addProfileToDatabase(CropNutritionProfile profile) {
		String sql = "INSERT INTO crop_nutrition_profiles "
				+ "(crop_name, farm_location, growing_method, soil_nutrients, crop_nutrients, "
				+ "expected_harvest_date, sustainability_score, certifications) "
				+ "VALUES (?, ?, ?, ?::jsonb, ?::jsonb, ?, ?, ?) RETURNING id, created_at, updated_at";

		try (Connection conn = dbConfig.getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {

			stmt.setString(1, profile.getCropName());
			stmt.setString(2, profile.getFarmLocation());
			stmt.setString(3, profile.getGrowingMethod());

			// Convert soil nutrients to JSON
			if (profile.getSoilNutrients() != null) {
				String soilJson = objectMapper.writeValueAsString(profile.getSoilNutrients());
				stmt.setString(4, soilJson);
			} else {
				stmt.setNull(4, Types.OTHER);
			}

			// Convert crop nutrients to JSON
			if (profile.getCropNutrients() != null) {
				String cropJson = objectMapper.writeValueAsString(profile.getCropNutrients());
				stmt.setString(5, cropJson);
			} else {
				stmt.setNull(5, Types.OTHER);
			}

			// Convert harvest season string to date (if it's a valid date format)
			if (profile.getHarvestSeason() != null && !profile.getHarvestSeason().trim().isEmpty()) {
				try {
					// Try to parse as a date, if it fails, set to null
					java.sql.Date harvestDate = java.sql.Date.valueOf(profile.getHarvestSeason());
					stmt.setDate(6, harvestDate);
				} catch (Exception e) {
					// If it's not a valid date format, set to null
					stmt.setNull(6, Types.DATE);
				}
			} else {
				stmt.setNull(6, Types.DATE);
			}
			stmt.setBigDecimal(7, java.math.BigDecimal.valueOf(profile.getSustainabilityScore()));

			// Convert certifications to PostgreSQL array
			if (profile.getCertifications() != null) {
				Array certificationsArray = conn.createArrayOf("text", profile.getCertifications().toArray());
				stmt.setArray(8, certificationsArray);
			} else {
				stmt.setNull(8, Types.ARRAY);
			}

			ResultSet rs = stmt.executeQuery();
			if (rs.next()) {
				profile.setId(rs.getLong("id"));
				profile.setLastUpdated(rs.getTimestamp("created_at"));
				LOGGER.info("Successfully added crop profile to database with ID: " + profile.getId());
				return profile;
			}

		} catch (Exception e) {
			LOGGER.log(Level.SEVERE, "Failed to add crop profile to database: " + e.getMessage(), e);
			// Fallback to in-memory storage
			long id = cropIdCounter.getAndIncrement();
			profile.setId(id);
			profile.setLastUpdated(new java.util.Date());
			cropProfiles.put(id, profile);
			LOGGER.info("Added crop profile to in-memory storage as fallback");
		}

		return profile;
	}

	private CropNutritionProfile updateProfileInDatabase(CropNutritionProfile profile) {
		String sql = "UPDATE crop_nutrition_profiles SET " + "crop_name = ?, farm_location = ?, growing_method = ?, "
				+ "soil_nutrients = ?::jsonb, crop_nutrients = ?::jsonb, "
				+ "expected_harvest_date = ?, sustainability_score = ?, certifications = ?, updated_at = CURRENT_TIMESTAMP "
				+ "WHERE id = ? RETURNING updated_at";

		try (Connection conn = dbConfig.getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {

			stmt.setString(1, profile.getCropName());
			stmt.setString(2, profile.getFarmLocation());
			stmt.setString(3, profile.getGrowingMethod());

			// Convert soil nutrients to JSON
			if (profile.getSoilNutrients() != null) {
				String soilJson = objectMapper.writeValueAsString(profile.getSoilNutrients());
				stmt.setString(4, soilJson);
			} else {
				stmt.setNull(4, Types.OTHER);
			}

			// Convert crop nutrients to JSON
			if (profile.getCropNutrients() != null) {
				String cropJson = objectMapper.writeValueAsString(profile.getCropNutrients());
				stmt.setString(5, cropJson);
			} else {
				stmt.setNull(5, Types.OTHER);
			}

			// Convert harvest season string to date (if it's a valid date format)
			if (profile.getHarvestSeason() != null && !profile.getHarvestSeason().trim().isEmpty()) {
				try {
					// Try to parse as a date, if it fails, set to null
					java.sql.Date harvestDate = java.sql.Date.valueOf(profile.getHarvestSeason());
					stmt.setDate(6, harvestDate);
				} catch (Exception e) {
					// If it's not a valid date format, set to null
					stmt.setNull(6, Types.DATE);
				}
			} else {
				stmt.setNull(6, Types.DATE);
			}
			stmt.setBigDecimal(7, java.math.BigDecimal.valueOf(profile.getSustainabilityScore()));

			// Convert certifications to PostgreSQL array
			if (profile.getCertifications() != null) {
				Array certificationsArray = conn.createArrayOf("text", profile.getCertifications().toArray());
				stmt.setArray(8, certificationsArray);
			} else {
				stmt.setNull(8, Types.ARRAY);
			}

			stmt.setLong(9, profile.getId());

			ResultSet rs = stmt.executeQuery();
			if (rs.next()) {
				profile.setLastUpdated(rs.getTimestamp("updated_at"));
				LOGGER.info("Successfully updated crop profile in database with ID: " + profile.getId());
				return profile;
			} else {
				throw new CropNotFoundException("Crop nutrition profile with id " + profile.getId() + " not found");
			}

		} catch (Exception e) {
			LOGGER.log(Level.SEVERE, "Failed to update crop profile in database: " + e.getMessage(), e);
			throw new CropNotFoundException("Crop nutrition profile with id " + profile.getId() + " not found");
		}
	}

	private void removeProfileFromDatabase(long id) {
		// First delete associated harvest batches, then the profile
		String deleteBatchesSql = "DELETE FROM harvest_batches WHERE crop_profile_id = ?";
		String deleteProfileSql = "DELETE FROM crop_nutrition_profiles WHERE id = ?";

		try (Connection conn = dbConfig.getConnection()) {
			conn.setAutoCommit(false); // Start transaction

			try {
				// Delete harvest batches first
				try (PreparedStatement stmt = conn.prepareStatement(deleteBatchesSql)) {
					stmt.setLong(1, id);
					int batchesDeleted = stmt.executeUpdate();
					LOGGER.info("Deleted " + batchesDeleted + " harvest batches for crop profile ID: " + id);
				}

				// Delete profile
				try (PreparedStatement stmt = conn.prepareStatement(deleteProfileSql)) {
					stmt.setLong(1, id);
					int profilesDeleted = stmt.executeUpdate();

					if (profilesDeleted == 0) {
						throw new CropNotFoundException("Crop nutrition profile with id " + id + " not found");
					}

					LOGGER.info("Successfully deleted crop profile from database with ID: " + id);
				}

				conn.commit(); // Commit transaction

			} catch (Exception e) {
				conn.rollback(); // Rollback on error
				throw e;
			}

		} catch (SQLException e) {
			LOGGER.log(Level.SEVERE, "Failed to delete crop profile from database: " + e.getMessage(), e);
			throw new CropNotFoundException("Crop nutrition profile with id " + id + " not found");
		}
	}

	private CropNutritionProfile mapResultSetToProfile(ResultSet rs) throws SQLException {
		CropNutritionProfile profile = new CropNutritionProfile();
		profile.setId(rs.getLong("id"));
		profile.setCropName(rs.getString("crop_name"));
		profile.setFarmLocation(rs.getString("farm_location"));
		profile.setGrowingMethod(rs.getString("growing_method"));
		// Convert date back to string for the model
		java.sql.Date harvestDate = rs.getDate("expected_harvest_date");
		if (harvestDate != null) {
			profile.setHarvestSeason(harvestDate.toString());
		} else {
			profile.setHarvestSeason(null);
		}
		profile.setSustainabilityScore(rs.getBigDecimal("sustainability_score").doubleValue());
		profile.setLastUpdated(rs.getTimestamp("updated_at"));

		// Handle JSON soil nutrients
		String soilJson = rs.getString("soil_nutrients");
		if (soilJson != null) {
			try {
				Map<String, Double> soilNutrients = objectMapper.readValue(soilJson, Map.class);
				profile.setSoilNutrients(soilNutrients);
			} catch (Exception e) {
				LOGGER.warning("Failed to parse soil nutrients JSON: " + e.getMessage());
			}
		}

		// Handle JSON crop nutrients
		String cropJson = rs.getString("crop_nutrients");
		if (cropJson != null) {
			try {
				Map<String, Double> cropNutrients = objectMapper.readValue(cropJson, Map.class);
				profile.setCropNutrients(cropNutrients);
			} catch (Exception e) {
				LOGGER.warning("Failed to parse crop nutrients JSON: " + e.getMessage());
			}
		}

		// Handle array certifications
		Array certificationsArray = rs.getArray("certifications");
		if (certificationsArray != null) {
			String[] certifications = (String[]) certificationsArray.getArray();
			profile.setCertifications(Arrays.asList(certifications));
		}

		return profile;
	}

	// Query methods - DATABASE OPERATIONS
	public List<CropNutritionProfile> getProfilesByCropType(String cropType) {
		if (dbConfig.isDatabaseAvailable()) {
			return getProfilesByCropTypeFromDatabase(cropType);
		} else {
			// Fallback to in-memory
			return cropProfiles.values().stream()
					.filter(profile -> profile.getCropName().toLowerCase().contains(cropType.toLowerCase()))
					.collect(Collectors.toList());
		}
	}

	public List<CropNutritionProfile> getProfilesByGrowingMethod(String method) {
		if (dbConfig.isDatabaseAvailable()) {
			return getProfilesByGrowingMethodFromDatabase(method);
		} else {
			// Fallback to in-memory
			return cropProfiles.values().stream().filter(profile -> method.equalsIgnoreCase(profile.getGrowingMethod()))
					.collect(Collectors.toList());
		}
	}

	public List<CropNutritionProfile> getProfilesByRegion(String region) {
		if (dbConfig.isDatabaseAvailable()) {
			return getProfilesByRegionFromDatabase(region);
		} else {
			// Fallback to in-memory
			return cropProfiles.values().stream()
					.filter(profile -> profile.getFarmLocation().toLowerCase().contains(region.toLowerCase()))
					.collect(Collectors.toList());
		}
	}

	private List<CropNutritionProfile> getProfilesByCropTypeFromDatabase(String cropType) {
		String sql = "SELECT id, crop_name, farm_location, growing_method, soil_nutrients, "
				+ "crop_nutrients, expected_harvest_date, sustainability_score, certifications, created_at, updated_at "
				+ "FROM crop_nutrition_profiles WHERE LOWER(crop_name) LIKE LOWER(?) ORDER BY id";

		List<CropNutritionProfile> profiles = new ArrayList<>();

		try (Connection conn = dbConfig.getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {

			stmt.setString(1, "%" + cropType + "%");

			ResultSet rs = stmt.executeQuery();
			while (rs.next()) {
				CropNutritionProfile profile = mapResultSetToProfile(rs);
				profiles.add(profile);
			}

			LOGGER.info("Retrieved " + profiles.size() + " crop profiles by crop type from database");
			return profiles;

		} catch (Exception e) {
			LOGGER.log(Level.SEVERE, "Failed to get crop profiles by crop type from database: " + e.getMessage(), e);
			return new ArrayList<>();
		}
	}

	private List<CropNutritionProfile> getProfilesByGrowingMethodFromDatabase(String method) {
		String sql = "SELECT id, crop_name, farm_location, growing_method, soil_nutrients, "
				+ "crop_nutrients, expected_harvest_date, sustainability_score, certifications, created_at, updated_at "
				+ "FROM crop_nutrition_profiles WHERE LOWER(growing_method) = LOWER(?) ORDER BY id";

		List<CropNutritionProfile> profiles = new ArrayList<>();

		try (Connection conn = dbConfig.getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {

			stmt.setString(1, method);

			ResultSet rs = stmt.executeQuery();
			while (rs.next()) {
				CropNutritionProfile profile = mapResultSetToProfile(rs);
				profiles.add(profile);
			}

			LOGGER.info("Retrieved " + profiles.size() + " crop profiles by growing method from database");
			return profiles;

		} catch (Exception e) {
			LOGGER.log(Level.SEVERE, "Failed to get crop profiles by growing method from database: " + e.getMessage(),
					e);
			return new ArrayList<>();
		}
	}

	private List<CropNutritionProfile> getProfilesByRegionFromDatabase(String region) {
		String sql = "SELECT id, crop_name, farm_location, growing_method, soil_nutrients, "
				+ "crop_nutrients, expected_harvest_date, sustainability_score, certifications, created_at, updated_at "
				+ "FROM crop_nutrition_profiles WHERE LOWER(farm_location) LIKE LOWER(?) ORDER BY id";

		List<CropNutritionProfile> profiles = new ArrayList<>();

		try (Connection conn = dbConfig.getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {

			stmt.setString(1, "%" + region + "%");

			ResultSet rs = stmt.executeQuery();
			while (rs.next()) {
				CropNutritionProfile profile = mapResultSetToProfile(rs);
				profiles.add(profile);
			}

			LOGGER.info("Retrieved " + profiles.size() + " crop profiles by region from database");
			return profiles;

		} catch (Exception e) {
			LOGGER.log(Level.SEVERE, "Failed to get crop profiles by region from database: " + e.getMessage(), e);
			return new ArrayList<>();
		}
	}

	// Harvest Batch operations - DATABASE OPERATIONS
	public List<HarvestBatch> getAllBatches(long cropProfileId) {
		if (dbConfig.isDatabaseAvailable()) {
			return getAllBatchesFromDatabase(cropProfileId);
		} else {
			// Fallback to in-memory
			return harvestBatches.values().stream().filter(batch -> batch.getCropProfileId() == cropProfileId)
					.collect(Collectors.toList());
		}
	}

	public HarvestBatch addHarvestBatch(HarvestBatch batch) {
		if (dbConfig.isDatabaseAvailable()) {
			return addHarvestBatchToDatabase(batch);
		} else {
			// Fallback to in-memory
			long id = batchIdCounter.getAndIncrement();
			batch.setId(id);
			harvestBatches.put(id, batch);
			return batch;
		}
	}

	private List<HarvestBatch> getAllBatchesFromDatabase(long cropProfileId) {
		String sql = "SELECT id, crop_profile_id, harvest_date, quantity_kg, quality_grade, "
				+ "weather_conditions, freshness_days, distribution_path, actual_nutrients, created_at "
				+ "FROM harvest_batches WHERE crop_profile_id = ? ORDER BY id";

		List<HarvestBatch> batches = new ArrayList<>();

		try (Connection conn = dbConfig.getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {

			stmt.setLong(1, cropProfileId);

			ResultSet rs = stmt.executeQuery();
			while (rs.next()) {
				HarvestBatch batch = mapResultSetToBatch(rs);
				batches.add(batch);
			}

			LOGGER.info("Retrieved " + batches.size() + " harvest batches from database for crop profile: "
					+ cropProfileId);
			return batches;

		} catch (Exception e) {
			LOGGER.log(Level.SEVERE, "Failed to get harvest batches from database: " + e.getMessage(), e);
			return new ArrayList<>();
		}
	}

	private HarvestBatch addHarvestBatchToDatabase(HarvestBatch batch) {
		String sql = "INSERT INTO harvest_batches " + "(crop_profile_id, harvest_date, quantity_kg, quality_grade, "
				+ "weather_conditions, freshness_days, distribution_path, actual_nutrients) "
				+ "VALUES (?, ?, ?, ?, ?, ?, ?, ?::jsonb) RETURNING id, created_at";

		try (Connection conn = dbConfig.getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {

			stmt.setLong(1, batch.getCropProfileId());
			stmt.setDate(2, new java.sql.Date(batch.getHarvestDate().getTime()));
			stmt.setBigDecimal(3, java.math.BigDecimal.valueOf(batch.getQuantity()));
			stmt.setString(4, batch.getQualityGrade());

			// Convert weather conditions to PostgreSQL array
			if (batch.getWeatherConditions() != null) {
				Array weatherArray = conn.createArrayOf("text", batch.getWeatherConditions().toArray());
				stmt.setArray(5, weatherArray);
			} else {
				stmt.setNull(5, Types.ARRAY);
			}

			stmt.setBigDecimal(6, java.math.BigDecimal.valueOf(batch.getFreshnessDays()));
			stmt.setString(7, batch.getDistributionPath());

			// Convert actual nutrients to JSON
			if (batch.getActualNutrients() != null) {
				String nutrientsJson = objectMapper.writeValueAsString(batch.getActualNutrients());
				stmt.setString(8, nutrientsJson);
			} else {
				stmt.setNull(8, Types.OTHER);
			}

			ResultSet rs = stmt.executeQuery();
			if (rs.next()) {
				batch.setId(rs.getLong("id"));
				batch.setHarvestDate(rs.getTimestamp("created_at"));
				LOGGER.info("Successfully added harvest batch to database with ID: " + batch.getId());
				return batch;
			}

		} catch (Exception e) {
			LOGGER.log(Level.SEVERE, "Failed to add harvest batch to database: " + e.getMessage(), e);
			// Fallback to in-memory
			long id = batchIdCounter.getAndIncrement();
			batch.setId(id);
			harvestBatches.put(id, batch);
			LOGGER.info("Added harvest batch to in-memory storage as fallback");
		}

		return batch;
	}

	private HarvestBatch mapResultSetToBatch(ResultSet rs) throws SQLException {
		HarvestBatch batch = new HarvestBatch();
		batch.setId(rs.getLong("id"));
		batch.setCropProfileId(rs.getLong("crop_profile_id"));
		batch.setHarvestDate(rs.getTimestamp("harvest_date"));
		batch.setQuantity(rs.getBigDecimal("quantity_kg").doubleValue());
		batch.setQualityGrade(rs.getString("quality_grade"));
		batch.setFreshnessDays(rs.getBigDecimal("freshness_days").doubleValue());
		batch.setDistributionPath(rs.getString("distribution_path"));

		// Handle array weather conditions
		Array weatherArray = rs.getArray("weather_conditions");
		if (weatherArray != null) {
			String[] conditions = (String[]) weatherArray.getArray();
			batch.setWeatherConditions(Arrays.asList(conditions));
		}

		// Handle JSON actual nutrients
		String nutrientsJson = rs.getString("actual_nutrients");
		if (nutrientsJson != null) {
			try {
				Map<String, Double> nutrients = objectMapper.readValue(nutrientsJson, Map.class);
				batch.setActualNutrients(nutrients);
			} catch (Exception e) {
				LOGGER.warning("Failed to parse actual nutrients JSON: " + e.getMessage());
			}
		}

		return batch;
	}

	public List<HarvestBatch> getBatchesByDate(long cropProfileId, String harvestDate) {
		return harvestBatches.values().stream().filter(batch -> batch.getCropProfileId() == cropProfileId)
				.filter(batch -> batch.getHarvestDate().toString().contains(harvestDate)).collect(Collectors.toList());
	}

	public List<HarvestBatch> getBatchesByQuality(long cropProfileId, String qualityGrade) {
		return harvestBatches.values().stream().filter(batch -> batch.getCropProfileId() == cropProfileId)
				.filter(batch -> qualityGrade.equalsIgnoreCase(batch.getQualityGrade())).collect(Collectors.toList());
	}

	// Business logic methods
	public double calculateSustainabilityScore(CropNutritionProfile profile) {
		double score = 5.0; // Base score

		if ("organic".equalsIgnoreCase(profile.getGrowingMethod())) {
			score += 2.0;
		} else if ("hydroponic".equalsIgnoreCase(profile.getGrowingMethod())) {
			score += 1.5;
		}

		if (profile.getCertifications() != null) {
			score += profile.getCertifications().size() * 0.5;
		}

		return Math.min(score, 10.0); // Cap at 10
	}

	public Map<String, Double> predictNutritionalContent(CropNutritionProfile profile) {
		Map<String, Double> predicted = new HashMap<>();

		// Simple prediction based on soil nutrients
		Map<String, Double> soil = profile.getSoilNutrients();
		if (soil != null) {
			predicted.put("Vitamin C", soil.getOrDefault("Nitrogen", 0.0) * 0.6);
			predicted.put("Potassium", soil.getOrDefault("Potassium", 0.0) * 1.2);
			predicted.put("Fiber", soil.getOrDefault("Phosphorus", 0.0) * 0.8);
		}

		return predicted;
	}

	public Map<String, Double> calculateActualNutrients(HarvestBatch batch) {
		Map<String, Double> nutrients = new HashMap<>();

		// Simulate nutrient calculation based on weather and quality
		double qualityMultiplier = "Premium".equalsIgnoreCase(batch.getQualityGrade()) ? 1.2
				: "Good".equalsIgnoreCase(batch.getQualityGrade()) ? 1.0 : 0.8;

		nutrients.put("Vitamin C", 25.0 * qualityMultiplier);
		nutrients.put("Potassium", 200.0 * qualityMultiplier);
		nutrients.put("Fiber", 3.0 * qualityMultiplier);

		return nutrients;
	}

	// Initialize sample data
	private static void initializeSampleData() {
		// Sample crop nutrition profile 1
		CropNutritionProfile tomatoes = new CropNutritionProfile();
		tomatoes.setId(1L);
		tomatoes.setCropName("Organic Cherry Tomatoes");
		tomatoes.setFarmLocation("Jyväskylä, Finland");
		tomatoes.setGrowingMethod("organic");

		Map<String, Double> soilNutrients1 = new HashMap<>();
		soilNutrients1.put("Nitrogen", 45.0);
		soilNutrients1.put("Phosphorus", 25.0);
		soilNutrients1.put("Potassium", 180.0);
		tomatoes.setSoilNutrients(soilNutrients1);

		Map<String, Double> cropNutrients1 = new HashMap<>();
		cropNutrients1.put("Vitamin C", 28.0);
		cropNutrients1.put("Lycopene", 2.6);
		cropNutrients1.put("Folate", 15.0);
		cropNutrients1.put("Potassium", 237.0);
		tomatoes.setCropNutrients(cropNutrients1);

		tomatoes.setHarvestSeason("Summer 2025");
		tomatoes.setSustainabilityScore(8.7);
		tomatoes.setCertifications(Arrays.asList("EU Organic", "Carbon Neutral"));

		cropProfiles.put(1L, tomatoes);

		// Sample crop nutrition profile 2
		CropNutritionProfile carrots = new CropNutritionProfile();
		carrots.setId(2L);
		carrots.setCropName("Hydroponic Carrots");
		carrots.setFarmLocation("Tampere, Finland");
		carrots.setGrowingMethod("hydroponic");

		Map<String, Double> soilNutrients2 = new HashMap<>();
		soilNutrients2.put("Nitrogen", 35.0);
		soilNutrients2.put("Phosphorus", 30.0);
		soilNutrients2.put("Potassium", 150.0);
		carrots.setSoilNutrients(soilNutrients2);

		Map<String, Double> cropNutrients2 = new HashMap<>();
		cropNutrients2.put("Beta-Carotene", 8285.0);
		cropNutrients2.put("Vitamin A", 835.0);
		cropNutrients2.put("Fiber", 2.8);
		cropNutrients2.put("Potassium", 320.0);
		carrots.setCropNutrients(cropNutrients2);

		carrots.setHarvestSeason("Autumn 2025");
		carrots.setSustainabilityScore(7.2);
		carrots.setCertifications(Arrays.asList("Sustainable Farming"));

		cropProfiles.put(2L, carrots);

		// Sample harvest batches
		HarvestBatch batch1 = new HarvestBatch();
		batch1.setId(1L);
		batch1.setCropProfileId(1L);
		batch1.setHarvestDate(new java.util.Date());
		batch1.setQuantity(150.5);
		batch1.setQualityGrade("Premium");
		batch1.setWeatherConditions(Arrays.asList("Sunny", "Optimal Temperature"));
		batch1.setFreshnessDays(3.0);
		batch1.setDistributionPath("Farm -> Local Market -> Consumer");

		Map<String, Double> actualNutrients1 = new HashMap<>();
		actualNutrients1.put("Vitamin C", 32.0);
		actualNutrients1.put("Lycopene", 3.1);
		actualNutrients1.put("Potassium", 285.0);
		batch1.setActualNutrients(actualNutrients1);

		harvestBatches.put(1L, batch1);

		HarvestBatch batch2 = new HarvestBatch();
		batch2.setId(2L);
		batch2.setCropProfileId(2L);
		batch2.setHarvestDate(new java.util.Date());
		batch2.setQuantity(200.0);
		batch2.setQualityGrade("Good");
		batch2.setWeatherConditions(Arrays.asList("Controlled Environment"));
		batch2.setFreshnessDays(7.0);
		batch2.setDistributionPath("Hydroponic Farm -> Distribution Center -> Retailer");

		Map<String, Double> actualNutrients2 = new HashMap<>();
		actualNutrients2.put("Beta-Carotene", 8500.0);
		actualNutrients2.put("Vitamin A", 850.0);
		actualNutrients2.put("Fiber", 3.0);
		batch2.setActualNutrients(actualNutrients2);

		harvestBatches.put(2L, batch2);
	}
}
