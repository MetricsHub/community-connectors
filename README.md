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

## Release instructions

The artifact is deployed to Sonatype's [Maven Central](https://central.sonatype.com/).

It is strongly recommended to only use [GitHub Actions "Release to Maven Central"](../../actions/workflows/release.yml) to perform a release:

* Manually trigger the "Release" workflow
* Specify the version being released and the next version number (SNAPSHOT)
* Release the corresponding staging repository on [Maven Central](https://central.sonatype.com/)
* Merge the PR that has been created to prepare the next version

## License

License is Affero General Public License (AGPL) version 3.0. Each source file includes the AGPL-3 header (build will fail otherwise).
To update source files with the proper header, simply execute the below command:

```bash
mvn license:update-file-header
```
