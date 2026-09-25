package org.metricshub.connector.it;

import org.junit.jupiter.api.Test;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * Base class for connector integration tests using recorded data replay.
 * Each connector gets its own subclass to minimize merge conflicts
 * and provide clear JUnit output per connector.
 */
abstract class AbstractConnectorReplayIT {

	private final String connectorId;

	/**
	 * @param connectorId The identifier of the connector to test, also the name of its fixture folder
	 */
	protected AbstractConnectorReplayIT(final String connectorId) {
		this.connectorId = connectorId;
	}

	/**
	 * Replays recorded data for the connector and verifies the expected results.
	 *
	 * @throws Exception In case of any errors during the test execution
	 */
	@Test
	void testReplay() throws Exception {
		new EmulationITBase(connectorId)
			.executeStrategies()
			.verifyExpected(connectorId + "/expected/expected.json");
	}

	/**
	 * Writes the generated expected JSON output to a file for the specified connector.
	 * Omits the machine-specific agent host name and uses LF line endings for portability.
	 *
	 * @param connectorId The identifier of the connector to generate expected JSON for
	 * @throws Exception In case of any errors during JSON generation or file writing
	 */
	static void writeExpectedJson(final String connectorId) throws Exception {
		final Path outputPath = Paths.get("src/it/resources/" + connectorId + "/expected/expected-gen.json");
		outputPath.getParent().toFile().mkdirs();
		final var job = new EmulationITBase(connectorId);
		job.executeStrategies();
		job.getTelemetryManager().getMonitors().get("host").values()
			.forEach(monitor -> monitor.getAttributes().remove("agent.host.name"));
		Files.writeString(outputPath, job.getTelemetryManager().toJson().replace("\r\n", "\n"));
	}
}
