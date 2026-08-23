# Change Log

## Unreleased

## [3.22.7](https://github.com/test-kitchen/kitchen-ec2/compare/v3.22.6...v3.22.7) (2026-08-23)


### Bug Fixes

* Update FreeBSD AMI search to the FreeBSD project's AWS account ([#677](https://github.com/test-kitchen/kitchen-ec2/issues/677)) ([f58f255](https://github.com/test-kitchen/kitchen-ec2/commit/f58f25578fb507d77134e3ce8976fe75ccfd3d08))

## [3.22.6](https://github.com/test-kitchen/kitchen-ec2/compare/v3.22.5...v3.22.6) (2026-08-23)


### Bug Fixes

* Detect sized .metal instance types when allocating dedicated hosts ([#674](https://github.com/test-kitchen/kitchen-ec2/issues/674)) ([304e08b](https://github.com/test-kitchen/kitchen-ec2/commit/304e08bafdc9592cff834107f3fa3c66bfad4d04))

## [3.22.5](https://github.com/test-kitchen/kitchen-ec2/compare/v3.22.4...v3.22.5) (2026-08-23)


### Bug Fixes

* Default to t3.micro instead of t2.micro ([#673](https://github.com/test-kitchen/kitchen-ec2/issues/673)) ([f131db4](https://github.com/test-kitchen/kitchen-ec2/commit/f131db4a25aa56154f27d8ed1c3e6b4ef07edba8))

## [3.22.4](https://github.com/test-kitchen/kitchen-ec2/compare/v3.22.3...v3.22.4) (2026-08-23)

### Bug Fixes

* Correct platform detection, SSM plugin check, and dedicated host lookups ([#667](https://github.com/test-kitchen/kitchen-ec2/issues/667)) ([8461c75](https://github.com/test-kitchen/kitchen-ec2/commit/8461c75e0dfe5fc4e0eaaa7023dfcc3c4cf97e46))

### Other Changes

* chore(deps): update googleapis/release-please-action action to v5 ([#658](https://github.com/test-kitchen/kitchen-ec2/pull/658)) ([355bbe9](https://github.com/test-kitchen/kitchen-ec2/commit/355bbe9))
* chore(deps): update actions/checkout action to v7 ([#661](https://github.com/test-kitchen/kitchen-ec2/pull/661)) ([1ce10ed](https://github.com/test-kitchen/kitchen-ec2/commit/1ce10ed))
* chore(deps): update dependency ruby to v3.4.10 ([#662](https://github.com/test-kitchen/kitchen-ec2/pull/662)) ([825a877](https://github.com/test-kitchen/kitchen-ec2/commit/825a877))
* Fix malformed YARD tags ([#663](https://github.com/test-kitchen/kitchen-ec2/pull/663)) ([b42f1b7](https://github.com/test-kitchen/kitchen-ec2/commit/b42f1b7))
* Fix markdown and YAML lint failures ([6d34910](https://github.com/test-kitchen/kitchen-ec2/commit/6d34910))
* Let cookstyle decide which files to lint ([#664](https://github.com/test-kitchen/kitchen-ec2/pull/664)) ([a09d837](https://github.com/test-kitchen/kitchen-ec2/commit/a09d837))
* Docs: rewrite README for new users and split contributor docs ([#665](https://github.com/test-kitchen/kitchen-ec2/pull/665)) ([d4b1499](https://github.com/test-kitchen/kitchen-ec2/commit/d4b1499))
* Fix the Test badge, which rendered 'no status' ([#666](https://github.com/test-kitchen/kitchen-ec2/pull/666)) ([8f33808](https://github.com/test-kitchen/kitchen-ec2/commit/8f33808))

## [3.22.3](https://github.com/test-kitchen/kitchen-ec2/compare/v3.22.2...v3.22.3) (2026-04-28)

### Bug Fixes

* Corrected the Amazon Linux 2023 naming convention ([#659](https://github.com/test-kitchen/kitchen-ec2/issues/659)) ([8757f4c](https://github.com/test-kitchen/kitchen-ec2/commit/8757f4c447921dd8a107985427d150029c35ed75))

## [3.22.2](https://github.com/test-kitchen/kitchen-ec2/compare/v3.22.1...v3.22.2) (2026-03-16)

### Bug Fixes

* Add support for Windows Server 2025 ([#656](https://github.com/test-kitchen/kitchen-ec2/issues/656)) ([c3ec8d4](https://github.com/test-kitchen/kitchen-ec2/commit/c3ec8d4c6edb3a4921fa09bc1b3e75d3a53027e1))

## [3.22.1](https://github.com/test-kitchen/kitchen-ec2/compare/v3.22.0...v3.22.1) (2026-01-22)

### Bug Fixes

* bump tk dep &lt;5 ([#652](https://github.com/test-kitchen/kitchen-ec2/issues/652)) ([2135e0e](https://github.com/test-kitchen/kitchen-ec2/commit/2135e0e17ed6893f928849c7fc747740f96f764c))

## [3.22.0](https://github.com/test-kitchen/kitchen-ec2/compare/v3.21.0...v3.22.0) (2026-01-22)

### Features

* Add AWS SSM Session Manager transport support ([#646](https://github.com/test-kitchen/kitchen-ec2/issues/646)) ([6b0fa6d](https://github.com/test-kitchen/kitchen-ec2/commit/6b0fa6d9f838249eb6f1f16c44906eb1bff84307))


### Bug Fixes

* Fix issue on failing create action ([#622](https://github.com/test-kitchen/kitchen-ec2/issues/622)) ([eb1d328](https://github.com/test-kitchen/kitchen-ec2/commit/eb1d328c2b56ec505ca7af4b244d82a3ba3ff175))
* Fixing cookstyle error ([1e319c8](https://github.com/test-kitchen/kitchen-ec2/commit/1e319c887755f606a6ec2d8989fb420a42a01cbf))

### Other Changes

* Update Debian release order ([#644](https://github.com/test-kitchen/kitchen-ec2/pull/644)) ([bd665f2](https://github.com/test-kitchen/kitchen-ec2/commit/bd665f2))
* chore(deps): update dependency ruby to v3.4.6 ([#643](https://github.com/test-kitchen/kitchen-ec2/pull/643)) ([deaa0e0](https://github.com/test-kitchen/kitchen-ec2/commit/deaa0e0))
* chore(deps): update dependency ruby to v3.4.8 ([#645](https://github.com/test-kitchen/kitchen-ec2/pull/645)) ([d74dd5b](https://github.com/test-kitchen/kitchen-ec2/commit/d74dd5b))
* chore(deps): update actions/checkout action to v6 ([#648](https://github.com/test-kitchen/kitchen-ec2/pull/648)) ([178742a](https://github.com/test-kitchen/kitchen-ec2/commit/178742a))

## [3.21.0](https://github.com/test-kitchen/kitchen-ec2/compare/v3.20.0...v3.21.0) (2025-09-09)

### Features

* Added AWS EC2 Instance Connect support ([#640](https://github.com/test-kitchen/kitchen-ec2/issues/640)) ([241ce70](https://github.com/test-kitchen/kitchen-ec2/commit/241ce70fd4998db3fe9245e8c5f2b06fb40e2d09))

### Other Changes

* chore(deps): update dependency ruby to v3.4.4 ([#636](https://github.com/test-kitchen/kitchen-ec2/pull/636)) ([c30a69e](https://github.com/test-kitchen/kitchen-ec2/commit/c30a69e))
* chore(deps): update actions/checkout action to v5 ([#641](https://github.com/test-kitchen/kitchen-ec2/pull/641)) ([3d6ccc5](https://github.com/test-kitchen/kitchen-ec2/commit/3d6ccc5))
* chore(deps): update dependency ruby to v3.4.5 ([#638](https://github.com/test-kitchen/kitchen-ec2/pull/638)) ([50b2fab](https://github.com/test-kitchen/kitchen-ec2/commit/50b2fab))

## [3.20.0](https://github.com/test-kitchen/kitchen-ec2/compare/v3.19.1...v3.20.0) (2025-06-15)

### Features

* add support for IPv6 ([#623](https://github.com/test-kitchen/kitchen-ec2/issues/623)) ([0577c59](https://github.com/test-kitchen/kitchen-ec2/commit/0577c59fec43dfdb7e7f452ee0001ff699135422))


### Bug Fixes

* Fix tests on Ruby 3.3 ([#634](https://github.com/test-kitchen/kitchen-ec2/issues/634)) ([4b3b524](https://github.com/test-kitchen/kitchen-ec2/commit/4b3b524f2d0f1080f629e88dde5d48309d392d40))

### Other Changes

* Update URLs + fix minor typos + use cookstyle ([#633](https://github.com/test-kitchen/kitchen-ec2/pull/633)) ([e29002c](https://github.com/test-kitchen/kitchen-ec2/commit/e29002c))

## [3.19.1](https://github.com/test-kitchen/kitchen-ec2/compare/v3.19.0...v3.19.1) (2025-06-08)

### Bug Fixes

* Update CentOS for username change on 9+ ([#631](https://github.com/test-kitchen/kitchen-ec2/issues/631)) ([471e027](https://github.com/test-kitchen/kitchen-ec2/commit/471e027b052a20400e6142aa74c907902d76c0d8)), closes [#630](https://github.com/test-kitchen/kitchen-ec2/issues/630)

## [3.19.0](https://github.com/test-kitchen/kitchen-ec2/compare/v3.18.0...v3.19.0) (2024-06-21)

### Features

* Bump Ruby version to 3.1 ([#618](https://github.com/test-kitchen/kitchen-ec2/issues/618)) ([9645154](https://github.com/test-kitchen/kitchen-ec2/commit/9645154606fb23430879d5bb01f748a6ca45546b))


### Bug Fixes

* release please configs ([#627](https://github.com/test-kitchen/kitchen-ec2/issues/627)) ([3fdc119](https://github.com/test-kitchen/kitchen-ec2/commit/3fdc1194114803d730e1998ae3ba6ef74ebbedba))

## [3.18.0](https://github.com/test-kitchen/kitchen-ec2/compare/v3.17.1...v3.18.0) (2023-11-28)

### Features

* Implements placement options and license specifications ([#607](https://github.com/test-kitchen/kitchen-ec2/issues/607)) ([9a269b4](https://github.com/test-kitchen/kitchen-ec2/commit/9a269b45d3886be77df47fec146d6cdcb9f28d1c))

### Other Changes

* Revert "feat: Implements placement options and license specifications… ([#614](https://github.com/test-kitchen/kitchen-ec2/pull/614)) ([a8e84e5](https://github.com/test-kitchen/kitchen-ec2/commit/a8e84e5))

## [3.17.1](https://github.com/test-kitchen/kitchen-ec2/compare/v3.17.0...v3.17.1) (2023-11-27)

### Bug Fixes

* Release ([b58158f](https://github.com/test-kitchen/kitchen-ec2/commit/b58158fa2693e581a9f1f5dbdbe7badb12536129))

### Other Changes

* A few rubocop fixes ([#601](https://github.com/test-kitchen/kitchen-ec2/pull/601)) ([b209600](https://github.com/test-kitchen/kitchen-ec2/commit/b209600))
* Tag other resources ([#605](https://github.com/test-kitchen/kitchen-ec2/pull/605)) ([2bb3437](https://github.com/test-kitchen/kitchen-ec2/commit/2bb3437))
* Fix workflows, run Cookstyle ([#610](https://github.com/test-kitchen/kitchen-ec2/pull/610)) ([8502d05](https://github.com/test-kitchen/kitchen-ec2/commit/8502d05))
* chore(deps): update dependency chefstyle to v2.2.3 ([#611](https://github.com/test-kitchen/kitchen-ec2/pull/611)) ([473737b](https://github.com/test-kitchen/kitchen-ec2/commit/473737b))
* Fix markdown ([957283f](https://github.com/test-kitchen/kitchen-ec2/commit/957283f))

## [3.17.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.17.0) (2023-06-14)

- Add support for Rocky and AlmaLinux [#602](https://github.com/test-kitchen/kitchen-ec2/pull/602) ([@bjakauppila](https://github.com/jakauppila))
- Ruby 3 compatibility for RSpec suite [#603](https://github.com/test-kitchen/kitchen-ec2/pull/603) ([@RulerOf](https://github.com/RulerOf))

* Update copyrights and comments for Jared ([cd94de4](https://github.com/test-kitchen/kitchen-ec2/commit/cd94de4))

## [3.16.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.16.0) (2023-03-16)

- Add support for Amazon Linux 2023 [#600](https://github.com/test-kitchen/kitchen-ec2/pull/600) ([@bjakauppila](https://github.com/jakauppila))
- Remove support for EOL Ruby 2.6 ([@tas50](https://github.com/tas50))

* Add missing changelog entry ([3c9badb](https://github.com/test-kitchen/kitchen-ec2/commit/3c9badb))
* Switch CentOS 7 to new AWS account owner, add CentOS stream to search ([#597](https://github.com/test-kitchen/kitchen-ec2/pull/597)) ([f14ef06](https://github.com/test-kitchen/kitchen-ec2/commit/f14ef06))
* Drop support for EOL Ruby 2.6 ([14a3490](https://github.com/test-kitchen/kitchen-ec2/commit/14a3490))

## [3.15.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.15.0) (2022-12-13)

- Add support for specifying the SSH key type to be automatically generated [#583](https://github.com/test-kitchen/kitchen-ec2/pull/583) ([@bdwyertech](https://github.com/bdwyertech))

* Add support for `mac1`/`mac2` instances ([#594](https://github.com/test-kitchen/kitchen-ec2/pull/594)) ([c474342](https://github.com/test-kitchen/kitchen-ec2/commit/c474342))

## [3.14.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.14.0) (2022-12-01)

- Support for dedicated hosts [#592](https://github.com/test-kitchen/kitchen-ec2/pull/592) ([@tecracer-theinen](https://github.com/tecracer-theinen))

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.13.0..v3.14.0)

## [3.13.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.13.0) (2022-05-30)

- Added support for metadata_options [#573](https://github.com/test-kitchen/kitchen-ec2/pull/573) ([@bdwyertech](https://github.com/bdwyertech))
- Improve speed of readiness detection for Windows instances [#582](https://github.com/test-kitchen/kitchen-ec2/pull/582) ([@jakauppila](https://github.com/jakauppila))
- Updated the README to point to kitchen.ci [#577](https://github.com/test-kitchen/kitchen-ec2/pull/577) ([@kasif-adnan](https://github.com/kasif-adnan))
- Github workflow updates [#579](https://github.com/test-kitchen/kitchen-ec2/pull/579), [#584](https://github.com/test-kitchen/kitchen-ec2/pull/584)
  ([@kasif-adnan](https://github.com/kasif-adnan))
- Chefstyle linting and version updates

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.12.0..v3.13.0)

* Use chefstyle linting ([#578](https://github.com/test-kitchen/kitchen-ec2/pull/578)) ([40f93c3](https://github.com/test-kitchen/kitchen-ec2/commit/40f93c3))
* Update chefstyle requirement from 2.1.3 to 2.2.1 ([#574](https://github.com/test-kitchen/kitchen-ec2/pull/574)) ([b5b35f8](https://github.com/test-kitchen/kitchen-ec2/commit/b5b35f8))
* Update chefstyle requirement from 2.2.1 to 2.2.2 ([#581](https://github.com/test-kitchen/kitchen-ec2/pull/581)) ([9265495](https://github.com/test-kitchen/kitchen-ec2/commit/9265495))

## [3.12.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.12.0) (2021-12-20)

- Adds support for defining multiple tags for subnet_filter [#570](https://github.com/test-kitchen/kitchen-ec2/pull/570) ([@jakauppila](https://github.com/jakauppila))
- Ensure instance is terminated if a failure occurs during creation [#570](https://github.com/test-kitchen/kitchen-ec2/pull/570) ([@jakauppila](https://github.com/jakauppila))

* Update chefstyle requirement from 2.1.2 to 2.1.3 ([#568](https://github.com/test-kitchen/kitchen-ec2/pull/568)) ([6e71914](https://github.com/test-kitchen/kitchen-ec2/commit/6e71914))

## [3.11.1](https://github.com/test-kitchen/kitchen-ec2/tree/v3.11.1) (2021-11-11)

- Resolve deprecation warnings from the AWS SDK during execution [#567](https://github.com/test-kitchen/kitchen-ec2/pull/567) ([kasif-adnan](https://github.com/kasif-adnan))

* Remove extra space in debug logging ([b8a9e78](https://github.com/test-kitchen/kitchen-ec2/commit/b8a9e78))

## [3.11.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.11.0) (2021-11-02)

- Added support for Windows 2022 [#557](https://github.com/test-kitchen/kitchen-ec2/pull/557) ([bdwyertech](https://github.com/bdwyertech))
- Added support for finding vendor images on Debian 10 and later ([tas50](https://github.com/tas50))
- Removed support for EOL Ruby 2.5 ([tas50](https://github.com/tas50))

* Make Debian 11 the default for Debian now ([3c5f9ac](https://github.com/test-kitchen/kitchen-ec2/commit/3c5f9ac))
* Add support for the upcoming Debian 13 release ([ec20149](https://github.com/test-kitchen/kitchen-ec2/commit/ec20149))
* Please yamllint ([#552](https://github.com/test-kitchen/kitchen-ec2/pull/552)) ([b46ed6a](https://github.com/test-kitchen/kitchen-ec2/commit/b46ed6a))
* Update chefstyle requirement from 2.0.5 to 2.1.2 ([#560](https://github.com/test-kitchen/kitchen-ec2/pull/560)) ([d68010c](https://github.com/test-kitchen/kitchen-ec2/commit/d68010c))
* Remove support for EOL Ruby 2.5 ([#562](https://github.com/test-kitchen/kitchen-ec2/pull/562)) ([4da8329](https://github.com/test-kitchen/kitchen-ec2/commit/4da8329))
* Use the new Debian EC2 owner ID for Debian 10 onwards ([#561](https://github.com/test-kitchen/kitchen-ec2/pull/561)) ([1e35adf](https://github.com/test-kitchen/kitchen-ec2/commit/1e35adf))

## [3.10.1](https://github.com/test-kitchen/kitchen-ec2/tree/v3.10.1) (2021-10-28)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.10.0..v3.10.1)

- Don't wait the full 300 seconds during `kitchen destroy` if the instance was deleted outside of Test Kitchen.

* skip waiting period if aws instance is already destroyed ref#191 ([#559](https://github.com/test-kitchen/kitchen-ec2/pull/559)) ([d877db5](https://github.com/test-kitchen/kitchen-ec2/commit/d877db5))

## [3.10.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.10.0) (2021-07-02)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.9.0..v3.10.0)

- Allow specifying Elastic Network Interface ID with a new `elastic_network_interface_id` configuration option. See the readme for additional details
- Support Test Kitchen 3.0
- Improved the error message when an AMI ID cannot be found

* Upgrade to GitHub-native Dependabot ([#542](https://github.com/test-kitchen/kitchen-ec2/pull/542)) ([db5a530](https://github.com/test-kitchen/kitchen-ec2/commit/db5a530))
* Update chefstyle requirement from 1.7.4 to 2.0.5 ([#548](https://github.com/test-kitchen/kitchen-ec2/pull/548)) ([5a8943f](https://github.com/test-kitchen/kitchen-ec2/commit/5a8943f))
* Fix typo in the README. ([#546](https://github.com/test-kitchen/kitchen-ec2/pull/546)) ([4cde25a](https://github.com/test-kitchen/kitchen-ec2/commit/4cde25a))
* updated the error messages on bogus ami_id ([#547](https://github.com/test-kitchen/kitchen-ec2/pull/547)) ([72c2fc6](https://github.com/test-kitchen/kitchen-ec2/commit/72c2fc6))

## [3.9.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.9.0) (2021-04-09)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.8.0..v3.9.0)

- Require Ruby 2.5 + misc test cleanup [#533](https://github.com/test-kitchen/kitchen-ec2/pull/533) ([tas50](https://github.com/tas50))
- Update `delete_on_termination` to be true by default so we properly cleanup EBS volumes on RHEL systems [#539](https://github.com/test-kitchen/kitchen-ec2/pull/539) ([i5pranay93](https://github.com/i5pranay93))
- Add support for GP3 EBS volume types [#525](https://github.com/test-kitchen/kitchen-ec2/pull/525) ([bdwyertech](https://github.com/bdwyertech))

* Update chefstyle requirement from = 1.4.4 to = 1.4.5 ([f1dec82](https://github.com/test-kitchen/kitchen-ec2/commit/f1dec82))
* Update chefstyle requirement from = 1.4.5 to = 1.5.0 ([e5dfe10](https://github.com/test-kitchen/kitchen-ec2/commit/e5dfe10))
* Update README.md ([5a1ee7b](https://github.com/test-kitchen/kitchen-ec2/commit/5a1ee7b))
* Update chefstyle requirement from = 1.5.0 to = 1.5.2 ([67d8da1](https://github.com/test-kitchen/kitchen-ec2/commit/67d8da1))
* Update chefstyle requirement from = 1.5.2 to = 1.5.6 ([2b7b4c5](https://github.com/test-kitchen/kitchen-ec2/commit/2b7b4c5))
* Update chefstyle requirement from = 1.5.6 to = 1.5.7 ([00d3cc3](https://github.com/test-kitchen/kitchen-ec2/commit/00d3cc3))
* Update for GP3 Support ([10607a6](https://github.com/test-kitchen/kitchen-ec2/commit/10607a6))
* Update chefstyle requirement from = 1.5.7 to = 1.5.8 ([ea7edaa](https://github.com/test-kitchen/kitchen-ec2/commit/ea7edaa))
* Update chefstyle requirement from = 1.5.8 to = 1.5.9 ([#527](https://github.com/test-kitchen/kitchen-ec2/pull/527)) ([a2d922e](https://github.com/test-kitchen/kitchen-ec2/commit/a2d922e))
* Test on Ruby 3.0 and cache gems ([#528](https://github.com/test-kitchen/kitchen-ec2/pull/528)) ([2c93417](https://github.com/test-kitchen/kitchen-ec2/commit/2c93417))
* Cleanup rakefile tests + split github tests ([#532](https://github.com/test-kitchen/kitchen-ec2/pull/532)) ([bcdee7f](https://github.com/test-kitchen/kitchen-ec2/commit/bcdee7f))
* Update chefstyle requirement from =1.5.9 to 1.6.2 ([#535](https://github.com/test-kitchen/kitchen-ec2/pull/535)) ([799eb7f](https://github.com/test-kitchen/kitchen-ec2/commit/799eb7f))
* Update chefstyle requirement from 1.6.2 to 1.7.2 ([#537](https://github.com/test-kitchen/kitchen-ec2/pull/537)) ([4b1eb1c](https://github.com/test-kitchen/kitchen-ec2/commit/4b1eb1c))
* Update chefstyle requirement from 1.7.2 to 1.7.4 ([#538](https://github.com/test-kitchen/kitchen-ec2/pull/538)) ([3d02fc6](https://github.com/test-kitchen/kitchen-ec2/commit/3d02fc6))

## [3.8.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.8.0) (2020-10-14)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.7.2..v3.8.0)

- Allow multiple ip addresses to be specified when creating a security group [#509](https://github.com/test-kitchen/kitchen-ec2/pull/509) ([trainsushi](https://github.com/trainsushi))
- Use defaults when creating spot instances - fixes block_duration_minutes [#512](https://github.com/test-kitchen/kitchen-ec2/pull/512) ([clintoncwolfe](https://github.com/clintoncwolfe))

* Update chefstyle requirement from = 1.4.0 to = 1.4.3 ([4c7d79c](https://github.com/test-kitchen/kitchen-ec2/commit/4c7d79c))
* Update chefstyle requirement from = 1.4.3 to = 1.4.4 ([3da2d78](https://github.com/test-kitchen/kitchen-ec2/commit/3da2d78))
* Allow multiple ip addresses in security group ([0c307ab](https://github.com/test-kitchen/kitchen-ec2/commit/0c307ab))

## [3.7.2](https://github.com/test-kitchen/kitchen-ec2/tree/v3.7.2) (2020-09-29)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.7.1..v3.7.2)

- Prefer non-Beta RHEL AMIs in search [#506](https://github.com/test-kitchen/kitchen-ec2/pull/506) ([clintoncwolfe](https://github.com/clintoncwolfe))
- Minor performance optimization to subnet determination [#514](https://github.com/test-kitchen/kitchen-ec2/pull/514) ([clintoncwolfe](https://github.com/clintoncwolfe))
- Optimize our requires [#510](https://github.com/test-kitchen/kitchen-ec2/pull/510) ([tas50](https://github.com/tas50))
- Use match? instead of =~ to reduce memory usage [#508](https://github.com/test-kitchen/kitchen-ec2/pull/508) ([tas50](https://github.com/tas50))
- Document missing properties [#504](https://github.com/test-kitchen/kitchen-ec2/pull/504) ([mbaitelman](https://github.com/mbaitelman))

* Update chefstyle requirement from = 1.1.2 to = 1.1.3 ([#501](https://github.com/test-kitchen/kitchen-ec2/pull/501)) ([aa89308](https://github.com/test-kitchen/kitchen-ec2/commit/aa89308))
* Update chefstyle requirement from = 1.1.3 to = 1.2.0 ([#503](https://github.com/test-kitchen/kitchen-ec2/pull/503)) ([7a0fcf1](https://github.com/test-kitchen/kitchen-ec2/commit/7a0fcf1))
* Update chefstyle requirement from = 1.2.0 to = 1.2.1 ([#507](https://github.com/test-kitchen/kitchen-ec2/pull/507)) ([4095e3a](https://github.com/test-kitchen/kitchen-ec2/commit/4095e3a))

## [3.7.1](https://github.com/test-kitchen/kitchen-ec2/tree/v3.7.1) (2020-07-13)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.7.0..v3.7.1)

- Improvements to CentOS Image search [#502](https://github.com/test-kitchen/kitchen-ec2/pull/502) ([clintoncwolfe](https://github.com/clintoncwolfe))
- Spot Instances - Cascading Subnet Filter Support [#499](https://github.com/test-kitchen/kitchen-ec2/pull/499) ([bdwyertech](https://github.com/bdwyertech))
- Remove excon and multi-json deps [#500](https://github.com/test-kitchen/kitchen-ec2/pull/500) ([tas50](https://github.com/tas50))

* Preparing for 3.7.1 release ([928f95b](https://github.com/test-kitchen/kitchen-ec2/commit/928f95b))

## [3.7.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.7.0) (2020-07-02)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.6.0..v3.7.0)

- Tag on-demand instances and volumes at creation time [#496](https://github.com/test-kitchen/kitchen-ec2/pull/496) ([clintoncwolfe](https://github.com/clintoncwolfe))

* Update chefstyle requirement from = 1.0.5 to = 1.1.1 ([#495](https://github.com/test-kitchen/kitchen-ec2/pull/495)) ([2dd22a3](https://github.com/test-kitchen/kitchen-ec2/commit/2dd22a3))
* Update chefstyle requirement from = 1.1.1 to = 1.1.2 ([#498](https://github.com/test-kitchen/kitchen-ec2/pull/498)) ([02ef4b0](https://github.com/test-kitchen/kitchen-ec2/commit/02ef4b0))

## [3.6.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.6.0) (2020-05-17)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.5.0..v3.6.0)

- Remove support for EOL Ruby 2.3 [#491](https://github.com/test-kitchen/kitchen-ec2/pull/491) ([tas50](https://github.com/tas50))
- Make Debian 10 the Debian default [#492](https://github.com/test-kitchen/kitchen-ec2/pull/492) ([tas50](https://github.com/tas50))

* Add yard comments from my previous refactor PR ([#490](https://github.com/test-kitchen/kitchen-ec2/pull/490)) ([519cf4e](https://github.com/test-kitchen/kitchen-ec2/commit/519cf4e))

## [3.5.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.5.0) (2020-05-06)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.4.0..v3.5.0)

- Select the least-populated subnet if we have multiple matches. This should help to distribute the test-kitchen load more evenly across multi-az VPC's while maintaining full backward compatibility. [\#489](https://github.com/test-kitchen/kitchen-ec2/pull/489) ([bdwyertech](https://github.com/bdwyertech))
- Readme example cleanup [\#484](https://github.com/test-kitchen/kitchen-ec2/pull/484) ([arothian](https://github.com/arothian))

* Update chefstyle requirement from = 0.14.1 to = 0.15.1 ([#486](https://github.com/test-kitchen/kitchen-ec2/pull/486)) ([0cc93aa](https://github.com/test-kitchen/kitchen-ec2/commit/0cc93aa))

## [3.4.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.4.0) (2020-03-18)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.3.0..v3.4.0)

- Don't crash upon destroy if instance is already dead [\#482](https://github.com/test-kitchen/kitchen-ec2/pull/482) ([kamaradclimber](https://github.com/kamaradclimber))

* Migrate to GitHub Actions for testing ([#483](https://github.com/test-kitchen/kitchen-ec2/pull/483)) ([400ca53](https://github.com/test-kitchen/kitchen-ec2/commit/400ca53))
* Update chefstyle requirement from = 0.14.0 to = 0.14.1 ([#481](https://github.com/test-kitchen/kitchen-ec2/pull/481)) ([5b7c3fc](https://github.com/test-kitchen/kitchen-ec2/commit/5b7c3fc))
* Remove double chefstyle dep ([374e8d0](https://github.com/test-kitchen/kitchen-ec2/commit/374e8d0))

## [3.3.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.3.0) (2020-01-20)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.2.0..v3.3.0)

- Ignore case when checking if the instance provisioner is Chef [\#474](https://github.com/test-kitchen/kitchen-ec2/pull/474) ([slapvanilla](https://github.com/slapvanilla))
- Enhancements: Security Group Search & Spot Instance Provisioning [\#470](https://github.com/test-kitchen/kitchen-ec2/pull/470) ([bdwyertech](https://github.com/bdwyertech))
- Update chefstyle requirement from = 0.13.3 to = 0.14.0 [\#472](https://github.com/test-kitchen/kitchen-ec2/pull/472) ([tas50](https://github.com/tas50))
- Use require_relative instead of require [\#478](https://github.com/test-kitchen/kitchen-ec2/pull/478) ([tas50](https://github.com/tas50))

* Test on the latest ruby releases ([#477](https://github.com/test-kitchen/kitchen-ec2/pull/477)) ([51d2d74](https://github.com/test-kitchen/kitchen-ec2/commit/51d2d74))

## [3.2.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.2.0) (2019-09-17)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.1.0..v3.2.0)

- Allow for retryable 3.0 [\#466](https://github.com/test-kitchen/kitchen-ec2/pull/466) ([tas50](https://github.com/tas50))
- Update Chefstyle to 0.13.3 [\#465](https://github.com/test-kitchen/kitchen-ec2/pull/465) ([tas50](https://github.com/tas50))
- Adds Windows Server 2019 \(and tests\) [\#462](https://github.com/test-kitchen/kitchen-ec2/pull/462) ([mbaitelman](https://github.com/mbaitelman))
- \#394: Check subnet\_filter as well when creating security group [\#413](https://github.com/test-kitchen/kitchen-ec2/pull/413) ([llibicpep](https://github.com/llibicpep))

* Preparing 3.2.0 release ([#469](https://github.com/test-kitchen/kitchen-ec2/pull/469)) ([2b85027](https://github.com/test-kitchen/kitchen-ec2/commit/2b85027))

## [3.1.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.1.0) (2019-08-07)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.0.1..v3.1.0)

- Resolve additional deprecation warnings from the new aws-sdk-v3 dependency. Thanks [@Annih](https://github.com/Annih)
- Add support for SSH through Session Manager. Thanks [@awiddersheim](https://github.com/awiddersheim)
- Adds support for searching for multiple security groups, as well as searching by group name. Thanks [@bdwyertech](https://github.com/bdwyertech)
- Allow asking for multiple instance types and subnets for spot pricing. Thanks [@vmiszczak-teads](https://github.com/vmiszczak-teads)

* Security Group Filter Enhancement ([#458](https://github.com/test-kitchen/kitchen-ec2/pull/458)) ([bc9ec83](https://github.com/test-kitchen/kitchen-ec2/commit/bc9ec83))
* Fix aws-sdk-ec2 deprecation warnings ([#454](https://github.com/test-kitchen/kitchen-ec2/pull/454)) ([a6e56c8](https://github.com/test-kitchen/kitchen-ec2/commit/a6e56c8))

## [3.0.1](https://github.com/test-kitchen/kitchen-ec2/tree/v3.0.1) (2019-05-08)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.0.0..v3.0.1)

- Resolve deprecation warnings from the new aws-sdk-v3 dependency

* Avoid a deprecation warninig when spinning up a new instance ([#455](https://github.com/test-kitchen/kitchen-ec2/pull/455)) ([454a820](https://github.com/test-kitchen/kitchen-ec2/commit/454a820))

## [3.0.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.0.0) (2019-05-01)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v2.4.0..v3.0.0)

- Switch from the monolithic aws-sdk-v2 to the just aws-sdk-ec2 aka aws-sdk-v3. This greatly reduces the number of dependencies necessary for this plugin, but is a major change that makes it incompatible with older released of ChefDK that require aws-sdk-v2.
- Require Ruby 2.3 or later as Ruby 2.2 is now EOL
- Loosen the dependency on Test Kitchen to allow this plugin to work with Test Kitchen 2.0
- Fix hostname detection to not fail when the system doesn't have a public IP. Thanks [@niekrasp](https://github.com/niekrasp)
- Added a new `security_group_cidr_ip` config for specifying IP CIDRs in the security group. Defaults to 0.0.0.0/0. Thanks [@dpattmann](https://github.com/dpattmann)
- Support providing full Debian versions like 9.6 instead of just the major release like 9
- Ensure tags keys are strings as expected by AWS SDK. Thanks [@Annih](https://github.com/Annih)
- Leverage quadratic backoff retry on instance creation throttling. Thanks [@Annih](https://github.com/Annih)
- Honor AWS_PROFILE if present. Thanks [@bdwyertech](https://github.com/bdwyertech)

* Require Ruby 2.3 and aws-sdk-ec2 ([#419](https://github.com/test-kitchen/kitchen-ec2/pull/419)) ([3fb421a](https://github.com/test-kitchen/kitchen-ec2/commit/3fb421a))
* Test on the latest versions of Ruby in Travis ([#449](https://github.com/test-kitchen/kitchen-ec2/pull/449)) ([0aac028](https://github.com/test-kitchen/kitchen-ec2/commit/0aac028))
* Add missing changelog entries ([ca750ed](https://github.com/test-kitchen/kitchen-ec2/commit/ca750ed))

## [2.5.0](https://github.com/test-kitchen/kitchen-ec2/compare/v2.4.0...v2.5.0) (2019-03-20)

* Warn but properly lookup full debian versions like 9.6 ([#439](https://github.com/test-kitchen/kitchen-ec2/pull/439)) ([3edab05](https://github.com/test-kitchen/kitchen-ec2/commit/3edab05))
* Make ingress ip range configurable ([#446](https://github.com/test-kitchen/kitchen-ec2/pull/446)) ([f048491](https://github.com/test-kitchen/kitchen-ec2/commit/f048491))
* Fallback to ordered mapping when failed to detect hostname using interface_type ([#421](https://github.com/test-kitchen/kitchen-ec2/pull/421)) ([485cd74](https://github.com/test-kitchen/kitchen-ec2/commit/485cd74))
* Loosen the test-kitchen and yard deps ([#448](https://github.com/test-kitchen/kitchen-ec2/pull/448)) ([c96f891](https://github.com/test-kitchen/kitchen-ec2/commit/c96f891))
* Remove the github changelog generator task ([09ed003](https://github.com/test-kitchen/kitchen-ec2/commit/09ed003))

## [2.4.0](https://github.com/test-kitchen/kitchen-ec2/tree/v2.4.0) (2018-12-20)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v2.3.4..v2.4.0)

- Don't ship spec files in the gem artifact
- Support Amazon Linux 2.0 image searching. Use the platform 'amazon2'
- Support Windows Server 1709 and 1803 image searching

* Add support for Amazon Linux 2 ([#430](https://github.com/test-kitchen/kitchen-ec2/pull/430)) ([ddd4e1a](https://github.com/test-kitchen/kitchen-ec2/commit/ddd4e1a))
* Add support for Windows 1709 and Windows 1803 ([#429](https://github.com/test-kitchen/kitchen-ec2/pull/429)) ([d2fd013](https://github.com/test-kitchen/kitchen-ec2/commit/d2fd013))
* Skip the test files in the gem ([5a2ed76](https://github.com/test-kitchen/kitchen-ec2/commit/5a2ed76))

## [2.3.4](https://github.com/test-kitchen/kitchen-ec2/tree/v2.3.4) (2018-12-04)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v2.3.3...v2.3.4)

- Don't ship the changelog in the gem

* Don't ship the changelog in the gem artifact ([#436](https://github.com/test-kitchen/kitchen-ec2/pull/436)) ([03d6064](https://github.com/test-kitchen/kitchen-ec2/commit/03d6064))

## [2.3.3](https://github.com/test-kitchen/kitchen-ec2/tree/v2.3.3) (2018-11-28)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v2.3.2...v2.3.3)

**Merged pull requests:**

- Adding support for arm64 architecture [\#433]

* Preparing 2.3.3 release ([#435](https://github.com/test-kitchen/kitchen-ec2/pull/435)) ([edb7207](https://github.com/test-kitchen/kitchen-ec2/commit/edb7207))

## [2.3.2](https://github.com/test-kitchen/kitchen-ec2/tree/v2.3.2) (2018-11-28)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v2.3.1...v2.3.2)

**Fixed Bugs:**

- fix x86_64 architecture default for image search (fixes new arm64 arch appearing instead) [\#432]

## [2.3.1](https://github.com/test-kitchen/kitchen-ec2/tree/v2.3.1) (2018-10-19)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v2.3.0...v2.3.1)

**Fixed Bugs:**

- windows2012-r2 hanging on userdata.ps1 in kitchen-ec2 2.3.0 [\#424]

* Add -Type parameter to userdata to support PowerShell 4.0 ([#425](https://github.com/test-kitchen/kitchen-ec2/pull/425)) ([48e4cd7](https://github.com/test-kitchen/kitchen-ec2/commit/48e4cd7))

## [2.3.0](https://github.com/test-kitchen/kitchen-ec2/tree/v2.3.0) (2018-10-05)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v2.2.2...v2.3.0)

- Add port 3389 (RDP) to the automatically generated security group
- Fix logfile creation on Windows to not fail if the directory doesn't exist
- The gem no longer ships with test deps so we can slim the install size

* Update to latest ruby releases in Travis ([#403](https://github.com/test-kitchen/kitchen-ec2/pull/403)) ([b694d20](https://github.com/test-kitchen/kitchen-ec2/commit/b694d20))
* Fix Windows user-data log location ([#405](https://github.com/test-kitchen/kitchen-ec2/pull/405)) ([a4f4304](https://github.com/test-kitchen/kitchen-ec2/commit/a4f4304))
* Adding the RDP port to the list of default security group ports ([#415](https://github.com/test-kitchen/kitchen-ec2/pull/415)) ([f2c2e1c](https://github.com/test-kitchen/kitchen-ec2/commit/f2c2e1c))
* Remove github_changelog_generator & don't include specs in the gem ([#422](https://github.com/test-kitchen/kitchen-ec2/pull/422)) ([f6926b8](https://github.com/test-kitchen/kitchen-ec2/commit/f6926b8))

## [2.2.2](https://github.com/test-kitchen/kitchen-ec2/tree/v2.2.2) (2018-06-11)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v2.2.1...v2.2.2)

**Fixed bugs:**

- Kitchen failure when adding spot\_price [\#328](https://github.com/test-kitchen/kitchen-ec2/issues/328)

**Merged pull requests:**

- Fix dynamic key creation [\#400](https://github.com/test-kitchen/kitchen-ec2/pull/400) ([bdwyertech](https://github.com/bdwyertech))
- allow AWS-managed ssh key pairs to be disabled [\#392](https://github.com/test-kitchen/kitchen-ec2/pull/392) ([cheeseplus](https://github.com/cheeseplus))

## [2.2.1](https://github.com/test-kitchen/kitchen-ec2/tree/v2.2.1) (2018-02-12)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v2.2.0...v2.2.1)

**Fixed bugs:**

- Fix `undefined` error when Windows AMIs don't include "windows" in name [\#322](https://github.com/test-kitchen/kitchen-ec2/issues/322) [\#324](https://github.com/test-kitchen/kitchen-ec2/pull/324) ([BenLiyanage](https://github.com/BenLiyanage))
- Fix error behavior when security\_group\_filter is set but no security group found for those tags [\#386](https://github.com/test-kitchen/kitchen-ec2/pull/386) ([dpattmann](https://github.com/dpattmann))
- Don't create security group if security\_group\_filter is set [\#385](https://github.com/test-kitchen/kitchen-ec2/pull/385) ([dpattmann](https://github.com/dpattmann))

* I forgot this comment earlier, but better late than never. ([84ea443](https://github.com/test-kitchen/kitchen-ec2/commit/84ea443))
* Fixing up PR324 ([#387](https://github.com/test-kitchen/kitchen-ec2/pull/387)) ([d5c7b9e](https://github.com/test-kitchen/kitchen-ec2/commit/d5c7b9e))
* Releasing 2.2.1 ([#388](https://github.com/test-kitchen/kitchen-ec2/pull/388)) ([3bbbc2e](https://github.com/test-kitchen/kitchen-ec2/commit/3bbbc2e))

## [2.2.0](https://github.com/test-kitchen/kitchen-ec2/tree/v2.2.0) (2018-01-27)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v2.1.0...v2.2.0)

- When config validation fails we now show you just the error message instead of the full stack trace with a buried error message
- Removed the username logic for FreeBSD < 9.1 as those releases are EOL
- Add support for Debian 10/11 so we'll support them as soon as they're released
- Added support for the 'host' tenancy value
- Added proper config validation for tenancy instead of silently skipping bad data
- Properly handle Integers in tags instead of failing the run
- Properly handle nil values in tags instead of failing the run
- Add validation to make sure the tags are passed as a single hash instead of an array of each tag
- Update our Yard dev dependency to make sure we have 0.9.11+ to avoid a CVE in earlier releases
- Update links in docs and distros in the examples
- Removed Rubocop comments that weren't necessary from the code

* Updating readme to prevent confusion ([#371](https://github.com/test-kitchen/kitchen-ec2/pull/371)) ([566baec](https://github.com/test-kitchen/kitchen-ec2/commit/566baec))
* Update links and remove super old distros ([#372](https://github.com/test-kitchen/kitchen-ec2/pull/372)) ([0b9b636](https://github.com/test-kitchen/kitchen-ec2/commit/0b9b636))
* Remove logic for FreeBSD &lt; 9.1 ([#376](https://github.com/test-kitchen/kitchen-ec2/pull/376)) ([08a4602](https://github.com/test-kitchen/kitchen-ec2/commit/08a4602))
* Use the https link to the website in the gemspec ([#374](https://github.com/test-kitchen/kitchen-ec2/pull/374)) ([a056753](https://github.com/test-kitchen/kitchen-ec2/commit/a056753))
* Add future Debian codenames ([#375](https://github.com/test-kitchen/kitchen-ec2/pull/375)) ([1e87ea9](https://github.com/test-kitchen/kitchen-ec2/commit/1e87ea9))
* Throw a more friendly warning on bad configs ([#373](https://github.com/test-kitchen/kitchen-ec2/pull/373)) ([a3213a9](https://github.com/test-kitchen/kitchen-ec2/commit/a3213a9))
* Add copyrights, license headers and remove old rubocop comments ([#378](https://github.com/test-kitchen/kitchen-ec2/pull/378)) ([6579630](https://github.com/test-kitchen/kitchen-ec2/commit/6579630))
* Bump Yard dep to avoid a CVE ([#379](https://github.com/test-kitchen/kitchen-ec2/pull/379)) ([7812988](https://github.com/test-kitchen/kitchen-ec2/commit/7812988))
* Fix handling of nil/Integer tags and add logging if improper format is used ([#381](https://github.com/test-kitchen/kitchen-ec2/pull/381)) ([7f5c84a](https://github.com/test-kitchen/kitchen-ec2/commit/7f5c84a))
* Allow 'host' type tenancy & add proper validation warnings ([#382](https://github.com/test-kitchen/kitchen-ec2/pull/382)) ([303118f](https://github.com/test-kitchen/kitchen-ec2/commit/303118f))

## [2.1.0](https://github.com/test-kitchen/kitchen-ec2/tree/v2.1.0) (2018-01-27)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v2.0.0...v2.1.0)

**Merged pull requests:**

- Only create Ohai hint when provisioner is `/chef/` [\#366](https://github.com/test-kitchen/kitchen-ec2/pull/366) ([cheeseplus](https://github.com/cheeseplus))
- Automatically create a security group and key pair if needed. [\#362](https://github.com/test-kitchen/kitchen-ec2/pull/362) ([coderanger](https://github.com/coderanger))

* Adding ruby 2.5 to testing matrix ([#365](https://github.com/test-kitchen/kitchen-ec2/pull/365)) ([d8303df](https://github.com/test-kitchen/kitchen-ec2/commit/d8303df))
* Fix issue link in changelog ([#363](https://github.com/test-kitchen/kitchen-ec2/pull/363)) ([eff3ee9](https://github.com/test-kitchen/kitchen-ec2/commit/eff3ee9))

## [2.0.0](https://github.com/test-kitchen/kitchen-ec2/tree/v2.0.0) (2017-12-08)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v1.4.0...v2.0.0)

### Improvements

- Clean up original Authentication; Rely on SDK for Chain. [\#353](https://github.com/test-kitchen/kitchen-ec2/pull/353) ([rhyas](https://github.com/rhyas))
- Use quadratic backoff when encountering RequestLimit errors [\#320](https://github.com/test-kitchen/kitchen-ec2/pull/320) ([kamaradclimber](https://github.com/kamaradclimber))

## [1.4.0](https://github.com/test-kitchen/kitchen-ec2/tree/v1.4.0) (2017-11-29)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v1.3.2...v1.4.0)

### Improvements

- Explicitly initialise secondary disks on windows 2016 [\#352](https://github.com/test-kitchen/kitchen-ec2/pull/352) ([rlaveycal](https://github.com/rlaveycal))
- Fix windows user\_data log file [\#350](https://github.com/test-kitchen/kitchen-ec2/pull/350) ([rlaveycal](https://github.com/rlaveycal))
- Set LocalAccountTokenFilterPolicy to allow powershell remoting from local accounts [\#348](https://github.com/test-kitchen/kitchen-ec2/pull/348) ([Sam-Martin](https://github.com/Sam-Martin))
- Add EC2 hostname when printing ready message [\#346](https://github.com/test-kitchen/kitchen-ec2/pull/346) ([pierrecdn](https://github.com/pierrecdn))
- Fix for issue with instance-store backed instance \(issue \#318\) [\#343](https://github.com/test-kitchen/kitchen-ec2/pull/343) ([naunga](https://github.com/naunga))
- Handle nulls/binary text in user data so it supports gzip [\#338](https://github.com/test-kitchen/kitchen-ec2/pull/338) ([brodygov](https://github.com/brodygov))
- This updates the documentation [\#337](https://github.com/test-kitchen/kitchen-ec2/pull/337) ([stiller-leser](https://github.com/stiller-leser))
- Add support for Debian Stretch [\#327](https://github.com/test-kitchen/kitchen-ec2/pull/327) ([RoboticCheese](https://github.com/RoboticCheese))
- Add support for Amazon Linux [\#321](https://github.com/test-kitchen/kitchen-ec2/pull/321) ([steven-burns](https://github.com/steven-burns))
- modernize winrm setup and fix for 2008r2 [\#304](https://github.com/test-kitchen/kitchen-ec2/pull/304) ([mwrock](https://github.com/mwrock))
- Updated readme based on issue 300 [\#302](https://github.com/test-kitchen/kitchen-ec2/pull/302) ([pgporada](https://github.com/pgporada))
- Use Chefstyle and require Ruby 2.2.2 [\#301](https://github.com/test-kitchen/kitchen-ec2/pull/301) ([tas50](https://github.com/tas50))

### Other Changes

* Correct the docs for image_id ([d801b17](https://github.com/test-kitchen/kitchen-ec2/commit/d801b17))
* Gem cleanup prior to a release ([#340](https://github.com/test-kitchen/kitchen-ec2/pull/340)) ([39defa1](https://github.com/test-kitchen/kitchen-ec2/commit/39defa1))

## [1.3.2](https://github.com/test-kitchen/kitchen-ec2/tree/v1.3.2) (2017-02-24)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v1.3.1...v1.3.2)

**Improvements:**

- Don't try to set tags if there aren't any. [\#298](https://github.com/test-kitchen/kitchen-ec2/pull/298) ([coderanger](https://github.com/coderanger))

* Cut 1.3.2 ([#299](https://github.com/test-kitchen/kitchen-ec2/pull/299)) ([6a45a2b](https://github.com/test-kitchen/kitchen-ec2/commit/6a45a2b))

## [1.3.1](https://github.com/test-kitchen/kitchen-ec2/tree/v1.3.1) (2017-02-16)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v1.3.0...v1.3.1)

**Merged pull requests:**

- reinstate default shared creds option [\#296](https://github.com/test-kitchen/kitchen-ec2/pull/296) ([davidcpell](https://github.com/davidcpell))

* Actually bumping version ([72d1229](https://github.com/test-kitchen/kitchen-ec2/commit/72d1229))

## [1.3.0](https://github.com/test-kitchen/kitchen-ec2/tree/v1.3.0) (2017-02-11)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v1.2.0...v1.3.0)

**Implemented Enhancements:**

- Support Windows 2016 [\#291](https://github.com/test-kitchen/kitchen-ec2/pull/291) ([gdavison](https://github.com/gdavison))
- Add expiration to spot requests [\#285](https://github.com/test-kitchen/kitchen-ec2/pull/285) ([alanbrent](https://github.com/alanbrent))
- Don't break if we're using a custom "platform" AMI [\#273](https://github.com/test-kitchen/kitchen-ec2/pull/273) ([hynd](https://github.com/hynd))
- Propagate tags to volumes [\#260](https://github.com/test-kitchen/kitchen-ec2/pull/260) ([mrbobbytables](https://github.com/mrbobbytables))
- In the client, only source creds from the shared file when necessary [\#259](https://github.com/test-kitchen/kitchen-ec2/pull/259) ([davidcpell](https://github.com/davidcpell))
- Add notes for AMI image name requirements [\#252](https://github.com/test-kitchen/kitchen-ec2/pull/252) ([freimer](https://github.com/freimer))
- Provide the option to set ssl\_peer\_verify to false [\#251](https://github.com/test-kitchen/kitchen-ec2/pull/251) ([mwrock](https://github.com/mwrock))
- Adding support for tenancy parameter in placement config. [\#235](https://github.com/test-kitchen/kitchen-ec2/pull/235) ([jcastillocano](https://github.com/jcastillocano))
- Lookup ID from tag [\#232](https://github.com/test-kitchen/kitchen-ec2/pull/232) ([dlukman](https://github.com/dlukman))

* Fix syntax in example ([#283](https://github.com/test-kitchen/kitchen-ec2/pull/283)) ([8a15628](https://github.com/test-kitchen/kitchen-ec2/commit/8a15628))
* Add support for "Assume Role" credentials ([#227](https://github.com/test-kitchen/kitchen-ec2/pull/227)) ([01d7c87](https://github.com/test-kitchen/kitchen-ec2/commit/01d7c87))
* Revert "Add support for "Assume Role" credentials" ([#292](https://github.com/test-kitchen/kitchen-ec2/pull/292)) ([2549243](https://github.com/test-kitchen/kitchen-ec2/commit/2549243))

## [1.2.0](https://github.com/test-kitchen/kitchen-ec2/tree/v1.2.0) (2016-09-12)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v1.1.0...v1.2.0)

**Fixed bugs:**

- Turn on eager loading for AWS resources [\#255](https://github.com/test-kitchen/kitchen-ec2/pull/255) ([hfinucane](https://github.com/hfinucane))

**Merged pull requests:**

- Add optional config for shutdown\_behavior [\#274](https://github.com/test-kitchen/kitchen-ec2/pull/274) ([alexpop](https://github.com/alexpop))
- pin rack to ~\> 1.0 [\#272](https://github.com/test-kitchen/kitchen-ec2/pull/272) ([mwrock](https://github.com/mwrock))
- Fix \#268 [\#269](https://github.com/test-kitchen/kitchen-ec2/pull/269) ([gasserk](https://github.com/gasserk))
- Allow PowerShell script execution [\#234](https://github.com/test-kitchen/kitchen-ec2/pull/234) ([dlukman](https://github.com/dlukman))

* Preparing 1.2.0 release ([aa8e7f2](https://github.com/test-kitchen/kitchen-ec2/commit/aa8e7f2))

## [1.1.0](https://github.com/test-kitchen/kitchen-ec2/tree/v1.1.0) (2016-08-09)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v1.0.1...v1.1.0)

**Implemented enhancements:**

- Make tags optional for clients without IAM rights to CreateTags [\#257](https://github.com/test-kitchen/kitchen-ec2/pull/257) ([freimer](https://github.com/freimer))

**Fixed bugs:**

- New transport.ssh\_key does not work in Travis, possibly elsewhere [\#203](https://github.com/test-kitchen/kitchen-ec2/issues/203)
- not able to connect via winrm [\#175](https://github.com/test-kitchen/kitchen-ec2/issues/175)
- Fix AWS Ruby SDK autoload for all time [\#270](https://github.com/test-kitchen/kitchen-ec2/pull/270) ([jkeiser](https://github.com/jkeiser))

## [1.0.1](https://github.com/test-kitchen/kitchen-ec2/tree/v1.0.1) (2016-07-20)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v1.0.0...v1.0.1)

**Fixed bugs:**

- Default AMIs for Windows not available [\#174](https://github.com/test-kitchen/kitchen-ec2/issues/174)
- Fix autoload race in Aws::EC2::\* [\#264](https://github.com/test-kitchen/kitchen-ec2/pull/264) ([jkeiser](https://github.com/jkeiser))

* Unpin github_changelog_generator ([fec3f19](https://github.com/test-kitchen/kitchen-ec2/commit/fec3f19))
* Update version to 1.0.1 ([#265](https://github.com/test-kitchen/kitchen-ec2/pull/265)) ([1ebfabc](https://github.com/test-kitchen/kitchen-ec2/commit/1ebfabc))

## [1.0.0](https://github.com/test-kitchen/kitchen-ec2/tree/v1.0.0) (2016-03-03)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v1.0.0.beta.1...v1.0.0)

**Merged pull requests:**

- Use github\_changelog\_generator for changelog [\#231](https://github.com/test-kitchen/kitchen-ec2/pull/231) ([jkeiser](https://github.com/jkeiser))
- Rename price -\> spot\_price, fix rubocop [\#229](https://github.com/test-kitchen/kitchen-ec2/pull/229) ([jkeiser](https://github.com/jkeiser))
- support duration for spot instances [\#214](https://github.com/test-kitchen/kitchen-ec2/pull/214) ([wjordan](https://github.com/wjordan))
- Add support for looking up Private DNS Name for hostname [\#197](https://github.com/test-kitchen/kitchen-ec2/pull/197) ([mekf](https://github.com/mekf))

* Merge branch 'jk/changelog' ([a93ff5a](https://github.com/test-kitchen/kitchen-ec2/commit/a93ff5a))
* Update changelog for 1.0.0 ([cfff0a4](https://github.com/test-kitchen/kitchen-ec2/commit/cfff0a4))

## [1.0.0.beta.1](https://github.com/test-kitchen/kitchen-ec2/tree/v1.0.0.beta.1) (2016-02-13)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.10.0...v1.0.0.beta.1)

**Implemented enhancements:**

- Slow file transference [\#93](https://github.com/test-kitchen/kitchen-ec2/issues/93)
- Dynamically find default images for many platforms [\#221](https://github.com/test-kitchen/kitchen-ec2/pull/221) ([jkeiser](https://github.com/jkeiser))
- Query Ubuntu AMI IDs [\#169](https://github.com/test-kitchen/kitchen-ec2/pull/169) ([whiteley](https://github.com/whiteley))

**Fixed bugs:**

- Improve error handling if kitchen instance is destroy out of band [\#210](https://github.com/test-kitchen/kitchen-ec2/issues/210)
- SSH prompting password for an instance inside VPC [\#129](https://github.com/test-kitchen/kitchen-ec2/issues/129)
- amis.json out of date [\#117](https://github.com/test-kitchen/kitchen-ec2/issues/117)
- Fix sudo dependency. Fixes \#204 [\#219](https://github.com/test-kitchen/kitchen-ec2/pull/219) ([alexpop](https://github.com/alexpop))
- Use ubuntu user for Ubuntu 15.04 and 15.10 [\#196](https://github.com/test-kitchen/kitchen-ec2/pull/196) ([jaym](https://github.com/jaym))
- Adding better retry logic to creation, fixes \#179 \(hopefully\) [\#184](https://github.com/test-kitchen/kitchen-ec2/pull/184) ([tyler-ball](https://github.com/tyler-ball))
- Add support for looking up AMIs with the EC2 API [\#177](https://github.com/test-kitchen/kitchen-ec2/pull/177) ([zl4bv](https://github.com/zl4bv))
- Trying :instance\_running check before tagging [\#171](https://github.com/test-kitchen/kitchen-ec2/pull/171) ([tyler-ball](https://github.com/tyler-ball))

**Merged pull requests:**

- Bump revision to 1.0.0.beta.1 [\#224](https://github.com/test-kitchen/kitchen-ec2/pull/224) ([jkeiser](https://github.com/jkeiser))
- Update travis ruby versions and update badges [\#213](https://github.com/test-kitchen/kitchen-ec2/pull/213) ([tas50](https://github.com/tas50))
- Allow configuring retry\_limit in Aws.config [\#208](https://github.com/test-kitchen/kitchen-ec2/pull/208) ([jlyheden](https://github.com/jlyheden))
- Default instance type change, and Ubuntu AMI search options to match [\#207](https://github.com/test-kitchen/kitchen-ec2/pull/207) ([vancluever](https://github.com/vancluever))
- Add support for CentOS 7 [\#199](https://github.com/test-kitchen/kitchen-ec2/pull/199) ([proffalken](https://github.com/proffalken))
- Update CHANGELOG.md [\#183](https://github.com/test-kitchen/kitchen-ec2/pull/183) ([failshell](https://github.com/failshell))

* Updating for next development version after 0.10.0 release ([3242389](https://github.com/test-kitchen/kitchen-ec2/commit/3242389))
* Extending retry on NotFound errors until after the machine reports ready ([030e989](https://github.com/test-kitchen/kitchen-ec2/commit/030e989))
* Merge branch 'jk/ec2-defaults' ([5e92115](https://github.com/test-kitchen/kitchen-ec2/commit/5e92115))
* Merge branch 'patch-3' ([3cd5c76](https://github.com/test-kitchen/kitchen-ec2/commit/3cd5c76))
* aws_ssh_key_id - AWS CLI reference ([2d76cd3](https://github.com/test-kitchen/kitchen-ec2/commit/2d76cd3))
* Remove deprecated config ([1a129a4](https://github.com/test-kitchen/kitchen-ec2/commit/1a129a4))

## [0.10.0](https://github.com/test-kitchen/kitchen-ec2/tree/v0.10.0) (2015-06-24)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.10.0.rc.1...v0.10.0)

**Fixed bugs:**

- ebs\_volume\_type missing parameters when set to 'io1' [\#157](https://github.com/test-kitchen/kitchen-ec2/issues/157)
- setting http\_proxy causes no\_proxy to be ignored [\#156](https://github.com/test-kitchen/kitchen-ec2/issues/156)
- transport configuration options do not work [\#145](https://github.com/test-kitchen/kitchen-ec2/issues/145)
- expected params\[:network\_interfaces\]\[0\]\[:groups\] to be an array [\#144](https://github.com/test-kitchen/kitchen-ec2/issues/144)
- Premature timeout when waiting for WinRM for be ready [\#132](https://github.com/test-kitchen/kitchen-ec2/issues/132)
- Allow `:security\_group\_ids` to accept a string value. [\#166](https://github.com/test-kitchen/kitchen-ec2/pull/166) ([fnichol](https://github.com/fnichol))
- Adding block\_device\_mapping iops parameter, fixes \#157 [\#165](https://github.com/test-kitchen/kitchen-ec2/pull/165) ([tyler-ball](https://github.com/tyler-ball))
- Fix 'invalid char in json text' error [\#161](https://github.com/test-kitchen/kitchen-ec2/pull/161) ([zl4bv](https://github.com/zl4bv))
- Remove useless log message [\#158](https://github.com/test-kitchen/kitchen-ec2/pull/158) ([ustuehler](https://github.com/ustuehler))

**Merged pull requests:**

- reference to required IAM settings [\#160](https://github.com/test-kitchen/kitchen-ec2/pull/160) ([gmiranda23](https://github.com/gmiranda23))

* Updating README to display correct proxy default ([024a4d3](https://github.com/test-kitchen/kitchen-ec2/commit/024a4d3))
* Adding CHANGELOG for https://github.com/test-kitchen/kitchen-ec2/pull/161 and addressing https://github.com/test-kitchen/kitchen-ec2/pull/161#discussion_r33169704 ([551f217](https://github.com/test-kitchen/kitchen-ec2/commit/551f217))
* Updating http_proxy with instructions for setting it to nil ([a3d0db0](https://github.com/test-kitchen/kitchen-ec2/commit/a3d0db0))
* Finalizing CHANGELOG and version file for release ([f84a357](https://github.com/test-kitchen/kitchen-ec2/commit/f84a357))

## [0.10.0.rc.1](https://github.com/test-kitchen/kitchen-ec2/tree/v0.10.0.rc.1) (2015-06-19)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.10.0.rc.0...v0.10.0.rc.1)

* Clarity updates ([0971194](https://github.com/test-kitchen/kitchen-ec2/commit/0971194))
* I excluded the aws SDK v1 gem but still had a require that was trying to use it, causing a failure ([ef382e9](https://github.com/test-kitchen/kitchen-ec2/commit/ef382e9))

## [0.10.0.rc.0](https://github.com/test-kitchen/kitchen-ec2/tree/v0.10.0.rc.0) (2015-06-18)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.9.5...v0.10.0.rc.0)

**Fixed bugs:**

- block device examples updated [\#136](https://github.com/test-kitchen/kitchen-ec2/pull/136) ([gmiranda23](https://github.com/gmiranda23))

**Merged pull requests:**

- Pulling together existing PRs for windows support [\#150](https://github.com/test-kitchen/kitchen-ec2/pull/150) ([tyler-ball](https://github.com/tyler-ball))

* Bumping to next development version after release ([2aed937](https://github.com/test-kitchen/kitchen-ec2/commit/2aed937))
* Updating the default configuration section about AMI usernames to be true ([def8ee4](https://github.com/test-kitchen/kitchen-ec2/commit/def8ee4))
* Updating version file for 0.10.0 RC release ([40d2985](https://github.com/test-kitchen/kitchen-ec2/commit/40d2985))

## [0.9.5](https://github.com/test-kitchen/kitchen-ec2/tree/v0.9.5) (2015-06-08)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.9.4...v0.9.5)

**Fixed bugs:**

- You broke Chef's Travis CI tests =\) [\#148](https://github.com/test-kitchen/kitchen-ec2/issues/148)

**Merged pull requests:**

- Query correct instance object for hostname fixes \#148 [\#151](https://github.com/test-kitchen/kitchen-ec2/pull/151) ([tyler-ball](https://github.com/tyler-ball))

* Reving version to next development version after 0.9.4 release ([4206f9c](https://github.com/test-kitchen/kitchen-ec2/commit/4206f9c))

## [0.9.4](https://github.com/test-kitchen/kitchen-ec2/tree/v0.9.4) (2015-06-03)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.9.3...v0.9.4)

**Fixed bugs:**

- undefined local variable or method `logger' on kitchen create [\#142](https://github.com/test-kitchen/kitchen-ec2/issues/142)
- Kitchen setup on Centos6.4 fails initial ssh auth with valid credentials [\#137](https://github.com/test-kitchen/kitchen-ec2/issues/137)
- TK Can't Connect to EC2 Instance via SSH [\#135](https://github.com/test-kitchen/kitchen-ec2/issues/135)
- Providing logger to instance\_generator, fixes \#142 [\#146](https://github.com/test-kitchen/kitchen-ec2/pull/146) ([tyler-ball](https://github.com/tyler-ball))

**Merged pull requests:**

- \#66: changed \[driver\_usage\] link to point to GitHub [\#141](https://github.com/test-kitchen/kitchen-ec2/pull/141) ([dsavinkov](https://github.com/dsavinkov))

* Reving development version after release ([258b658](https://github.com/test-kitchen/kitchen-ec2/commit/258b658))

## [0.9.3](https://github.com/test-kitchen/kitchen-ec2/tree/v0.9.3) (2015-05-29)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.9.2...v0.9.3)

**Fixed bugs:**

- Error trying to tag instance before it exists [\#138](https://github.com/test-kitchen/kitchen-ec2/issues/138)
- \[Network interfaces and an instance-level security groups may not be specified on the same request\] [\#127](https://github.com/test-kitchen/kitchen-ec2/issues/127)

**Merged pull requests:**

- Adding an existence check before tagging server [\#140](https://github.com/test-kitchen/kitchen-ec2/pull/140) ([tyler-ball](https://github.com/tyler-ball))

* Updating to next development release version after 0.9.2 release ([8cd0080](https://github.com/test-kitchen/kitchen-ec2/commit/8cd0080))
* Fixing CHANGELOG with correct description ([1512109](https://github.com/test-kitchen/kitchen-ec2/commit/1512109))
* Preping 0.9.3 release ([28878cb](https://github.com/test-kitchen/kitchen-ec2/commit/28878cb))

## [0.9.2](https://github.com/test-kitchen/kitchen-ec2/tree/v0.9.2) (2015-05-27)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.9.1...v0.9.2)

**Fixed bugs:**

- Support for proxy? [\#126](https://github.com/test-kitchen/kitchen-ec2/issues/126)
- User Data content should be base64 encoded when passed to aws sdk [\#121](https://github.com/test-kitchen/kitchen-ec2/issues/121)

**Merged pull requests:**

- Adding proxy support that was present in Fog back [\#131](https://github.com/test-kitchen/kitchen-ec2/pull/131) ([tyler-ball](https://github.com/tyler-ball))
- Fixing 2 regressions in 0.9.1 [\#128](https://github.com/test-kitchen/kitchen-ec2/pull/128) ([tyler-ball](https://github.com/tyler-ball))

* Restoring development version after release ([476ea6d](https://github.com/test-kitchen/kitchen-ec2/commit/476ea6d))

## [0.9.1](https://github.com/test-kitchen/kitchen-ec2/tree/v0.9.1) (2015-05-21)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.9.0...v0.9.1)

**Fixed bugs:**

- hostname missing when waiting for ssh service in create action  [\#122](https://github.com/test-kitchen/kitchen-ec2/issues/122)
- ebs\_delete\_on\_termination is not working [\#91](https://github.com/test-kitchen/kitchen-ec2/issues/91)
- Fixing error where aws returns DNS name as empty string [\#124](https://github.com/test-kitchen/kitchen-ec2/pull/124) ([tyler-ball](https://github.com/tyler-ball))

**Merged pull requests:**

- Fixing :subnet\_id payload placement if :associate\_public\_ip is set [\#125](https://github.com/test-kitchen/kitchen-ec2/pull/125) ([tyler-ball](https://github.com/tyler-ball))

* Uping version for development after 0.9.0 release ([b994f18](https://github.com/test-kitchen/kitchen-ec2/commit/b994f18))
* Preping release 0.9.1 ([0499774](https://github.com/test-kitchen/kitchen-ec2/commit/0499774))
* Forgot CHANGELOG formatting for release ([4d69ad4](https://github.com/test-kitchen/kitchen-ec2/commit/4d69ad4))

## [0.9.0](https://github.com/test-kitchen/kitchen-ec2/tree/v0.9.0) (2015-05-19)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.8.0...v0.9.0)

**Implemented enhancements:**

- Support HVM based virtualization [\#25](https://github.com/test-kitchen/kitchen-ec2/issues/25)
- Support spot-instances [\#6](https://github.com/test-kitchen/kitchen-ec2/issues/6)

**Fixed bugs:**

- Might be leaving orphaned EBS volumes [\#30](https://github.com/test-kitchen/kitchen-ec2/issues/30)
- `kitchen login` fails if ssh\_key is a relative path. [\#26](https://github.com/test-kitchen/kitchen-ec2/issues/26)
- Fix security\_group\_ids parameter for spot requests [\#90](https://github.com/test-kitchen/kitchen-ec2/pull/90) ([gfloyd](https://github.com/gfloyd))

**Merged pull requests:**

- Test Kitchen 1.4.0 has been released [\#112](https://github.com/test-kitchen/kitchen-ec2/pull/112) ([jaym](https://github.com/jaym))
- Adding test coverage [\#110](https://github.com/test-kitchen/kitchen-ec2/pull/110) ([tyler-ball](https://github.com/tyler-ball))
- Updating to depend on TK 1.4 [\#109](https://github.com/test-kitchen/kitchen-ec2/pull/109) ([tyler-ball](https://github.com/tyler-ball))
- Add explicit option for using iam profile for authentication [\#107](https://github.com/test-kitchen/kitchen-ec2/pull/107) ([JamesAwesome](https://github.com/JamesAwesome))
- Add support for IAM role credentials [\#104](https://github.com/test-kitchen/kitchen-ec2/pull/104) ([Igorshp](https://github.com/Igorshp))
- Fix the regression after changes in 23f4d945 [\#99](https://github.com/test-kitchen/kitchen-ec2/pull/99) ([mumoshu](https://github.com/mumoshu))
- New `block\_device\_mappings` config [\#98](https://github.com/test-kitchen/kitchen-ec2/pull/98) ([tyler-ball](https://github.com/tyler-ball))
- Fix connection to servers without a "public\_ip\_address" interface \(ie: VPC\) [\#97](https://github.com/test-kitchen/kitchen-ec2/pull/97) ([tyler-ball](https://github.com/tyler-ball))
- Updating documentation so first-time users have an easier time [\#92](https://github.com/test-kitchen/kitchen-ec2/pull/92) ([tyler-ball](https://github.com/tyler-ball))
- Added private\_ip\_address support. [\#84](https://github.com/test-kitchen/kitchen-ec2/pull/84) ([scarolan](https://github.com/scarolan))
- added user\_data for instance preparation [\#82](https://github.com/test-kitchen/kitchen-ec2/pull/82) ([sebbrandt87](https://github.com/sebbrandt87))
- Fix connection to servers without a "public\_ip\_address" interface \(ie: VPC\) [\#69](https://github.com/test-kitchen/kitchen-ec2/pull/69) ([chuckg](https://github.com/chuckg))
- Add Ubuntu 13.10 and 14.04 AMIs [\#63](https://github.com/test-kitchen/kitchen-ec2/pull/63) ([justincampbell](https://github.com/justincampbell))
- Added AWS\_SESSION\_TOKEN parameter to readme [\#60](https://github.com/test-kitchen/kitchen-ec2/pull/60) ([berniedurfee](https://github.com/berniedurfee))
- Customize ssh\_timeout and ssh\_retries [\#58](https://github.com/test-kitchen/kitchen-ec2/pull/58) ([ekrupnik](https://github.com/ekrupnik))
- Added .project to .gitignore file [\#57](https://github.com/test-kitchen/kitchen-ec2/pull/57) ([ekrupnik](https://github.com/ekrupnik))
- Add missing "a" to interface header [\#49](https://github.com/test-kitchen/kitchen-ec2/pull/49) ([eherot](https://github.com/eherot))
- Don't create multiple instances if "kitchen create" is called multiple t... [\#46](https://github.com/test-kitchen/kitchen-ec2/pull/46) ([anl](https://github.com/anl))
- Warn about $$$ [\#41](https://github.com/test-kitchen/kitchen-ec2/pull/41) ([sethvargo](https://github.com/sethvargo))
- IAM Profile Support for Created instance [\#35](https://github.com/test-kitchen/kitchen-ec2/pull/35) ([nicgrayson](https://github.com/nicgrayson))

* Up version for development. ([b408880](https://github.com/test-kitchen/kitchen-ec2/commit/b408880))
* Merge branch 'americanhonors-feature/public_ip_address' ([7172ced](https://github.com/test-kitchen/kitchen-ec2/commit/7172ced))
* Add support for Eucalyptus ([719394e](https://github.com/test-kitchen/kitchen-ec2/commit/719394e))
* Add EBS configuration options ([a18c88a](https://github.com/test-kitchen/kitchen-ec2/commit/a18c88a))
* Add ability to request spot instance pricing ([7801b0b](https://github.com/test-kitchen/kitchen-ec2/commit/7801b0b))
* Warn about possibly costing money ([c4c21fa](https://github.com/test-kitchen/kitchen-ec2/commit/c4c21fa))
* Fix broken tests ([e7f840f](https://github.com/test-kitchen/kitchen-ec2/commit/e7f840f))
* Updating README with better info ([abc4115](https://github.com/test-kitchen/kitchen-ec2/commit/abc4115))
* Merge branch 'JamesAwesome-master', closes PR https://github.com/test-kitchen/kitchen-ec2/pull/107 ([a4e6838](https://github.com/test-kitchen/kitchen-ec2/commit/a4e6838))
* Formatting errors ([24fbb6a](https://github.com/test-kitchen/kitchen-ec2/commit/24fbb6a))
* Updating changelog and version in preperation for 0.9.0 release ([f09c4a5](https://github.com/test-kitchen/kitchen-ec2/commit/f09c4a5))
* Fixing a regression where I was calling the wrong Aws API ([aa3348d](https://github.com/test-kitchen/kitchen-ec2/commit/aa3348d))

## [0.8.0](https://github.com/test-kitchen/kitchen-ec2/tree/v0.8.0) (2014-02-12)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.7.0...v0.8.0)

**Fixed bugs:**

- AWS ENV vars not honored [\#17](https://github.com/test-kitchen/kitchen-ec2/issues/17)
- Periodic failures in kitchen-ec2 [\#10](https://github.com/test-kitchen/kitchen-ec2/issues/10)

**Merged pull requests:**

- Support AWS session tokens for use with IAM roles. [\#34](https://github.com/test-kitchen/kitchen-ec2/pull/34) ([coderanger](https://github.com/coderanger))
- endpoint should have a trailing slash [\#31](https://github.com/test-kitchen/kitchen-ec2/pull/31) ([spheromak](https://github.com/spheromak))
- Compat with test-kitchen master. [\#29](https://github.com/test-kitchen/kitchen-ec2/pull/29) ([coderanger](https://github.com/coderanger))
- Support selection of private ip [\#21](https://github.com/test-kitchen/kitchen-ec2/pull/21) ([Atalanta](https://github.com/Atalanta))

* Up version for development. ([b8b2030](https://github.com/test-kitchen/kitchen-ec2/commit/b8b2030))
* Update CHANGELOG. ([d06815e](https://github.com/test-kitchen/kitchen-ec2/commit/d06815e))
* Relax the constraint to work with test-kitchen master. ([99df957](https://github.com/test-kitchen/kitchen-ec2/commit/99df957))
* Add some fallback env vars. ([3d315ac](https://github.com/test-kitchen/kitchen-ec2/commit/3d315ac))
* Update README badges and re-add Travis ([054a6fd](https://github.com/test-kitchen/kitchen-ec2/commit/054a6fd))
* Make ec2 endpoint configurable. ([22e1552](https://github.com/test-kitchen/kitchen-ec2/commit/22e1552))
* Document endpoint attribute [ci skip] ([823f8be](https://github.com/test-kitchen/kitchen-ec2/commit/823f8be))
* Try to use dns_name before public and private ip address ([44b6bae](https://github.com/test-kitchen/kitchen-ec2/commit/44b6bae))
* Add ebs_optimized attribute ([bc27a19](https://github.com/test-kitchen/kitchen-ec2/commit/bc27a19))
* Spelling (optimize -&gt; optimized) ([bd592a0](https://github.com/test-kitchen/kitchen-ec2/commit/bd592a0))
* s/groups/security_group_ids/g and add security groups to the configuration example ([879d1e0](https://github.com/test-kitchen/kitchen-ec2/commit/879d1e0))
* Use value of region when determining default endpoint value. ([1a86e53](https://github.com/test-kitchen/kitchen-ec2/commit/1a86e53))
* Revert README sections. ([775177b](https://github.com/test-kitchen/kitchen-ec2/commit/775177b))
* Update YAML examples to use modern syntax in README. ([69d3429](https://github.com/test-kitchen/kitchen-ec2/commit/69d3429))
* Remove require_chef_omnibus & sudo documentation from README. ([a527301](https://github.com/test-kitchen/kitchen-ec2/commit/a527301))
* Update project links in README. ([47aad65](https://github.com/test-kitchen/kitchen-ec2/commit/47aad65))

## [0.7.0](https://github.com/test-kitchen/kitchen-ec2/tree/v0.7.0) (2013-08-29)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.6.0...v0.7.0)

**Merged pull requests:**

- wait\_for\_ssh takes 2 arguments [\#13](https://github.com/test-kitchen/kitchen-ec2/pull/13) ([dysinger](https://github.com/dysinger))

* Up version for development. ([95fe93f](https://github.com/test-kitchen/kitchen-ec2/commit/95fe93f))
* Add license to gemspec. ([c2c0b11](https://github.com/test-kitchen/kitchen-ec2/commit/c2c0b11))
* Added computed/sane defaults!! ([44079bf](https://github.com/test-kitchen/kitchen-ec2/commit/44079bf))

## [0.6.0](https://github.com/test-kitchen/kitchen-ec2/tree/v0.6.0) (2013-07-23)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.5.1...v0.6.0)

**Merged pull requests:**

- Match access and secret key env vars in example kitchen config with CLI tools' env vars. [\#9](https://github.com/test-kitchen/kitchen-ec2/pull/9) ([juliandunn](https://github.com/juliandunn))
- Use private ip if the public ip is nil [\#8](https://github.com/test-kitchen/kitchen-ec2/pull/8) ([dissonanz](https://github.com/dissonanz))

* Up version for development. ([9ed714e](https://github.com/test-kitchen/kitchen-ec2/commit/9ed714e))
* Depend on test-kitchen ~&gt; 1.0.0.beta.1 for upstream changes. ([6f74337](https://github.com/test-kitchen/kitchen-ec2/commit/6f74337))

## [0.5.1](https://github.com/test-kitchen/kitchen-ec2/tree/v0.5.1) (2013-05-23)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.5.0...v0.5.1)

**Merged pull requests:**

- Adding subnet\_id option for use with VPCs [\#7](https://github.com/test-kitchen/kitchen-ec2/pull/7) ([dissonanz](https://github.com/dissonanz))

* Up version for development. ([f0a33d1](https://github.com/test-kitchen/kitchen-ec2/commit/f0a33d1))

## [0.5.0](https://github.com/test-kitchen/kitchen-ec2/tree/v0.5.0) (2013-05-23)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.4.0...v0.5.0)

**Merged pull requests:**

- Add the ability to give ec2 instances tags. [\#5](https://github.com/test-kitchen/kitchen-ec2/pull/5) ([halcyonCorsair](https://github.com/halcyonCorsair))
- additional ec2 debugging [\#2](https://github.com/test-kitchen/kitchen-ec2/pull/2) ([mattray](https://github.com/mattray))

* Up version for development. ([a896b02](https://github.com/test-kitchen/kitchen-ec2/commit/a896b02))
* Refactor Rakefile. ([6151037](https://github.com/test-kitchen/kitchen-ec2/commit/6151037))
* Refactor server debugging & add tags to debugging. ([a328536](https://github.com/test-kitchen/kitchen-ec2/commit/a328536))
* Remove default_config :port in favor of SSHBase default (also 22). ([685fe5d](https://github.com/test-kitchen/kitchen-ec2/commit/685fe5d))
* Add required_config attributes for driver. ([995eb2f](https://github.com/test-kitchen/kitchen-ec2/commit/995eb2f))
* Fix tailor warnings. ([7c2095f](https://github.com/test-kitchen/kitchen-ec2/commit/7c2095f))
* Improvements to README.md. ([7cbd6d1](https://github.com/test-kitchen/kitchen-ec2/commit/7cbd6d1))

## [0.4.0](https://github.com/test-kitchen/kitchen-ec2/tree/v0.4.0) (2013-03-02)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.3.0...v0.4.0)

* Up version for development. ([b193dac](https://github.com/test-kitchen/kitchen-ec2/commit/b193dac))
* Merge branch 'jamie-to-kitchen' ([2ca95fa](https://github.com/test-kitchen/kitchen-ec2/commit/2ca95fa))
* README typos, pays to pay attention. ([b2e418c](https://github.com/test-kitchen/kitchen-ec2/commit/b2e418c))

\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*
* Initial project scaffold, generated from `jamie new_plugin ec2`. ([e4e5ace](https://github.com/test-kitchen/kitchen-ec2/commit/e4e5ace))
* Initial implementation. ([6297428](https://github.com/test-kitchen/kitchen-ec2/commit/6297428))

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.1.0...v0.2.0)
* TravisCI &lt;3 &lt;3 &lt;3 ([ecb07e9](https://github.com/test-kitchen/kitchen-ec2/commit/ecb07e9))
* Add attribution comments. ([364c82e](https://github.com/test-kitchen/kitchen-ec2/commit/364c82e))
* Add code stats to Rakefile. ([0a4df55](https://github.com/test-kitchen/kitchen-ec2/commit/0a4df55))
* Add TravisCI notifications to freenode. ([e4d6674](https://github.com/test-kitchen/kitchen-ec2/commit/e4d6674))
* [API] Driver API update in Jamie. ([52dcefb](https://github.com/test-kitchen/kitchen-ec2/commit/52dcefb))
* Use logging facility. ([52375c7](https://github.com/test-kitchen/kitchen-ec2/commit/52375c7))
* Remove creation timing as Instance now tracks all action timings. ([691edc5](https://github.com/test-kitchen/kitchen-ec2/commit/691edc5))

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.2.0...v0.3.0)
* Merge branch 'symbolize' ([ea4dd40](https://github.com/test-kitchen/kitchen-ec2/commit/ea4dd40))
