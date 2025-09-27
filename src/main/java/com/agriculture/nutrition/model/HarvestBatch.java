package com.agriculture.nutrition.model;

import javax.xml.bind.annotation.XmlRootElement;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@XmlRootElement
public class HarvestBatch {
	private long id;
	private long cropProfileId;
	private Date harvestDate;
	private double quantity;
	private String qualityGrade;
	private Map<String, Double> actualNutrients;
	private List<String> weatherConditions;
	private double freshnessDays;
	private String distributionPath;
	private List<Link> links = new ArrayList<>();

	public HarvestBatch() {
		this.actualNutrients = new HashMap<>();
		this.weatherConditions = new ArrayList<>();
		this.harvestDate = new Date();
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

	public long getCropProfileId() {
		return cropProfileId;
	}

	public void setCropProfileId(long cropProfileId) {
		this.cropProfileId = cropProfileId;
	}

	public Date getHarvestDate() {
		return harvestDate;
	}

	public void setHarvestDate(Date harvestDate) {
		this.harvestDate = harvestDate;
	}

	public double getQuantity() {
		return quantity;
	}

	public void setQuantity(double quantity) {
		this.quantity = quantity;
	}

	public String getQualityGrade() {
		return qualityGrade;
	}

	public void setQualityGrade(String qualityGrade) {
		this.qualityGrade = qualityGrade;
	}

	public Map<String, Double> getActualNutrients() {
		return actualNutrients;
	}

	public void setActualNutrients(Map<String, Double> actualNutrients) {
		this.actualNutrients = actualNutrients;
	}

	public List<String> getWeatherConditions() {
		return weatherConditions;
	}

	public void setWeatherConditions(List<String> weatherConditions) {
		this.weatherConditions = weatherConditions;
	}

	public double getFreshnessDays() {
		return freshnessDays;
	}

	public void setFreshnessDays(double freshnessDays) {
		this.freshnessDays = freshnessDays;
	}

	public String getDistributionPath() {
		return distributionPath;
	}

	public void setDistributionPath(String distributionPath) {
		this.distributionPath = distributionPath;
	}

	public List<Link> getLinks() {
		return links;
	}

	public void setLinks(List<Link> links) {
		this.links = links;
	}
}
