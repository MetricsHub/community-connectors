package org.metricshub.connector.it;

import static org.junit.jupiter.api.condition.OS.WINDOWS;

import org.junit.jupiter.api.condition.EnabledOnOs;

/**
 * WBEMGenDiskNT has a service criterion that only runs on Windows
 * and thus is only included in the Windows test suite to avoid unnecessary test failures on other OSes.
 */
@EnabledOnOs(WINDOWS)
class WBEMGenDiskNTIT extends AbstractConnectorReplayIT {

	WBEMGenDiskNTIT() {
		super("WBEMGenDiskNT");
	}
}
