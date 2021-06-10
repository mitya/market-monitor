namespace :db do
  task :dump => :env do
    sh "pg_dump trading > tmp/data_#{Time.current.to_s :split_number}.sql"
  end
end

# createdb trading
# psql -d trading < tmp/data_2105
