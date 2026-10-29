# MetricsHub Community Connectors Repository
![GitHub release (with filter)](https://img.shields.io/github/v/release/metricshub/community-connectors)
![Build](https://img.shields.io/github/actions/workflow/status/metricshub/community-connectors/deploy.yml)
![GitHub top language](https://img.shields.io/github/languages/top/metricshub/community-connectors)
![License](https://img.shields.io/github/license/metricshub/community-connectors)

This project is a repository for the MetricsHub Community Connectors.

See **[Project Documentation](https://github.com/metricshub/community-connectors)** for more information on how to use this library in your code.

## Build instructions

This is a simple Maven project. Build with:

```bash
mvn verify
```

The build resolves the MetricsHub artifacts (the *SNAPSHOT* versions used by the tests, and the MetricsHub Connector Maven Plugin) from `https://repo.metricshub.com/repository/maven-public/`, which requires credentials. Declare them in the `metricshub` server of your `~/.m2/settings.xml`:

```xml
<settings>
  <servers>
    <server>
      <id>metricshub</id>
      <username>your-username</username>
      <password>your-token</password>
    </server>
  </servers>
</settings>
```

## Release instructions

The artifact is deployed to the MetricsHub Maven repository:

* Releases: https://repo.metricshub.com/repository/maven-oss-releases/
* Snapshots: https://repo.metricshub.com/repository/maven-oss-snapshots/

It is strongly recommended to only use [GitHub Actions "Release to repo.metricshub.com"](../../actions/workflows/release.yml) to perform a release:

* Manually trigger the "Release" workflow
* Specify the version being released and the next version number (SNAPSHOT)
* Merge the PR that has been created to prepare the next version

The release is published immediately: there is no staging repository to release. A version that has been partially deployed can't be deployed again: delete its components on https://repo.metricshub.com before restarting the workflow, or release the next version instead.

## License

License is Affero General Public License (AGPL) version 3.0. Each source file includes the AGPL-3 header (build will fail otherwise).
To update source files with the proper header, simply execute the below command:

```bash
mvn license:update-file-header
```
