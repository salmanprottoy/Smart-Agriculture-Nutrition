package com.agriculture.nutrition.config;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.SQLException;

/**
 * Database configuration and connection management for Smart Agriculture
 * Nutrition API Supports both in-memory mode (for development/testing) and
 * PostgreSQL (for production)
 */
public class DatabaseConfig {

	private static DatabaseConfig instance;
	private DataSource dataSource;
	private boolean useDatabase = false;

	// Database connection parameters - loaded from environment
	private final String DB_URL;
	private final String DB_USERNAME;
	private final String DB_PASSWORD;
	private static final String DB_DRIVER = "org.postgresql.Driver";

	private DatabaseConfig() {
		// Load database configuration from environment variables and .env files
		DB_URL = loadDatabaseUrl();
		DB_USERNAME = loadDatabaseUsername();
		DB_PASSWORD = loadDatabasePassword();
		initializeDataSource();
	}

	public static synchronized DatabaseConfig getInstance() {
		if (instance == null) {
			instance = new DatabaseConfig();
		}
		return instance;
	}

	private void initializeDataSource() {
		try {
			// Try to initialize PostgreSQL connection
			HikariConfig config = new HikariConfig();
			config.setJdbcUrl(DB_URL);
			config.setUsername(DB_USERNAME);
			config.setPassword(DB_PASSWORD);
			config.setDriverClassName(DB_DRIVER);

			// Connection pool settings
			config.setMaximumPoolSize(10);
			config.setMinimumIdle(2);
			config.setConnectionTimeout(30000);
			config.setIdleTimeout(600000);
			config.setMaxLifetime(1800000);
			config.setLeakDetectionThreshold(60000);

			// Connection validation
			config.setConnectionTestQuery("SELECT 1");
			config.setValidationTimeout(5000);

			// Pool name for monitoring
			config.setPoolName("SmartAgriculturePool");

			this.dataSource = new HikariDataSource(config);

			// Test the connection
			try (Connection conn = dataSource.getConnection()) {
				if (conn != null && !conn.isClosed()) {
					this.useDatabase = true;
					System.out.println("✅ PostgreSQL database connection established successfully!");
					System.out.println("📊 Database URL: " + DB_URL);
					System.out.println("👤 Database User: " + DB_USERNAME);
				}
			}

		} catch (Exception e) {
			System.err.println("⚠️  PostgreSQL connection failed: " + e.getMessage());
			System.out.println("🔄 Falling back to in-memory data mode...");
			this.useDatabase = false;
			this.dataSource = null;
		}
	}

	/**
	 * Get a database connection
	 * 
	 * @return Connection object or null if database is not available
	 */
	public Connection getConnection() throws SQLException {
		if (dataSource != null && useDatabase) {
			return dataSource.getConnection();
		}
		return null;
	}

	/**
	 * Check if database is available and should be used
	 * 
	 * @return true if database is available, false if using in-memory mode
	 */
	public boolean isDatabaseAvailable() {
		return useDatabase && dataSource != null;
	}

	/**
	 * Get the data source
	 * 
	 * @return DataSource object or null if not available
	 */
	public DataSource getDataSource() {
		return dataSource;
	}

	/**
	 * Close the data source and clean up resources
	 */
	public void close() {
		if (dataSource instanceof HikariDataSource) {
			((HikariDataSource) dataSource).close();
			System.out.println("🔒 Database connection pool closed.");
		}
	}

	/**
	 * Test database connectivity
	 * 
	 * @return true if database is reachable, false otherwise
	 */
	public boolean testConnection() {
		if (!useDatabase || dataSource == null) {
			return false;
		}

		try (Connection conn = dataSource.getConnection()) {
			return conn != null && !conn.isClosed();
		} catch (SQLException e) {
			System.err.println("❌ Database connection test failed: " + e.getMessage());
			return false;
		}
	}

	/**
	 * Get database status information
	 * 
	 * @return String with database status details
	 */
	public String getStatus() {
		if (useDatabase && dataSource != null) {
			HikariDataSource hikariDS = (HikariDataSource) dataSource;
			return String.format(
					"Database Status: CONNECTED\n" + "URL: %s\n" + "Pool Name: %s\n" + "Active Connections: %d\n"
							+ "Idle Connections: %d\n" + "Total Connections: %d",
					DB_URL, hikariDS.getPoolName(), hikariDS.getHikariPoolMXBean().getActiveConnections(),
					hikariDS.getHikariPoolMXBean().getIdleConnections(),
					hikariDS.getHikariPoolMXBean().getTotalConnections());
		} else {
			return "Database Status: IN-MEMORY MODE\n" + "Using in-memory data storage for development/testing";
		}
	}

	/**
	 * Force switch to in-memory mode (for testing purposes)
	 */
	public void switchToInMemoryMode() {
		if (dataSource instanceof HikariDataSource) {
			((HikariDataSource) dataSource).close();
		}
		this.useDatabase = false;
		this.dataSource = null;
		System.out.println("🔄 Switched to in-memory mode");
	}

	/**
	 * Get database configuration for display purposes
	 * 
	 * @return Configuration details as string
	 */
	public String getConfigInfo() {
		return String.format(
				"Database Configuration:\n" + "- Mode: %s\n" + "- URL: %s\n" + "- Username: %s\n" + "- Driver: %s\n"
						+ "- Max Pool Size: 10\n" + "- Connection Timeout: 30s",
				useDatabase ? "PostgreSQL" : "In-Memory", useDatabase ? DB_URL : "N/A",
				useDatabase ? DB_USERNAME : "N/A", useDatabase ? DB_DRIVER : "N/A");
	}

	/**
	 * Load database URL from environment variables and .env files
	 */
	private String loadDatabaseUrl() {
		// First try system environment
		String host = System.getenv("DB_HOST");
		String port = System.getenv("DB_PORT");
		String name = System.getenv("DB_NAME");

		if (host != null && port != null && name != null) {
			return String.format("jdbc:postgresql://%s:%s/%s", host, port, name);
		}

		// Try loading from .env files
		String[] envFiles = { "application.properties", // Eclipse-friendly properties file
				".env", // Standard .env file
				"src/main/webapp/.env", // Webapp .env
				"/WEB-INF/.env" // Deployed .env
		};

		for (String envFile : envFiles) {
			try {
				java.util.Properties props = new java.util.Properties();
				java.io.InputStream is = getClass().getClassLoader().getResourceAsStream(envFile);
				if (is == null) {
					// Try as file path
					java.io.File file = new java.io.File(envFile);
					if (file.exists()) {
						is = new java.io.FileInputStream(file);
					}
				}

				if (is != null) {
					props.load(is);
					is.close();

					String envHost = props.getProperty("DB_HOST");
					String envPort = props.getProperty("DB_PORT");
					String envName = props.getProperty("DB_NAME");

					if (envHost != null && envPort != null && envName != null) {
						return String.format("jdbc:postgresql://%s:%s/%s", envHost, envPort, envName);
					}
				}
			} catch (Exception e) {
				// Continue to next file
			}
		}

		// Default fallback
		return "jdbc:postgresql://localhost:5432/smart_agriculture_nutrition";
	}

	/**
	 * Load database username from environment variables and .env files
	 */
	private String loadDatabaseUsername() {
		// First try system environment
		String username = System.getenv("DB_USERNAME");
		if (username != null && !username.trim().isEmpty()) {
			return username;
		}

		// Try loading from .env files
		String[] envFiles = { "application.properties", ".env", "src/main/webapp/.env", "/WEB-INF/.env" };

		for (String envFile : envFiles) {
			try {
				java.util.Properties props = new java.util.Properties();
				java.io.InputStream is = getClass().getClassLoader().getResourceAsStream(envFile);
				if (is == null) {
					java.io.File file = new java.io.File(envFile);
					if (file.exists()) {
						is = new java.io.FileInputStream(file);
					}
				}

				if (is != null) {
					props.load(is);
					is.close();

					String envUsername = props.getProperty("DB_USERNAME");
					if (envUsername != null && !envUsername.trim().isEmpty()) {
						return envUsername;
					}
				}
			} catch (Exception e) {
				// Continue to next file
			}
		}

		// Default fallback
		return "agriculture_user";
	}

	/**
	 * Load database password from environment variables and .env files
	 */
	private String loadDatabasePassword() {
		// First try system environment
		String password = System.getenv("DB_PASSWORD");
		if (password != null && !password.trim().isEmpty()) {
			return password;
		}

		// Try loading from .env files
		String[] envFiles = { "application.properties", ".env", "src/main/webapp/.env", "/WEB-INF/.env" };

		for (String envFile : envFiles) {
			try {
				java.util.Properties props = new java.util.Properties();
				java.io.InputStream is = getClass().getClassLoader().getResourceAsStream(envFile);
				if (is == null) {
					java.io.File file = new java.io.File(envFile);
					if (file.exists()) {
						is = new java.io.FileInputStream(file);
					}
				}

				if (is != null) {
					props.load(is);
					is.close();

					String envPassword = props.getProperty("DB_PASSWORD");
					if (envPassword != null && !envPassword.trim().isEmpty()) {
						return envPassword;
					}
				}
			} catch (Exception e) {
				// Continue to next file
			}
		}

		// Default fallback - use the correct password from docker-compose
		return "nutrition_pass_2024";
	}
}
