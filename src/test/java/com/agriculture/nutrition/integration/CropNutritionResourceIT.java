package com.agriculture.nutrition.integration;

import com.agriculture.nutrition.model.CropNutritionProfile;
import com.agriculture.nutrition.model.HarvestBatch;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.glassfish.jersey.test.JerseyTest;
import org.glassfish.jersey.test.TestProperties;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

import javax.ws.rs.client.Entity;
import javax.ws.rs.core.Application;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import java.util.List;

import static org.assertj.core.api.Assertions.*;

/**
 * Integration tests for Crop Nutrition Resource Uses Testcontainers for
 * database integration testing
 */
@Testcontainers
@DisplayName("Crop Nutrition Resource Integration Tests")
class CropNutritionResourceIT extends JerseyTest {

	@Container
	static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>(DockerImageName.parse("postgres:15-alpine"))
			.withDatabaseName("test_agriculture").withUsername("test_user").withPassword("test_password")
			.withInitScript("test-schema.sql");

	private final ObjectMapper objectMapper = new ObjectMapper();

	@Override
	protected Application configure() {
		enable(TestProperties.LOG_TRAFFIC);
		enable(TestProperties.DUMP_ENTITY);

		// Configure test application with test database
		System.setProperty("DB_HOST", postgres.getHost());
		System.setProperty("DB_PORT", String.valueOf(postgres.getFirstMappedPort()));
		System.setProperty("DB_NAME", postgres.getDatabaseName());
		System.setProperty("DB_USERNAME", postgres.getUsername());
		System.setProperty("DB_PASSWORD", postgres.getPassword());

		return new TestApplication();
	}

	@Test
	@DisplayName("Should create and retrieve crop nutrition profile")
	void createAndRetrieveCropProfile_Success() throws Exception {
		// Given
		CropNutritionProfile profile = createTestCropProfile();

		// When - Create profile
		Response createResponse = target("/api/v1/crop-nutrition-profiles").request(MediaType.APPLICATION_JSON)
				.post(Entity.json(profile));

		// Then - Verify creation
		assertThat(createResponse.getStatus()).isEqualTo(201);

		String locationHeader = createResponse.getHeaderString("Location");
		assertThat(locationHeader).isNotNull();

		String profileId = locationHeader.substring(locationHeader.lastIndexOf("/") + 1);

		// When - Retrieve profile
		Response getResponse = target("/api/v1/crop-nutrition-profiles/" + profileId)
				.request(MediaType.APPLICATION_JSON).get();

		// Then - Verify retrieval
		assertThat(getResponse.getStatus()).isEqualTo(200);

		String jsonResponse = getResponse.readEntity(String.class);
		CropNutritionProfile retrievedProfile = objectMapper.readValue(jsonResponse, CropNutritionProfile.class);

		assertThat(retrievedProfile.getCropName()).isEqualTo(profile.getCropName());
		assertThat(retrievedProfile.getFarmLocation()).isEqualTo(profile.getFarmLocation());
		assertThat(retrievedProfile.getGrowingMethod()).isEqualTo(profile.getGrowingMethod());
	}

	@Test
	@DisplayName("Should list all crop nutrition profiles")
	void getAllCropProfiles_ReturnsProfiles() throws Exception {
		// Given - Create multiple profiles
		CropNutritionProfile profile1 = createTestCropProfile();
		profile1.setCropName("Organic Tomatoes");

		CropNutritionProfile profile2 = createTestCropProfile();
		profile2.setCropName("Hydroponic Lettuce");
		profile2.setGrowingMethod("Hydroponic");

		target("/api/v1/crop-nutrition-profiles").request(MediaType.APPLICATION_JSON).post(Entity.json(profile1));

		target("/api/v1/crop-nutrition-profiles").request(MediaType.APPLICATION_JSON).post(Entity.json(profile2));

		// When
		Response response = target("/api/v1/crop-nutrition-profiles").request(MediaType.APPLICATION_JSON).get();

		// Then
		assertThat(response.getStatus()).isEqualTo(200);

		String jsonResponse = response.readEntity(String.class);
		List<CropNutritionProfile> profiles = objectMapper.readValue(jsonResponse,
				new TypeReference<List<CropNutritionProfile>>() {
				});

		assertThat(profiles).hasSizeGreaterThanOrEqualTo(2);
		assertThat(profiles).extracting(CropNutritionProfile::getCropName).contains("Organic Tomatoes",
				"Hydroponic Lettuce");
	}

	@Test
	@DisplayName("Should filter crop profiles by growing method")
	void getCropProfiles_FilterByGrowingMethod_ReturnsFilteredResults() throws Exception {
		// Given
		CropNutritionProfile organicProfile = createTestCropProfile();
		organicProfile.setCropName("Organic Carrots");
		organicProfile.setGrowingMethod("Organic");

		CropNutritionProfile hydroponicProfile = createTestCropProfile();
		hydroponicProfile.setCropName("Hydroponic Spinach");
		hydroponicProfile.setGrowingMethod("Hydroponic");

		target("/api/v1/crop-nutrition-profiles").request(MediaType.APPLICATION_JSON).post(Entity.json(organicProfile));

		target("/api/v1/crop-nutrition-profiles").request(MediaType.APPLICATION_JSON)
				.post(Entity.json(hydroponicProfile));

		// When
		Response response = target("/api/v1/crop-nutrition-profiles").queryParam("growing_method", "Organic")
				.request(MediaType.APPLICATION_JSON).get();

		// Then
		assertThat(response.getStatus()).isEqualTo(200);

		String jsonResponse = response.readEntity(String.class);
		List<CropNutritionProfile> profiles = objectMapper.readValue(jsonResponse,
				new TypeReference<List<CropNutritionProfile>>() {
				});

		assertThat(profiles).isNotEmpty();
		assertThat(profiles).allMatch(p -> "Organic".equals(p.getGrowingMethod()));
	}

	@Test
	@DisplayName("Should update crop nutrition profile")
	void updateCropProfile_Success() throws Exception {
		// Given - Create initial profile
		CropNutritionProfile profile = createTestCropProfile();

		Response createResponse = target("/api/v1/crop-nutrition-profiles").request(MediaType.APPLICATION_JSON)
				.post(Entity.json(profile));

		String locationHeader = createResponse.getHeaderString("Location");
		String profileId = locationHeader.substring(locationHeader.lastIndexOf("/") + 1);

		// When - Update profile
		profile.setCropName("Updated Crop Name");
		profile.setSustainabilityScore(9.5);

		Response updateResponse = target("/api/v1/crop-nutrition-profiles/" + profileId)
				.request(MediaType.APPLICATION_JSON).put(Entity.json(profile));

		// Then - Verify update
		assertThat(updateResponse.getStatus()).isEqualTo(200);

		// Verify the update persisted
		Response getResponse = target("/api/v1/crop-nutrition-profiles/" + profileId)
				.request(MediaType.APPLICATION_JSON).get();

		String jsonResponse = getResponse.readEntity(String.class);
		CropNutritionProfile updatedProfile = objectMapper.readValue(jsonResponse, CropNutritionProfile.class);

		assertThat(updatedProfile.getCropName()).isEqualTo("Updated Crop Name");
		assertThat(updatedProfile.getSustainabilityScore()).isEqualTo(9.5);
	}

	@Test
	@DisplayName("Should delete crop nutrition profile")
	void deleteCropProfile_Success() throws Exception {
		// Given
		CropNutritionProfile profile = createTestCropProfile();

		Response createResponse = target("/api/v1/crop-nutrition-profiles").request(MediaType.APPLICATION_JSON)
				.post(Entity.json(profile));

		String locationHeader = createResponse.getHeaderString("Location");
		String profileId = locationHeader.substring(locationHeader.lastIndexOf("/") + 1);

		// When
		Response deleteResponse = target("/api/v1/crop-nutrition-profiles/" + profileId)
				.request(MediaType.APPLICATION_JSON).delete();

		// Then
		assertThat(deleteResponse.getStatus()).isEqualTo(204);

		// Verify deletion
		Response getResponse = target("/api/v1/crop-nutrition-profiles/" + profileId)
				.request(MediaType.APPLICATION_JSON).get();

		assertThat(getResponse.getStatus()).isEqualTo(404);
	}

	@Test
	@DisplayName("Should handle harvest batches for crop profile")
	void manageHarvestBatches_Success() throws Exception {
		// Given - Create crop profile
		CropNutritionProfile profile = createTestCropProfile();

		Response createResponse = target("/api/v1/crop-nutrition-profiles").request(MediaType.APPLICATION_JSON)
				.post(Entity.json(profile));

		String locationHeader = createResponse.getHeaderString("Location");
		String profileId = locationHeader.substring(locationHeader.lastIndexOf("/") + 1);

		// When - Add harvest batch
		HarvestBatch batch = createTestHarvestBatch();

		Response addBatchResponse = target("/api/v1/crop-nutrition-profiles/" + profileId + "/harvest-batches")
				.request(MediaType.APPLICATION_JSON).post(Entity.json(batch));

		// Then - Verify batch addition
		assertThat(addBatchResponse.getStatus()).isEqualTo(201);

		// When - Get harvest batches
		Response getBatchesResponse = target("/api/v1/crop-nutrition-profiles/" + profileId + "/harvest-batches")
				.request(MediaType.APPLICATION_JSON).get();

		// Then - Verify batch retrieval
		assertThat(getBatchesResponse.getStatus()).isEqualTo(200);

		String jsonResponse = getBatchesResponse.readEntity(String.class);
		List<HarvestBatch> batches = objectMapper.readValue(jsonResponse, new TypeReference<List<HarvestBatch>>() {
		});

		assertThat(batches).isNotEmpty();
		assertThat(batches.get(0).getId()).isEqualTo(batch.getId());
	}

	@Test
	@DisplayName("Should return 404 for non-existent crop profile")
	void getCropProfile_NotFound_Returns404() {
		// When
		Response response = target("/api/v1/crop-nutrition-profiles/999999").request(MediaType.APPLICATION_JSON).get();

		// Then
		assertThat(response.getStatus()).isEqualTo(404);
	}

	@Test
	@DisplayName("Should validate crop profile data")
	void createCropProfile_InvalidData_ReturnsBadRequest() {
		// Given - Invalid profile (missing required fields)
		CropNutritionProfile invalidProfile = new CropNutritionProfile();
		// Not setting required fields

		// When
		Response response = target("/api/v1/crop-nutrition-profiles").request(MediaType.APPLICATION_JSON)
				.post(Entity.json(invalidProfile));

		// Then
		assertThat(response.getStatus()).isEqualTo(400);
	}

	@Test
	@DisplayName("Should handle concurrent access to crop profiles")
	void concurrentAccess_HandledCorrectly() throws Exception {
		// Given
		CropNutritionProfile profile = createTestCropProfile();

		Response createResponse = target("/api/v1/crop-nutrition-profiles").request(MediaType.APPLICATION_JSON)
				.post(Entity.json(profile));

		String locationHeader = createResponse.getHeaderString("Location");
		String profileId = locationHeader.substring(locationHeader.lastIndexOf("/") + 1);

		// When - Simulate concurrent updates
		profile.setCropName("Concurrent Update 1");
		profile.setSustainabilityScore(8.0);

		CropNutritionProfile profile2 = createTestCropProfile();
		profile2.setCropName("Concurrent Update 2");
		profile2.setSustainabilityScore(9.0);

		Response update1 = target("/api/v1/crop-nutrition-profiles/" + profileId).request(MediaType.APPLICATION_JSON)
				.put(Entity.json(profile));

		Response update2 = target("/api/v1/crop-nutrition-profiles/" + profileId).request(MediaType.APPLICATION_JSON)
				.put(Entity.json(profile2));

		// Then - Both updates should succeed (last one wins)
		assertThat(update1.getStatus()).isEqualTo(200);
		assertThat(update2.getStatus()).isEqualTo(200);
	}

	@Test
	@DisplayName("Should provide soil impact analysis")
	void getSoilImpactAnalysis_ReturnsAnalysis() throws Exception {
		// Given
		CropNutritionProfile profile = createTestCropProfile();

		Response createResponse = target("/api/v1/crop-nutrition-profiles").request(MediaType.APPLICATION_JSON)
				.post(Entity.json(profile));

		String locationHeader = createResponse.getHeaderString("Location");
		String profileId = locationHeader.substring(locationHeader.lastIndexOf("/") + 1);

		// When
		Response response = target("/api/v1/crop-nutrition-profiles/" + profileId + "/soil-impact")
				.request(MediaType.TEXT_PLAIN).get();

		// Then
		assertThat(response.getStatus()).isEqualTo(200);

		String analysis = response.readEntity(String.class);
		assertThat(analysis).isNotEmpty();
		assertThat(analysis).contains("SOIL IMPACT ANALYSIS");
	}

	// Helper methods
	private CropNutritionProfile createTestCropProfile() {
		CropNutritionProfile profile = new CropNutritionProfile();
		profile.setCropName("Test Crop");
		profile.setFarmLocation("Test Farm, Finland");
		profile.setGrowingMethod("Organic");
		profile.setSustainabilityScore(8.5);
		profile.setCertifications(List.of("EU Organic", "Carbon Neutral"));
		// Set crop nutrients using the actual Map structure
		profile.getCropNutrients().put("vitamin_c", 25.0);
		profile.getCropNutrients().put("vitamin_k", 15.0);
		profile.getCropNutrients().put("folate", 18.0);
		profile.getCropNutrients().put("potassium", 300.0);
		profile.getCropNutrients().put("calcium", 40.0);
		profile.getCropNutrients().put("iron", 0.8);
		profile.getCropNutrients().put("fiber", 2.5);
		
		// Set soil nutrients
		profile.getSoilNutrients().put("nitrogen", 45.0);
		profile.getSoilNutrients().put("phosphorus", 25.0);
		profile.getSoilNutrients().put("potassium", 180.0);
		profile.getSoilNutrients().put("ph", 6.8);
		
		return profile;
	}

	private HarvestBatch createTestHarvestBatch() {
		HarvestBatch batch = new HarvestBatch();
		batch.setId(1L);
		batch.setHarvestDate(new java.util.Date());
		batch.setQuantity(150.0);
		batch.setQualityGrade("A");
		batch.setDistributionPath("Local distribution");
		batch.setFreshnessDays(7.0);
		
		// Set actual nutrients using the Map structure
		batch.getActualNutrients().put("vitamin_c", 28.0);
		batch.getActualNutrients().put("antioxidants", 135.0);
		
		// Set weather conditions
		batch.getWeatherConditions().add("Sunny");
		batch.getWeatherConditions().add("Optimal temperature");
		
		return batch;
	}

	// Test application configuration
	private static class TestApplication extends javax.ws.rs.core.Application {
		@Override
		public java.util.Set<Class<?>> getClasses() {
			java.util.Set<Class<?>> classes = new java.util.HashSet<>();
			// Add your resource classes here
			classes.add(com.agriculture.nutrition.resources.CropNutritionResource.class);
			classes.add(com.agriculture.nutrition.exception.CropNotFoundExceptionMapper.class);
			classes.add(com.agriculture.nutrition.exception.GenericExceptionMapper.class);
			return classes;
		}
	}
}
