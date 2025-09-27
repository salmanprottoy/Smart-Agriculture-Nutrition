package com.agriculture.nutrition.exception;

public class TrackerNotFoundException extends RuntimeException {
	private static final long serialVersionUID = 1L;

	public TrackerNotFoundException(String message) {
		super(message);
	}
}
