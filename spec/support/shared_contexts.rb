# frozen_string_literal: true

RSpec.shared_context 'common data' do
  let!(:developers) do
    {
      first: {
        id: '0191effd-5782-713e-8134-a59129cd7a87',
        app_id: '0191effd-b349-7740-8728-c9056f008398',
        api_token: '0191effd-e9b7-7cd2-89b9-c518b2be0f7a'
      },
      second: {
        id: '0191effe-0aa2-7430-ad59-f0a19b012032',
        app_id: '0191effe-4558-7a4d-8411-8cf503eb7558',
        api_token: '0191effe-72b1-7b2f-80b6-840ad64bb233'
      }
    }
  end

  let!(:users) do
    {
      one: {
        id: '0191effe-d200-7a69-885c-d38cf8dd855b',
        app_id: developers.dig(:one, :id)
      },
      two: {
        id: '0191efff-0a87-7850-9096-cbbf17145710',
        app_id: developers.dig(:two, :id)
      }
    }
  end

  let!(:valid_headers) do
    {
      first_dev: {
        'X-Developer-Token' => developers.dig(:first, :api_token),
        'X-User-Id' => users.dig(:one, :id),
        'X-App-Id' => developers.dig(:first, :app_id)
      },
      second_dev: {
        'X-Developer-Token' => developers.dig(:first, :api_token),
        'X-User-Id' => users.dig(:two, :id),
        'X-App-Id' => developers.dig(:second, :app_id)
      }
    }
  end

  let!(:first_dev_category_kitchen) do
    Category.create!(name: 'Kitchen Appliances',
                     description: 'Products that are to used in the kitchen',
                     developer_id: developers.dig(:first, :id))
  end

  let!(:second_dev_category_computers) do
    Category.create!(name: 'Computers',
                     description: 'Products that are to used for computing',
                     developer_id: developers.dig(:second, :id))
  end
end
