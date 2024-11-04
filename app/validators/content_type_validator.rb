# frozen_string_literal: true

# This class provides a custom validator for ActiveModel that checks if the
# content type of a given attribute is included in a specified list of allowed
# content types.
class ContentTypeValidator < ActiveModel::EachValidator
  # Validates the content type of each file in the given attribute of
  # the record.
  #
  # @param record [Object] The record to validate.
  # @param attribute [Symbol] The attribute of the record to validate.
  # @param value [Array<File>] The files to validate.
  #
  # @return [void]
  def validate_each(record, attribute, value)
    return if value.blank?

    allowed_types = options[:in] || []

    # Iterate over each file in the value.
    value.each do |file|
      next if allowed_types.include?(file.content_type)

      record.errors.add(attribute, "Invalid file type. Allowed types are: " \
        "image/png, image/jpg, image/jpeg, images/webp")
    end
  end
end
