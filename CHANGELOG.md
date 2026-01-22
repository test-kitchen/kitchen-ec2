# Change Log

## [3.22.1](https://github.com/test-kitchen/kitchen-ec2/compare/v3.22.0...v3.22.1) (2026-01-22)


### Bug Fixes

* bump tk dep &lt;5 ([#652](https://github.com/test-kitchen/kitchen-ec2/issues/652)) ([2135e0e](https://github.com/test-kitchen/kitchen-ec2/commit/2135e0e17ed6893f928849c7fc747740f96f764c))

## [3.22.0](https://github.com/test-kitchen/kitchen-ec2/compare/v3.21.0...v3.22.0) (2026-01-22)


### Features

* Add AWS SSM Session Manager transport support ([#646](https://github.com/test-kitchen/kitchen-ec2/issues/646)) ([6b0fa6d](https://github.com/test-kitchen/kitchen-ec2/commit/6b0fa6d9f838249eb6f1f16c44906eb1bff84307))


### Bug Fixes

* Fix issue on failing create action ([#622](https://github.com/test-kitchen/kitchen-ec2/issues/622)) ([eb1d328](https://github.com/test-kitchen/kitchen-ec2/commit/eb1d328c2b56ec505ca7af4b244d82a3ba3ff175))
* Fixing cookstyle error ([1e319c8](https://github.com/test-kitchen/kitchen-ec2/commit/1e319c887755f606a6ec2d8989fb420a42a01cbf))

## [3.21.0](https://github.com/test-kitchen/kitchen-ec2/compare/v3.20.0...v3.21.0) (2025-09-09)


### Features

* Added AWS EC2 Instance Connect support ([#640](https://github.com/test-kitchen/kitchen-ec2/issues/640)) ([241ce70](https://github.com/test-kitchen/kitchen-ec2/commit/241ce70fd4998db3fe9245e8c5f2b06fb40e2d09))

## [3.20.0](https://github.com/test-kitchen/kitchen-ec2/compare/v3.19.1...v3.20.0) (2025-06-15)


### Features

* add support for IPv6 ([#623](https://github.com/test-kitchen/kitchen-ec2/issues/623)) ([0577c59](https://github.com/test-kitchen/kitchen-ec2/commit/0577c59fec43dfdb7e7f452ee0001ff699135422))


### Bug Fixes

* Fix tests on Ruby 3.3 ([#634](https://github.com/test-kitchen/kitchen-ec2/issues/634)) ([4b3b524](https://github.com/test-kitchen/kitchen-ec2/commit/4b3b524f2d0f1080f629e88dde5d48309d392d40))

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
* Implements placement options and license specifications ([#615](https://github.com/test-kitchen/kitchen-ec2/issues/615)) ([10f0232](https://github.com/test-kitchen/kitchen-ec2/commit/10f02328571ef520bca8311efa2f54561ccb6b34))

## [3.17.1](https://github.com/test-kitchen/kitchen-ec2/compare/v3.17.0...v3.17.1) (2023-11-27)


### Bug Fixes

* Release ([b58158f](https://github.com/test-kitchen/kitchen-ec2/commit/b58158fa2693e581a9f1f5dbdbe7badb12536129))

## [v3.17.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.17.0) (2023-06-14)

- Add support for Rocky and AlmaLinux [#602](https://github.com/test-kitchen/kitchen-ec2/pull/602) ([@bjakauppila](https://github.com/jakauppila))
- Ruby 3 compatibility for RSpec suite [#603](https://github.com/test-kitchen/kitchen-ec2/pull/603) ([@RulerOf](https://github.com/RulerOf))

## [v3.16.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.16.0) (2023-03-16)

- Add support for Amazon Linux 2023 [#600](https://github.com/test-kitchen/kitchen-ec2/pull/600) ([@bjakauppila](https://github.com/jakauppila))
- Remove support for EOL Ruby 2.6 ([@tas50](https://github.com/tas50))

## [v3.15.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.15.0) (2022-12-13)

- Add support for specifying the SSH key type to be automatically generated [#583](https://github.com/test-kitchen/kitchen-ec2/pull/583) ([@bdwyertech](https://github.com/bdwyertech))

## [v3.14.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.14.0) (2022-12-01)

- Support for dedicated hosts [#592](https://github.com/test-kitchen/kitchen-ec2/pull/592) ([@tecracer-theinen](https://github.com/tecracer-theinen))

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.13.0..v3.14.0)


## [v3.13.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.13.0) (2022-05-30)

- Added support for metadata_options [#573](https://github.com/test-kitchen/kitchen-ec2/pull/573) ([@bdwyertech](https://github.com/bdwyertech))
- Improve speed of readiness detection for Windows instances [#582](https://github.com/test-kitchen/kitchen-ec2/pull/582) ([@jakauppila](https://github.com/jakauppila))
- Updated the README to point to kitchen.ci [#577](https://github.com/test-kitchen/kitchen-ec2/pull/577) ([@kasif-adnan](https://github.com/kasif-adnan))
- Github workflow updates [#579](https://github.com/test-kitchen/kitchen-ec2/pull/579), [#584](https://github.com/test-kitchen/kitchen-ec2/pull/584)
  ([@kasif-adnan](https://github.com/kasif-adnan))
- Chefstyle linting and version updates

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.12.0..v3.13.0)

## [v3.12.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.12.0) (2021-12-20)

- Adds support for defining multiple tags for subnet_filter [#570](https://github.com/test-kitchen/kitchen-ec2/pull/570) ([@jakauppila](https://github.com/jakauppila))
- Ensure instance is terminated if a failure occurs during creation [#570](https://github.com/test-kitchen/kitchen-ec2/pull/570) ([@jakauppila](https://github.com/jakauppila))

## [v3.11.1](https://github.com/test-kitchen/kitchen-ec2/tree/v3.11.1) (2021-11-11)

- Resolve deprecation warnings from the AWS SDK during execution [#567](https://github.com/test-kitchen/kitchen-ec2/pull/567) ([kasif-adnan](https://github.com/kasif-adnan))

## [v3.11.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.11.0) (2021-11-02)

- Added support for Windows 2022 [#557](https://github.com/test-kitchen/kitchen-ec2/pull/557) ([bdwyertech](https://github.com/bdwyertech))
- Added support for finding vendor images on Debian 10 and later ([tas50](https://github.com/tas50))
- Removed support for EOL Ruby 2.5 ([tas50](https://github.com/tas50))

## [v3.10.1](https://github.com/test-kitchen/kitchen-ec2/tree/v3.10.1) (2021-10-28)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.10.0..v3.10.1)

- Don't wait the full 300 seconds during `kitchen destroy` if the instance was deleted outside of Test Kitchen.

## [v3.10.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.10.0) (2021-07-02)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.9.0..v3.10.0)

- Allow specifying Elastic Network Interface ID with a new `elastic_network_interface_id` configuration option. See the readme for additional details
- Support Test Kitchen 3.0
- Improved the error message when an AMI ID cannot be found

## [v3.9.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.9.0) (2021-04-09)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.8.0..v3.9.0)

- Require Ruby 2.5 + misc test cleanup [#533](https://github.com/test-kitchen/kitchen-ec2/pull/533) ([tas50](https://github.com/tas50))
- Update `delete_on_termination` to be true by default so we properly cleanup EBS volumes on RHEL systems [#539](https://github.com/test-kitchen/kitchen-ec2/pull/539) ([i5pranay93](https://github.com/i5pranay93))
- Add support for GP3 EBS volume types [#525](https://github.com/test-kitchen/kitchen-ec2/pull/525) ([bdwyertech](https://github.com/bdwyertech))

## [v3.8.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.8.0) (2020-10-14)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.7.2..v3.8.0)

- Allow multiple ip addresses to be specified when creating a security group [#509](https://github.com/test-kitchen/kitchen-ec2/pull/509) ([trainsushi](https://github.com/trainsushi))
- Use defaults when creating spot instances - fixes block_duration_minutes [#512](https://github.com/test-kitchen/kitchen-ec2/pull/512) ([clintoncwolfe](https://github.com/clintoncwolfe))


## [v3.7.2](https://github.com/test-kitchen/kitchen-ec2/tree/v3.7.2) (2020-09-29)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.7.1..v3.7.2)

- Prefer non-Beta RHEL AMIs in search [#506](https://github.com/test-kitchen/kitchen-ec2/pull/506) ([clintoncwolfe](https://github.com/clintoncwolfe))
- Minor performance optimization to subnet determination [#514](https://github.com/test-kitchen/kitchen-ec2/pull/514) ([clintoncwolfe](https://github.com/clintoncwolfe))
- Optimize our requires [#510](https://github.com/test-kitchen/kitchen-ec2/pull/510) ([tas50](https://github.com/tas50))
- Use match? instead of =~ to reduce memory usage [#508](https://github.com/test-kitchen/kitchen-ec2/pull/508) ([tas50](https://github.com/tas50))
- Document missing properties [#504](https://github.com/test-kitchen/kitchen-ec2/pull/504) ([mbaitelman](https://github.com/mbaitelman))

## [v3.7.1](https://github.com/test-kitchen/kitchen-ec2/tree/v3.7.1) (2020-07-13)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.7.0..v3.7.1)

- Improvements to CentOS Image search [#502](https://github.com/test-kitchen/kitchen-ec2/pull/502) ([clintoncwolfe](https://github.com/clintoncwolfe))
- Spot Instances - Cascading Subnet Filter Support [#499](https://github.com/test-kitchen/kitchen-ec2/pull/499) ([bdwyertech](https://github.com/bdwyertech))
- Remove excon and multi-json deps [#500](https://github.com/test-kitchen/kitchen-ec2/pull/500) ([tas50](https://github.com/tas50))

## [v3.7.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.7.0) (2020-07-02)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.6.0..v3.7.0)

- Tag on-demand instances and volumes at creation time [#496](https://github.com/test-kitchen/kitchen-ec2/pull/496) ([clintoncwolfe](https://github.com/clintoncwolfe))

## [v3.6.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.6.0) (2020-05-17)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.5.0..v3.6.0)

- Remove support for EOL Ruby 2.3 [#491](https://github.com/test-kitchen/kitchen-ec2/pull/491) ([tas50](https://github.com/tas50))
- Make Debian 10 the Debian default [#492](https://github.com/test-kitchen/kitchen-ec2/pull/492) ([tas50](https://github.com/tas50))

## [v3.5.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.5.0) (2020-05-06)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.4.0..v3.5.0)

- Select the least-populated subnet if we have multiple matches. This should help to distribute the test-kitchen load more evenly across multi-az VPC's while maintaining full backward compatibility. [\#489](https://github.com/test-kitchen/kitchen-ec2/pull/489) ([bdwyertech](https://github.com/bdwyertech))
- Readme example cleanup [\#484](https://github.com/test-kitchen/kitchen-ec2/pull/484) ([arothian](https://github.com/arothian))

## [v3.4.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.4.0) (2020-03-18)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.3.0..v3.4.0)

- Don't crash upon destroy if instance is already dead [\#482](https://github.com/test-kitchen/kitchen-ec2/pull/482) ([kamaradclimber](https://github.com/kamaradclimber))

## [v3.3.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.3.0) (2020-01-20)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.2.0..v3.3.0)

- Ignore case when checking if the instance provisioner is Chef [\#474](https://github.com/test-kitchen/kitchen-ec2/pull/474) ([slapvanilla](https://github.com/slapvanilla))
- Enhancements: Security Group Search & Spot Instance Provisioning [\#470](https://github.com/test-kitchen/kitchen-ec2/pull/470) ([bdwyertech](https://github.com/bdwyertech))
- Update chefstyle requirement from = 0.13.3 to = 0.14.0 [\#472](https://github.com/test-kitchen/kitchen-ec2/pull/472) ([tas50](https://github.com/tas50))
- Use require_relative instead of require [\#478](https://github.com/test-kitchen/kitchen-ec2/pull/478) ([tas50](https://github.com/tas50))

## [v3.2.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.2.0) (2019-09-17)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.1.0..v3.2.0)

- Allow for retryable 3.0 [\#466](https://github.com/test-kitchen/kitchen-ec2/pull/466) ([tas50](https://github.com/tas50))
- Update Chefstyle to 0.13.3 [\#465](https://github.com/test-kitchen/kitchen-ec2/pull/465) ([tas50](https://github.com/tas50))
- Adds Windows Server 2019 \(and tests\) [\#462](https://github.com/test-kitchen/kitchen-ec2/pull/462) ([mbaitelman](https://github.com/mbaitelman))
- \#394: Check subnet\_filter as well when creating security group [\#413](https://github.com/test-kitchen/kitchen-ec2/pull/413) ([llibicpep](https://github.com/llibicpep))

## [v3.1.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.1.0) (2019-08-07)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.0.1..v3.1.0)

- Resolve additional deprecation warnings from the new aws-sdk-v3 dependency. Thanks [@Annih](https://github.com/Annih)
- Add support for SSH through Session Manager. Thanks [@awiddersheim](https://github.com/awiddersheim)
- Adds support for searching for multiple security groups, as well as searching by group name. Thanks [@bdwyertech](https://github.com/bdwyertech)
- Allow asking for multiple instance types and subnets for spot pricing. Thanks [@vmiszczak-teads](https://github.com/vmiszczak-teads)

## [v3.0.1](https://github.com/test-kitchen/kitchen-ec2/tree/v3.0.1) (2019-05-08)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v3.0.0..v3.0.1)

- Resolve deprecation warnings from the new aws-sdk-v3 dependency

## [v3.0.0](https://github.com/test-kitchen/kitchen-ec2/tree/v3.0.0) (2019-05-01)

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

## [v2.4.0](https://github.com/test-kitchen/kitchen-ec2/tree/v2.4.0) (2018-12-20)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v2.3.4..v2.4.0)

- Don't ship spec files in the gem artifact
- Support Amazon Linux 2.0 image searching. Use the platform 'amazon2'
- Support Windows Server 1709 and 1803 image searching

## [v2.3.4](https://github.com/test-kitchen/kitchen-ec2/tree/v2.3.4) (2018-12-04)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v2.3.3...v2.3.4)

- Don't ship the changelog in the gem

## [v2.3.3](https://github.com/test-kitchen/kitchen-ec2/tree/v2.3.3) (2018-11-28)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v2.3.2...v2.3.3)

**Merged pull requests:**

- Adding support for arm64 architecture [\#433]

## [v2.3.2](https://github.com/test-kitchen/kitchen-ec2/tree/v2.3.2) (2018-11-28)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v2.3.1...v2.3.2)

**Fixed Bugs:**

- fix x86_64 architecture default for image search (fixes new arm64 arch appearing instead) [\#432]

## [v2.3.1](https://github.com/test-kitchen/kitchen-ec2/tree/v2.3.1) (2018-10-19)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v2.3.0...v2.3.1)

**Fixed Bugs:**

- windows2012-r2 hanging on userdata.ps1 in kitchen-ec2 2.3.0 [\#424]

## [v2.3.0](https://github.com/test-kitchen/kitchen-ec2/tree/v2.3.0) (2018-10-05)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v2.2.2...v2.3.0)

- Add port 3389 (RDP) to the automatically generated security group
- Fix logfile creation on Windows to not fail if the directory doesn't exist
- The gem no longer ships with test deps so we can slim the install size

## [v2.2.2](https://github.com/test-kitchen/kitchen-ec2/tree/v2.2.2) (2018-06-11)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v2.2.1...v2.2.2)

**Fixed bugs:**

- Kitchen failure when adding spot\_price [\#328](https://github.com/test-kitchen/kitchen-ec2/issues/328)

**Closed issues:**

- image\_id: required [\#397](https://github.com/test-kitchen/kitchen-ec2/issues/397)
- kitchen-ec2 ssh port [\#396](https://github.com/test-kitchen/kitchen-ec2/issues/396)
- Provide option to terminate after "X" minutes [\#395](https://github.com/test-kitchen/kitchen-ec2/issues/395)
- Explicitly support usage w/o manual or autoconfiguration of aws\_ssh\_key\_id [\#391](https://github.com/test-kitchen/kitchen-ec2/issues/391)

**Merged pull requests:**

- Fix dynamic key creation [\#400](https://github.com/test-kitchen/kitchen-ec2/pull/400) ([bdwyertech](https://github.com/bdwyertech))
- allow AWS-managed ssh key pairs to be disabled [\#392](https://github.com/test-kitchen/kitchen-ec2/pull/392) ([cheeseplus](https://github.com/cheeseplus))

## [v2.2.1](https://github.com/test-kitchen/kitchen-ec2/tree/v2.2.1) (2018-02-12)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v2.2.0...v2.2.1)

**Fixed bugs:**

- Fix `undefined` error when Windows AMIs don't include "windows" in name [\#322](https://github.com/test-kitchen/kitchen-ec2/issues/322) [\#324](https://github.com/test-kitchen/kitchen-ec2/pull/324) ([BenLiyanage](https://github.com/BenLiyanage))
- Fix error behavior when security\_group\_filter is set but no security group found for those tags [\#386](https://github.com/test-kitchen/kitchen-ec2/pull/386) ([dpattmann](https://github.com/dpattmann))
- Don't create security group if security\_group\_filter is set [\#385](https://github.com/test-kitchen/kitchen-ec2/pull/385) ([dpattmann](https://github.com/dpattmann))

## [v2.2.0](https://github.com/test-kitchen/kitchen-ec2/tree/v2.2.0) (2018-01-27)

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

## [v2.1.0](https://github.com/test-kitchen/kitchen-ec2/tree/v2.1.0) (2018-01-27)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v2.0.0...v2.1.0)

**Merged pull requests:**

- Only create Ohai hint when provisioner is `/chef/` [\#366](https://github.com/test-kitchen/kitchen-ec2/pull/366) ([cheeseplus](https://github.com/cheeseplus))
- Automatically create a security group and key pair if needed. [\#362](https://github.com/test-kitchen/kitchen-ec2/pull/362) ([coderanger](https://github.com/coderanger))

## [v2.0.0](https://github.com/test-kitchen/kitchen-ec2/tree/v2.0.0) (2017-12-08)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v1.4.0...v2.0.0)

### Improvements

- Clean up original Authentication; Rely on SDK for Chain. [\#353](https://github.com/test-kitchen/kitchen-ec2/pull/353) ([rhyas](https://github.com/rhyas))
- Use quadratic backoff when encountering RequestLimit errors [\#320](https://github.com/test-kitchen/kitchen-ec2/pull/320) ([kamaradclimber](https://github.com/kamaradclimber))

## [v1.4.0](https://github.com/test-kitchen/kitchen-ec2/tree/v1.4.0) (2017-11-29)

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

## [v1.3.2](https://github.com/test-kitchen/kitchen-ec2/tree/v1.3.2) (2017-02-24)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v1.3.1...v1.3.2)

**Improvements:**

- Don't try to set tags if there aren't any. [\#298](https://github.com/test-kitchen/kitchen-ec2/pull/298) ([coderanger](https://github.com/coderanger))

## [v1.3.1](https://github.com/test-kitchen/kitchen-ec2/tree/v1.3.1) (2017-02-16)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v1.3.0...v1.3.1)

**Closed issues:**

- Shared AWS credentials file being ignored. [\#295](https://github.com/test-kitchen/kitchen-ec2/issues/295)
- Missing AMI generates Nil::NilClass error [\#284](https://github.com/test-kitchen/kitchen-ec2/issues/284)
- `kitchen converge` failing - not prioritizing env vars over ~/.aws/credentials [\#258](https://github.com/test-kitchen/kitchen-ec2/issues/258)

**Merged pull requests:**

- reinstate default shared creds option [\#296](https://github.com/test-kitchen/kitchen-ec2/pull/296) ([davidcpell](https://github.com/davidcpell))

## [v1.3.0](https://github.com/test-kitchen/kitchen-ec2/tree/v1.3.0) (2017-02-11)

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

## [v1.2.0](https://github.com/test-kitchen/kitchen-ec2/tree/v1.2.0) (2016-09-12)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v1.1.0...v1.2.0)

**Fixed bugs:**

- Turn on eager loading for AWS resources [\#255](https://github.com/test-kitchen/kitchen-ec2/pull/255) ([hfinucane](https://github.com/hfinucane))

**Merged pull requests:**

- Add optional config for shutdown\_behavior [\#274](https://github.com/test-kitchen/kitchen-ec2/pull/274) ([alexpop](https://github.com/alexpop))
- pin rack to ~\> 1.0 [\#272](https://github.com/test-kitchen/kitchen-ec2/pull/272) ([mwrock](https://github.com/mwrock))
- Fix \#268 [\#269](https://github.com/test-kitchen/kitchen-ec2/pull/269) ([gasserk](https://github.com/gasserk))
- Allow PowerShell script execution [\#234](https://github.com/test-kitchen/kitchen-ec2/pull/234) ([dlukman](https://github.com/dlukman))

## [v1.1.0](https://github.com/test-kitchen/kitchen-ec2/tree/v1.1.0) (2016-08-09)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v1.0.1...v1.1.0)

**Implemented enhancements:**

- Make tags optional for clients without IAM rights to CreateTags [\#257](https://github.com/test-kitchen/kitchen-ec2/pull/257) ([freimer](https://github.com/freimer))

**Fixed bugs:**

- New transport.ssh\_key does not work in Travis, possibly elsewhere [\#203](https://github.com/test-kitchen/kitchen-ec2/issues/203)
- not able to connect via winrm [\#175](https://github.com/test-kitchen/kitchen-ec2/issues/175)
- Fix AWS Ruby SDK autoload for all time [\#270](https://github.com/test-kitchen/kitchen-ec2/pull/270) ([jkeiser](https://github.com/jkeiser))

**Closed issues:**

- Do not require aws\_ssh\_key\_id in ec2.rb [\#268](https://github.com/test-kitchen/kitchen-ec2/issues/268)
- Retrieve AMI IDs from the EC2 API [\#147](https://github.com/test-kitchen/kitchen-ec2/issues/147)

## [v1.0.1](https://github.com/test-kitchen/kitchen-ec2/tree/v1.0.1) (2016-07-20)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v1.0.0...v1.0.1)

**Fixed bugs:**

- Default AMIs for Windows not available [\#174](https://github.com/test-kitchen/kitchen-ec2/issues/174)
- Fix autoload race in Aws::EC2::\* [\#264](https://github.com/test-kitchen/kitchen-ec2/pull/264) ([jkeiser](https://github.com/jkeiser))

## [v1.0.0](https://github.com/test-kitchen/kitchen-ec2/tree/v1.0.0) (2016-03-03)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v1.0.0.beta.1...v1.0.0)

**Merged pull requests:**

- Use github\_changelog\_generator for changelog [\#231](https://github.com/test-kitchen/kitchen-ec2/pull/231) ([jkeiser](https://github.com/jkeiser))
- Rename price -\> spot\_price, fix rubocop [\#229](https://github.com/test-kitchen/kitchen-ec2/pull/229) ([jkeiser](https://github.com/jkeiser))
- support duration for spot instances [\#214](https://github.com/test-kitchen/kitchen-ec2/pull/214) ([wjordan](https://github.com/wjordan))
- Add support for looking up Private DNS Name for hostname [\#197](https://github.com/test-kitchen/kitchen-ec2/pull/197) ([mekf](https://github.com/mekf))

## [v1.0.0.beta.1](https://github.com/test-kitchen/kitchen-ec2/tree/v1.0.0.beta.1) (2016-02-13)

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

**Closed issues:**

- Requesting to include this plug-in in ChefDK [\#218](https://github.com/test-kitchen/kitchen-ec2/issues/218)
- Can't ssh to instance after it's created [\#217](https://github.com/test-kitchen/kitchen-ec2/issues/217)
- No installation instructions [\#216](https://github.com/test-kitchen/kitchen-ec2/issues/216)
- availability\_zone is always b [\#215](https://github.com/test-kitchen/kitchen-ec2/issues/215)
- Windows create fails fetching password [\#211](https://github.com/test-kitchen/kitchen-ec2/issues/211)
- Offering to help maintain this repo [\#209](https://github.com/test-kitchen/kitchen-ec2/issues/209)
- Support for HVM EC2 instances [\#205](https://github.com/test-kitchen/kitchen-ec2/issues/205)
- Installation fails due to sudo dependency in test-kitchen [\#204](https://github.com/test-kitchen/kitchen-ec2/issues/204)
- Not all AMIs in amis.json are public. [\#202](https://github.com/test-kitchen/kitchen-ec2/issues/202)
- connection\_retries doesn't seem to work? [\#200](https://github.com/test-kitchen/kitchen-ec2/issues/200)
- kitchen converge needs to be run 2-3 times to work with stock Windows 2012r2 AMI ami-dfccd1ef [\#198](https://github.com/test-kitchen/kitchen-ec2/issues/198)
- Unable to assign a name to an ec2 instance [\#194](https://github.com/test-kitchen/kitchen-ec2/issues/194)
- Administrator password not being retrieved on Windows 2008 R2 [\#192](https://github.com/test-kitchen/kitchen-ec2/issues/192)
- Removing Default Storage when running Kitchen Destroy [\#188](https://github.com/test-kitchen/kitchen-ec2/issues/188)
- Test Kitchen issues on EC2 using RHEL platform? [\#181](https://github.com/test-kitchen/kitchen-ec2/issues/181)
- Failure for numeric key name [\#178](https://github.com/test-kitchen/kitchen-ec2/issues/178)
- Issues under high concurrency [\#176](https://github.com/test-kitchen/kitchen-ec2/issues/176)
- SSH Connection Expiring Upon Instance Creation [\#173](https://github.com/test-kitchen/kitchen-ec2/issues/173)
- Throttle requests to EC2 API [\#170](https://github.com/test-kitchen/kitchen-ec2/issues/170)
- missing aws\_secret\_access\_key causes quiet timeout [\#155](https://github.com/test-kitchen/kitchen-ec2/issues/155)

**Merged pull requests:**

- Bump revision to 1.0.0.beta.1 [\#224](https://github.com/test-kitchen/kitchen-ec2/pull/224) ([jkeiser](https://github.com/jkeiser))
- Update travis ruby versions and update badges [\#213](https://github.com/test-kitchen/kitchen-ec2/pull/213) ([tas50](https://github.com/tas50))
- Allow configuring retry\_limit in Aws.config [\#208](https://github.com/test-kitchen/kitchen-ec2/pull/208) ([jlyheden](https://github.com/jlyheden))
- Default instance type change, and Ubuntu AMI search options to match [\#207](https://github.com/test-kitchen/kitchen-ec2/pull/207) ([vancluever](https://github.com/vancluever))
- Add support for CentOS 7 [\#199](https://github.com/test-kitchen/kitchen-ec2/pull/199) ([proffalken](https://github.com/proffalken))
- Update CHANGELOG.md [\#183](https://github.com/test-kitchen/kitchen-ec2/pull/183) ([failshell](https://github.com/failshell))

## [v0.10.0](https://github.com/test-kitchen/kitchen-ec2/tree/v0.10.0) (2015-06-24)

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
- Remove useless log message [\#158](https://github.com/test-kitchen/kitchen-ec2/pull/158) ([ustuehler](https://github.com/ustuehler))

**Closed issues:**

- efdk bundle update [\#163](https://github.com/test-kitchen/kitchen-ec2/issues/163)

**Merged pull requests:**

- reference to required IAM settings [\#160](https://github.com/test-kitchen/kitchen-ec2/pull/160) ([gmiranda23](https://github.com/gmiranda23))

## [v0.10.0.rc.1](https://github.com/test-kitchen/kitchen-ec2/tree/v0.10.0.rc.1) (2015-06-19)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.10.0.rc.0...v0.10.0.rc.1)

## [v0.10.0.rc.0](https://github.com/test-kitchen/kitchen-ec2/tree/v0.10.0.rc.0) (2015-06-18)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.9.5...v0.10.0.rc.0)

**Fixed bugs:**

- block device examples updated [\#136](https://github.com/test-kitchen/kitchen-ec2/pull/136) ([gmiranda23](https://github.com/gmiranda23))

**Closed issues:**

- Documentation - IAM policy document [\#159](https://github.com/test-kitchen/kitchen-ec2/issues/159)
- kitchen-ec2 version 0.9.4 ssh transport is broken [\#154](https://github.com/test-kitchen/kitchen-ec2/issues/154)
- Setting multiple non-default transport usernames per platform will soon be broken [\#153](https://github.com/test-kitchen/kitchen-ec2/issues/153)

**Merged pull requests:**

- Pulling together existing PRs for windows support [\#150](https://github.com/test-kitchen/kitchen-ec2/pull/150) ([tyler-ball](https://github.com/tyler-ball))

## [v0.9.5](https://github.com/test-kitchen/kitchen-ec2/tree/v0.9.5) (2015-06-08)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.9.4...v0.9.5)

**Fixed bugs:**

- You broke Chef's Travis CI tests =\) [\#148](https://github.com/test-kitchen/kitchen-ec2/issues/148)

**Closed issues:**

- Race condition logging into RHEL/CentOS instances [\#149](https://github.com/test-kitchen/kitchen-ec2/issues/149)

**Merged pull requests:**

- Query correct instance object for hostname fixes \#148 [\#151](https://github.com/test-kitchen/kitchen-ec2/pull/151) ([tyler-ball](https://github.com/tyler-ball))

## [v0.9.4](https://github.com/test-kitchen/kitchen-ec2/tree/v0.9.4) (2015-06-03)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.9.3...v0.9.4)

**Fixed bugs:**

- undefined local variable or method `logger' on kitchen create [\#142](https://github.com/test-kitchen/kitchen-ec2/issues/142)
- Kitchen setup on Centos6.4 fails initial ssh auth with valid credentials [\#137](https://github.com/test-kitchen/kitchen-ec2/issues/137)
- TK Can't Connect to EC2 Instance via SSH [\#135](https://github.com/test-kitchen/kitchen-ec2/issues/135)
- Providing logger to instance\_generator, fixes \#142 [\#146](https://github.com/test-kitchen/kitchen-ec2/pull/146) ([tyler-ball](https://github.com/tyler-ball))

**Closed issues:**

- kitchen destroy bombs trying to destroy non-existent instances [\#143](https://github.com/test-kitchen/kitchen-ec2/issues/143)
- EC2-Instance terminates while TK waits on it to become ready [\#130](https://github.com/test-kitchen/kitchen-ec2/issues/130)

**Merged pull requests:**

- \#66: changed \[driver\_usage\] link to point to GitHub [\#141](https://github.com/test-kitchen/kitchen-ec2/pull/141) ([dsavinkov](https://github.com/dsavinkov))

## [v0.9.3](https://github.com/test-kitchen/kitchen-ec2/tree/v0.9.3) (2015-05-29)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.9.2...v0.9.3)

**Fixed bugs:**

- Error trying to tag instance before it exists [\#138](https://github.com/test-kitchen/kitchen-ec2/issues/138)
- \[Network interfaces and an instance-level security groups may not be specified on the same request\] [\#127](https://github.com/test-kitchen/kitchen-ec2/issues/127)

**Closed issues:**

- Failure to specify username leads to confusing error message [\#113](https://github.com/test-kitchen/kitchen-ec2/issues/113)
- Kitchen attempts to log in before sshd is ready [\#85](https://github.com/test-kitchen/kitchen-ec2/issues/85)

**Merged pull requests:**

- Adding an existence check before tagging server [\#140](https://github.com/test-kitchen/kitchen-ec2/pull/140) ([tyler-ball](https://github.com/tyler-ball))

## [v0.9.2](https://github.com/test-kitchen/kitchen-ec2/tree/v0.9.2) (2015-05-27)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.9.1...v0.9.2)

**Fixed bugs:**

- Support for proxy? [\#126](https://github.com/test-kitchen/kitchen-ec2/issues/126)
- Support for proxy? [\#126](https://github.com/test-kitchen/kitchen-ec2/issues/126)
- User Data content should be base64 encoded when passed to aws sdk [\#121](https://github.com/test-kitchen/kitchen-ec2/issues/121)

**Closed issues:**

- kitchen-ec2 fails when setting associate\_public\_ip: false [\#106](https://github.com/test-kitchen/kitchen-ec2/issues/106)

**Merged pull requests:**

- Adding proxy support that was present in Fog back [\#131](https://github.com/test-kitchen/kitchen-ec2/pull/131) ([tyler-ball](https://github.com/tyler-ball))
- Fixing 2 regressions in 0.9.1 [\#128](https://github.com/test-kitchen/kitchen-ec2/pull/128) ([tyler-ball](https://github.com/tyler-ball))

## [v0.9.1](https://github.com/test-kitchen/kitchen-ec2/tree/v0.9.1) (2015-05-21)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.9.0...v0.9.1)

**Fixed bugs:**

- hostname missing when waiting for ssh service in create action  [\#122](https://github.com/test-kitchen/kitchen-ec2/issues/122)
- ebs\_delete\_on\_termination is not working [\#91](https://github.com/test-kitchen/kitchen-ec2/issues/91)
- Fixing error where aws returns DNS name as empty string [\#124](https://github.com/test-kitchen/kitchen-ec2/pull/124) ([tyler-ball](https://github.com/tyler-ball))

**Closed issues:**

- Limited Permissions - Failed to complete \#create action: \[You are not authorized to perform this operation.\] [\#120](https://github.com/test-kitchen/kitchen-ec2/issues/120)
- release 0.8.0 doesn't properly honor instance\_type [\#114](https://github.com/test-kitchen/kitchen-ec2/issues/114)
- tag\_server: tag key needs to be cast to string [\#111](https://github.com/test-kitchen/kitchen-ec2/issues/111)
- The specified wait\_for timeout \(600 seconds\) was exceeded [\#103](https://github.com/test-kitchen/kitchen-ec2/issues/103)
- block\_device\_mappings setting is not optional [\#100](https://github.com/test-kitchen/kitchen-ec2/issues/100)
- kitchen-ec2 - iam\_profile\_name fog not passing through [\#94](https://github.com/test-kitchen/kitchen-ec2/issues/94)
- Unable to SSH into VPC Instance [\#77](https://github.com/test-kitchen/kitchen-ec2/issues/77)
- Can't get a public IP  [\#72](https://github.com/test-kitchen/kitchen-ec2/issues/72)
- Why no releases since Feb? [\#65](https://github.com/test-kitchen/kitchen-ec2/issues/65)

**Merged pull requests:**

- Fixing :subnet\_id payload placement if :associate\_public\_ip is set [\#125](https://github.com/test-kitchen/kitchen-ec2/pull/125) ([tyler-ball](https://github.com/tyler-ball))

## [v0.9.0](https://github.com/test-kitchen/kitchen-ec2/tree/v0.9.0) (2015-05-19)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.8.0...v0.9.0)

**Implemented enhancements:**

- Support HVM based virtualization [\#25](https://github.com/test-kitchen/kitchen-ec2/issues/25)
- Support spot-instances [\#6](https://github.com/test-kitchen/kitchen-ec2/issues/6)

**Fixed bugs:**

- Might be leaving orphaned EBS volumes [\#30](https://github.com/test-kitchen/kitchen-ec2/issues/30)
- `kitchen login` fails if ssh\_key is a relative path. [\#26](https://github.com/test-kitchen/kitchen-ec2/issues/26)
- Fix security\_group\_ids parameter for spot requests [\#90](https://github.com/test-kitchen/kitchen-ec2/pull/90) ([gfloyd](https://github.com/gfloyd))

**Closed issues:**

- Issue with amazon linux 32 bit and SCP failing \>\>\>\>\>\> Message: Failed to complete \#converge action: \[SCP did not finish successfully \(127\): \] [\#88](https://github.com/test-kitchen/kitchen-ec2/issues/88)
- The plugin does not create /etc/chef/ohai/hints/ec2.json file [\#86](https://github.com/test-kitchen/kitchen-ec2/issues/86)
- how do you pass user data to the instance? [\#79](https://github.com/test-kitchen/kitchen-ec2/issues/79)
- Can't find how to set EBS Volume Size [\#71](https://github.com/test-kitchen/kitchen-ec2/issues/71)
- Instance created but nothing happens from there [\#62](https://github.com/test-kitchen/kitchen-ec2/issues/62)
- Use IAM role to authenticate with AWS [\#55](https://github.com/test-kitchen/kitchen-ec2/issues/55)
- iam\_profile\_name not being added to ec2 [\#54](https://github.com/test-kitchen/kitchen-ec2/issues/54)
- it always invokes tests as root [\#52](https://github.com/test-kitchen/kitchen-ec2/issues/52)
- Failing authentication for some larger instances. [\#51](https://github.com/test-kitchen/kitchen-ec2/issues/51)
- allow to hide aws keys from kitchen.yml [\#50](https://github.com/test-kitchen/kitchen-ec2/issues/50)
- Configuration option for naming EC2 instances? [\#48](https://github.com/test-kitchen/kitchen-ec2/issues/48)
- Ohai attribute node\[:ec2\] is nil [\#47](https://github.com/test-kitchen/kitchen-ec2/issues/47)
- Resolving dependencies on ec2 instead upload resolved cookbooks to ec2  [\#40](https://github.com/test-kitchen/kitchen-ec2/issues/40)
- fails to connect to ec2 if ip/host is not in known\_hosts entry [\#38](https://github.com/test-kitchen/kitchen-ec2/issues/38)
- doesn't invoke test while using ec2 driver [\#37](https://github.com/test-kitchen/kitchen-ec2/issues/37)
- Default to IAM Credentials if aws\_access\_key\_id or aws\_secret\_access\_key Not Provided [\#19](https://github.com/test-kitchen/kitchen-ec2/issues/19)

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

## [v0.8.0](https://github.com/test-kitchen/kitchen-ec2/tree/v0.8.0) (2014-02-12)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.7.0...v0.8.0)

**Fixed bugs:**

- AWS ENV vars not honored [\#17](https://github.com/test-kitchen/kitchen-ec2/issues/17)
- Periodic failures in kitchen-ec2 [\#10](https://github.com/test-kitchen/kitchen-ec2/issues/10)

**Closed issues:**

- encrypted\_data\_bag\_secret not found [\#24](https://github.com/test-kitchen/kitchen-ec2/issues/24)
- busser bats tests don't run [\#16](https://github.com/test-kitchen/kitchen-ec2/issues/16)
- Support for server.dns\_name [\#14](https://github.com/test-kitchen/kitchen-ec2/issues/14)

**Merged pull requests:**

- Support AWS session tokens for use with IAM roles. [\#34](https://github.com/test-kitchen/kitchen-ec2/pull/34) ([coderanger](https://github.com/coderanger))
- endpoint should have a trailing slash [\#31](https://github.com/test-kitchen/kitchen-ec2/pull/31) ([spheromak](https://github.com/spheromak))
- Compat with test-kitchen master. [\#29](https://github.com/test-kitchen/kitchen-ec2/pull/29) ([coderanger](https://github.com/coderanger))
- Support selection of private ip [\#21](https://github.com/test-kitchen/kitchen-ec2/pull/21) ([Atalanta](https://github.com/Atalanta))

## [v0.7.0](https://github.com/test-kitchen/kitchen-ec2/tree/v0.7.0) (2013-08-29)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.6.0...v0.7.0)

**Closed issues:**

- Error running kitchen-ec2 0.6.0 [\#12](https://github.com/test-kitchen/kitchen-ec2/issues/12)
- License missing from gemspec [\#11](https://github.com/test-kitchen/kitchen-ec2/issues/11)

**Merged pull requests:**

- wait\_for\_ssh takes 2 arguments [\#13](https://github.com/test-kitchen/kitchen-ec2/pull/13) ([dysinger](https://github.com/dysinger))

## [v0.6.0](https://github.com/test-kitchen/kitchen-ec2/tree/v0.6.0) (2013-07-23)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.5.1...v0.6.0)

**Closed issues:**

- net-scp version is 1.0.4 [\#1](https://github.com/test-kitchen/kitchen-ec2/issues/1)

**Merged pull requests:**

- Match access and secret key env vars in example kitchen config with CLI tools' env vars. [\#9](https://github.com/test-kitchen/kitchen-ec2/pull/9) ([juliandunn](https://github.com/juliandunn))
- Use private ip if the public ip is nil [\#8](https://github.com/test-kitchen/kitchen-ec2/pull/8) ([dissonanz](https://github.com/dissonanz))

## [v0.5.1](https://github.com/test-kitchen/kitchen-ec2/tree/v0.5.1) (2013-05-23)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.5.0...v0.5.1)

**Merged pull requests:**

- Adding subnet\_id option for use with VPCs [\#7](https://github.com/test-kitchen/kitchen-ec2/pull/7) ([dissonanz](https://github.com/dissonanz))

## [v0.5.0](https://github.com/test-kitchen/kitchen-ec2/tree/v0.5.0) (2013-05-23)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.4.0...v0.5.0)

**Closed issues:**

- We should be able to specify tags for ec2 instances [\#4](https://github.com/test-kitchen/kitchen-ec2/issues/4)
- SSH private key config value needed [\#3](https://github.com/test-kitchen/kitchen-ec2/issues/3)

**Merged pull requests:**

- Add the ability to give ec2 instances tags. [\#5](https://github.com/test-kitchen/kitchen-ec2/pull/5) ([halcyonCorsair](https://github.com/halcyonCorsair))
- additional ec2 debugging [\#2](https://github.com/test-kitchen/kitchen-ec2/pull/2) ([mattray](https://github.com/mattray))

## [v0.4.0](https://github.com/test-kitchen/kitchen-ec2/tree/v0.4.0) (2013-03-02)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.3.0...v0.4.0)

## [v0.3.0](https://github.com/test-kitchen/kitchen-ec2/tree/v0.3.0) (2013-01-09)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.2.0...v0.3.0)

## [v0.2.0](https://github.com/test-kitchen/kitchen-ec2/tree/v0.2.0) (2013-01-03)

[Full Changelog](https://github.com/test-kitchen/kitchen-ec2/compare/v0.1.0...v0.2.0)

## [v0.1.0](https://github.com/test-kitchen/kitchen-ec2/tree/v0.1.0) (2012-12-27)


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*
