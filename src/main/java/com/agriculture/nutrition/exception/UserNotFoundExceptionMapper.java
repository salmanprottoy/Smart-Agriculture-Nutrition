package com.agriculture.nutrition.exception;
import com.agriculture.nutrition.model.ErrorMessage;

import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.ext.ExceptionMapper;
import javax.ws.rs.ext.Provider;

@Provider
public class UserNotFoundExceptionMapper implements ExceptionMapper<UserNotFoundException> {

    @Override
    public Response toResponse(UserNotFoundException ex) {
        ErrorMessage errorMessage = new ErrorMessage(ex.getMessage(), 404,
                "http://localhost:8080/SmartAgricultureNutrition/docs");
        return Response.status(Response.Status.NOT_FOUND)
                .entity(errorMessage)
                .type(MediaType.APPLICATION_JSON)
                .build();
    }
}