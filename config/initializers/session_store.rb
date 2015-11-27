# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_intrasite2_session',
  :secret      => 'aae2df6878f224fca39d024d43cc62b22dbdf45d46989b1c4004be4bbcd798c2f385f0bf569655342a314c965c40cc476e2624fa2b7e73ec608760a8a2343801'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
