require 'test_helper'

class ContactsControllerTest < ActionDispatch::IntegrationTest
  test 'GET /contact returns success' do
    get new_contact_path
    assert_response :success
  end

  test 'POST /contact with valid params redirects to root' do
    post contacts_path, params: {
      contact: {
        email: 'test@example.com',
        message: 'Hello, I have a question about your service.',
      },
    }
    assert_redirected_to root_url
    assert_not_nil flash[:notice]
  end

  test 'POST /contact with invalid params re-renders form' do
    post contacts_path, params: {
      contact: {
        email: '',
        message: '',
      },
    }
    assert_includes [200, 422], response.status
  end

  test 'POST /contact with missing email re-renders form' do
    post contacts_path, params: {
      contact: {
        email: '',
        message: 'Valid message',
      },
    }
    assert_includes [200, 422], response.status
  end
end
