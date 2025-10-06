package com.agriculture.nutrition.service;

import com.agriculture.nutrition.model.User;
import com.agriculture.nutrition.exception.UserNotFoundException;
import org.mindrot.jbcrypt.BCrypt;

import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

public class UserService {

    private static final Map<String, User> users = new HashMap<>();
    private final AtomicLong idCounter = new AtomicLong(1);

    public UserService() {
        String adminPass = BCrypt.hashpw("admin123", BCrypt.gensalt());
        User admin = new User("admin", adminPass, "admin@example.com", Set.of("ADMIN", "USER"));
        admin.setId(idCounter.getAndIncrement());
        users.put(admin.getUsername(), admin);
    }

    public User registerUser(String username, String rawPassword, String email) {
        if (users.containsKey(username)) {
            throw new IllegalArgumentException("Username already exists: " + username);
        }

        String hashedPassword = BCrypt.hashpw(rawPassword, BCrypt.gensalt());
        Set<String> roles = Set.of("USER");

        User user = new User(username, hashedPassword, email, roles);
        user.setId(idCounter.getAndIncrement());

        users.put(username, user);
        return user;
    }

    public User getUserByUsername(String username) {
        User user = users.get(username);
        if (user == null) {
            throw new UserNotFoundException("User not found: " + username);
        }
        return user;
    }

    public Collection<User> getAllUsers() {
        return users.values();
    }

}
