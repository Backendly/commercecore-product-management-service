# frozen_string_literal: true

module AuthenticationHelper
  def mock_authentication(controller_class:, developer_id: nil, user_id: nil,
                          app_id: nil)
    allow_any_instance_of(UserServiceClient).to \
      receive(:fetch_developer_id).and_return(developer_id)

    allow_any_instance_of(controller_class).to \
      receive(:developer_id).and_return(developer_id)

    allow_any_instance_of(UserServiceClient).to \
      receive(:fetch_user).and_return(user_id ? { message: 'Valid user' } : nil)

    allow_any_instance_of(UserServiceClient).to \
      receive(:fetch_app).and_return(app_id ? { message: 'Valid app' } : nil)
  end
end
