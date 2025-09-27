package com.agriculture.nutrition.model;

import javax.xml.bind.annotation.XmlRootElement;
import javax.xml.bind.annotation.XmlTransient;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@XmlRootElement
public class CropNutritionProfile {
	private long id;
	private String cropName;
	private String farmLocation;
	private String growingMethod; // organic, conventional, hydroponic
	private Map<String, Double> soilNutrients;
	private Map<String, Double> cropNutrients; // vitamins, minerals per 100g
	private String harvestSeason;
	private double sustainabilityScore;
	private List<String> certifications; // organic, non-gmo, etc.
	private Date lastUpdated;
	private List<Link> links = new ArrayList<>();

	public CropNutritionProfile() {
		this.soilNutrients = new HashMap<>();
		this.cropNutrients = new HashMap<>();
		this.certifications = new ArrayList<>();
		this.lastUpdated = new Date();
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

	public String getCropName() {
		return cropName;
	}

	public void setCropName(String cropName) {
		this.cropName = cropName;
	}

	public String getFarmLocation() {
		return farmLocation;
	}

	public void setFarmLocation(String farmLocation) {
		this.farmLocation = farmLocation;
	}

	public String getGrowingMethod() {
		return growingMethod;
	}

	public void setGrowingMethod(String growingMethod) {
		this.growingMethod = growingMethod;
	}

	public Map<String, Double> getSoilNutrients() {
		return soilNutrients;
	}

	public void setSoilNutrients(Map<String, Double> soilNutrients) {
		this.soilNutrients = soilNutrients;
	}

	public Map<String, Double> getCropNutrients() {
		return cropNutrients;
	}

	public void setCropNutrients(Map<String, Double> cropNutrients) {
		this.cropNutrients = cropNutrients;
	}

	public String getHarvestSeason() {
		return harvestSeason;
	}

	public void setHarvestSeason(String harvestSeason) {
		this.harvestSeason = harvestSeason;
	}

	public double getSustainabilityScore() {
		return sustainabilityScore;
	}

	public void setSustainabilityScore(double sustainabilityScore) {
		this.sustainabilityScore = sustainabilityScore;
	}

	public List<String> getCertifications() {
		return certifications;
	}

	public void setCertifications(List<String> certifications) {
		this.certifications = certifications;
	}

	public Date getLastUpdated() {
		return lastUpdated;
	}

	public void setLastUpdated(Date lastUpdated) {
		this.lastUpdated = lastUpdated;
	}

	public List<Link> getLinks() {
		return links;
	}

	public void setLinks(List<Link> links) {
		this.links = links;
	}
}
