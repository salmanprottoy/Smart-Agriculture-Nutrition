package com.agriculture.nutrition.config;

import com.agriculture.nutrition.resources.PersonalNutritionTrackerResource;
import io.swagger.v3.jaxrs2.integration.resources.OpenApiResource;
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
@OpenAPIDefinition(info = @Info(title = "Smart Agriculture Nutrition", version = "1.0.0", description = "REST API connecting smart agriculture data with personal nutrition tracking. "
		+ "This API bridges the gap between agricultural production and personal health outcomes, "
		+ "creating a complete food-to-health ecosystem.", contact = @Contact(name = "Smart Agriculture Team", email = "agriculture@nutrition.com", url = "https://github.com/agriculture-nutrition/api"), license = @License(name = "MIT License", url = "https://opensource.org/licenses/MIT")), servers = {
				@Server(url = "http://localhost:8080/SmartAgricultureNutrition/api/v1", description = "Development Server"),
				@Server(url = "https://api.agriculture-nutrition.com/v1", description = "Production Server") }, tags = {
						@Tag(name = "Crop Nutrition Profiles", description = "Operations related to crop nutrition profiles and agricultural data"),
						@Tag(name = "Personal Nutrition Trackers", description = "Personal nutrition tracking and health goal management")})
public class SwaggerConfig extends Application {

	@Override
	public java.util.Set<Class<?>> getClasses() {
		java.util.Set<Class<?>> classes = new java.util.HashSet<>();

		// Add all resource classes
        classes.add(OpenApiResource.class);
		classes.add(com.agriculture.nutrition.resources.CropNutritionResource.class);
		classes.add(PersonalNutritionTrackerResource.class);
		classes.add(com.agriculture.nutrition.resources.WeatherResource.class);
		classes.add(com.agriculture.nutrition.resources.NutritionDataResource.class);
		classes.add(com.agriculture.nutrition.resources.CorrelationResource.class);
		classes.add(com.agriculture.nutrition.resources.SwaggerUIResource.class);

		// Add exception mappers
		classes.add(com.agriculture.nutrition.exception.CropNotFoundExceptionMapper.class);
		classes.add(com.agriculture.nutrition.exception.TrackerNotFoundExceptionMapper.class);
		classes.add(com.agriculture.nutrition.exception.GenericExceptionMapper.class);

		// Add JSON providers for proper serialization
		classes.add(com.fasterxml.jackson.jaxrs.json.JacksonJsonProvider.class);

		return classes;
	}
}
