package org.metricshub.connector.it;

import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;

import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * Integration tests for various connectors using recorded data replay.
 * Each test method corresponds to a single connector to minimize merge conflicts
 * and provide clear JUnit output per connector.
 */
class ConnectorReplayIT {

	/**
	 * Replays recorded data for the specified connector and verifies the expected results.
	 *
	 * @param connectorId The identifier of the connector to test
	 * @throws Exception In case of any errors during the test execution
	 */
	private void testConnectorReplay(String connectorId) throws Exception {
		new EmulationITBase(connectorId)
			.withServerRecordData()
			.executeStrategies()
			.verifyExpected(connectorId + "/expected/expected.json");
	}

	/**
	 * Writes the generated expected JSON output to a file for the specified connector.
	 *
	 * @param connectorId The identifier of the connector to generate expected JSON for
	 * @throws Exception In case of any errors during JSON generation or file writing
	 */
	void writeExpectedJson(String connectorId) throws Exception {
		final Path outputPath = Paths.get("src/it/resources/" + connectorId + "/expected/expected-gen.json");
		outputPath.getParent().toFile().mkdirs();
		new EmulationITBase(connectorId)
			.withServerRecordData()
			.executeStrategies()
			.saveTelemetryManagerJson(outputPath);
	}

	@Test
	@Disabled
	void testAMDRadeon() throws Exception {
		testConnectorReplay("AMDRadeon");
	}

	@Test
	@Disabled
	void testCassandra() throws Exception {
		testConnectorReplay("Cassandra");
	}

	@Test
	@Disabled
	void testIpmiTool() throws Exception {
		testConnectorReplay("IpmiTool");
	}

	@Test
	@Disabled
	void testLinux() throws Exception {
		testConnectorReplay("Linux");
	}

	@Test
	@Disabled
	void testLinuxFile() throws Exception {
		testConnectorReplay("LinuxFile");
	}

	@Test
	@Disabled
	void testLinuxIfConfigNetwork() throws Exception {
		testConnectorReplay("LinuxIfConfigNetwork");
	}

	@Test
	@Disabled
	void testLinuxIPNetwork() throws Exception {
		testConnectorReplay("LinuxIPNetwork");
	}

	@Test
	@Disabled
	void testLinuxIpmiTool() throws Exception {
		testConnectorReplay("LinuxIpmiTool");
	}

	@Test
	@Disabled
	void testLmsensors() throws Exception {
		testConnectorReplay("Lmsensors");
	}

	@Test
	@Disabled
	void testMariaDB() throws Exception {
		testConnectorReplay("MariaDB");
	}

	@Test
	void testMIB2() throws Exception {
		testConnectorReplay("MIB2");
	}

	@Test
	void testMIB2Switch() throws Exception {
		testConnectorReplay("MIB2Switch");
	}

	@Test
	@Disabled
	void testMySQL() throws Exception {
		testConnectorReplay("MySQL");
	}

	@Test
	@Disabled
	void testPostgreSQL() throws Exception {
		testConnectorReplay("PostgreSQL");
	}

	@Test
	void testRedfish() throws Exception {
		testConnectorReplay("Redfish");
	}

	@Test
	@Disabled
	void testSmartMonLinux() throws Exception {
		testConnectorReplay("SmartMonLinux");
	}

	@Test
	@Disabled
	void testWbemGenDiskNT() throws Exception {
		testConnectorReplay("WbemGenDiskNT");
	}

	@Test
	@Disabled
	void testWindowsFile() throws Exception {
		testConnectorReplay("WindowsFile");
	}

	@Test
	@Disabled
	void testWindowsIpmiTool() throws Exception {
		testConnectorReplay("WindowsIpmiTool");
	}

	@Test
	@Disabled
	void testWinStorageSpaces() throws Exception {
		testConnectorReplay("WinStorageSpaces");
	}
}
