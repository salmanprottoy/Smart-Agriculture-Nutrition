package com.agriculture.nutrition.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import io.swagger.v3.oas.annotations.media.Schema;

import javax.xml.bind.annotation.XmlRootElement;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

/**
 * Food nutrition data model for USDA FoodData Central API integration
 * Represents comprehensive nutritional information for foods
 */
@XmlRootElement
@JsonIgnoreProperties(ignoreUnknown = true)
@Schema(description = "Comprehensive nutrition data from USDA FoodData Central API")
public class FoodNutritionData {

	@Schema(description = "USDA food ID", example = "167512")
	@JsonProperty("fdcId")
	private long fdcId;

	@Schema(description = "Food description", example = "Tomatoes, red, ripe, raw")
	private String description;

	@Schema(description = "Data type", example = "Foundation")
	private String dataType;

	@Schema(description = "Publication date", example = "2019-04-01")
	private String publicationDate;

	@Schema(description = "Food nutrients list")
	private List<FoodNutrient> foodNutrients;

	@Schema(description = "Food category")
	private FoodCategory foodCategory;

	// Nested classes for USDA API structure
	@JsonIgnoreProperties(ignoreUnknown = true)
	public static class FoodNutrient {
		private Nutrient nutrient;
		private double amount;

		@JsonProperty("unitName")
		private String unitName;

		// Getters and setters
		public Nutrient getNutrient() {
			return nutrient;
		}

		public void setNutrient(Nutrient nutrient) {
			this.nutrient = nutrient;
		}

		public double getAmount() {
			return amount;
		}

		public void setAmount(double amount) {
			this.amount = amount;
		}

		public String getUnitName() {
			return unitName;
		}

		public void setUnitName(String unitName) {
			this.unitName = unitName;
		}
	}

	@JsonIgnoreProperties(ignoreUnknown = true)
	public static class Nutrient {
		private int id;
		private String number;
		private String name;
		private String rank;

		@JsonProperty("unitName")
		private String unitName;

		// Getters and setters
		public int getId() {
			return id;
		}

		public void setId(int id) {
			this.id = id;
		}

		public String getNumber() {
			return number;
		}

		public void setNumber(String number) {
			this.number = number;
		}

		public String getName() {
			return name;
		}

		public void setName(String name) {
			this.name = name;
		}

		public String getRank() {
			return rank;
		}

		public void setRank(String rank) {
			this.rank = rank;
		}

		public String getUnitName() {
			return unitName;
		}

		public void setUnitName(String unitName) {
			this.unitName = unitName;
		}
	}

	@JsonIgnoreProperties(ignoreUnknown = true)
	public static class FoodCategory {
		private int id;
		private String code;
		private String description;

		// Getters and setters
		public int getId() {
			return id;
		}

		public void setId(int id) {
			this.id = id;
		}

		public String getCode() {
			return code;
		}

		public void setCode(String code) {
			this.code = code;
		}

		public String getDescription() {
			return description;
		}

		public void setDescription(String description) {
			this.description = description;
		}
	}

	// Main class getters and setters
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

	public String getPublicationDate() {
		return publicationDate;
	}

	public void setPublicationDate(String publicationDate) {
		this.publicationDate = publicationDate;
	}

	public List<FoodNutrient> getFoodNutrients() {
		return foodNutrients;
	}

	public void setFoodNutrients(List<FoodNutrient> foodNutrients) {
		this.foodNutrients = foodNutrients;
	}

	public FoodCategory getFoodCategory() {
		return foodCategory;
	}

	public void setFoodCategory(FoodCategory foodCategory) {
		this.foodCategory = foodCategory;
	}

	/**
	 * Get simplified nutrient map for easy access
	 * 
	 * @return Map of nutrient name to amount with unit
	 */
	public Map<String, String> getSimplifiedNutrients() {
		Map<String, String> nutrients = new HashMap<>();

		if (foodNutrients != null) {
			for (FoodNutrient fn : foodNutrients) {
				if (fn.getNutrient() != null) {
					String value = String.format("%.2f %s", fn.getAmount(),
							fn.getUnitName() != null ? fn.getUnitName() : "");
					nutrients.put(fn.getNutrient().getName(), value);
				}
			}
		}

		return nutrients;
	}

	/**
	 * Get specific nutrient amount by name
	 * 
	 * @param nutrientName Name of the nutrient to find
	 * @return Amount of the nutrient, or 0 if not found
	 */
	public double getNutrientAmount(String nutrientName) {
		if (foodNutrients != null) {
			for (FoodNutrient fn : foodNutrients) {
				if (fn.getNutrient() != null
						&& fn.getNutrient().getName().toLowerCase().contains(nutrientName.toLowerCase())) {
					return fn.getAmount();
				}
			}
		}
		return 0.0;
	}

	/**
	 * Calculate nutrition density score (0-10) Based on vitamin and mineral content
	 * 
	 * @return Nutrition density score
	 */
	public double calculateNutritionDensityScore() {
		double score = 0.0;

		// Key nutrients for scoring
		double vitaminC = getNutrientAmount("Vitamin C");
		double vitaminA = getNutrientAmount("Vitamin A");
		double iron = getNutrientAmount("Iron");
		double calcium = getNutrientAmount("Calcium");
		double potassium = getNutrientAmount("Potassium");
		double fiber = getNutrientAmount("Fiber");
		double protein = getNutrientAmount("Protein");

		// Scoring based on nutrient content (simplified scoring system)
		if (vitaminC > 10)
			score += 1.5; // Good source of Vitamin C
		if (vitaminA > 100)
			score += 1.0; // Good source of Vitamin A
		if (iron > 1)
			score += 1.0; // Good source of Iron
		if (calcium > 50)
			score += 1.0; // Good source of Calcium
		if (potassium > 200)
			score += 1.5; // Good source of Potassium
		if (fiber > 2)
			score += 1.5; // Good source of Fiber
		if (protein > 5)
			score += 1.5; // Good source of Protein

		return Math.min(10.0, score); // Cap at 10
	}

	/**
	 * Get health benefits based on nutritional content
	 * 
	 * @return Description of health benefits
	 */
	public String getHealthBenefits() {
		double densityScore = calculateNutritionDensityScore();

		if (densityScore >= 8) {
			return "Excellent nutritional profile. Rich in essential vitamins and minerals. "
					+ "Supports immune system, bone health, and overall wellness.";
		} else if (densityScore >= 6) {
			return "Good nutritional value. Contains important nutrients for health maintenance. "
					+ "Contributes to balanced diet and nutritional goals.";
		} else if (densityScore >= 4) {
			return "Moderate nutritional content. Provides some essential nutrients. "
					+ "Best consumed as part of varied diet.";
		} else {
			return "Basic nutritional profile. Consider pairing with nutrient-dense foods "
					+ "for optimal health benefits.";
		}
	}

	/**
	 * Check if food is suitable for specific dietary goals
	 * 
	 * @param goal Dietary goal (e.g., "weight_loss", "muscle_building",
	 *             "heart_health")
	 * @return Suitability assessment
	 */
	public String getDietaryGoalSuitability(String goal) {
		double calories = getNutrientAmount("Energy");
		double protein = getNutrientAmount("Protein");
		double fiber = getNutrientAmount("Fiber");
		double sodium = getNutrientAmount("Sodium");
		double sugar = getNutrientAmount("Sugars");

		switch (goal.toLowerCase()) {
		case "weight_loss":
			if (calories < 50 && fiber > 2) {
				return "Excellent for weight loss - low calorie, high fiber";
			} else if (calories < 100) {
				return "Good for weight loss - relatively low calorie";
			} else {
				return "Moderate for weight loss - consume in controlled portions";
			}

		case "muscle_building":
			if (protein > 10) {
				return "Excellent for muscle building - high protein content";
			} else if (protein > 5) {
				return "Good for muscle building - moderate protein content";
			} else {
				return "Limited for muscle building - consider protein-rich additions";
			}

		case "heart_health":
			if (sodium < 100 && fiber > 3) {
				return "Excellent for heart health - low sodium, high fiber";
			} else if (sodium < 200) {
				return "Good for heart health - moderate sodium content";
			} else {
				return "Limited for heart health - high sodium content";
			}

		default:
			return "Nutritional information available for dietary planning";
		}
	}
}
