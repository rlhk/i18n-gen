{strict-equal: eq, deep-equal: deep-eq, ok} = require 'assert'

suite 'test-setup' ->
  test 'Test can be performed' ->
    eq 'i18n-gen', 'i18n-gen'
