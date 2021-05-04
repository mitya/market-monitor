namespace :db do
  task :dump => :env do
    sh "pg_dump trading_dev > tmp/data_#{Time.current.to_s :split_number}.sql"
  end
end

# createdb trading_dev
# psql -d trading_dev < tmp/data_210420_1505.sql
