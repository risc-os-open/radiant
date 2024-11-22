begin
  ActiveRecord::Base.connection.execute('SELECT * FROM translations LIMIT 1')

  CONFIGURED_DATABASE_AVAILABLE = true

rescue ActiveRecord::ConnectionNotEstablished, # No connection to PostgreSQL
       ActiveRecord::NoDatabaseError,          # PostgreSQL available but database (e.g. "bookkeeper_test") doesn't exist
       ActiveRecord::StatementInvalid          # Database available, but tables are missing (schema not loaded)

  CONFIGURED_DATABASE_AVAILABLE = false

end
