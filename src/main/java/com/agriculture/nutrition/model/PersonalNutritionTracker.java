package com.agriculture.nutrition.model;

import javax.xml.bind.annotation.XmlRootElement;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@XmlRootElement
public class PersonalNutritionTracker {
	private long id;
	private String userName;
	private double currentBMI; // Integration with Task-2 BMI calculator
	private Map<String, Double> dailyNutrientIntake;
	private List<String> healthGoals;
	private Map<String, String> foodSources; // food -> farm origin
	private double farmToForkScore; // sustainability metric
	private Date trackingDate;
	private List<Link> links = new ArrayList<>();

	public PersonalNutritionTracker() {
		this.dailyNutrientIntake = new HashMap<>();
		this.healthGoals = new ArrayList<>();
		this.foodSources = new HashMap<>();
		this.trackingDate = new Date();
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

	public String getUserName() {
		return userName;
	}

	public void setUserName(String userName) {
		this.userName = userName;
	}

	public double getCurrentBMI() {
		return currentBMI;
	}

	public void setCurrentBMI(double currentBMI) {
		this.currentBMI = currentBMI;
	}

	public Map<String, Double> getDailyNutrientIntake() {
		return dailyNutrientIntake;
	}

	public void setDailyNutrientIntake(Map<String, Double> dailyNutrientIntake) {
		this.dailyNutrientIntake = dailyNutrientIntake;
	}

	public List<String> getHealthGoals() {
		return healthGoals;
	}

	public void setHealthGoals(List<String> healthGoals) {
		this.healthGoals = healthGoals;
	}

	public Map<String, String> getFoodSources() {
		return foodSources;
	}

	public void setFoodSources(Map<String, String> foodSources) {
		this.foodSources = foodSources;
	}

	public double getFarmToForkScore() {
		return farmToForkScore;
	}

	public void setFarmToForkScore(double farmToForkScore) {
		this.farmToForkScore = farmToForkScore;
	}

	public Date getTrackingDate() {
		return trackingDate;
	}

	public void setTrackingDate(Date trackingDate) {
		this.trackingDate = trackingDate;
	}

	public List<Link> getLinks() {
		return links;
	}

	public void setLinks(List<Link> links) {
		this.links = links;
	}
}
