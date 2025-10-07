import org.junit.jupiter.api.Test;

public class EmulationIT {

	@Test
	void testWinStorageSpaces() throws Exception {
		final String connectorName = "WinStorageSpaces";
		final EmulationITBase winStorageSpaces = new EmulationITBase(connectorName);
		winStorageSpaces.emulateViaConfig();
		winStorageSpaces.verifyExpected(connectorName + "/expected/expected.json");
	}

	@Test
	void testMIB2() throws Exception {
		final String connectorName = "MIB2";
		final EmulationITBase mib2Emulation = new EmulationITBase(connectorName);
		mib2Emulation.emulateViaConfig();
		mib2Emulation.verifyExpected(connectorName + "/expected/expected.json");
	}

	@Test
	void testLmSensors() throws Exception {
		final String connectorName = "Lmsensors";
		final EmulationITBase lmsensorsEmulation = new EmulationITBase(connectorName);
		lmsensorsEmulation.emulateViaConfig();
		lmsensorsEmulation.verifyExpected(connectorName + "/expected/expected.json");
	}

	@Test
	void testLinux() throws Exception {
		final String connectorName = "Linux";
		final EmulationITBase linuxEmulation = new EmulationITBase(connectorName);
		linuxEmulation.emulateViaConfig();
		linuxEmulation.verifyExpected(connectorName + "/expected/expected.json");
	}

	@Test
	void testMySql() throws Exception {
		final String connectorName = "MySql";
		final EmulationITBase mySqlEmulation = new EmulationITBase(connectorName);
		mySqlEmulation.emulateViaConfig();
		mySqlEmulation.verifyExpected(connectorName + "/expected/expected.json");
	}

	@Test
	void testWbemGenDiskNT() throws Exception {
		final String connectorName = "WbemGenDiskNT";
		final EmulationITBase wbemGenDiskNTEmulation = new EmulationITBase(connectorName);
		wbemGenDiskNTEmulation.emulateViaConfig();
		wbemGenDiskNTEmulation.verifyExpected(connectorName + "/expected/expected.json");
	}

	@Test
	void testSmartMonLinux() throws Exception {
		final String connectorName = "SmartMonLinux";
		final EmulationITBase smartMonEmulation = new EmulationITBase(connectorName);
		smartMonEmulation.emulateViaConfig();
		smartMonEmulation.verifyExpected(connectorName + "/expected/expected.json");
	}
}

