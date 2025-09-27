package com.agriculture.nutrition.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.info.Contact;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.info.License;
import io.swagger.v3.oas.annotations.servers.Server;
import io.swagger.v3.oas.annotations.tags.Tag;

import javax.ws.rs.ApplicationPath;
import javax.ws.rs.core.Application;

/**
 * Swagger/OpenAPI configuration for Smart Agriculture Nutrition Provides
 * comprehensive API documentation with interactive testing capabilities
 */
@ApplicationPath("/api/v1")
@OpenAPIDefinition(info = @Info(title = "Smart Agriculture Nutrition", version = "1.0.0", description = "REST API connecting smart agriculture data with personal nutrition tracking. "
		+ "This API bridges the gap between agricultural production and personal health outcomes, "
		+ "creating a complete food-to-health ecosystem.", contact = @Contact(name = "Smart Agriculture Team", email = "agriculture@nutrition.com", url = "https://github.com/agriculture-nutrition/api"), license = @License(name = "MIT License", url = "https://opensource.org/licenses/MIT")), servers = {
				@Server(url = "http://localhost:8080/SmartAgricultureNutrition/api/v1", description = "Development Server"),
				@Server(url = "https://api.agriculture-nutrition.com/v1", description = "Production Server") }, tags = {
						@Tag(name = "Crop Nutrition Profiles", description = "Operations related to crop nutrition profiles and agricultural data"),
						@Tag(name = "Harvest Batches", description = "Harvest batch management and nutrient analysis"),
						@Tag(name = "Personal Nutrition Trackers", description = "Personal nutrition tracking and health goal management"),
						@Tag(name = "Meal Sources", description = "Meal tracking with farm-to-fork sourcing analysis"),
						@Tag(name = "Health Analytics", description = "Health correlations and BMI analysis endpoints"),
						@Tag(name = "System", description = "System status and configuration endpoints") })
public class SwaggerConfig extends Application {

	@Override
	public java.util.Set<Class<?>> getClasses() {
		java.util.Set<Class<?>> classes = new java.util.HashSet<>();

		// Add all resource classes
		classes.add(com.agriculture.nutrition.resources.CropNutritionResource.class);
		classes.add(com.agriculture.nutrition.resources.PersonalNutritionTrackerResource.class);
		classes.add(com.agriculture.nutrition.resources.WeatherResource.class);
		classes.add(com.agriculture.nutrition.resources.NutritionDataResource.class);
		classes.add(com.agriculture.nutrition.resources.CorrelationResource.class);
		classes.add(com.agriculture.nutrition.resources.SwaggerUIResource.class);
		classes.add(com.agriculture.nutrition.resources.OpenApiResource.class);

		// Add exception mappers
		classes.add(com.agriculture.nutrition.exception.CropNotFoundExceptionMapper.class);
		classes.add(com.agriculture.nutrition.exception.TrackerNotFoundExceptionMapper.class);
		classes.add(com.agriculture.nutrition.exception.GenericExceptionMapper.class);

		// Add JSON providers for proper serialization
		classes.add(com.fasterxml.jackson.jaxrs.json.JacksonJsonProvider.class);

		return classes;
	}
}
