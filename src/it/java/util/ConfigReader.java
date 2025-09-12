package util;
/*-
 * ╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲
 * MetricsHub community connectors
 * ჻჻჻჻჻჻
 * Copyright 2023 - 2025 MetricsHub
 * ჻჻჻჻჻჻
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * ╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱
 */

import com.fasterxml.jackson.annotation.JsonSetter;
import com.fasterxml.jackson.databind.InjectableValues;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Builder.Default;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.metricshub.agent.config.AgentConfig;
import org.metricshub.agent.deserialization.PostConfigDeserializer;
import org.metricshub.agent.helper.AgentConstants;
import org.metricshub.agent.helper.ConfigHelper;
import org.metricshub.agent.helper.PostConfigDeserializeHelper;
import org.metricshub.agent.service.ConfigurationService;
import org.metricshub.engine.common.helpers.JsonHelper;
import org.metricshub.engine.connector.model.ConnectorStore;
import org.metricshub.engine.connector.parser.EnvironmentProcessor;
import org.metricshub.engine.extension.ExtensionManager;
import org.metricshub.engine.telemetry.TelemetryManager;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Map;

import static com.fasterxml.jackson.annotation.Nulls.SKIP;

/**
 * Reads and processes the configuration for the MetricsHub Agent.
 * This class is responsible for loading the configuration from a specified directory,
 * initializing various components such as AgentInfo, AgentConfig, ConnectorStore,
 * TelemetryManagers, and other services required for the agent's operation.
 */
@Data
public class ConfigReader {
	private Path configDirectory;
	private JsonNode configNode;
	private AgentConfig agentConfig;
	private ConnectorStore connectorStore;
	private Map<String, Map<String, TelemetryManager>> telemetryManagers;
	protected ExtensionManager extensionManager;

	/**
	 * Instantiate the global context
	 *
	 * @param alternateConfigDirectory Alternative configuration directory provided by the user
	 * @param extensionManager         Manages and aggregates various types of extensions used within MetricsHub.
	 * @throws IOException Signals that an I/O exception has occurred
	 */
	public ConfigReader(final String alternateConfigDirectory, final ExtensionManager extensionManager)
		throws IOException {
		this.extensionManager = extensionManager;
		build(alternateConfigDirectory, true);
	}

	/**
	 * Builds the agent context
	 * @param alternateConfigDirectory Alternative configuration directory provided by the user
	 * @param createConnectorStore     Whether we should create a new connector store
	 * @throws IOException Signals that an I/O exception has occurred
	 */
	public void build(final String alternateConfigDirectory, final boolean createConnectorStore) throws IOException {
		// Find the configuration directory
		configDirectory = ConfigHelper.findConfigDirectory(alternateConfigDirectory);

		final ConfigurationService configurationService = ConfigurationService.builder().withConfigDirectory(configDirectory).build();

		configNode = configurationService.loadConfiguration(extensionManager);
		final ObjectMapper mapper = ConfigHelper.newObjectMapper();

		// Build PreConfig
		final ConfigReader.PreConfig preconfig = ConfigReader.PreConfig.builder()
				.patchDirectory(Paths.get("src", "main", "connector").toString())
				.build();

		// Convert PreConfig -> JsonNode
		final JsonNode preConfigNode = mapper.valueToTree(preconfig);

		// Cast configNode to mutable ObjectNode
		final ObjectNode objectNode = (ObjectNode) configNode;

		// Add PreConfig under a field (e.g., "preConfig")
		objectNode.set("preConfig", preConfigNode);

		final PreConfig preConfig = loadPreConfig(configNode);

		// Configure the global logger
		if (!"off".equalsIgnoreCase(preConfig.getLoggerLevel())) {
			ConfigHelper.configureGlobalLogger(preConfig.getLoggerLevel(), preConfig.getOutputDirectory());
		}

		if (createConnectorStore) {
			connectorStore = ConfigHelper.buildConnectorStore(extensionManager, preConfig.getPatchDirectory());
		}

		// Read the agent configuration file (Default: metricshub.yaml)
		agentConfig = loadConfiguration(configNode);

		// Normalizes the agent configuration, configurations from parent will be set in children configuration
		// to ease data retrieval in the scheduler
		ConfigHelper.normalizeAgentConfiguration(agentConfig);

		telemetryManagers = ConfigHelper.buildTelemetryManagers(agentConfig, connectorStore);
	}

	/**
	 * Load the {@link PreConfig} instance
	 *
	 * @param configNode The configuration JSON node
	 *
	 * @return new {@link PreConfig} instance.
	 * @throws IOException  If an I/O error occurs during the initial reading of the YAML file.
	 */
	private static PreConfig loadPreConfig(final JsonNode configNode) throws IOException {
		final ObjectMapper objectMapper = ConfigHelper.newObjectMapper();
		JsonNode preConfigNode = configNode.get("preConfig");
		if (preConfigNode == null) {
			return PreConfig.builder().build(); // fall back to defaults
		}
		return JsonHelper.deserialize(objectMapper, preConfigNode, PreConfig.class);
	}

	/**
	 * Loads the agent configuration from a YAML configuration file into an {@link AgentConfig} instance.
	 *
	 * @param configNode The configuration JSON node
	 * @return {@link AgentConfig} instance.
	 * @throws IOException If an I/O error occurs during the initial reading of the YAML file, during
	 *         the processing phase with {@link EnvironmentProcessor} or at the final deserialization
	 *		   into an {@link AgentConfig}.
	 */
	private AgentConfig loadConfiguration(final JsonNode configNode) throws IOException {
		final ObjectMapper objectMapper = newAgentConfigObjectMapper(extensionManager);

		new EnvironmentProcessor().process(configNode);

		return JsonHelper.deserialize(objectMapper, configNode, AgentConfig.class);
	}

	/**
	 * Create a new {@link ObjectMapper} instance then add to it the
	 * {@link PostConfigDeserializer}
	 *
	 * @param extensionManager Manages and aggregates various types of extensions used within MetricsHub.
	 * @return new {@link ObjectMapper} instance
	 */
	public static ObjectMapper newAgentConfigObjectMapper(final ExtensionManager extensionManager) {
		final ObjectMapper objectMapper = ConfigHelper.newObjectMapper();

		PostConfigDeserializeHelper.addPostDeserializeSupport(objectMapper);

		// Inject the extension manager in the deserialization context
		final InjectableValues.Std injectableValues = new InjectableValues.Std();
		injectableValues.addValue(ExtensionManager.class, extensionManager);
		objectMapper.setInjectableValues(injectableValues);

		return objectMapper;
	}

	@Data
	@Builder
	@NoArgsConstructor
	@AllArgsConstructor
	public static class PreConfig {

		@Default
		@JsonSetter(nulls = SKIP)
		private String loggerLevel = "error";

		@Default
		@JsonSetter(nulls = SKIP)
		private String outputDirectory = AgentConstants.DEFAULT_OUTPUT_DIRECTORY.toString();

		@JsonSetter(nulls = SKIP)
		private String patchDirectory;
	}
}
