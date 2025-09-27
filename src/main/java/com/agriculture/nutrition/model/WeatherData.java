package com.agriculture.nutrition.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import io.swagger.v3.oas.annotations.media.Schema;

import javax.xml.bind.annotation.XmlRootElement;
import java.util.List;

/**
 * Weather data model for OpenWeatherMap API integration Represents current
 * weather conditions for agricultural analysis
 */
@XmlRootElement
@JsonIgnoreProperties(ignoreUnknown = true)
@Schema(description = "Weather data from OpenWeatherMap API for agricultural analysis")
public class WeatherData {

	@Schema(description = "Location coordinates", example = "{'lon': 25.7342, 'lat': 62.2426}")
	private Coord coord;

	@Schema(description = "Weather conditions", example = "[{'main': 'Clear', 'description': 'clear sky'}]")
	private List<Weather> weather;

	@Schema(description = "Main weather parameters")
	private Main main;

	@Schema(description = "Wind information")
	private Wind wind;

	@Schema(description = "System information")
	private Sys sys;

	@Schema(description = "City name", example = "Jyväskylä")
	private String name;

	@Schema(description = "Data calculation timestamp")
	private long dt;

	@Schema(description = "Visibility in meters")
	private double visibility;

	// Nested classes for weather API structure
	@JsonIgnoreProperties(ignoreUnknown = true)
	public static class Coord {
		private double lon;
		private double lat;

		// Getters and setters
		public double getLon() {
			return lon;
		}

		public void setLon(double lon) {
			this.lon = lon;
		}

		public double getLat() {
			return lat;
		}

		public void setLat(double lat) {
			this.lat = lat;
		}
	}

	@JsonIgnoreProperties(ignoreUnknown = true)
	public static class Weather {
		private String main;
		private String description;
		private String icon;

		// Getters and setters
		public String getMain() {
			return main;
		}

		public void setMain(String main) {
			this.main = main;
		}

		public String getDescription() {
			return description;
		}

		public void setDescription(String description) {
			this.description = description;
		}

		public String getIcon() {
			return icon;
		}

		public void setIcon(String icon) {
			this.icon = icon;
		}
	}

	@JsonIgnoreProperties(ignoreUnknown = true)
	public static class Main {
		private double temp;
		private double humidity;
		private double pressure;

		@JsonProperty("temp_min")
		private double tempMin;

		@JsonProperty("temp_max")
		private double tempMax;

		@JsonProperty("feels_like")
		private double feelsLike;

		// Getters and setters
		public double getTemp() {
			return temp;
		}

		public void setTemp(double temp) {
			this.temp = temp;
		}

		public double getHumidity() {
			return humidity;
		}

		public void setHumidity(double humidity) {
			this.humidity = humidity;
		}

		public double getPressure() {
			return pressure;
		}

		public void setPressure(double pressure) {
			this.pressure = pressure;
		}

		public double getTempMin() {
			return tempMin;
		}

		public void setTempMin(double tempMin) {
			this.tempMin = tempMin;
		}

		public double getTempMax() {
			return tempMax;
		}

		public void setTempMax(double tempMax) {
			this.tempMax = tempMax;
		}

		public double getFeelsLike() {
			return feelsLike;
		}

		public void setFeelsLike(double feelsLike) {
			this.feelsLike = feelsLike;
		}
	}

	@JsonIgnoreProperties(ignoreUnknown = true)
	public static class Wind {
		private double speed;
		private double deg;

		// Getters and setters
		public double getSpeed() {
			return speed;
		}

		public void setSpeed(double speed) {
			this.speed = speed;
		}

		public double getDeg() {
			return deg;
		}

		public void setDeg(double deg) {
			this.deg = deg;
		}
	}

	@JsonIgnoreProperties(ignoreUnknown = true)
	public static class Sys {
		private String country;
		private long sunrise;
		private long sunset;

		// Getters and setters
		public String getCountry() {
			return country;
		}

		public void setCountry(String country) {
			this.country = country;
		}

		public long getSunrise() {
			return sunrise;
		}

		public void setSunrise(long sunrise) {
			this.sunrise = sunrise;
		}

		public long getSunset() {
			return sunset;
		}

		public void setSunset(long sunset) {
			this.sunset = sunset;
		}
	}

	// Main class getters and setters
	public Coord getCoord() {
		return coord;
	}

	public void setCoord(Coord coord) {
		this.coord = coord;
	}

	public List<Weather> getWeather() {
		return weather;
	}

	public void setWeather(List<Weather> weather) {
		this.weather = weather;
	}

	public Main getMain() {
		return main;
	}

	public void setMain(Main main) {
		this.main = main;
	}

	public Wind getWind() {
		return wind;
	}

	public void setWind(Wind wind) {
		this.wind = wind;
	}

	public Sys getSys() {
		return sys;
	}

	public void setSys(Sys sys) {
		this.sys = sys;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public long getDt() {
		return dt;
	}

	public void setDt(long dt) {
		this.dt = dt;
	}

	public double getVisibility() {
		return visibility;
	}

	public void setVisibility(double visibility) {
		this.visibility = visibility;
	}

	/**
	 * Calculate agricultural impact score based on weather conditions
	 * 
	 * @return Score from 0-10 indicating favorable growing conditions
	 */
	public double calculateAgricultureImpactScore() {
		if (main == null)
			return 5.0; // neutral score if no data

		double score = 5.0; // base score

		// Temperature impact (optimal range 15-25°C)
		double tempCelsius = main.getTemp() - 273.15; // Convert from Kelvin
		if (tempCelsius >= 15 && tempCelsius <= 25) {
			score += 2.0;
		} else if (tempCelsius >= 10 && tempCelsius <= 30) {
			score += 1.0;
		} else if (tempCelsius < 5 || tempCelsius > 35) {
			score -= 2.0;
		}

		// Humidity impact (optimal range 40-70%)
		if (main.getHumidity() >= 40 && main.getHumidity() <= 70) {
			score += 1.5;
		} else if (main.getHumidity() < 30 || main.getHumidity() > 80) {
			score -= 1.0;
		}

		// Weather condition impact
		if (weather != null && !weather.isEmpty()) {
			String condition = weather.get(0).getMain().toLowerCase();
			switch (condition) {
			case "clear":
			case "clouds":
				score += 1.0;
				break;
			case "rain":
				score += 0.5; // light rain can be beneficial
				break;
			case "thunderstorm":
			case "snow":
				score -= 1.5;
				break;
			}
		}

		return Math.max(0, Math.min(10, score)); // Clamp between 0-10
	}

	/**
	 * Get weather impact on crop nutrition
	 * 
	 * @return Description of how weather affects crop nutritional content
	 */
	public String getNutritionImpact() {
		double score = calculateAgricultureImpactScore();

		if (score >= 8) {
			return "Excellent conditions for nutrient development. High vitamin and mineral content expected.";
		} else if (score >= 6) {
			return "Good growing conditions. Normal nutrient levels expected.";
		} else if (score >= 4) {
			return "Moderate conditions. Some impact on nutrient density possible.";
		} else {
			return "Challenging conditions. May reduce nutritional content and crop quality.";
		}
	}
}
