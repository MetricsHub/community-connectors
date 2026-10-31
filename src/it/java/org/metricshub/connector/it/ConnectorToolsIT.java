package org.metricshub.connector.it;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertFalse;

import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.metricshub.engine.connector.model.ConnectorStore;

/**
 * The agent leaves out, with a mere warning, a tool whose declaration it refuses: a reference to an undeclared
 * parameter or to an optional one without default, a pattern that does not compile, a default its own parameter
 * refuses. Check every tool here instead.
 */
class ConnectorToolsIT {

	@Test
	void testToolDeclarations() {
		final ConnectorStore connectorStore = new ConnectorStore(Path.of("src", "main", "connector"));
		assertFalse(connectorStore.getStore().get("Linux").getTools().isEmpty());
		connectorStore
			.getStore()
			.forEach((connectorId, connector) ->
				connector
					.getTools()
					.forEach((name, tool) -> assertDoesNotThrow(() -> tool.toDefinition(name), connectorId + "_" + name))
			);
	}
}
