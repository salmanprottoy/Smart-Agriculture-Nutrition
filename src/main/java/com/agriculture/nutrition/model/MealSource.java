package com.agriculture.nutrition.model;

import javax.xml.bind.annotation.XmlRootElement;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@XmlRootElement
public class MealSource {
	private long id;
	private long trackerId;
	private String mealName;
	private List<String> ingredients;
	private Map<String, String> ingredientOrigins; // ingredient -> farm
	private double localSourcePercentage;
	private double nutritionalDensity;
	private Date consumptionDate;
	private List<Link> links = new ArrayList<>();

	public MealSource() {
		this.ingredients = new ArrayList<>();
		this.ingredientOrigins = new HashMap<>();
		this.consumptionDate = new Date();
	}

	public void addLink(String url, String rel) {
		Link link = new Link();
		link.setLink(url);
		link.setRel(rel);
		links.add(link);
	}

	// Getters and setters
	public long getId() {
		return id;
	}

	public void setId(long id) {
		this.id = id;
	}

	public long getTrackerId() {
		return trackerId;
	}

	public void setTrackerId(long trackerId) {
		this.trackerId = trackerId;
	}

	public String getMealName() {
		return mealName;
	}

	public void setMealName(String mealName) {
		this.mealName = mealName;
	}

	public List<String> getIngredients() {
		return ingredients;
	}

	public void setIngredients(List<String> ingredients) {
		this.ingredients = ingredients;
	}

	public Map<String, String> getIngredientOrigins() {
		return ingredientOrigins;
	}

	public void setIngredientOrigins(Map<String, String> ingredientOrigins) {
		this.ingredientOrigins = ingredientOrigins;
	}

	public double getLocalSourcePercentage() {
		return localSourcePercentage;
	}

	public void setLocalSourcePercentage(double localSourcePercentage) {
		this.localSourcePercentage = localSourcePercentage;
	}

	public double getNutritionalDensity() {
		return nutritionalDensity;
	}

	public void setNutritionalDensity(double nutritionalDensity) {
		this.nutritionalDensity = nutritionalDensity;
	}

	public Date getConsumptionDate() {
		return consumptionDate;
	}

	public void setConsumptionDate(Date consumptionDate) {
		this.consumptionDate = consumptionDate;
	}

	public List<Link> getLinks() {
		return links;
	}

	public void setLinks(List<Link> links) {
		this.links = links;
	}
}
