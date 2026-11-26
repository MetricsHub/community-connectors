package org.metricshub.connector.it;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;

import com.fasterxml.jackson.databind.JsonNode;
import io.jawk.Awk;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.stream.Stream;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.metricshub.engine.awk.AwkExecutor;
import org.metricshub.engine.awk.MetricsHubExtensionForJawk;
import org.metricshub.engine.common.helpers.JsonHelper;
import org.metricshub.engine.common.helpers.MetricsHubConstants;
import org.metricshub.engine.connector.deserializer.ConnectorDeserializer;
import org.metricshub.engine.connector.model.Connector;
import org.metricshub.engine.connector.model.ConnectorStore;
import org.metricshub.engine.connector.model.IntermediateConnector;
import org.metricshub.engine.connector.model.RawConnectorStore;
import org.metricshub.engine.connector.model.monitor.task.source.JawkSource;
import org.metricshub.engine.connector.model.monitor.task.source.compute.Compute;
import org.metricshub.engine.connector.parser.ConnectorParser;
import org.metricshub.engine.connector.parser.ConnectorStoreComposer;
import org.metricshub.engine.connector.parser.RawConnectorLibraryParser;
import org.metricshub.engine.connector.update.ContentTypeCheck;
import org.metricshub.engine.strategy.utils.EmbeddedFileHelper;

/**
 * Every connector of the library loads and every AWK script compiles, with the engine this repository builds
 * against. The engine leaves out, with a logged error, a connector it refuses, and compiles a script the first
 * time it runs: nothing else tells for a connector without a replay IT.
 */
class ConnectorLibraryIT {

	private static final Path CONNECTOR_DIRECTORY = Path.of("src", "main", "connector");

	private static ConnectorStoreComposer composer;

	private static ConnectorStore connectorStore;

	@BeforeAll
	static void loadConnectors() {
		composer = ConnectorStoreComposer.builder()
			.withRawConnectorStore(new RawConnectorStore(CONNECTOR_DIRECTORY))
			.withUpdateChain(ConnectorParser.createUpdateChain())
			.withDeserializer(new ConnectorDeserializer(JsonHelper.buildYamlMapper()))
			.build();
		connectorStore = composer.generateStaticConnectorStore();
		// The connectors declaring variables, with their default values
		connectorStore.addMany(composer.resolveConnectorStoreVariables(connectorStore).getCustomConnectorsMap());
	}

	@Test
	void everyConnectorFileLoads() throws IOException {
		final List<String> unloaded = new ArrayList<>();
		// The store is keyed by file name, case-insensitive: of two files with the same name, only one loads
		final Map<String, Path> ids = new TreeMap<>(String.CASE_INSENSITIVE_ORDER);
		try (Stream<Path> files = Files.walk(CONNECTOR_DIRECTORY)) {
			for (final Path file : files.sorted().toList()) {
				final String name = file.getFileName().toString();
				if (name.toLowerCase().endsWith(".yaml") && isConnector(file)) {
					final String id = name.substring(0, name.length() - ".yaml".length());
					final Path other = ids.putIfAbsent(id, file);
					if (other != null) {
						unloaded.add(file + ": its id is also that of " + other);
					} else if (!connectorStore.getStore().containsKey(id)) {
						unloaded.add(file + ": " + loadError(id, file));
					}
				}
			}
		}
		assertEquals(List.of(), unloaded, "These connector files did not load");
	}

	/** The engine only logs that a connector does not load: the file is parsed again for the reason. */
	private static String loadError(final String id, final Path file) {
		IntermediateConnector connector = null;
		try {
			connector =
				new IntermediateConnector(
					id,
					ConnectorParser.withNodeProcessorAndUpdateChain(file.getParent()).parseRaw(file.toFile())
				);
			composer.parseConnector(connector);
			return "it parses alone, see the other files";
		} catch (Exception e) {
			// This parse does not substitute the variables: an error may then come from a placeholder
			final String caveat = connector != null && connector.hasVariables()
				? " (variables not substituted here, the engine log at debug level has the reason)"
				: "";
			return e.getClass().getSimpleName() + ": " + e.getMessage() + caveat;
		}
	}

	/** A connector declares <code>connector.displayName</code>. A YAML file that does not parse counts as one. */
	private static boolean isConnector(final Path file) {
		try {
			return RawConnectorLibraryParser.OBJECT_MAPPER.readTree(file.toFile()).path("connector").hasNonNull("displayName");
		} catch (IOException e) {
			return true;
		}
	}

	@Test
	void everyTableJoinWritesItsJoinType() throws IOException {
		// The engine fills in the default join type: only the YAML as written tells whether the connector chose one
		final List<String> withoutJoinType = new ArrayList<>();
		try (Stream<Path> files = Files.walk(CONNECTOR_DIRECTORY)) {
			for (final Path file : files.filter(file -> file.toString().toLowerCase().endsWith(".yaml")).sorted().toList()) {
				tableJoinsWithoutJoinType(
					RawConnectorLibraryParser.OBJECT_MAPPER.readTree(file.toFile()),
					file.toString(),
					withoutJoinType
				);
			}
		}
		assertEquals(List.of(), withoutJoinType, "These tableJoin sources write neither joinType: inner nor joinType: left");
	}

	/** Adds to <code>found</code> the path of each tableJoin source of the node that does not write its joinType. */
	private static void tableJoinsWithoutJoinType(final JsonNode node, final String where, final List<String> found) {
		if ("tableJoin".equalsIgnoreCase(node.path("type").asText()) && !node.has("joinType")) {
			found.add(where);
		}
		if (node.isArray()) {
			node.forEach(item -> tableJoinsWithoutJoinType(item, where, found));
		} else {
			node.properties().forEach(entry -> tableJoinsWithoutJoinType(entry.getValue(), where + "." + entry.getKey(), found));
		}
	}

	@Test
	void everyAwkScriptCompiles() {
		// An engine as the awk source builds it, with the MetricsHub functions; the awk compute has the utility engine
		final Awk sourceEngine = AwkExecutor.newAwk(null, MetricsHubExtensionForJawk.builder().build());
		final List<String> compiled = new ArrayList<>();
		final List<String> failures = new ArrayList<>();
		connectorStore
			.getStore()
			.forEach((connectorId, connector) ->
				ContentTypeCheck.forEachSource(connector, source -> {
					final String where = connectorId + " " + source.getKey();
					if (source instanceof JawkSource jawkSource) {
						compile(connector, jawkSource.getScript(), sourceEngine, where, compiled, failures);
					}
					for (final Compute compute : source.getComputes() == null ? List.<Compute>of() : source.getComputes()) {
						if (compute instanceof org.metricshub.engine.connector.model.monitor.task.source.compute.Awk awk) {
							compile(connector, awk.getScript(), AwkExecutor.getUtilityEngine(), where, compiled, failures);
						}
					}
				})
			);
		assertEquals(List.of(), failures, "The AWK scripts of these sources do not compile");
		assertFalse(compiled.isEmpty(), "The library has AWK scripts");
	}

	/** Compiles a script as the run does: the embedded file the property references, or the property itself. */
	private static void compile(
		final Connector connector,
		final String script,
		final Awk engine,
		final String where,
		final List<String> compiled,
		final List<String> failures
	) {
		compiled.add(where);
		try {
			engine.compile(
				MetricsHubConstants.FILE_PATTERN.matcher(script).find()
					? EmbeddedFileHelper.findEmbeddedFile(script, connector.getEmbeddedFiles(), "n/a", where)
						.orElseThrow()
						.getContentAsString()
					: script
			);
		} catch (Exception e) {
			failures.add(where + ": " + e.getMessage());
		}
	}
}
