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

## Running the tests

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
AWS credentials.

### Manual testing against AWS

Changes that touch instance creation, networking, or connectivity should also be
exercised against a real account, since the stubbed tests cannot catch API-level
regressions.

**This launches billable resources.** Run `kitchen destroy` when you are done
and confirm in the EC2 console that no instances, security groups, key pairs, or
dedicated hosts were left behind — a run that fails partway through can leave
resources running.

Prefer a scratch account, a cheap instance type, and a region you do not use for
anything else, so stray resources are easy to spot.

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
