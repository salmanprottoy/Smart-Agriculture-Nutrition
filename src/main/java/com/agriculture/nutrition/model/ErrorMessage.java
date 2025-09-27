package com.agriculture.nutrition.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import io.swagger.v3.oas.annotations.media.Schema;

import javax.xml.bind.annotation.XmlRootElement;

@XmlRootElement
@Schema(description = "Error message response")
public class ErrorMessage {

	@JsonProperty("errorMessage")
	@Schema(description = "Error message description", example = "Resource not found")
	private String errorMessage;

	@JsonProperty("errorCode")
	@Schema(description = "HTTP error code", example = "404")
	private int errorCode;

	@JsonProperty("documentation")
	@Schema(description = "Link to API documentation", example = "https://api.example.com/docs")
	private String documentation;

	public ErrorMessage() {
	}

	public ErrorMessage(String errorMessage, int errorCode, String documentation) {
		this.errorMessage = errorMessage;
		this.errorCode = errorCode;
		this.documentation = documentation;
	}

	// Getters and setters
	public String getErrorMessage() {
		return errorMessage;
	}

	public void setErrorMessage(String errorMessage) {
		this.errorMessage = errorMessage;
	}

	public int getErrorCode() {
		return errorCode;
	}

	public void setErrorCode(int errorCode) {
		this.errorCode = errorCode;
	}

	public String getDocumentation() {
		return documentation;
	}

	public void setDocumentation(String documentation) {
		this.documentation = documentation;
	}
}
