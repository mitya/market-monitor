require "test_helper"

class InsiderTransactionsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get insider_transactions_index_url
    assert_response :success
  end
end
