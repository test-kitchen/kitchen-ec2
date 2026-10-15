# Contributing to kitchen-ec2

Thanks for your interest in improving kitchen-ec2. Bug reports, feature requests, and pull requests are all welcome.

## Reporting issues

Report bugs and request features on the [issue tracker](https://github.com/test-kitchen/kitchen-ec2/issues). For bugs, please include:

- the version of kitchen-ec2 and Test Kitchen you are using
- your `kitchen.yml` with credentials and account IDs removed
- the output of the failing command, ideally with `-l debug`

## Development setup

Clone the repository and install the dependencies:

```sh
git clone https://github.com/test-kitchen/kitchen-ec2.git
cd kitchen-ec2
bundle install
```

## Running the unit tests

Run the unit tests and the style check together:

```sh
bundle exec rake
```

Run them individually:

```sh
bundle exec rake test    # RSpec unit tests
bundle exec rake style   # Cookstyle / RuboCop
```

To run a single spec file:

```sh
bundle exec rspec spec/kitchen/driver/ec2_spec.rb
```

Many style offenses can be corrected automatically:

```sh
bundle exec cookstyle -a
```

The unit tests stub the AWS SDK, so they neither launch instances nor require
AWS credentials. `spec/` mirrors `lib/`, and the shared helpers under
`spec/support/` build stubbed AWS clients, EC2 image fixtures, and configured
driver instances.

## Running the integration tests

The unit tests prove the driver *builds* the right EC2 request. They cannot
prove EC2 accepts it, or that the instance comes up configured the way the
request asked for — a stub encodes the same assumption the code does.

`integration/` holds Test Kitchen suites that launch real instances and assert
on the machine itself: AMI search per platform, the instance type default
following the image architecture, block device mappings, `user_data`, metadata
options, spot requests, and the Windows path end to end.

```sh
export AWS_REGION=us-east-1
bundle exec rake integration:list
bundle exec rake integration:test
bundle exec rake integration:destroy   # always, after a failed run
```

**These launch billable resources**, so they are not part of `bundle exec rake`
and never run on a pull request. Full details, including the IAM permissions
needed and how CI authenticates, are in
[integration/README.md](integration/README.md).

Changes that touch instance creation, networking, or connectivity should be
exercised this way. Confirm in the EC2 console afterwards that no instances,
security groups, key pairs, or dedicated hosts were left behind — a run that
fails partway through can leave resources running. Prefer a scratch account and
a region you do not use for anything else, so stray resources are easy to spot.

## Documentation

The library is documented with [YARD](https://yardoc.org/). Generate the HTML
docs into `doc/`:

```sh
bundle exec rake yard
```

Check documentation coverage and list anything undocumented:

```sh
bundle exec rake yard:stats
```

Browse the docs locally, reloading as you edit:

```sh
bundle exec rake yard:serve
```

Documentation is not checked in CI, so `rake yard` never fails a build. Please
still add YARD comments to new methods, and update the ones you change.

## Submitting changes

1. Fork the repository.
2. Create a feature branch off `main`.
3. Make your change, adding or updating tests to cover it.
4. Make sure `bundle exec rake` passes.
5. Push the branch to your fork and open a pull request.

Please keep pull requests focused on a single change — it makes review much
faster. Update the documentation in `README.md` when you add or change a
configuration option, and `docs/ssm-session-manager.md` for Session Manager
behaviour.

## Release process

Releases are handled by the maintainers.

1. Update `lib/kitchen/driver/ec2_version.rb` with the new version.
2. Update `CHANGELOG.md`.
3. Merge to `main`; the [publish workflow](.github/workflows/publish.yaml) builds
   the gem and pushes it to RubyGems.
