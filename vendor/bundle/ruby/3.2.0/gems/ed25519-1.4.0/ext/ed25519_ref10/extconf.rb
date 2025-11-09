# frozen_string_literal: true

require "mkmf"

append_cflags(["-Wall", "-O3", "-pedantic", "-std=c99"])

create_makefile "ed25519_ref10"
