# test/test_helper.exs

# Set the AUTH_SECRET_KEY environment variable for tests
System.put_env("AUTH_SECRET_KEY", "secret")

ExUnit.start()
