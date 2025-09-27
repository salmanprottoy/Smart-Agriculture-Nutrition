package com.agriculture.nutrition.exception;

import com.agriculture.nutrition.model.ErrorMessage;

import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;
import javax.ws.rs.ext.ExceptionMapper;
import javax.ws.rs.ext.Provider;

@Provider
public class TrackerNotFoundExceptionMapper implements ExceptionMapper<TrackerNotFoundException> {

	@Override
	public Response toResponse(TrackerNotFoundException ex) {
		ErrorMessage errorMessage = new ErrorMessage(ex.getMessage(), 404,
				"http://localhost:8080/SmartAgricultureNutrition/docs");
		return Response.status(Status.NOT_FOUND)
				.entity(errorMessage)
				.type(MediaType.APPLICATION_JSON)
				.build();
	}
}
